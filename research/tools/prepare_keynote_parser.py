#!/usr/bin/env python3
"""Assemble the proven Keynote 15.3-schema/14.4-registry parser locally."""
from __future__ import annotations

import hashlib
import importlib.metadata
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCHEMAS = ROOT / "vendor/keynote-parser/protos/15.3"
COMPAT = ROOT / "vendor/keynote-parser/compat/14.4"
CACHE = ROOT / "build/keynote-parser"
PARSER_VERSION = "1.14.4.0"
GRPC_TOOLS_VERSION = "1.82.1"


def tree_hash(paths: list[Path]) -> str:
    digest = hashlib.sha256()
    for path in sorted(paths):
        digest.update(str(path.relative_to(ROOT)).encode())
        digest.update(path.read_bytes())
    return digest.hexdigest()[:20]


def rewrite_imports(path: Path) -> None:
    text = path.read_text()
    text = re.sub(
        r"^import (\w+_pb2) as (\w+__pb2)$",
        r"from . import \1 as \2",
        text,
        flags=re.MULTILINE,
    )
    path.write_text(text)


def validate(package_root: Path) -> None:
    code = """
from google.protobuf import symbol_database
from keynote_parser import mapping
assert len(mapping.TSPRegistryMapping) == 631, len(mapping.TSPRegistryMapping)
symbols = symbol_database.Default()
missing = []
for name in mapping.TSPRegistryMapping.values():
    try: symbols.GetSymbol(name)
    except KeyError: missing.append(name)
assert not missing, missing
print('631 registry entries; 0 missing message names')
"""
    subprocess.run(
        [sys.executable, "-c", code], check=True,
        env={"PYTHONPATH": str(package_root)},
    )


def prepare() -> Path:
    actual = importlib.metadata.version("keynote-parser")
    if actual != PARSER_VERSION:
        raise SystemExit(f"keynote-parser=={PARSER_VERSION} required; found {actual}")
    compiler = importlib.metadata.version("grpcio-tools")
    if compiler != GRPC_TOOLS_VERSION:
        raise SystemExit(f"grpcio-tools=={GRPC_TOOLS_VERSION} required; found {compiler}")

    inputs = list(SCHEMAS.glob("*.proto")) + [
        COMPAT / "TSKArchives_sos.proto", COMPAT / "mapping.py"
    ]
    key = tree_hash(inputs)
    package_root = CACHE / key
    package = package_root / "keynote_parser"
    marker = package_root / ".complete"
    if marker.exists():
        validate(package_root)
        return package_root

    if package_root.exists():
        shutil.rmtree(package_root)
    installed = Path(__import__("keynote_parser").__file__).resolve().parent
    shutil.copytree(installed, package, ignore=shutil.ignore_patterns("__pycache__"))
    generated = package / "generated"
    shutil.rmtree(generated)
    generated.mkdir()
    (generated / "__init__.py").write_text("")

    protos = sorted(SCHEMAS.glob("*.proto")) + [COMPAT / "TSKArchives_sos.proto"]
    command = [
        sys.executable, "-m", "grpc_tools.protoc",
        f"-I{SCHEMAS}", f"-I{COMPAT}", f"--python_out={generated}",
        *map(str, protos),
    ]
    subprocess.run(command, check=True)
    for path in generated.glob("*_pb2.py"):
        rewrite_imports(path)
    shutil.copy2(COMPAT / "mapping.py", package / "mapping.py")
    validate(package_root)
    marker.write_text(key + "\n")
    return package_root


if __name__ == "__main__":
    print(prepare())
