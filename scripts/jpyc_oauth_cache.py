#!/usr/bin/env python3
"""Persist JPYC Agent MCP OAuth credentials locally and reuse them later.

This helper is intended for local operator workflows when the MCP client
does not reliably persist and refresh OAuth credentials on its own.
"""

from __future__ import annotations

import argparse
import base64
import ctypes
import ctypes.wintypes
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import webbrowser
from pathlib import Path
from typing import Any


RESOURCE = "https://jpyc-info.com/api/jpyc-agent-mcp"
OAUTH_BASE = "https://jpyc-info.com/api/jpyc-agent-oauth"
START_URL = f"{OAUTH_BASE}/start"
AUTH_SESSION_URL = f"{OAUTH_BASE}/auth-session"
TOKEN_URL = f"{OAUTH_BASE}/token"
DEFAULT_CACHE_PATH = Path.home() / ".jpyc-agent-mcp" / "oauth-cache.json"


def http_request(
    url: str,
    *,
    method: str = "GET",
    headers: dict[str, str] | None = None,
    data: bytes | None = None,
) -> tuple[int, dict[str, str], str]:
    request = urllib.request.Request(url, method=method, headers=headers or {}, data=data)
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            body = response.read().decode("utf-8")
            return response.status, dict(response.headers.items()), body
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        return exc.code, dict(exc.headers.items()), body


def http_json(
    url: str,
    *,
    method: str = "GET",
    headers: dict[str, str] | None = None,
    payload: dict[str, Any] | None = None,
    form: dict[str, str] | None = None,
) -> tuple[int, dict[str, str], Any]:
    request_headers = dict(headers or {})
    data = None
    if payload is not None:
        request_headers["Content-Type"] = "application/json"
        data = json.dumps(payload).encode("utf-8")
    elif form is not None:
        request_headers["Content-Type"] = "application/x-www-form-urlencoded"
        data = urllib.parse.urlencode(form).encode("utf-8")

    status, response_headers, body = http_request(
        url,
        method=method,
        headers=request_headers,
        data=data,
    )
    parsed = json.loads(body) if body else None
    return status, response_headers, parsed


def b64url_decode(segment: str) -> bytes:
    padding = "=" * (-len(segment) % 4)
    return base64.urlsafe_b64decode(segment + padding)


def decode_jwt_payload(token: str) -> dict[str, Any]:
    parts = token.split(".")
    if len(parts) != 3:
        raise ValueError("JWT does not have 3 segments")
    return json.loads(b64url_decode(parts[1]).decode("utf-8"))


class DATA_BLOB(ctypes.Structure):
    _fields_ = [("cbData", ctypes.wintypes.DWORD), ("pbData", ctypes.POINTER(ctypes.c_char))]


def _blob_from_bytes(data: bytes) -> DATA_BLOB:
    buffer = ctypes.create_string_buffer(data)
    return DATA_BLOB(len(data), ctypes.cast(buffer, ctypes.POINTER(ctypes.c_char)))


def _blob_to_bytes(blob: DATA_BLOB) -> bytes:
    return ctypes.string_at(blob.pbData, blob.cbData)


def protect_bytes(data: bytes) -> str:
    if os.name != "nt":
        raise RuntimeError("This helper currently supports Windows DPAPI only.")

    crypt32 = ctypes.windll.crypt32
    kernel32 = ctypes.windll.kernel32
    in_blob = _blob_from_bytes(data)
    out_blob = DATA_BLOB()

    if not crypt32.CryptProtectData(
        ctypes.byref(in_blob),
        "JPYC Agent MCP".encode("utf-16-le"),
        None,
        None,
        None,
        0,
        ctypes.byref(out_blob),
    ):
        raise ctypes.WinError()
    try:
        return base64.b64encode(_blob_to_bytes(out_blob)).decode("ascii")
    finally:
        kernel32.LocalFree(out_blob.pbData)


def unprotect_bytes(encoded: str) -> bytes:
    if os.name != "nt":
        raise RuntimeError("This helper currently supports Windows DPAPI only.")

    crypt32 = ctypes.windll.crypt32
    kernel32 = ctypes.windll.kernel32
    in_blob = _blob_from_bytes(base64.b64decode(encoded))
    out_blob = DATA_BLOB()

    if not crypt32.CryptUnprotectData(
        ctypes.byref(in_blob),
        None,
        None,
        None,
        None,
        0,
        ctypes.byref(out_blob),
    ):
        raise ctypes.WinError()
    try:
        return _blob_to_bytes(out_blob)
    finally:
        kernel32.LocalFree(out_blob.pbData)


def load_cache(cache_path: Path) -> dict[str, Any]:
    if not cache_path.exists():
        raise FileNotFoundError(f"cache file not found: {cache_path}")
    return json.loads(cache_path.read_text(encoding="utf-8"))


def save_cache(cache_path: Path, data: dict[str, Any]) -> None:
    cache_path.parent.mkdir(parents=True, exist_ok=True)
    cache_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def start_auth(args: argparse.Namespace) -> int:
    status, headers, _ = http_request(START_URL, method="GET", headers={"Accept": "application/json"})
    if status not in {302, 303}:
        print(f"unexpected status from start: {status}", file=sys.stderr)
        return 1

    authorization_url = headers.get("Location")
    if not authorization_url:
        print("missing Location header from auth start", file=sys.stderr)
        return 1

    parsed = urllib.parse.urlparse(authorization_url)
    qs = urllib.parse.parse_qs(parsed.query)
    redirect_uri = qs.get("redirect_uri", [""])[0]
    auth_session_id = urllib.parse.parse_qs(urllib.parse.urlparse(redirect_uri).query).get(
        "auth_session_id",
        [""],
    )[0]
    result = {
        "authorization_url": authorization_url,
        "auth_session_id": auth_session_id,
    }
    print(json.dumps(result, indent=2))
    if args.open_browser:
        webbrowser.open(authorization_url)
    return 0


def auth_session_info(auth_session_id: str) -> dict[str, Any]:
    status, _, data = http_json(f"{AUTH_SESSION_URL}?auth_session_id={urllib.parse.quote(auth_session_id)}")
    if status != 200:
        raise RuntimeError(f"auth-session lookup failed with status {status}: {data}")
    if not isinstance(data, dict):
        raise RuntimeError("auth-session response is not JSON object")
    return data


def persist_authorized_session(cache_path: Path, auth_session_id: str, session_data: dict[str, Any]) -> dict[str, Any]:
    access_token = session_data["access_token"]
    refresh_token = session_data["refresh_token"]
    payload = decode_jwt_payload(access_token)
    expires_at = int(time.time()) + int(session_data.get("expires_in", 0))
    cache = {
        "resource": RESOURCE,
        "token_endpoint": TOKEN_URL,
        "auth_session_id": auth_session_id,
        "client_id": payload.get("client_id"),
        "email": payload.get("email"),
        "user_id": payload.get("sub"),
        "scope": session_data.get("scope"),
        "access_token": access_token,
        "access_token_expires_at": expires_at,
        "refresh_token_protected": protect_bytes(refresh_token.encode("utf-8")),
        "saved_at": int(time.time()),
    }
    save_cache(cache_path, cache)
    return cache


def wait_for_auth(args: argparse.Namespace) -> int:
    deadline = time.time() + args.timeout_seconds
    last_status = None
    while True:
        session_data = auth_session_info(args.auth_session_id)
        status_value = session_data.get("status")
        if status_value != last_status:
            print(json.dumps({"auth_session_id": args.auth_session_id, "status": status_value}, indent=2))
            last_status = status_value
        if status_value == "authorized":
            cache = persist_authorized_session(args.cache_path, args.auth_session_id, session_data)
            print(
                json.dumps(
                    {
                        "saved": True,
                        "cache_path": str(args.cache_path),
                        "email": cache.get("email"),
                        "user_id": cache.get("user_id"),
                    },
                    indent=2,
                )
            )
            return 0
        if time.time() >= deadline:
            print("timed out waiting for authorization", file=sys.stderr)
            return 1
        time.sleep(args.poll_interval_seconds)


def refresh_access_token(cache_path: Path) -> dict[str, Any]:
    cache = load_cache(cache_path)
    refresh_token = unprotect_bytes(cache["refresh_token_protected"]).decode("utf-8")
    form = {
        "grant_type": "refresh_token",
        "refresh_token": refresh_token,
        "client_id": cache["client_id"],
    }
    status, _, data = http_json(cache["token_endpoint"], method="POST", form=form)
    if status != 200:
        raise RuntimeError(f"token refresh failed with status {status}: {data}")
    if not isinstance(data, dict):
        raise RuntimeError("token refresh response is not JSON object")

    new_access_token = data["access_token"]
    payload = decode_jwt_payload(new_access_token)
    cache["access_token"] = new_access_token
    cache["access_token_expires_at"] = int(time.time()) + int(data.get("expires_in", 0))
    cache["client_id"] = payload.get("client_id", cache.get("client_id"))
    cache["email"] = payload.get("email", cache.get("email"))
    cache["user_id"] = payload.get("sub", cache.get("user_id"))
    if "refresh_token" in data and data["refresh_token"]:
        cache["refresh_token_protected"] = protect_bytes(data["refresh_token"].encode("utf-8"))
    save_cache(cache_path, cache)
    return cache


def cached_access_token(cache_path: Path) -> dict[str, Any]:
    cache = load_cache(cache_path)
    if int(cache.get("access_token_expires_at", 0)) - int(time.time()) > 60:
        return cache
    return refresh_access_token(cache_path)


def call_mcp(cache_path: Path, payload: dict[str, Any]) -> Any:
    cache = cached_access_token(cache_path)
    status, _, data = http_json(
        RESOURCE,
        method="POST",
        headers={
            "Accept": "application/json, text/event-stream",
            "Authorization": f"Bearer {cache['access_token']}",
        },
        payload=payload,
    )
    if status != 200:
        raise RuntimeError(f"MCP call failed with status {status}: {data}")
    return data


def print_access_token(args: argparse.Namespace) -> int:
    cache = cached_access_token(args.cache_path)
    print(
        json.dumps(
            {
                "access_token": cache["access_token"],
                "expires_at": cache["access_token_expires_at"],
                "email": cache.get("email"),
                "user_id": cache.get("user_id"),
            },
            indent=2,
        )
    )
    return 0


def check_auth(args: argparse.Namespace) -> int:
    response = call_mcp(
        args.cache_path,
        {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/call",
            "params": {"name": "auth_status", "arguments": {}},
        },
    )
    print(json.dumps(response, indent=2))
    return 0


def call_tool(args: argparse.Namespace) -> int:
    arguments = json.loads(args.arguments) if args.arguments else {}
    response = call_mcp(
        args.cache_path,
        {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "tools/call",
            "params": {"name": args.tool, "arguments": arguments},
        },
    )
    print(json.dumps(response, indent=2))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.set_defaults(cache_path=DEFAULT_CACHE_PATH)
    parser.add_argument(
        "--cache-path",
        type=Path,
        default=DEFAULT_CACHE_PATH,
        help=f"default: {DEFAULT_CACHE_PATH}",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    start = subparsers.add_parser("start", help="create a new OAuth session")
    start.add_argument("--open-browser", action="store_true", help="open the auth URL automatically")
    start.set_defaults(func=start_auth)

    wait = subparsers.add_parser("wait", help="wait for auth-session authorization and save tokens")
    wait.add_argument("--auth-session-id", required=True)
    wait.add_argument("--timeout-seconds", type=int, default=300)
    wait.add_argument("--poll-interval-seconds", type=int, default=3)
    wait.set_defaults(func=wait_for_auth)

    access = subparsers.add_parser("access-token", help="refresh and print a usable access token")
    access.set_defaults(func=print_access_token)

    auth = subparsers.add_parser("auth-status", help="call auth_status using the cached token")
    auth.set_defaults(func=check_auth)

    call = subparsers.add_parser("call-tool", help="call an MCP tool using the cached token")
    call.add_argument("--tool", required=True)
    call.add_argument(
        "--arguments",
        default="{}",
        help='JSON object string for tool arguments, default "{}"',
    )
    call.set_defaults(func=call_tool)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        return args.func(args)
    except Exception as exc:  # noqa: BLE001
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
