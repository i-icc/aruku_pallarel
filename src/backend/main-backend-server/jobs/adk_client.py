import json
import os
import urllib.error
import urllib.request

from google.auth.transport import requests as google_requests
from google.oauth2 import id_token


class AdkClient:
    def __init__(
        self,
        base_url=None,
        app_name=None,
        timeout_seconds=None,
        id_token_audience=None,
    ):
        self._base_url = base_url or os.getenv("ADK_BASE_URL")
        self._app_name = app_name or os.getenv("ADK_APP_NAME")
        self._timeout_seconds = int(
            timeout_seconds or os.getenv("ADK_TIMEOUT_SECONDS", "10")
        )
        self._id_token_audience = id_token_audience or os.getenv(
            "ADK_ID_TOKEN_AUDIENCE"
        )

    def generate_message(
        self,
        lat: float,
        lon: float,
        user_id: str | None = None,
        session_id: str | None = None,
    ) -> str:
        if not self._base_url:
            raise RuntimeError("ADK_BASE_URL is not set")
        if not self._app_name:
            raise RuntimeError("ADK_APP_NAME is not set")
        resolved_user_id = _coerce_id(user_id, "unknown")
        resolved_session_id = _coerce_id(session_id, "default")
        self._ensure_session(resolved_user_id, resolved_session_id)
        payload = json.dumps(
            {
                "appName": self._app_name,
                "userId": resolved_user_id,
                "sessionId": resolved_session_id,
                "newMessage": {
                    "role": "user",
                    "parts": [{"text": json.dumps({"lat": lat, "lon": lon})}],
                },
            }
        ).encode("utf-8")
        status, body = self._post_json("/run", payload)
        if status >= 300:
            raise RuntimeError(
                f"ADK run failed: status={status} body={_decode_body(body)}"
            )

        try:
            data = json.loads(body.decode("utf-8"))
        except (json.JSONDecodeError, UnicodeDecodeError) as exc:
            raise RuntimeError("ADK response is invalid JSON") from exc

        events = _extract_events(data)
        text = _extract_text(events)
        if not text:
            raise RuntimeError("ADK response missing text")
        return _extract_message(text)

    def _ensure_session(self, user_id: str, session_id: str) -> None:
        path = f"/apps/{self._app_name}/users/{user_id}/sessions/{session_id}"
        status, body = self._post_json(path, b"{}")
        if status == 409 or _is_session_exists_error(body):
            return
        if status >= 300:
            raise RuntimeError(
                f"ADK session create failed: status={status} body={_decode_body(body)}"
            )

    def _post_json(self, path: str, payload: bytes) -> tuple[int, bytes]:
        url = f"{self._base_url.rstrip('/')}{path}"
        headers = {"Content-Type": "application/json"}
        headers.update(self._auth_header())
        request_obj = urllib.request.Request(
            url,
            data=payload,
            headers=headers,
            method="POST",
        )
        try:
            with urllib.request.urlopen(
                request_obj, timeout=self._timeout_seconds
            ) as response:
                return response.status, response.read()
        except urllib.error.HTTPError as exc:
            return exc.code, exc.read()
        except urllib.error.URLError as exc:
            raise RuntimeError(f"ADK request failed: {exc}") from exc

    def _auth_header(self) -> dict[str, str]:
        if not self._id_token_audience:
            return {}
        try:
            token = id_token.fetch_id_token(
                google_requests.Request(), self._id_token_audience
            )
        except Exception as exc:
            raise RuntimeError("ADK ID token fetch failed") from exc
        return {"Authorization": f"Bearer {token}"}


def _coerce_id(value, fallback: str) -> str:
    if isinstance(value, str) and value.strip():
        return value
    return fallback


def _extract_events(data):
    if isinstance(data, dict):
        events = data.get("events")
        if isinstance(events, list):
            return events
    if isinstance(data, list):
        return data
    raise RuntimeError("ADK response missing events")


def _extract_text(events) -> str:
    texts = []
    for event in events:
        if not isinstance(event, dict):
            continue
        content = event.get("content")
        if not isinstance(content, dict):
            continue
        parts = content.get("parts")
        if not isinstance(parts, list):
            continue
        for part in parts:
            if not isinstance(part, dict):
                continue
            text = part.get("text")
            if isinstance(text, str):
                texts.append(text)
    return "".join(texts).strip()


def _extract_message(text: str) -> str:
    message = _parse_message_from_json(text)
    if message:
        return message
    start = text.find("{")
    end = text.rfind("}")
    if start != -1 and end > start:
        message = _parse_message_from_json(text[start : end + 1])
        if message:
            return message
    return text.strip()


def _parse_message_from_json(text: str) -> str | None:
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        return None
    message = data.get("message")
    if isinstance(message, str) and message.strip():
        return message.strip()
    return None


def _decode_body(body: bytes) -> str:
    try:
        return body.decode("utf-8")
    except UnicodeDecodeError:
        return "<binary>"


def _is_session_exists_error(body: bytes) -> bool:
    text = _decode_body(body).lower()
    return "session already exists" in text
