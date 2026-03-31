<#
.SYNOPSIS
    Persist JPYC Agent MCP OAuth credentials locally and reuse them later.

.DESCRIPTION
    PowerShell version of the OAuth token cache helper for Windows users
    who do not have Python installed. Uses Windows DPAPI to encrypt the
    refresh token at rest.

.EXAMPLE
    # First-time setup
    .\jpyc_oauth_cache.ps1 start -OpenBrowser
    .\jpyc_oauth_cache.ps1 wait -AuthSessionId <id>

    # Reuse across sessions
    .\jpyc_oauth_cache.ps1 auth-status
    .\jpyc_oauth_cache.ps1 call-tool -Tool list_agent_wallets -Arguments '{"limit":20,"chain":"polygon"}'
#>
param(
    [Parameter(Position=0)]
    [string]$Command,
    [string]$AuthSessionId,
    [string]$Tool,
    [string]$Arguments = "{}",
    [int]$TimeoutSeconds = 300,
    [int]$PollIntervalSeconds = 3,
    [switch]$OpenBrowser
)

$RESOURCE = "https://jpyc-info.com/api/jpyc-agent-mcp"
$OAUTH_BASE = "https://jpyc-info.com/api/jpyc-agent-oauth"
$START_URL = "$OAUTH_BASE/start"
$AUTH_SESSION_URL = "$OAUTH_BASE/auth-session"
$TOKEN_URL = "$OAUTH_BASE/token"
$CACHE_PATH = Join-Path $env:USERPROFILE ".jpyc-agent-mcp\oauth-cache.json"

Add-Type -AssemblyName System.Security
Add-Type -AssemblyName System.Web

function Protect-String([string]$plainText) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($plainText)
    $encrypted = [System.Security.Cryptography.ProtectedData]::Protect(
        $bytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser
    )
    return [Convert]::ToBase64String($encrypted)
}

function Unprotect-String([string]$encoded) {
    $encrypted = [Convert]::FromBase64String($encoded)
    $bytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
        $encrypted, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser
    )
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

function Decode-JwtPayload([string]$token) {
    $parts = $token.Split(".")
    $payload = $parts[1]
    $padding = switch ($payload.Length % 4) { 2 { "==" } 3 { "=" } default { "" } }
    $decoded = [System.Text.Encoding]::UTF8.GetString(
        [Convert]::FromBase64String($payload.Replace("-","+").Replace("_","/") + $padding)
    )
    return $decoded | ConvertFrom-Json
}

function Load-Cache {
    if (-not (Test-Path $CACHE_PATH)) { throw "Cache file not found: $CACHE_PATH" }
    return Get-Content $CACHE_PATH -Raw | ConvertFrom-Json
}

function Save-Cache($data) {
    $dir = Split-Path $CACHE_PATH
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $data | ConvertTo-Json -Depth 10 | Set-Content $CACHE_PATH -Encoding UTF8
}

function Do-Start {
    $request = [System.Net.HttpWebRequest]::Create($START_URL)
    $request.Method = "GET"
    $request.Accept = "application/json"
    $request.AllowAutoRedirect = $false
    $request.Timeout = 30000
    try {
        $response = $request.GetResponse()
    } catch [System.Net.WebException] {
        $response = $_.Exception.Response
    }
    $statusCode = [int]$response.StatusCode
    $location = $response.Headers["Location"]
    $response.Close()

    if ($statusCode -notin @(302, 303) -or -not $location) {
        Write-Error "Unexpected status $statusCode from start endpoint"
        return
    }

    $uri = [System.Uri]$location
    $qs = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
    $redirectUri = $qs["redirect_uri"]
    $redirectQs = [System.Web.HttpUtility]::ParseQueryString(([System.Uri]$redirectUri).Query)
    $sessionId = $redirectQs["auth_session_id"]

    $result = @{ authorization_url = $location; auth_session_id = $sessionId }
    $result | ConvertTo-Json -Depth 5
    if ($OpenBrowser) { Start-Process $location }
}

function Do-Wait {
    if (-not $AuthSessionId) { throw "-AuthSessionId is required" }
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $lastStatus = $null
    while ($true) {
        $url = "${AUTH_SESSION_URL}?auth_session_id=$([System.Uri]::EscapeDataString($AuthSessionId))"
        $resp = Invoke-RestMethod -Uri $url -Method GET -TimeoutSec 30 -ErrorAction Stop
        $statusValue = $resp.status
        if ($statusValue -ne $lastStatus) {
            Write-Host "Status: $statusValue"
            $lastStatus = $statusValue
        }
        if ($statusValue -eq "authorized") {
            $accessToken = $resp.access_token
            $refreshToken = $resp.refresh_token
            $payload = Decode-JwtPayload $accessToken
            $expiresAt = [int](Get-Date -UFormat %s) + [int]($resp.expires_in)
            $cache = @{
                resource = $RESOURCE
                token_endpoint = $TOKEN_URL
                auth_session_id = $AuthSessionId
                client_id = $payload.client_id
                email = $payload.email
                user_id = $payload.sub
                scope = $resp.scope
                access_token = $accessToken
                access_token_expires_at = $expiresAt
                refresh_token_protected = (Protect-String $refreshToken)
                saved_at = [int](Get-Date -UFormat %s)
            }
            Save-Cache $cache
            Write-Host "Saved to $CACHE_PATH"
            Write-Host "Email: $($payload.email)"
            Write-Host "User: $($payload.sub)"
            return
        }
        if ((Get-Date) -ge $deadline) { throw "Timed out waiting for authorization" }
        Start-Sleep -Seconds $PollIntervalSeconds
    }
}

function Refresh-AccessToken {
    $cache = Load-Cache
    $refreshToken = Unprotect-String $cache.refresh_token_protected
    $form = @{
        grant_type = "refresh_token"
        refresh_token = $refreshToken
        client_id = $cache.client_id
    }
    $resp = Invoke-RestMethod -Uri $cache.token_endpoint -Method POST -Body $form `
        -ContentType "application/x-www-form-urlencoded" -TimeoutSec 30
    $newAccessToken = $resp.access_token
    $payload = Decode-JwtPayload $newAccessToken
    $cache.access_token = $newAccessToken
    $cache.access_token_expires_at = [int](Get-Date -UFormat %s) + [int]($resp.expires_in)
    $cache.client_id = $payload.client_id
    $cache.email = $payload.email
    $cache.user_id = $payload.sub
    if ($resp.refresh_token) {
        $cache.refresh_token_protected = (Protect-String $resp.refresh_token)
    }
    Save-Cache $cache
    return $cache
}

function Get-CachedAccessToken {
    $cache = Load-Cache
    $now = [int](Get-Date -UFormat %s)
    if (($cache.access_token_expires_at - $now) -gt 60) { return $cache }
    return Refresh-AccessToken
}

function Call-Mcp($payload) {
    $cache = Get-CachedAccessToken
    $headers = @{
        "Authorization" = "Bearer $($cache.access_token)"
        "Accept" = "application/json, text/event-stream"
    }
    $body = $payload | ConvertTo-Json -Depth 10
    $resp = Invoke-RestMethod -Uri $RESOURCE -Method POST -Headers $headers `
        -Body $body -ContentType "application/json" -TimeoutSec 30
    return $resp
}

function Do-AuthStatus {
    $payload = @{
        jsonrpc = "2.0"
        id = 1
        method = "tools/call"
        params = @{ name = "auth_status"; arguments = @{} }
    }
    $resp = Call-Mcp $payload
    $resp | ConvertTo-Json -Depth 10
}

function Do-CallTool {
    if (-not $Tool) { throw "-Tool is required" }
    $args_parsed = $Arguments | ConvertFrom-Json
    $payload = @{
        jsonrpc = "2.0"
        id = 1
        method = "tools/call"
        params = @{ name = $Tool; arguments = $args_parsed }
    }
    $resp = Call-Mcp $payload
    $resp | ConvertTo-Json -Depth 10
}

function Do-AccessToken {
    $cache = Get-CachedAccessToken
    @{
        access_token = $cache.access_token
        expires_at = $cache.access_token_expires_at
        email = $cache.email
        user_id = $cache.user_id
    } | ConvertTo-Json -Depth 5
}

switch ($Command) {
    "start"        { Do-Start }
    "wait"         { Do-Wait }
    "access-token" { Do-AccessToken }
    "auth-status"  { Do-AuthStatus }
    "call-tool"    { Do-CallTool }
    default {
        Write-Host @"
JPYC Agent MCP OAuth Cache Helper (PowerShell)

Usage:
  .\jpyc_oauth_cache.ps1 start [-OpenBrowser]
  .\jpyc_oauth_cache.ps1 wait -AuthSessionId <id> [-TimeoutSeconds 300]
  .\jpyc_oauth_cache.ps1 access-token
  .\jpyc_oauth_cache.ps1 auth-status
  .\jpyc_oauth_cache.ps1 call-tool -Tool <name> [-Arguments '{}']

Cache: $CACHE_PATH
"@
    }
}
