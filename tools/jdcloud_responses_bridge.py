#!/usr/bin/env python3
"""Bridge OpenAI Responses requests to a JD Cloud Anthropic Messages endpoint.

This exposes a local Responses-compatible API at /v1 so Codex can talk to a
custom provider, while the bridge forwards each request to the upstream JD
Cloud Anthropic endpoint.
"""

from __future__ import annotations

import argparse
import json
import os
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any
from urllib import error, request


UPSTREAM_URL = "https://modelservice.jdcloud.com/anthropic/v1/messages"


def _parse_text_from_content(content: Any) -> str:
    if isinstance(content, str):
        return content

    if isinstance(content, list):
        parts: list[str] = []
        for part in content:
            if not isinstance(part, dict):
                continue
            if part.get("type") in {"input_text", "output_text", "text"}:
                text = part.get("text")
                if isinstance(text, str) and text:
                    parts.append(text)
        return "\n".join(parts).strip()

    return ""


def _extract_messages(body: dict[str, Any]) -> tuple[str, list[dict[str, str]]]:
    system_prompt = ""
    if isinstance(body.get("instructions"), str):
        system_prompt = body["instructions"].strip()

    messages: list[dict[str, str]] = []
    input_items = body.get("input")
    if isinstance(input_items, str):
        text = input_items.strip()
        if text:
            messages.append({"role": "user", "content": text})
        return system_prompt, messages

    if not isinstance(input_items, list):
        return system_prompt, messages

    for item in input_items:
        if not isinstance(item, dict):
            continue
        item_type = item.get("type")
        if item_type != "message":
            continue
        role = item.get("role")
        if role not in {"user", "assistant"}:
            continue
        text = _parse_text_from_content(item.get("content"))
        if text:
            messages.append({"role": role, "content": text})

    return system_prompt, messages


def _upstream_call(payload: dict[str, Any], api_key: str) -> dict[str, Any]:
    req = request.Request(
        UPSTREAM_URL,
        data=json.dumps(payload).encode("utf-8"),
        method="POST",
    )
    req.add_header("Authorization", f"Bearer {api_key}")
    req.add_header("Content-Type", "application/json")

    try:
        with request.urlopen(req, timeout=120) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except error.HTTPError as exc:
        detail = exc.read().decode("utf-8", "replace")
        raise RuntimeError(f"upstream HTTP {exc.code}: {detail}") from exc


def _extract_text(upstream: dict[str, Any]) -> str:
    parts: list[str] = []
    for item in upstream.get("content", []):
        if isinstance(item, dict) and item.get("type") == "text":
            text = item.get("text")
            if isinstance(text, str):
                parts.append(text)
    return "".join(parts)


def _response_object(model: str, text: str) -> dict[str, Any]:
    response_id = f"resp_{uuid.uuid4().hex[:24]}"
    message_id = f"msg_{uuid.uuid4().hex[:24]}"
    created_at = int(time.time())
    return {
        "id": response_id,
        "object": "response",
        "created_at": created_at,
        "status": "completed",
        "model": model,
        "output": [
            {
                "type": "message",
                "id": message_id,
                "status": "completed",
                "role": "assistant",
                "content": [
                    {
                        "type": "output_text",
                        "text": text,
                        "annotations": [],
                    }
                ],
            }
        ],
        "usage": {
            "input_tokens": 0,
            "output_tokens": 0,
            "total_tokens": 0,
        },
    }


def _sse_event(event_type: str, payload: dict[str, Any]) -> bytes:
    data = json.dumps(payload, ensure_ascii=False)
    return f"event: {event_type}\ndata: {data}\n\n".encode("utf-8")


class BridgeHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, format: str, *args: Any) -> None:
        return

    def _send_json(self, status: int, payload: dict[str, Any]) -> None:
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _send_sse(self, status: int, events: list[tuple[str, dict[str, Any]]]) -> None:
        self.send_response(status)
        self.send_header("Content-Type", "text/event-stream; charset=utf-8")
        self.send_header("Cache-Control", "no-cache, no-transform")
        self.send_header("Connection", "close")
        self.end_headers()
        for event_type, payload in events:
            self.wfile.write(_sse_event(event_type, payload))
            self.wfile.flush()
        self.close_connection = True

    def do_GET(self) -> None:  # noqa: N802
        if self.path == "/v1/models":
            model_id = os.environ.get("JD_MODEL_ID", "T-C-4-jy")
            self._send_json(
                200,
                {
                    "object": "list",
                    "data": [{"id": model_id, "object": "model"}],
                },
            )
            return

        if self.path.startswith("/v1/models/"):
            model_id = self.path.rsplit("/", 1)[-1]
            self._send_json(200, {"id": model_id, "object": "model"})
            return

        if self.path == "/healthz":
            self._send_json(200, {"ok": True})
            return

        self._send_json(404, {"error": {"message": "not_found"}})

    def do_POST(self) -> None:  # noqa: N802
        if self.path != "/v1/responses":
            self._send_json(404, {"error": {"message": "not_found"}})
            return

        try:
            length = int(self.headers.get("Content-Length", "0"))
            body = json.loads(self.rfile.read(length) or b"{}")
            model = str(body.get("model") or os.environ.get("JD_MODEL_ID", "T-C-4-jy"))
            stream_requested = bool(body.get("stream", False))
            max_tokens = int(body.get("max_output_tokens") or body.get("max_tokens") or 1000)
            thinking_budget = int(body.get("thinking_budget") or 1024)
            system_prompt, messages = _extract_messages(body)

            if not messages:
                raise ValueError("no message input provided")

            upstream_payload: dict[str, Any] = {
                "model": model,
                "messages": messages,
                "thinking_budget": thinking_budget,
                "max_tokens": max_tokens,
                "stream": False,
            }
            if system_prompt:
                upstream_payload["system"] = system_prompt

            api_key = os.environ["JD_MODEL_API_KEY"]
            upstream = _upstream_call(upstream_payload, api_key)
            text = _extract_text(upstream)
            response = _response_object(model, text)

            if stream_requested:
                response_id = response["id"]
                message_id = response["output"][0]["id"]
                events = [
                    (
                        "response.created",
                        {
                            "type": "response.created",
                            "response": {
                                "id": response_id,
                                "object": "response",
                                "created_at": response["created_at"],
                                "status": "in_progress",
                                "model": model,
                                "output": [],
                            },
                        },
                    ),
                    (
                        "response.output_item.added",
                        {
                            "type": "response.output_item.added",
                            "output_index": 0,
                            "item": {
                                "id": message_id,
                                "type": "message",
                                "status": "in_progress",
                                "role": "assistant",
                                "content": [],
                            },
                        },
                    ),
                    (
                        "response.content_part.added",
                        {
                            "type": "response.content_part.added",
                            "item_id": message_id,
                            "output_index": 0,
                            "content_index": 0,
                            "part": {
                                "type": "output_text",
                                "text": "",
                                "annotations": [],
                            },
                        },
                    ),
                    (
                        "response.output_text.delta",
                        {
                            "type": "response.output_text.delta",
                            "item_id": message_id,
                            "output_index": 0,
                            "content_index": 0,
                            "delta": text,
                            "sequence_number": 1,
                        },
                    ),
                    (
                        "response.output_text.done",
                        {
                            "type": "response.output_text.done",
                            "item_id": message_id,
                            "output_index": 0,
                            "content_index": 0,
                            "text": text,
                            "sequence_number": 2,
                        },
                    ),
                    (
                        "response.content_part.done",
                        {
                            "type": "response.content_part.done",
                            "item_id": message_id,
                            "output_index": 0,
                            "content_index": 0,
                            "part": {
                                "type": "output_text",
                                "text": text,
                                "annotations": [],
                            },
                        },
                    ),
                    (
                        "response.output_item.done",
                        {
                            "type": "response.output_item.done",
                            "output_index": 0,
                            "item": {
                                "id": message_id,
                                "type": "message",
                                "status": "completed",
                                "role": "assistant",
                                "content": [
                                    {
                                        "type": "output_text",
                                        "text": text,
                                        "annotations": [],
                                    }
                                ],
                            },
                        },
                    ),
                    (
                        "response.completed",
                        {
                            "type": "response.completed",
                            "response": response,
                        },
                    ),
                ]
                self._send_sse(200, events)
                return

            self._send_json(200, response)
        except KeyError as exc:
            self._send_json(400, {"error": {"message": f"missing environment variable: {exc.args[0]}"}})
        except ValueError as exc:
            self._send_json(400, {"error": {"message": str(exc)}})
        except RuntimeError as exc:
            self._send_json(502, {"error": {"message": str(exc)}})
        except Exception as exc:  # pragma: no cover - defensive guard
            self._send_json(500, {"error": {"message": f"bridge failure: {exc}"}})


def main() -> int:
    parser = argparse.ArgumentParser(description="JD Cloud Anthropic to Responses bridge")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", default=8000, type=int)
    args = parser.parse_args()

    server = ThreadingHTTPServer((args.host, args.port), BridgeHandler)
    print(f"Bridge listening on http://{args.host}:{args.port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
