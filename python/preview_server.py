#!/usr/bin/env python3
# pyright: reportMissingImports=false
"""JSON-line preview server for nvim-bardic."""

from __future__ import annotations

import json
import sys
import traceback
from typing import Any

try:
    from bardic.runtime.engine import BardEngine
except ImportError as err:
    print(
        json.dumps(
            {
                "error": "bardic-not-installed",
                "message": "Please install Bardic: pip install bardic",
            }
        ),
        flush=True,
    )
    raise SystemExit(1) from err


def emit(payload: dict[str, Any]) -> None:
    print(json.dumps(payload), flush=True)


def serialize_output(output: Any) -> dict[str, Any]:
    return {
        "content": getattr(output, "content", ""),
        "choices": getattr(output, "choices", []) or [],
        "passage_id": getattr(output, "passage_id", None),
        "has_choices": bool(getattr(output, "choices", []) or []),
    }


def make_engine(story: dict[str, Any]) -> BardEngine:
    return BardEngine(story)


def main() -> int:
    story_line = sys.stdin.readline()
    if not story_line:
        emit({"error": "missing-story", "message": "No story JSON was provided"})
        return 1

    try:
        story = json.loads(story_line)
        engine = make_engine(story)
    except Exception as exc:  # noqa: BLE001 - sent to editor UI
        emit(
            {
                "error": "engine-init-failed",
                "message": str(exc),
                "traceback": traceback.format_exc(),
            }
        )
        return 1

    emit({"status": "ready"})

    for line in sys.stdin:
        if not line.strip():
            continue
        try:
            command = json.loads(line)
            command_type = command.get("type")

            if command_type == "preview":
                state = command.get("state") or {}
                passage = command.get("passage")
                if hasattr(engine, "state"):
                    engine.state.update(state)
                output = engine.goto(passage) if passage else engine.current()
                emit(serialize_output(output))
            elif command_type == "choice":
                output = engine.choose(int(command.get("index")))
                emit(serialize_output(output))
            elif command_type == "current":
                emit(serialize_output(engine.current()))
            elif command_type == "reset":
                engine = make_engine(story)
                output = engine.current()
                emit(serialize_output(output))
            elif command_type == "exit":
                return 0
            else:
                emit({"error": "unknown-command", "message": str(command_type)})
        except Exception as exc:  # noqa: BLE001 - sent to editor UI
            emit(
                {
                    "error": "preview-error",
                    "message": str(exc),
                    "traceback": traceback.format_exc(),
                }
            )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
