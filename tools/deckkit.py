#!/usr/bin/env python3
"""
deckkit.py — a minimal `Deck` intermediate model and an AppleScript backend that
lowers it to a real Keynote `.key`, for the SCRIPTABLE half of the format
(slide transitions).

Object builds (Phase 2, see findings/build_*.md) are now MODELLED and
READABLE here, but NOT buildable: builds are absent from Keynote's AppleScript
dictionary, so there is no osascript setter. The write side needs byte-level
template surgery (regenerated 15.3 pack mappings, see findings/versions.md) and
stays documented-as-future. What this module provides for builds is the IR
(`Build` on `Slide`, `BUILD_EFFECTS`) plus the read/verify half
(`extract_builds` / `verify_builds`), so a hand-made fixture can be parsed and
checked.

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
# Full set from Keynote 15.3's Keynote.sdef `transition effects` enum; archive
# strings confirmed by the catalog sweep (see findings/effect_type.md).
# "none" == off (has no AppleScript term).
EFFECTS: dict[str, tuple[str | None, str | None]] = {
    "none": ("none", None),
    # object/text effects (Core Animation "ca" family)
    "magic_move": ("apple:magic-move-implied-motion-path", "magic move"),
    "shimmer": ("apple:ca-text-shimmer", "shimmer"),
    "sparkle": ("apple:ca-text-sparkle", "sparkle"),
    "swing": ("apple:ca-swing", "swing"),
    "object_cube": ("apple:ca-cube", "object cube"),
    "object_flip": ("apple:ca-dissolve-and-flip", "object flip"),
    "object_pop": ("apple:ca-pop", "object pop"),
    "object_push": ("apple:ca-push", "object push"),
    "object_revolve": ("apple:ca-revolve", "object revolve"),
    "object_zoom": ("apple:ca-zoom", "object zoom"),
    "perspective": ("apple:ca-isometric", "perspective"),
    # apple: built-in slide effects
    "clothesline": ("apple:ClotheslinePush", "clothesline"),
    "dissolve": ("apple:dissolve", "dissolve"),
    "drop": ("apple:bounce", "drop"),
    "droplet": ("apple:droplet", "droplet"),
    "grid": ("apple:apple-grid", "grid"),
    "iris": ("apple:wipe-iris", "iris"),
    "move_in": ("apple:slide", "move in"),
    "push": ("apple:push", "push"),
    "reveal": ("apple:reveal", "reveal"),
    "switch": ("apple:FlipThrough", "switch"),
    "wipe": ("apple:wipe", "wipe"),
    "cube": ("apple:3D-cube", "cube"),
    "doorway": ("apple:doorway", "doorway"),
    "fall": ("apple:fall", "fall"),
    "flip": ("apple:revolve", "flip"),
    "page_flip": ("apple:pageflip", "page flip"),
    "pivot": ("apple:pivot", "pivot"),
    "scale": ("apple:scale", "scale"),
    "twirl": ("apple:twirl", "twirl"),
    "fade_and_move": ("apple:fade-and-move", "fade and move"),
    # archive string genuinely contains a space (confirmed via the catalog sweep)
    "radial_wipe": ("apple:radial wipe", "radial wipe"),
    # com.apple.iWork.Keynote.* plug-in effects
    "confetti": ("com.apple.iWork.Keynote.KLNConfetti", "confetti"),
    "fade_through_color": ("com.apple.iWork.Keynote.BLTFadeThruColor", "fade through color"),
    "blinds": ("com.apple.iWork.Keynote.BLTBlinds", "blinds"),
    "color_planes": ("com.apple.iWork.Keynote.KLNColorPlanes", "color planes"),
    "flop": ("com.apple.iWork.Keynote.BUKFlop", "flop"),
    "mosaic": ("com.apple.iWork.Keynote.BLTMosaicFlip", "mosaic"),
    "reflection": ("com.apple.iWork.Keynote.BLTReflection", "reflection"),
    "revolving_door": ("com.apple.iWork.Keynote.BLTRevolvingDoor", "revolving door"),
    "swap": ("com.apple.iWork.Keynote.KLNSwap", "swap"),
    "swoosh": ("com.apple.iWork.Keynote.BLTSwoosh", "swoosh"),
    "twist": ("com.apple.iWork.Keynote.BUKTwist", "twist"),
}

# Build effect name -> (archive effect string, AppleScript enumerator term).
# Builds are NOT AppleScript-settable, so the second element is always None (kept
# for shape-parity with EFFECTS). Verified strings from findings/build_fx.md; the
# " character" suffix marks the text-build variants. Extend as more builds are
# reverse-engineered.
BUILD_EFFECTS: dict[str, tuple[str | None, str | None]] = {
    "dissolve": ("apple:dissolve character", None),
    "move_in": ("apple:move in character", None),   # directional (carries `direction`)
}

# The two build kinds seen so far map to KN.BuildArchive.animationType.
BUILD_KINDS = {"In", "Out"}


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
class Build:
    """One object build (Phase 2). Not buildable via AppleScript; read/verify
    only. See findings/build_*.md.

    target: symbolic reference to the object the build animates. Resolves to
        KN.BuildArchive.drawable.identifier at emit time (byte-surgery, future).
        Read-side extraction reports the concrete drawable id instead.
    kind:   In | Out -> animationAttributes.animationType.
    effect: key into BUILD_EFFECTS -> animationAttributes.effect.
    options: sparse per-effect / delivery bag (direction, customBounce,
        customTextDelivery, customDeliveryOption, delivery, ...), mirroring
        Transition.options.
    Build order on a slide is LIST POSITION (findings/build_order.md), so the
    order of `Slide.builds` is the delivery order.
    """
    effect: str = "dissolve"
    kind: str = "In"
    duration: float = 1.0
    delay: float = 0.0
    target: str = ""
    trigger: str = "on_click"     # on_click | after_previous | with_previous
    options: dict = field(default_factory=dict)

    def validate(self) -> None:
        if self.effect not in BUILD_EFFECTS:
            raise ValueError(
                f"unknown build effect {self.effect!r}; known: "
                f"{sorted(BUILD_EFFECTS)}"
            )
        if self.kind not in BUILD_KINDS:
            raise ValueError(
                f"unknown build kind {self.kind!r}; known: {sorted(BUILD_KINDS)}"
            )


@dataclass
class Slide:
    items: list[TextItem] = field(default_factory=list)
    transition: Transition | None = None
    # ordered: list position == delivery order (findings/build_order.md)
    builds: list[Build] = field(default_factory=list)


@dataclass
class Deck:
    slides: list[Slide] = field(default_factory=list)

    def validate(self) -> None:
        if not self.slides:
            raise ValueError("deck has no slides")
        for s in self.slides:
            if s.transition:
                s.transition.validate()
            for b in s.builds:
                b.validate()


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
        builds = [
            Build(
                effect=bd["effect"],
                kind=bd.get("kind", "In"),
                duration=float(bd.get("duration", 1.0)),
                delay=float(bd.get("delay", 0.0)),
                target=str(bd.get("target", "")),
                trigger=bd.get("trigger", "on_click"),
                options=dict(bd.get("options", {})),
            )
            for bd in sd.get("builds", [])
        ]
        slides.append(Slide(items=items, transition=t, builds=builds))
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

_EFFECT_RE = re.compile(r"^\s*effect:\s*(.+?)\s*$", re.M)
_DUR_RE = re.compile(r"^\s*duration:\s*([\d.]+)\s*$", re.M)
_DELAY_RE = re.compile(r"^\s*delay:\s*([\d.]+)\s*$", re.M)
_AUTO_RE = re.compile(r"^\s*isAutomatic:\s*(true|false)\s*$", re.M)
_ANIMTYPE_RE = re.compile(r"^\s*animationType:\s*(\w+)\s*$", re.M)
_DIRECTION_RE = re.compile(r"^\s*direction:\s*(-?\d+)\s*$", re.M)
# an animationAttributes block, greedy enough to grab its scalars. NOTE this
# matches BOTH transitions (animationType: Transition) and builds
# (animationType: In/Out) — they share the struct — so callers MUST filter by
# animationType.
_ANIM_RE = re.compile(
    r"animationAttributes:\n((?:\s+\w[\w]*:.*\n)+)"
)
# a KN.BuildArchive object -> the following slice up to the next _pbtype
_BUILD_RE = re.compile(
    r"_pbtype:\s*KN\.BuildArchive\b(.*?)(?=_pbtype:|\Z)", re.S
)
_DRAWABLE_RE = re.compile(r"drawable:\s*\n\s*identifier:\s*'?(\d+)'?")

# Per-build option keys (the sparse bag Build.options represents): effect knobs
# + text delivery + start trigger. Captured from the KN.BuildArchive block.
_BUILD_OPTION_KEYS = (
    "customBounce", "customTravelDistance", "customTwist",
    "customTextDelivery", "customDeliveryOption", "delivery", "eventTrigger",
)


def _coerce_scalar(v: str):
    """true/false -> bool, ints/floats -> number, else the stripped string."""
    if v in ("true", "false"):
        return v == "true"
    try:
        return int(v)
    except ValueError:
        pass
    try:
        return float(v)
    except ValueError:
        pass
    return v


def _parse_build_options(blk: str) -> dict:
    """Extract the sparse option bag from one KN.BuildArchive block."""
    opts = {}
    for key in _BUILD_OPTION_KEYS:
        m = re.search(rf"^\s*{key}:\s*(.+?)\s*$", blk, re.M)
        if m:
            opts[key] = _coerce_scalar(m.group(1))
    return opts


def _slide_yaml_files(unpacked_dir: str):
    import os
    idx_dir = os.path.join(unpacked_dir, "Index")
    for name in sorted(os.listdir(idx_dir)):
        if name.startswith("Slide") and name.endswith(".iwa.yaml"):
            yield os.path.join(idx_dir, name)


def extract_transitions(unpacked_dir: str) -> list[dict]:
    """Return one dict per slide TRANSITION in the unpacked deck.

    Filters animationAttributes blocks to animationType == Transition so build
    blocks (animationType In/Out, same struct) are not miscounted.
    """
    out = []
    for path in _slide_yaml_files(unpacked_dir):
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            text = fh.read()
        for block in _ANIM_RE.findall(text):
            at = _ANIMTYPE_RE.search(block)
            if at and at.group(1) != "Transition":
                continue
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


def extract_builds(unpacked_dir: str) -> list[dict]:
    """Return one dict per object BUILD in the unpacked deck, in delivery order.

    Order is preserved as it appears in each slide file, which IS the delivery
    order (findings/build_order.md). Each dict carries the archive effect string,
    duration/delay (from animationAttributes), kind (animationType), the optional
    `direction`, the target `drawable` id, and an `options` bag (customBounce /
    customTravelDistance / customTextDelivery / customDeliveryOption / delivery /
    eventTrigger) — the same sparse bag `Build.options` models.
    """
    out = []
    for path in _slide_yaml_files(unpacked_dir):
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            text = fh.read()
        for m in _BUILD_RE.finditer(text):
            blk = m.group(1)
            at = _ANIMTYPE_RE.search(blk)
            eff = _EFFECT_RE.search(blk)
            if not eff:
                continue
            dur = _DUR_RE.search(blk)      # first duration == animationAttributes.duration
            dly = _DELAY_RE.search(blk)
            dirn = _DIRECTION_RE.search(blk)
            draw = _DRAWABLE_RE.search(blk)
            out.append({
                "kind": at.group(1) if at else None,
                "effect": eff.group(1),
                "duration": float(dur.group(1)) if dur else None,
                "delay": float(dly.group(1)) if dly else None,
                "direction": int(dirn.group(1)) if dirn else None,
                "drawable": draw.group(1) if draw else None,
                "options": _parse_build_options(blk),
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


# --- builds: read/verify (no build path — builds are not scriptable) --------

def expected_builds(deck: Deck) -> list[dict]:
    """Flatten the deck's builds to archive-shaped dicts (kind/effect/timing)."""
    exp = []
    for s in deck.slides:
        for b in s.builds:
            exp.append({
                "kind": b.kind,
                "effect": BUILD_EFFECTS[b.effect][0],
                "duration": b.duration,
                "delay": b.delay,
            })
    return exp


def verify_builds(deck: Deck, unpacked_dir: str) -> tuple[bool, str]:
    """Compare the multiset of (kind, effect, duration, delay) build tuples.

    Multiset because slide filenames are unordered across the deck; within one
    slide extract_builds preserves delivery order, but this deck-wide check is
    order-insensitive (mirrors verify() for transitions). Every expected build
    must be matched by an actual one with the same kind + effect + timing.
    """
    def key(d):
        return (d["kind"], d["effect"], d["duration"], d["delay"])

    actual = {key(x) for x in extract_builds(unpacked_dir)}
    missing = [e for e in expected_builds(deck) if key(e) not in actual]
    if missing:
        return False, "missing builds in deck: " + json.dumps(missing)
    n = len(expected_builds(deck))
    return True, "all %d expected build(s) present" % n
