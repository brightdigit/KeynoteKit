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
from pathlib import Path

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import yaml  # noqa: E402

import deckkit  # noqa: E402
import archive_backend  # noqa: E402

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
        {"items": [{"text": "Item 1"}, {"text": "Item 2"}],
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
    check(len(deckkit.BUILD_EFFECTS) == 8, "expected all 8 verified build effects")
    check(deckkit.BUILD_EFFECTS["dissolve"][0] == "apple:dissolve character",
          "dissolve build archive string")
    check(deckkit.BUILD_EFFECTS["move_in"][0] == "apple:move in character",
          "move_in build archive string")
    # builds are not scriptable: the AppleScript term must always be None
    for name, (s, term) in deckkit.BUILD_EFFECTS.items():
        check(bool(s) and term is None, f"{name} build must have archive str, no term")


def test_build_validation() -> None:
    cases = [
        ({"slides": [{"items": [{"text": "x"}], "builds": [
            {"effect": "dissolve", "target": "item:1"}]}]}, "bounds"),
        ({"slides": [{"items": [{"text": "x"}], "builds": [
            {"effect": "dissolve", "target": "shape:0"}]}]}, "symbolic target"),
        ({"slides": [{"items": [{"text": "x"}], "builds": [
            {"effect": "dissolve", "target": "item:0",
             "trigger": "after_previous"}]}]}, "unsupported trigger"),
        ({"slides": [{"items": [{"text": "x"}], "builds": [
            {"effect": "dissolve", "target": "item:0",
             "action_attributes": {"actionAcceleration": "kEaseBoth"}}]}]},
         "In action payload"),
        ({"slides": [{"items": [{"text": "x"}], "builds": [
            {"kind": "Action", "effect": "apple:action-motion-path",
             "target": "item:0", "action_attributes": {"eventTrigger": 1}}]}]},
         "reserved Action key"),
    ]
    for spec, label in cases:
        try:
            deckkit.deck_from_dict(spec)
            FAILS.append(label + " should raise")
        except ValueError:
            pass
    action = deckkit.deck_from_dict({"slides": [{
        "items": [{"text": "x"}],
        "transition": {"effect": "move_in", "direction": 11},
        "builds": [{"kind": "Action", "effect": "apple:action-motion-path",
                    "target": "item:0", "action_attributes": {
                        "actionAcceleration": "kEaseBoth",
                        "actionMotionPathSource": {"editableBezierPathSource": {
                            "naturalSize": {"width": 50.0, "height": 0.0}}}}}],
    }]})
    check(action.slides[0].transition.direction == 11, "transition direction parsed")
    check(action.slides[0].builds[0].action_attributes["actionAcceleration"] == "kEaseBoth",
          "nested Action attributes parsed")


def test_archive_emission() -> None:
    dissolve_in = deckkit.Build(target="item:0", kind="In", effect="dissolve")
    dissolve_out = deckkit.Build(target="item:0", kind="Out", effect="dissolve")
    action = deckkit.Build(
        target="item:0", kind="Action", effect="apple:action-motion-path",
        action_attributes={"actionAcceleration": "kEaseBoth",
                           "actionMotionPathSource": {"path": {"nodes": [1, 2]}}},
    )
    for build, kind in ((dissolve_in, "In"), (dissolve_out, "Out"),
                        (action, "Action")):
        archive, chunk, build_uuid = archive_backend.build_archive_records(
            build, "42", "100", "101")
        obj = archive["objects"][0]
        anim = obj["attributes"]["animationAttributes"]
        check(anim["animationType"] == kind, f"{kind} animation type emission")
        check(chunk["objects"][0]["build"]["identifier"] == "100",
              f"{kind} chunk back-reference")
        check(obj["drawable"]["identifier"] == "42", f"{kind} drawable emission")
        # the returned uuid is what gets registered in the package uuid map
        check(chunk["objects"][0]["buildId"] == build_uuid,
              f"{kind} chunk buildId must equal the returned build uuid")
        check(set(build_uuid) == {"lower", "upper"}
              and all(isinstance(v, str) and v.isdigit() for v in build_uuid.values()),
              f"{kind} build uuid must be all-digit strings")
    attrs = archive_backend.build_archive_records(action, "42", "100", "101")[0]["objects"][0]["attributes"]
    check(attrs["actionMotionPathSource"]["path"]["nodes"] == [1, 2],
          "arbitrary nested Action attributes emitted verbatim")
    check("customTextDelivery" not in attrs and "customDeliveryOption" not in attrs,
          "Action omits In/Out delivery attributes")


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


def test_extract_build_options() -> None:
    # A build carrying the full option bag: booleans, enums, and a
    # space-containing `delivery` value must all round-trip into `options`.
    with tempfile.TemporaryDirectory() as tmp:
        idx = os.path.join(tmp, "Index")
        os.makedirs(idx)
        with open(os.path.join(idx, "Slide-0.iwa.yaml"), "w") as fh:
            fh.write(
                "    objects:\n"
                "    - _pbtype: KN.BuildArchive\n"
                "      attributes:\n"
                "        animationAttributes:\n"
                "          animationType: In\n"
                "          delay: 0.0\n"
                "          direction: 13\n"
                "          duration: 0.5\n"
                "          effect: apple:move in character\n"
                "          writingDirectionIsRtl: false\n"
                "        customBounce: true\n"
                "        customDeliveryOption: kDeliveryOptionRandom\n"
                "        customTextDelivery: kTextDeliveryByCharacter\n"
                "        eventTrigger: 1\n"
                "      delivery: By Paragraph\n"
                "      drawable:\n"
                "        identifier: '2652601'\n"
                "      duration: 0.0\n"
            )
        got = deckkit.extract_builds(tmp)
        check(len(got) == 1, "expected 1 build")
        opts = got[0]["options"]
        check(opts.get("customBounce") is True, "customBounce must coerce to bool")
        check(opts.get("eventTrigger") == 1, "eventTrigger must coerce to int")
        check(opts.get("delivery") == "By Paragraph",
              "delivery must keep its space-containing string")
        check(opts.get("customTextDelivery") == "kTextDeliveryByCharacter",
              "customTextDelivery enum captured")
        check(opts.get("customDeliveryOption") == "kDeliveryOptionRandom",
              "customDeliveryOption enum captured")
        # BuildArchive.duration (0.0) must NOT leak into options
        check("duration" not in opts, "options must not include BuildArchive.duration")


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


# --- package uuid map registration (findings/write_backend_bisect.md) ---------
#
# Keynote registers every KN.BuildArchive id in
# Metadata.iwa.yaml -> TSP.PackageMetadata -> the slide's component ->
# objectUuidMapEntries, with uuid == the KN.BuildChunkArchive's buildId.
# Omitting it crashes Keynote 15.3 in -[__NSSetM addObject:]. These tests build a
# synthetic unpacked tree so the invariant is checked without Keynote.

def _synthetic_unpacked(root: str, slides: list[tuple[str, str, int]],
                        last_object_id: str = "9000") -> None:
    """Write a minimal but structurally real unpacked deck.

    slides: [(node_id, slide_id, n_drawables)] in presentation order.
    """
    idx = os.path.join(root, "Index")
    os.makedirs(idx, exist_ok=True)

    def archive(ident, obj):
        return {"header": {"_pbtype": "TSP.ArchiveInfo", "identifier": ident,
                           "messageInfos": [{"type": 1, "version": [1, 0, 5]}]},
                "objects": [obj]}

    components = []
    for node_id, slide_id, n_drawables in slides:
        components.append({
            "identifier": slide_id, "locator": f"Slide-{slide_id}",
            "preferredLocator": "Slide",
            # a pre-existing entry: authored entries must APPEND, not replace
            "objectUuidMapEntries": [
                {"identifier": slide_id,
                 "uuid": {"lower": "111", "upper": "222"}},
            ],
        })
        slide_obj = {
            "_pbtype": "KN.SlideArchive",
            "drawablesZOrder": [{"identifier": f"{slide_id}0{i}"}
                                for i in range(n_drawables)],
            "transition": {"attributes": {"animationAttributes": {
                "animationType": "Transition", "effect": "apple:slide",
                "duration": 1.0, "delay": 0.0}}},
        }
        node_obj = {"_pbtype": "KN.SlideNodeArchive",
                    "slide": {"identifier": slide_id}}
        with open(os.path.join(idx, f"Slide-{slide_id}.iwa.yaml"), "w") as fh:
            yaml.safe_dump({"chunks": [{"archives": [
                archive(node_id, node_obj), archive(slide_id, slide_obj),
            ]}]}, fh, sort_keys=False)

    with open(os.path.join(idx, "Metadata.iwa.yaml"), "w") as fh:
        yaml.safe_dump({"chunks": [{"archives": [archive("2", {
            "_pbtype": "TSP.PackageMetadata",
            "components": components,
            "lastObjectIdentifier": last_object_id,
        })]}]}, fh, sort_keys=False)

    show = {"_pbtype": "KN.ShowArchive",
            "slideTree": {"slides": [{"identifier": n} for n, _, _ in slides]}}
    with open(os.path.join(idx, "Document.iwa.yaml"), "w") as fh:
        yaml.safe_dump({"chunks": [{"archives": [archive("1", show)]}]},
                       fh, sort_keys=False)


def _read_component(root: str, slide_id: str) -> dict:
    with open(os.path.join(root, "Index", "Metadata.iwa.yaml")) as fh:
        meta = yaml.safe_load(fh)
    obj = meta["chunks"][0]["archives"][0]["objects"][0]
    return next(c for c in obj["components"]
                if str(c["identifier"]) == str(slide_id)), obj


def _slide_build_archives(root: str, slide_id: str) -> tuple[list, dict]:
    """Return ([KN.BuildArchive ids], {build id: chunk buildId})."""
    with open(os.path.join(root, "Index", f"Slide-{slide_id}.iwa.yaml")) as fh:
        doc = yaml.safe_load(fh)
    builds, chunks = [], {}
    for ar in doc["chunks"][0]["archives"]:
        obj = ar["objects"][0]
        if obj.get("_pbtype") == "KN.BuildArchive":
            builds.append(str(ar["header"]["identifier"]))
        elif obj.get("_pbtype") == "KN.BuildChunkArchive":
            chunks[str(obj["build"]["identifier"])] = obj["buildId"]
    return builds, chunks


def test_author_registers_build_uuid() -> None:
    deck = deckkit.deck_from_dict(BUILD_SPEC)  # one slide, two builds
    with tempfile.TemporaryDirectory() as tmp:
        _synthetic_unpacked(tmp, [("500", "600", 2)])
        archive_backend.author_unpacked(Path(tmp), deck)

        comp, meta_obj = _read_component(tmp, "600")
        entries = comp["objectUuidMapEntries"]
        builds, chunks = _slide_build_archives(tmp, "600")

        check(len(builds) == 2, "two build archives emitted")
        check(len(entries) == 3, "two entries appended to the pre-existing one")
        check(entries[0]["identifier"] == "600", "pre-existing entry preserved first")

        new_entries = entries[1:]
        check([e["identifier"] for e in new_entries] == builds,
              "registered ids must be the KN.BuildArchive ids, in order")
        for entry in new_entries:
            bid = entry["identifier"]
            check(entry["uuid"] == chunks[bid],
                  f"entry uuid for build {bid} must equal its chunk buildId")
            check(isinstance(bid, str)
                  and all(isinstance(v, str) for v in entry["uuid"].values()),
                  "uuid map entry values must be strings")

        # the chunk ARCHIVE ids are deliberately not registered (0/8 fixtures do)
        registered = {e["identifier"] for e in entries}
        with open(os.path.join(tmp, "Index", "Slide-600.iwa.yaml")) as fh:
            doc = yaml.safe_load(fh)
        chunk_ids = {str(ar["header"]["identifier"])
                     for ar in doc["chunks"][0]["archives"]
                     if ar["objects"][0].get("_pbtype") == "KN.BuildChunkArchive"}
        check(not (registered & chunk_ids),
              "KN.BuildChunkArchive ids must NOT be registered")

        highest = max(int(i) for i in list(builds) + list(chunk_ids))
        check(int(meta_obj["lastObjectIdentifier"]) > highest,
              "lastObjectIdentifier must exceed every authored archive id")
        check(isinstance(meta_obj["lastObjectIdentifier"], str),
              "lastObjectIdentifier must stay a string")


def test_author_registers_per_slide_component() -> None:
    # two slides, builds on each: entries must land in their OWN component
    deck = deckkit.deck_from_dict({"slides": [
        {"items": [{"text": "a"}],
         "builds": [{"effect": "dissolve", "target": "item:0"}]},
        {"items": [{"text": "b"}],
         "builds": [{"effect": "blur", "target": "item:0"}]},
    ]})
    with tempfile.TemporaryDirectory() as tmp:
        _synthetic_unpacked(tmp, [("500", "600", 1), ("501", "601", 1)])
        archive_backend.author_unpacked(Path(tmp), deck)
        for slide_id in ("600", "601"):
            comp, _ = _read_component(tmp, slide_id)
            builds, chunks = _slide_build_archives(tmp, slide_id)
            new = comp["objectUuidMapEntries"][1:]
            check(len(new) == 1, f"slide {slide_id} got exactly one new entry")
            if not new:
                continue
            check(new[0]["identifier"] == builds[0],
                  f"slide {slide_id} entry references its own build archive")
            check(new[0]["uuid"] == chunks[builds[0]],
                  f"slide {slide_id} entry uuid matches its own chunk")


def test_author_direction_only_adds_no_uuid_entries() -> None:
    # regression guard: the direction-only deck is the one that reopens TODAY
    deck = deckkit.deck_from_dict({"slides": [
        {"items": [{"text": "a"}],
         "transition": {"effect": "move_in", "duration": 1.0, "direction": 11}},
    ]})
    with tempfile.TemporaryDirectory() as tmp:
        _synthetic_unpacked(tmp, [("500", "600", 1)], last_object_id="9000")
        archive_backend.author_unpacked(Path(tmp), deck)
        comp, meta_obj = _read_component(tmp, "600")
        check(comp["objectUuidMapEntries"] == [
            {"identifier": "600", "uuid": {"lower": "111", "upper": "222"}}],
            "a builds-free slide must not touch objectUuidMapEntries")
        check(meta_obj["lastObjectIdentifier"] == "9000",
              "a builds-free slide must not bump lastObjectIdentifier")


def test_verify_uuid_map_catches_missing_entry() -> None:
    deck = deckkit.deck_from_dict(BUILD_SPEC)
    with tempfile.TemporaryDirectory() as tmp:
        _synthetic_unpacked(tmp, [("500", "600", 2)])
        archive_backend.author_unpacked(Path(tmp), deck)
        try:
            archive_backend._verify_uuid_map(Path(tmp), 2)
        except ValueError as exc:
            FAILS.append(f"authored tree must pass _verify_uuid_map: {exc}")

        meta_path = os.path.join(tmp, "Index", "Metadata.iwa.yaml")

        def rewrite(mutate) -> None:
            with open(meta_path) as fh:
                meta = yaml.safe_load(fh)
            mutate(meta["chunks"][0]["archives"][0]["objects"][0])
            with open(meta_path, "w") as fh:
                yaml.safe_dump(meta, fh, sort_keys=False)

        rewrite(lambda o: o["components"][0]["objectUuidMapEntries"].pop())
        try:
            archive_backend._verify_uuid_map(Path(tmp), 2)
            FAILS.append("_verify_uuid_map must raise on a missing entry")
        except ValueError:
            pass

        # restore, then corrupt a uuid instead of removing it
        _synthetic_unpacked(tmp, [("500", "600", 2)])
        archive_backend.author_unpacked(Path(tmp), deck)
        rewrite(lambda o: o["components"][0]["objectUuidMapEntries"][-1]["uuid"]
                .__setitem__("lower", "999999"))
        try:
            archive_backend._verify_uuid_map(Path(tmp), 2)
            FAILS.append("_verify_uuid_map must raise on a mismatched uuid")
        except ValueError:
            pass


def main() -> int:
    for fn in (test_parse, test_unknown_effect, test_effects_map,
               test_verify_handles_spaces, test_codegen,
               test_verify_positive_and_negative,
               test_parse_builds, test_unknown_build_effect_and_kind,
               test_build_effects_map, test_build_validation, test_archive_emission,
               test_extract_and_verify_builds,
               test_extract_build_options,
               test_extract_transitions_excludes_builds,
               test_author_registers_build_uuid,
               test_author_registers_per_slide_component,
               test_author_direction_only_adds_no_uuid_entries,
               test_verify_uuid_map_catches_missing_entry):
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
