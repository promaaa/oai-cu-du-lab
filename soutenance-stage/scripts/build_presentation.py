#!/usr/bin/env python3
"""Rebuild the editable PPTX with the required Artifact Tool runtime."""

from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
BUILD_DIR = ROOT / ".build"
SOURCE_MJS = ROOT / "scripts" / "build_presentation.mjs"


def find_skill_dir() -> Path:
    explicit = os.environ.get("CODEX_PRESENTATIONS_SKILL_DIR")
    if explicit:
        return Path(explicit).expanduser().resolve()
    cache = Path.home() / ".codex" / "plugins" / "cache" / "openai-primary-runtime" / "presentations"
    candidates = sorted(cache.glob("*/skills/presentations"), reverse=True)
    if not candidates:
        raise SystemExit("Présentation skill introuvable. Définir CODEX_PRESENTATIONS_SKILL_DIR.")
    return candidates[0]


def main() -> int:
    node = os.environ.get("NODE") or shutil.which("node")
    if not node:
        raise SystemExit("Node.js est requis pour reconstruire le PowerPoint.")
    skill_dir = find_skill_dir()
    setup = skill_dir / "container_tools" / "setup_artifact_tool_workspace.mjs"
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    subprocess.run([node, str(setup), "--workspace", str(BUILD_DIR)], check=True)
    staged_mjs = BUILD_DIR / "build_presentation.mjs"
    shutil.copy2(SOURCE_MJS, staged_mjs)
    env = dict(os.environ)
    env["SOUTENANCE_ROOT"] = str(ROOT)
    subprocess.run([node, str(staged_mjs)], check=True, cwd=BUILD_DIR, env=env)
    (ROOT / "presentation" / "soutenance-stage-marc-duboc.pptx.inspect.ndjson").unlink(missing_ok=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
