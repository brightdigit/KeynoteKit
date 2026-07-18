#!/usr/bin/env python3
"""
test_deckkit.py — validate the Deck backend WITHOUT Keynote or network.

Covers spec parsing, AppleScript code-gen, and the verify/extract logic (fed a
synthetic 'unpacked' deck). Keynote-driven building is not exercised here (that
needs the app); this guards the pure logic that surrounds it.
"""
from __future__ import annotations

import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import deckkit  # noqa: E402

FAILS: list[str] = []


def check(cond: bool, msg: str) -> None:
    if not cond:
        FAILS.append(msg)


SPEC = {
    "slides": [
        {"items": [{"text": "Title", "x": 200, "y": 200}],
         "transition": {"effect": "dissolve", "duration": 1.0, "delay": 0.0}},
        {"items": [{"text": 'He said "hi"', "x": 250, "y": 250}],
         "transition": {"effect": "magic_move", "duration": 1.5,
                        "delay": 0.5, "auto_advance": True}},
        {"items": [{"text": "plain"}]},  # no transition
    ]
}


def test_parse() -> None:
    deck = deckkit.deck_from_dict(SPEC)
    check(len(deck.slides) == 3, "expected 3 slides")
    check(deck.slides[0].transition.effect == "dissolve", "slide1 effect")
    check(deck.slides[1].transition.auto_advance is True, "slide2 auto_advance")
    check(deck.slides[2].transition is None, "slide3 has no transition")


def test_unknown_effect() -> None:
    try:
        deckkit.deck_from_dict({"slides": [{"transition": {"effect": "zzz"}}]})
        FAILS.append("unknown effect should raise")
    except ValueError:
        pass


def test_effects_map() -> None:
    # full sdef enum: none + 43 effects
    check(len(deckkit.EFFECTS) == 44, f"expected 44 EFFECTS, got {len(deckkit.EFFECTS)}")
    check(deckkit.EFFECTS["none"][1] is None, "none must have no AppleScript term")
    # the space-containing archive string must be preserved verbatim
    check(deckkit.EFFECTS["radial_wipe"][0] == "apple:radial wipe",
          "radial_wipe archive string must keep its space")
    # every non-none effect has both an archive string and an AppleScript term
    for name, (s, term) in deckkit.EFFECTS.items():
        if name == "none":
            continue
        check(bool(s) and bool(term), f"{name} missing string/term")


def test_verify_handles_spaces() -> None:
    # the effect extractor must capture values with spaces (regression: radial)
    import re
    m = deckkit._EFFECT_RE.search("            effect: apple:radial wipe\n")
    check(m is not None and m.group(1) == "apple:radial wipe",
          "effect regex must capture space-containing values")


def test_codegen() -> None:
    deck = deckkit.deck_from_dict(SPEC)
    s = deckkit.generate_applescript(deck, "/tmp/out.key")
    check('tell application "Keynote"' in s, "codegen missing app tell")
    check("transition effect:magic move" in s, "codegen missing magic move term")
    check("transition effect:dissolve" in s, "codegen missing dissolve term")
    check("automatic transition:true" in s, "codegen missing auto true")
    # quote escaping for the tricky text
    check('\\"hi\\"' in s, "codegen did not escape embedded quotes")
    # slide 3 has no transition -> only two 'set transition properties'
    check(s.count("set transition properties") == 2, "unexpected transition count")


def test_verify_positive_and_negative() -> None:
    deck = deckkit.deck_from_dict(SPEC)
    # Fabricate an 'unpacked' deck: two slide files with matching anim blocks.
    with tempfile.TemporaryDirectory() as tmp:
        idx = os.path.join(tmp, "Index")
        os.makedirs(idx)
        good = {
            "dissolve": ("apple:dissolve", 1.0, 0.0, "false"),
            "magic": ("apple:magic-move-implied-motion-path", 1.5, 0.5, "true"),
        }
        for i, (eff, dur, dly, au) in enumerate(good.values()):
            with open(os.path.join(idx, f"Slide-{i}.iwa.yaml"), "w") as fh:
                fh.write(
                    "      transition:\n        attributes:\n"
                    "          animationAttributes:\n"
                    "            animationType: Transition\n"
                    f"            delay: {dly}\n"
                    f"            duration: {dur}\n"
                    f"            effect: {eff}\n"
                    f"            isAutomatic: {au}\n"
                    "            writingDirectionIsRtl: false\n"
                    "      userDefinedGuideStorage:\n"
                )
        ok, msg = deckkit.verify(deck, tmp)
        check(ok, "verify should PASS on matching deck: " + msg)

        # Now corrupt one duration -> verify must FAIL.
        p = os.path.join(idx, "Slide-0.iwa.yaml")
        with open(p) as fh:
            bad = fh.read().replace("duration: 1.0", "duration: 9.9")
        with open(p, "w") as fh:
            fh.write(bad)
        ok2, _ = deckkit.verify(deck, tmp)
        check(not ok2, "verify should FAIL when a duration mismatches")


# --- builds (Phase 2): parse + read/verify, all synthetic (no keynote-parser) --

BUILD_SPEC = {
    "slides": [
        {"items": [{"text": "Item 1"}],
         "builds": [
             {"effect": "dissolve", "kind": "In", "duration": 1.0,
              "delay": 0.0, "target": "item:0"},
             {"effect": "move_in", "kind": "In", "duration": 0.5,
              "delay": 0.0, "target": "item:1",
              "options": {"direction": 13}},
         ]},
    ]
}


def test_parse_builds() -> None:
    deck = deckkit.deck_from_dict(BUILD_SPEC)
    s = deck.slides[0]
    check(len(s.builds) == 2, "expected 2 builds on slide 1")
    check(s.builds[0].effect == "dissolve" and s.builds[0].kind == "In",
          "build 0 effect/kind")
    check(s.builds[1].effect == "move_in", "build 1 effect")
    check(s.builds[1].options.get("direction") == 13, "build 1 direction option")
    check(s.builds[0].target == "item:0", "build 0 target ref preserved")
    # order is meaningful (delivery order); parsing must preserve list order
    check([b.effect for b in s.builds] == ["dissolve", "move_in"],
          "build list order preserved")


def test_unknown_build_effect_and_kind() -> None:
    try:
        deckkit.deck_from_dict({"slides": [{"builds": [{"effect": "zzz"}]}]})
        FAILS.append("unknown build effect should raise")
    except ValueError:
        pass
    try:
        deckkit.deck_from_dict(
            {"slides": [{"builds": [{"effect": "dissolve", "kind": "Sideways"}]}]})
        FAILS.append("unknown build kind should raise")
    except ValueError:
        pass


def test_build_effects_map() -> None:
    check(deckkit.BUILD_EFFECTS["dissolve"][0] == "apple:dissolve character",
          "dissolve build archive string")
    check(deckkit.BUILD_EFFECTS["move_in"][0] == "apple:move in character",
          "move_in build archive string")
    # builds are not scriptable: the AppleScript term must always be None
    for name, (s, term) in deckkit.BUILD_EFFECTS.items():
        check(bool(s) and term is None, f"{name} build must have archive str, no term")


def _write_build_slide(path: str, effect: str, dur: float, dly: float,
                       drawable: str, direction: str | None = None) -> None:
    """Write a minimal Index/Slide-*.iwa.yaml carrying one KN.BuildArchive."""
    dir_line = f"          direction: {direction}\n" if direction else ""
    with open(path, "w") as fh:
        fh.write(
            "    objects:\n"
            "    - _pbtype: KN.BuildArchive\n"
            "      attributes:\n"
            "        animationAttributes:\n"
            "          animationType: In\n"
            f"          delay: {dly}\n"
            + dir_line +
            f"          duration: {dur}\n"
            f"          effect: {effect}\n"
            "          writingDirectionIsRtl: false\n"
            "        eventTrigger: 1\n"
            "      delivery: All at Once\n"
            "      drawable:\n"
            f"        identifier: '{drawable}'\n"
            "      duration: 0.0\n"
        )


def test_extract_and_verify_builds() -> None:
    deck = deckkit.deck_from_dict(BUILD_SPEC)
    with tempfile.TemporaryDirectory() as tmp:
        idx = os.path.join(tmp, "Index")
        os.makedirs(idx)
        # two builds, matching BUILD_SPEC (dissolve then move_in w/ direction)
        _write_build_slide(os.path.join(idx, "Slide-0.iwa.yaml"),
                           "apple:dissolve character", 1.0, 0.0, "2652601")
        _write_build_slide(os.path.join(idx, "Slide-1.iwa.yaml"),
                           "apple:move in character", 0.5, 0.0, "2652626",
                           direction="13")
        got = deckkit.extract_builds(tmp)
        check(len(got) == 2, f"expected 2 extracted builds, got {len(got)}")
        by_eff = {g["effect"]: g for g in got}
        d = by_eff.get("apple:dissolve character")
        check(d is not None and d["kind"] == "In" and d["duration"] == 1.0
              and d["drawable"] == "2652601" and d["direction"] is None,
              "dissolve build extracted fields")
        mv = by_eff.get("apple:move in character")
        check(mv is not None and mv["direction"] == 13 and mv["duration"] == 0.5,
              "move_in build extracted direction/duration")

        ok, msg = deckkit.verify_builds(deck, tmp)
        check(ok, "verify_builds should PASS on matching deck: " + msg)

        # corrupt one duration -> verify_builds must FAIL
        p = os.path.join(idx, "Slide-0.iwa.yaml")
        with open(p) as fh:
            bad = fh.read().replace("duration: 1.0", "duration: 9.9")
        with open(p, "w") as fh:
            fh.write(bad)
        ok2, _ = deckkit.verify_builds(deck, tmp)
        check(not ok2, "verify_builds should FAIL when a build duration mismatches")


def test_extract_transitions_excludes_builds() -> None:
    # A slide file with BOTH a Transition anim block and an In build block:
    # the animationType filter must route each to the right extractor.
    with tempfile.TemporaryDirectory() as tmp:
        idx = os.path.join(tmp, "Index")
        os.makedirs(idx)
        with open(os.path.join(idx, "Slide-0.iwa.yaml"), "w") as fh:
            fh.write(
                "      transition:\n        attributes:\n"
                "          animationAttributes:\n"
                "            animationType: Transition\n"
                "            delay: 0.0\n"
                "            duration: 1.0\n"
                "            effect: apple:dissolve\n"
                "            isAutomatic: false\n"
                "            writingDirectionIsRtl: false\n"
                "    objects:\n"
                "    - _pbtype: KN.BuildArchive\n"
                "      attributes:\n"
                "        animationAttributes:\n"
                "          animationType: In\n"
                "          delay: 0.0\n"
                "          duration: 1.0\n"
                "          effect: apple:dissolve character\n"
                "          writingDirectionIsRtl: false\n"
                "        eventTrigger: 1\n"
                "      delivery: All at Once\n"
                "      drawable:\n"
                "        identifier: '2652601'\n"
                "      duration: 0.0\n"
            )
        trans = deckkit.extract_transitions(tmp)
        check(len(trans) == 1 and trans[0]["effect"] == "apple:dissolve",
              "extract_transitions must return only the Transition block")
        builds = deckkit.extract_builds(tmp)
        check(len(builds) == 1 and builds[0]["effect"] == "apple:dissolve character",
              "extract_builds must return only the In build block")


def main() -> int:
    for fn in (test_parse, test_unknown_effect, test_effects_map,
               test_verify_handles_spaces, test_codegen,
               test_verify_positive_and_negative,
               test_parse_builds, test_unknown_build_effect_and_kind,
               test_build_effects_map, test_extract_and_verify_builds,
               test_extract_transitions_excludes_builds):
        fn()
    if FAILS:
        print("DECKKIT TEST FAIL:")
        for f in FAILS:
            print("  - " + f)
        return 1
    print("DECKKIT TEST PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
