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


def main() -> int:
    for fn in (test_parse, test_unknown_effect, test_codegen,
               test_verify_positive_and_negative):
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
