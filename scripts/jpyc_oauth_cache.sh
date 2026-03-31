#!/usr/bin/env bash
# -------------------------------------------------------------------
# jpyc_oauth_cache.sh — JPYC Agent MCP OAuth helper (bash + curl)
#
# Portable alternative to the PowerShell / Python helpers.
# Works in Git Bash on Windows, macOS Terminal, and Linux.
#
# Dependencies: curl, base64, bash >=4
#
# Usage:
#   ./jpyc_oauth_cache.sh start [--open-browser]
#   ./jpyc_oauth_cache.sh wait  --auth-session-id <id> [--timeout 300]
#   ./jpyc_oauth_cache.sh access-token
#   ./jpyc_oauth_cache.sh auth-status
#   ./jpyc_oauth_cache.sh call-tool --tool <name> [--arguments '{}']
# -------------------------------------------------------------------
set -euo pipefail

RESOURCE="https://jpyc-info.com/api/jpyc-agent-mcp"
OAUTH_BASE="https://jpyc-info.com/api/jpyc-agent-oauth"
START_URL="${OAUTH_BASE}/start"
AUTH_SESSION_URL="${OAUTH_BASE}/auth-session"
TOKEN_URL="${OAUTH_BASE}/token"
CACHE_DIR="${HOME}/.jpyc-agent-mcp"
CACHE_PATH="${CACHE_DIR}/oauth-cache.json"

# ── Minimal JSON helpers (no jq required) ─────────────────────────

# Extract a top-level string value from a flat JSON object.
# Usage: json_get '{"key":"value"}' key  →  value
json_get() {
  local json="$1" key="$2"
  # Handles: "key": "value" and "key":"value"
  printf '%s' "$json" \
    | sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -1
}

# Extract a top-level numeric value from a flat JSON object.
json_get_num() {
  local json="$1" key="$2"
  printf '%s' "$json" \
    | sed -n 's/.*"'"$key"'"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' \
    | head -1
}

# ── JWT decode ────────────────────────────────────────────────────

decode_jwt_payload() {
  local token="$1"
  local payload
  payload=$(printf '%s' "$token" | cut -d. -f2)
  # Add padding
  local pad=$(( 4 - ${#payload} % 4 ))
  if (( pad == 1 )); then payload="${payload}=";
  elif (( pad == 2 )); then payload="${payload}==";
  elif (( pad == 3 )); then payload="${payload}==="; fi
  # URL-safe base64 → standard base64
  payload=$(printf '%s' "$payload" | tr '_-' '/+')
  printf '%s' "$payload" | base64 --decode 2>/dev/null
}

# ── Cache I/O ─────────────────────────────────────────────────────

save_cache() {
  mkdir -p "$CACHE_DIR"
  cat > "$CACHE_PATH"
  chmod 600 "$CACHE_PATH" 2>/dev/null || true
}

load_cache() {
  if [[ ! -f "$CACHE_PATH" ]]; then
    echo "Error: cache file not found: $CACHE_PATH" >&2
    exit 1
  fi
  cat "$CACHE_PATH"
}

# ── Open browser (cross-platform) ────────────────────────────────

open_url() {
  local url="$1"
  if command -v cmd.exe >/dev/null 2>&1; then
    cmd.exe /c start "" "$url" 2>/dev/null
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url"
  elif command -v open >/dev/null 2>&1; then
    open "$url"
  else
    echo "(Could not auto-open browser. Open this URL manually.)" >&2
  fi
}

# ── Commands ──────────────────────────────────────────────────────

cmd_start() {
  local open_browser=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --open-browser) open_browser=true; shift ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
  done

  # Follow-redirect disabled; capture Location header
  local response
  response=$(curl -s -D - -o /dev/null -X GET \
    -H "Accept: application/json" \
    --max-redirs 0 \
    "$START_URL" 2>&1 || true)

  local location
  location=$(printf '%s' "$response" | grep -i '^location:' | head -1 | tr -d '\r' | sed 's/^[Ll]ocation:[[:space:]]*//')

  if [[ -z "$location" ]]; then
    echo "Error: no Location header from start endpoint" >&2
    echo "$response" >&2
    exit 1
  fi

  # Parse auth_session_id from redirect_uri inside the authorization URL
  local redirect_uri auth_session_id
  redirect_uri=$(printf '%s' "$location" | sed -n 's/.*[?&]redirect_uri=\([^&]*\).*/\1/p')
  redirect_uri=$(printf '%b' "$(printf '%s' "$redirect_uri" | sed 's/%\([0-9A-Fa-f][0-9A-Fa-f]\)/\\x\1/g')")
  auth_session_id=$(printf '%s' "$redirect_uri" | sed -n 's/.*[?&]auth_session_id=\([^&]*\).*/\1/p')

  cat <<EOF
{
  "authorization_url": "${location}",
  "auth_session_id": "${auth_session_id}"
}
EOF

  if [[ "$open_browser" == true ]]; then
    open_url "$location"
  fi
}

cmd_wait() {
  local auth_session_id="" timeout_seconds=300 poll_interval=3
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --auth-session-id) auth_session_id="$2"; shift 2 ;;
      --timeout)         timeout_seconds="$2"; shift 2 ;;
      --poll-interval)   poll_interval="$2"; shift 2 ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
  done

  if [[ -z "$auth_session_id" ]]; then
    echo "Error: --auth-session-id is required" >&2
    exit 1
  fi

  local deadline last_status=""
  deadline=$(( $(date +%s) + timeout_seconds ))

  while true; do
    local body
    body=$(curl -s -X GET "${AUTH_SESSION_URL}?auth_session_id=$(printf '%s' "$auth_session_id" | sed 's/ /%20/g')")
    local status_value
    status_value=$(json_get "$body" "status")

    if [[ "$status_value" != "$last_status" ]]; then
      echo "Status: $status_value"
      last_status="$status_value"
    fi

    if [[ "$status_value" == "authorized" ]]; then
      local access_token refresh_token expires_in scope
      access_token=$(json_get "$body" "access_token")
      refresh_token=$(json_get "$body" "refresh_token")
      expires_in=$(json_get_num "$body" "expires_in")
      scope=$(json_get "$body" "scope")

      local jwt_payload client_id email user_id
      jwt_payload=$(decode_jwt_payload "$access_token")
      client_id=$(json_get "$jwt_payload" "client_id")
      email=$(json_get "$jwt_payload" "email")
      user_id=$(json_get "$jwt_payload" "sub")

      local now expires_at
      now=$(date +%s)
      expires_at=$(( now + ${expires_in:-0} ))

      cat <<EOF | save_cache
{
  "resource": "${RESOURCE}",
  "token_endpoint": "${TOKEN_URL}",
  "auth_session_id": "${auth_session_id}",
  "client_id": "${client_id}",
  "email": "${email}",
  "user_id": "${user_id}",
  "scope": "${scope}",
  "access_token": "${access_token}",
  "access_token_expires_at": ${expires_at},
  "refresh_token": "${refresh_token}",
  "saved_at": ${now}
}
EOF
      echo "Saved to ${CACHE_PATH}"
      echo "Email: ${email}"
      echo "User:  ${user_id}"
      return 0
    fi

    if (( $(date +%s) >= deadline )); then
      echo "Error: timed out waiting for authorization" >&2
      exit 1
    fi
    sleep "$poll_interval"
  done
}

# ── Token management ──────────────────────────────────────────────

refresh_access_token() {
  local cache
  cache=$(load_cache)
  local rt client_id token_endpoint
  rt=$(json_get "$cache" "refresh_token")
  client_id=$(json_get "$cache" "client_id")
  token_endpoint=$(json_get "$cache" "token_endpoint")

  local resp
  resp=$(curl -s -X POST "$token_endpoint" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=refresh_token&refresh_token=${rt}&client_id=${client_id}")

  local new_at new_rt new_expires_in
  new_at=$(json_get "$resp" "access_token")
  new_rt=$(json_get "$resp" "refresh_token")
  new_expires_in=$(json_get_num "$resp" "expires_in")

  if [[ -z "$new_at" ]]; then
    echo "Error: token refresh failed: $resp" >&2
    exit 1
  fi

  local jwt_payload new_client_id new_email new_user_id
  jwt_payload=$(decode_jwt_payload "$new_at")
  new_client_id=$(json_get "$jwt_payload" "client_id")
  new_email=$(json_get "$jwt_payload" "email")
  new_user_id=$(json_get "$jwt_payload" "sub")

  local now new_expires_at scope auth_session_id
  now=$(date +%s)
  new_expires_at=$(( now + ${new_expires_in:-0} ))
  scope=$(json_get "$cache" "scope")
  auth_session_id=$(json_get "$cache" "auth_session_id")

  # Use new refresh_token if rotated, otherwise keep old one
  local final_rt="${new_rt:-$rt}"

  cat <<EOF | save_cache
{
  "resource": "${RESOURCE}",
  "token_endpoint": "${token_endpoint}",
  "auth_session_id": "${auth_session_id}",
  "client_id": "${new_client_id:-$client_id}",
  "email": "${new_email}",
  "user_id": "${new_user_id}",
  "scope": "${scope}",
  "access_token": "${new_at}",
  "access_token_expires_at": ${new_expires_at},
  "refresh_token": "${final_rt}",
  "saved_at": ${now}
}
EOF
}

get_access_token() {
  local cache
  cache=$(load_cache)
  local expires_at now
  expires_at=$(json_get_num "$cache" "access_token_expires_at")
  now=$(date +%s)
  if (( expires_at - now > 60 )); then
    printf '%s' "$cache"
    return
  fi
  refresh_access_token >&2
  load_cache
}

call_mcp() {
  local payload="$1"
  local cache access_token
  cache=$(get_access_token)
  access_token=$(json_get "$cache" "access_token")

  curl -s -X POST "$RESOURCE" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    -H "Authorization: Bearer ${access_token}" \
    -d "$payload"
}

# ── Subcommands (continued) ───────────────────────────────────────

cmd_access_token() {
  local cache
  cache=$(get_access_token)
  local at expires email uid
  at=$(json_get "$cache" "access_token")
  expires=$(json_get_num "$cache" "access_token_expires_at")
  email=$(json_get "$cache" "email")
  uid=$(json_get "$cache" "user_id")
  cat <<EOF
{
  "access_token": "${at}",
  "expires_at": ${expires},
  "email": "${email}",
  "user_id": "${uid}"
}
EOF
}

cmd_auth_status() {
  call_mcp '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"auth_status","arguments":{}}}'
  echo
}

cmd_call_tool() {
  local tool="" arguments="{}"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tool)      tool="$2"; shift 2 ;;
      --arguments) arguments="$2"; shift 2 ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
  done
  if [[ -z "$tool" ]]; then
    echo "Error: --tool is required" >&2
    exit 1
  fi
  call_mcp "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"${tool}\",\"arguments\":${arguments}}}"
  echo
}

# ── Dispatch ──────────────────────────────────────────────────────

show_help() {
  cat <<'HELP'
JPYC Agent MCP OAuth Cache Helper (bash)

Usage:
  jpyc_oauth_cache.sh start [--open-browser]
  jpyc_oauth_cache.sh wait  --auth-session-id <id> [--timeout 300]
  jpyc_oauth_cache.sh access-token
  jpyc_oauth_cache.sh auth-status
  jpyc_oauth_cache.sh call-tool --tool <name> [--arguments '{}']

Cache: ~/.jpyc-agent-mcp/oauth-cache.json
HELP
}

command="${1:-help}"
shift || true

case "$command" in
  start)        cmd_start "$@" ;;
  wait)         cmd_wait "$@" ;;
  access-token) cmd_access_token ;;
  auth-status)  cmd_auth_status ;;
  call-tool)    cmd_call_tool "$@" ;;
  help|--help|-h) show_help ;;
  *)
    echo "Unknown command: $command" >&2
    show_help
    exit 1
    ;;
esac
