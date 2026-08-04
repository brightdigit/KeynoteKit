"""Dump ``deckkit.extract_builds`` output for every fixture as JSON.

The #18 parity gate compares Swift's archive navigation against Python's
``extract_builds`` on the 24 committed fixtures. CI has no Python, so the
Python side is precomputed here and committed as
``Tests/KeynoteArchiveNavigationTests/Expected/<fixture>.json``.

Regenerate (only needed if the fixtures or deckkit's extraction change):

    mise exec -- python3 research/tools/dump_expected_builds.py

Requires the venv bootstrap (`keynote-parser==1.14.4.0`) and
`mise run prepare-keynote-parser`.
"""

from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
ROOT = TOOLS.parent.parent
FIXTURES = ROOT / "research" / "fixtures"
EXPECTED = ROOT / "Tests" / "KeynoteArchiveNavigationTests" / "Expected"

sys.path.insert(0, str(TOOLS))

from archive_backend import _parser  # noqa: E402
from deckkit import extract_builds  # noqa: E402


def main() -> None:
    try:
        import keynote_parser  # noqa: F401
        version = getattr(keynote_parser, "__version__", "unknown")
    except ImportError:
        version = "1.14.4.0 (hybrid build)"
    EXPECTED.mkdir(parents=True, exist_ok=True)
    fixtures = sorted(FIXTURES.glob("*.key"))
    if len(fixtures) != 24:
        raise SystemExit(f"expected 24 fixtures, found {len(fixtures)}")
    for fixture in fixtures:
        with tempfile.TemporaryDirectory() as tmp:
            unpacked = Path(tmp) / fixture.stem
            _parser("unpack", fixture, unpacked)
            builds = extract_builds(str(unpacked))
        payload = {
            "_generator": (
                "research/tools/dump_expected_builds.py; "
                f"keynote-parser {version}; deckkit.extract_builds"
            ),
            "fixture": fixture.name,
            "builds": builds,
        }
        out = EXPECTED / f"{fixture.stem}.json"
        out.write_text(json.dumps(payload, indent=2, sort_keys=False) + "\n")
        print(f"{fixture.stem}: {len(builds)} builds")


if __name__ == "__main__":
    main()
