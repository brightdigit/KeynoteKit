#!/usr/bin/env python3
"""
deckkit.py — a minimal `Deck` intermediate model and an AppleScript backend that
lowers it to a real Keynote `.key`, for the SCRIPTABLE half of the format
(slide transitions). Builds are not scriptable and are out of scope here.

Design follows the Phase 1 findings (see findings/deck_model_notes.md):
- A transition is a per-slide record; slide 1 may carry one.
- The scriptable knobs are effect / duration / delay / auto-advance, all set via
  Keynote's `transition properties`. No `pack` is needed (and pack does not
  round-trip on Keynote 15.3), so we drive Keynote directly with osascript.
- The archive `effect` string equals the sdef Cocoa value; we key the model on
  stable names and map to both the AppleScript enumerator (for building) and the
  archive string (for verification).

Spec format (JSON):
    {
      "slides": [
        {
          "items": [{"text": "One", "x": 200, "y": 200}],
          "transition": {"effect": "dissolve", "duration": 1.5,
                         "delay": 0.5, "auto_advance": false}
        },
        ...
      ]
    }
`transition` is optional (omit or use effect "none" for no transition).

This module is stdlib-only so it runs under system Python or the mise venv.
"""
from __future__ import annotations

import json
import re
import subprocess
import tempfile
from dataclasses import dataclass, field

# name -> (archive effect string, AppleScript enumerator term)
# Verified against Keynote 15.3 (see findings/effect_type.md). "none" == off.
EFFECTS: dict[str, tuple[str | None, str | None]] = {
    "none": ("none", None),
    "magic_move": ("apple:magic-move-implied-motion-path", "magic move"),
    "dissolve": ("apple:dissolve", "dissolve"),
    "push": ("apple:push", "push"),
    "wipe": ("apple:wipe", "wipe"),
    "move_in": ("apple:slide", "move in"),
    "iris": ("apple:wipe-iris", "iris"),
    "object_cube": ("apple:ca-cube", "object cube"),
    "object_flip": ("apple:ca-dissolve-and-flip", "object flip"),
    "switch": ("apple:FlipThrough", "switch"),
}


@dataclass
class TextItem:
    text: str
    x: float = 200.0
    y: float = 200.0


@dataclass
class Transition:
    effect: str = "none"
    duration: float = 1.0
    delay: float = 0.0
    auto_advance: bool = False

    def validate(self) -> None:
        if self.effect not in EFFECTS:
            raise ValueError(
                f"unknown effect {self.effect!r}; known: {sorted(EFFECTS)}"
            )


@dataclass
class Slide:
    items: list[TextItem] = field(default_factory=list)
    transition: Transition | None = None


@dataclass
class Deck:
    slides: list[Slide] = field(default_factory=list)

    def validate(self) -> None:
        if not self.slides:
            raise ValueError("deck has no slides")
        for s in self.slides:
            if s.transition:
                s.transition.validate()


# --- spec loading ------------------------------------------------------------

def deck_from_dict(d: dict) -> Deck:
    slides = []
    for sd in d.get("slides", []):
        items = [
            TextItem(text=i["text"], x=i.get("x", 200.0), y=i.get("y", 200.0))
            for i in sd.get("items", [])
        ]
        t = None
        td = sd.get("transition")
        if td and td.get("effect", "none") != "none":
            t = Transition(
                effect=td["effect"],
                duration=float(td.get("duration", 1.0)),
                delay=float(td.get("delay", 0.0)),
                auto_advance=bool(td.get("auto_advance", False)),
            )
        slides.append(Slide(items=items, transition=t))
    deck = Deck(slides=slides)
    deck.validate()
    return deck


def load_spec(path: str) -> Deck:
    with open(path, "r", encoding="utf-8") as fh:
        return deck_from_dict(json.load(fh))


# --- AppleScript code generation --------------------------------------------

def _as_str(s: str) -> str:
    """Quote a Python string as an AppleScript string literal."""
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def _transition_stmt(t: Transition, target: str) -> str:
    _, term = EFFECTS[t.effect]
    auto = "true" if t.auto_advance else "false"
    return (
        f"set transition properties of {target} to "
        f"{{transition effect:{term}, transition duration:{t.duration}, "
        f"transition delay:{t.delay}, automatic transition:{auto}}}"
    )


def generate_applescript(deck: Deck, out_path: str) -> str:
    lines = [
        'on run',
        '    tell application "Keynote"',
        '        set thisDoc to make new document',
        '        tell thisDoc',
        '            set blankMaster to master slide "Blank"',
    ]
    for idx, slide in enumerate(deck.slides, start=1):
        if idx == 1:
            lines.append('            set theSlide to slide 1')
        else:
            lines.append(
                '            set theSlide to make new slide '
                'with properties {base slide:blankMaster}'
            )
        lines.append('            tell theSlide')
        if idx == 1:
            lines.append('                set base slide to blankMaster')
        for it in slide.items:
            lines.append(
                '                set _t to make new text item with properties '
                f'{{object text:{_as_str(it.text)}}}'
            )
            lines.append(f'                set position of _t to {{{it.x}, {it.y}}}')
        if slide.transition:
            lines.append('                ' + _transition_stmt(slide.transition, "theSlide"))
        lines.append('            end tell')
    lines += [
        '        end tell',
        f'        save thisDoc in POSIX file {_as_str(out_path)}',
        '        close thisDoc saving no',
        '    end tell',
        'end run',
    ]
    return "\n".join(lines) + "\n"


def build(deck: Deck, out_path: str) -> None:
    """Generate AppleScript and run it via osascript to produce out_path."""
    deck.validate()
    script = generate_applescript(deck, out_path)
    with tempfile.NamedTemporaryFile(
        "w", suffix=".applescript", delete=False, encoding="utf-8"
    ) as fh:
        fh.write(script)
        script_path = fh.name
    subprocess.run(["osascript", script_path], check=True)


# --- verification (unpack + compare transition fields) ----------------------

_EFFECT_RE = re.compile(r"^\s*effect:\s*(\S+)\s*$", re.M)
_DUR_RE = re.compile(r"^\s*duration:\s*([\d.]+)\s*$", re.M)
_DELAY_RE = re.compile(r"^\s*delay:\s*([\d.]+)\s*$", re.M)
_AUTO_RE = re.compile(r"^\s*isAutomatic:\s*(true|false)\s*$", re.M)
# an animationAttributes block, greedy enough to grab its scalars
_ANIM_RE = re.compile(
    r"animationAttributes:\n((?:\s+\w[\w]*:.*\n)+)"
)


def extract_transitions(unpacked_dir: str) -> list[dict]:
    """Return one dict per slide transition found in the unpacked deck."""
    import os

    out = []
    idx_dir = os.path.join(unpacked_dir, "Index")
    for name in os.listdir(idx_dir):
        if not (name.startswith("Slide") and name.endswith(".iwa.yaml")):
            continue
        with open(os.path.join(idx_dir, name), "r", encoding="utf-8",
                  errors="replace") as fh:
            text = fh.read()
        for block in _ANIM_RE.findall(text):
            eff = _EFFECT_RE.search(block)
            if not eff:
                continue
            dur = _DUR_RE.search(block)
            dly = _DELAY_RE.search(block)
            au = _AUTO_RE.search(block)
            out.append({
                "effect": eff.group(1),
                "duration": float(dur.group(1)) if dur else None,
                "delay": float(dly.group(1)) if dly else None,
                "auto": (au.group(1) == "true") if au else None,
            })
    return out


def expected_transitions(deck: Deck) -> list[dict]:
    exp = []
    for s in deck.slides:
        t = s.transition
        if t is None:
            exp.append({"effect": "none", "duration": None, "delay": None,
                        "auto": False})
        else:
            exp.append({
                "effect": EFFECTS[t.effect][0],
                "duration": t.duration,
                "delay": t.delay,
                "auto": t.auto_advance,
            })
    return exp


def verify(deck: Deck, unpacked_dir: str) -> tuple[bool, str]:
    """Compare the multiset of (effect,duration,delay,auto) tuples.

    Multiset (order-insensitive) because keynote-parser slide filenames are not
    ordered; every non-'none' expected transition must be matched by an actual
    one with the same effect + timing.
    """
    def key(d):
        return (d["effect"], d["duration"], d["delay"], d["auto"])

    actual = {key(x) for x in extract_transitions(unpacked_dir)}
    missing = []
    for e in expected_transitions(deck):
        if e["effect"] == "none":
            continue
        if key(e) not in actual:
            missing.append(e)
    if missing:
        return False, "missing transitions in built deck: " + json.dumps(missing)
    return True, "all %d expected transition(s) present" % (
        sum(1 for e in expected_transitions(deck) if e["effect"] != "none")
    )
