#!/usr/bin/env python3
"""Keynote YAML archive surgery for builds and transition direction."""
from __future__ import annotations

import copy
import os
import secrets
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml

import deckkit
from prepare_keynote_parser import prepare

VERSION = [1, 0, 5]


def _header(identifier: str, archive_type: int) -> dict:
    return {
        "_pbtype": "TSP.ArchiveInfo", "identifier": identifier,
        "messageInfos": [{"type": archive_type, "version": VERSION.copy()}],
    }


def build_archive_records(build: deckkit.Build, drawable_id: str,
                          build_id: str, chunk_id: str) -> tuple[dict, dict, dict]:
    """Return the two YAML archive mappings for one authored build, plus the
    128-bit build uuid.

    The uuid must also be registered in the package object->uuid map (see
    _slide_component); Keynote crashes on load without it
    (findings/write_backend_bisect.md).
    """
    effect = (build.effect if build.kind == "Action"
              else deckkit.BUILD_EFFECTS[build.effect][0])
    animation = {
        "animationType": build.kind,
        "delay": build.delay,
        "duration": build.duration,
        "effect": effect,
    }
    if "direction" in build.options:
        animation["direction"] = build.options["direction"]
    animation.update({
        "randomNumberSeed": secrets.randbits(31),
        "writingDirectionIsRtl": False,
    })
    attributes: dict = {"ChartRotation3D": 60.0}
    if build.kind == "Action":
        attributes.update(copy.deepcopy(build.action_attributes))
    else:
        attributes.update({
            "customDeliveryOption": "kDeliveryOptionForward",
            "customTextDelivery": "kTextDeliveryByObject",
        })
    for key, value in build.options.items():
        if key not in {"direction", "delivery"}:
            attributes[key] = copy.deepcopy(value)
    attributes["animationAttributes"] = animation
    attributes["eventTrigger"] = 1

    archive = {
        "header": _header(build_id, 8),
        "objects": [{
            "_pbtype": "KN.BuildArchive",
            "attributes": attributes,
            "chunkIdSeed": 1,
            "delivery": build.options.get("delivery", "All at Once"),
            "drawable": {"identifier": drawable_id},
            "duration": 0.0,
        }],
    }
    random_build_id = {
        "lower": str(secrets.randbits(64)), "upper": str(secrets.randbits(64))
    }
    chunk = {
        "header": _header(chunk_id, 153),
        "objects": [{
            "_pbtype": "KN.BuildChunkArchive",
            "automatic": False,
            "build": {"identifier": build_id},
            "buildChunkIdentifier": {
                "buildChunkId": 1, "buildId": random_build_id.copy(),
            },
            "buildId": random_build_id.copy(),
            "delay": build.delay,
            "duration": build.duration,
            "referent": True,
        }],
    }
    return archive, chunk, random_build_id


def _archives(doc: dict):
    for chunk in doc.get("chunks", []):
        yield from chunk.get("archives", [])


def _first_object(archive: dict) -> dict:
    return archive.get("objects", [{}])[0]


def _load_index(root: Path) -> dict[Path, dict]:
    return {
        path: yaml.safe_load(path.read_text())
        for path in sorted((root / "Index").glob("*.iwa.yaml"))
    }


def _identifier_values(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if key == "identifier" and str(child).isdigit():
                yield int(child)
            yield from _identifier_values(child)
    elif isinstance(value, list):
        for child in value:
            yield from _identifier_values(child)


def _slide_order(files: dict[Path, dict]) -> list[tuple[str, str]]:
    nodes: dict[str, dict] = {}
    show = None
    for data in files.values():
        for archive in _archives(data):
            obj = _first_object(archive)
            if obj.get("_pbtype") == "KN.ShowArchive":
                show = obj
            elif obj.get("_pbtype") == "KN.SlideNodeArchive":
                nodes[str(archive["header"]["identifier"])] = obj
    if show is None:
        raise ValueError("KN.ShowArchive not found")

    ordered_nodes: list[str] = []
    def walk(tree):
        if isinstance(tree, dict):
            if "identifier" in tree and str(tree["identifier"]) in nodes:
                ordered_nodes.append(str(tree["identifier"]))
            for child in tree.values():
                walk(child)
        elif isinstance(tree, list):
            for child in tree:
                walk(child)
    walk(show.get("slideTree", {}))
    if not ordered_nodes:
        raise ValueError("KN.ShowArchive.slideTree contains no slides")
    return [(node_id, str(nodes[node_id]["slide"]["identifier"]))
            for node_id in ordered_nodes]


def _package_metadata(files: dict[Path, dict]) -> dict:
    """Return the single TSP.PackageMetadata object (Index/Metadata.iwa.yaml)."""
    for data in files.values():
        for archive in _archives(data):
            obj = _first_object(archive)
            if obj.get("_pbtype") == "TSP.PackageMetadata":
                return obj
    raise ValueError("TSP.PackageMetadata not found in Index/*.iwa.yaml")


def _slide_component(metadata: dict, slide_id: str) -> dict:
    """Return the package component describing Slide-<slide_id>.

    Keyed on `identifier`, which every component carries; `locator` is absent on
    non-slide components (Document, ViewState, ...), so it is only cross-checked.
    """
    for component in metadata.get("components", []):
        if str(component.get("identifier", "")) == str(slide_id):
            locator = component.get("locator")
            if locator is not None and str(locator) != f"Slide-{slide_id}":
                raise ValueError(
                    f"component {slide_id} has locator {locator!r}, "
                    f"expected 'Slide-{slide_id}'"
                )
            return component
    raise ValueError(f"no package component for slide {slide_id}")


def author_unpacked(root: Path, deck: deckkit.Deck) -> list[dict]:
    """Mutate an unpacked deck and return authored structural expectations."""
    files = _load_index(root)
    order = _slide_order(files)
    if len(order) != len(deck.slides):
        raise ValueError(f"archive has {len(order)} slides; spec has {len(deck.slides)}")

    located: dict[str, tuple[Path, dict, dict]] = {}
    node_located: dict[str, tuple[Path, dict]] = {}
    for path, data in files.items():
        for archive in _archives(data):
            obj = _first_object(archive)
            ident = str(archive.get("header", {}).get("identifier", ""))
            if obj.get("_pbtype") == "KN.SlideArchive":
                located[ident] = (path, data, archive)
            elif obj.get("_pbtype") == "KN.SlideNodeArchive":
                node_located[ident] = (path, obj)

    next_id = max(v for data in files.values() for v in _identifier_values(data)) + 1
    first_id = next_id
    metadata = _package_metadata(files)
    expected = []
    for slide_index, ((node_id, slide_id), spec_slide) in enumerate(zip(order, deck.slides)):
        path, data, slide_archive = located[slide_id]
        slide_obj = _first_object(slide_archive)
        drawable_ids = [str(v["identifier"]) for v in slide_obj.get("drawablesZOrder", [])]
        if len(drawable_ids) != len(spec_slide.items):
            raise ValueError(
                f"slide {slide_index} archive has {len(drawable_ids)} drawables; "
                f"spec has {len(spec_slide.items)} items"
            )
        if spec_slide.transition and spec_slide.transition.direction is not None:
            slide_obj["transition"]["attributes"]["animationAttributes"]["direction"] = (
                spec_slide.transition.direction
            )
        insertion = data["chunks"][0]["archives"]
        insert_at = insertion.index(slide_archive) + 1
        refs = slide_archive["header"]["messageInfos"][0].setdefault("objectReferences", [])
        new_build_archives = []
        new_chunk_archives = []
        new_build_ids = []
        new_chunk_ids = []
        new_uuid_entries = []
        for build in spec_slide.builds:
            target_index = int(build.target.split(":", 1)[1])
            drawable_id = drawable_ids[target_index]
            build_archive_id, chunk_archive_id = str(next_id), str(next_id + 1)
            next_id += 2
            build_archive, chunk_archive, build_uuid = build_archive_records(
                build, drawable_id, build_archive_id, chunk_archive_id
            )
            new_build_archives.append(build_archive)
            new_chunk_archives.append(chunk_archive)
            new_build_ids.append(build_archive_id)
            new_chunk_ids.append(chunk_archive_id)
            # Only the KN.BuildArchive is registered; the chunk id is not
            # (0/8 human-authored fixtures register it).
            new_uuid_entries.append(
                {"identifier": build_archive_id, "uuid": build_uuid.copy()}
            )
            slide_obj.setdefault("builds", []).append({"identifier": build_archive_id})
            slide_obj.setdefault("buildChunks", []).append({"identifier": chunk_archive_id})
            expected.append({
                "slide": slide_index, "kind": build.kind,
                "effect": (build.effect if build.kind == "Action"
                           else deckkit.BUILD_EFFECTS[build.effect][0]),
                "duration": build.duration, "delay": build.delay,
                "drawable": drawable_id,
            })
        insertion[insert_at:insert_at] = new_build_archives + new_chunk_archives
        refs[1:1] = new_build_ids + new_chunk_ids
        if spec_slide.builds:
            _slide_component(metadata, slide_id).setdefault(
                "objectUuidMapEntries", []
            ).extend(new_uuid_entries)
            node_path, node = node_located[node_id]
            node["buildEventCount"] = len(spec_slide.builds)
            node["buildEventCountCacheVersion"] = 2
            node["hasExplicitBuilds"] = True
            node["hasExplicitBuildsCacheVersion"] = 2
            files[node_path] = files[node_path]
        files[path] = data

    # Keynote keeps lastObjectIdentifier strictly above every archive id it has
    # handed out (verified across 5 human-authored build fixtures). Our appended
    # build/chunk ids would otherwise sit ABOVE the recorded high-water mark.
    # Only bump when ids were actually allocated, so a builds-free deck (the
    # direction-only path, which already reopens cleanly) is left untouched.
    last = metadata.get("lastObjectIdentifier")
    if next_id > first_id and last is not None and int(last) < next_id:
        metadata["lastObjectIdentifier"] = str(next_id)

    for path, data in files.items():
        path.write_text(yaml.safe_dump(data, sort_keys=False, allow_unicode=True))
    return expected


def _verify_uuid_map(root: Path, expected_build_count: int) -> None:
    """Assert every KN.BuildArchive is registered with uuid == its chunk buildId.

    This is the invariant whose absence crashes Keynote 15.3 in
    -[__NSSetM addObject:] (findings/write_backend_bisect.md). extract_builds()
    reads only Index/Slide*.iwa.yaml, so it cannot observe this; check it here.
    """
    files = _load_index(root)
    metadata = _package_metadata(files)
    registered: dict[str, dict] = {}
    for component in metadata.get("components", []):
        for entry in component.get("objectUuidMapEntries", []):
            registered[str(entry["identifier"])] = entry["uuid"]

    build_ids: list[str] = []
    chunk_build_ids: dict[str, dict] = {}
    chunk_archive_ids: list[str] = []
    for data in files.values():
        for archive in _archives(data):
            obj = _first_object(archive)
            ident = str(archive.get("header", {}).get("identifier", ""))
            if obj.get("_pbtype") == "KN.BuildArchive":
                build_ids.append(ident)
            elif obj.get("_pbtype") == "KN.BuildChunkArchive":
                chunk_build_ids[str(obj["build"]["identifier"])] = obj["buildId"]
                chunk_archive_ids.append(ident)

    if len(build_ids) != expected_build_count:
        raise ValueError(
            f"expected {expected_build_count} build archives, found {len(build_ids)}"
        )
    for build_id in build_ids:
        if build_id not in registered:
            raise ValueError(
                f"build archive {build_id} is not registered in "
                f"PackageMetadata.objectUuidMapEntries (Keynote will crash)"
            )
        want = chunk_build_ids.get(build_id)
        if want is None:
            raise ValueError(f"build archive {build_id} has no KN.BuildChunkArchive")
        if registered[build_id] != want:
            raise ValueError(
                f"uuid map entry for build {build_id} is {registered[build_id]!r}, "
                f"expected chunk buildId {want!r}"
            )

    last = metadata.get("lastObjectIdentifier")
    if last is not None and build_ids:
        highest = max(int(i) for i in build_ids + chunk_archive_ids)
        if int(last) < highest:
            raise ValueError(
                f"lastObjectIdentifier {last} is below the highest authored "
                f"archive id {highest}"
            )


def _parser(command: str, source: Path, output: Path) -> None:
    package_root = prepare()
    env = os.environ.copy()
    env["PYTHONPATH"] = str(package_root)
    subprocess.run(
        [sys.executable, "-m", "keynote_parser.command_line", command,
         str(source), "--output", str(output)],
        check=True, env=env,
    )


def write_back(base_key: Path, output_key: Path, deck: deckkit.Deck) -> None:
    """Unpack, author, pack, structurally verify, then atomically replace output."""
    with tempfile.TemporaryDirectory(prefix="keynotekit-write-") as tmp_name:
        tmp = Path(tmp_name)
        unpacked, verified = tmp / "unpacked", tmp / "verified"
        packed = tmp / "packed.key"
        _parser("unpack", base_key, unpacked)
        expected = author_unpacked(unpacked, deck)
        _parser("pack", unpacked, packed)
        _parser("unpack", packed, verified)
        actual = deckkit.extract_builds(str(verified))
        if len(actual) != len(expected):
            raise ValueError(f"authored {len(expected)} builds but verified {len(actual)}")
        for want, got in zip(expected, actual):
            for key in ("kind", "effect", "duration", "delay", "drawable"):
                if got[key] != want[key]:
                    raise ValueError(f"build verification mismatch for {key}: {got[key]!r} != {want[key]!r}")
        _verify_uuid_map(verified, len(expected))
        transitions = deckkit.extract_transitions(str(verified))
        wanted_directions = [s.transition.direction for s in deck.slides
                             if s.transition and s.transition.direction is not None]
        actual_directions = [t.get("direction") for t in transitions if t.get("direction") is not None]
        if actual_directions != wanted_directions:
            raise ValueError(
                f"transition direction verification mismatch: {actual_directions} != {wanted_directions}"
            )
        output_key.parent.mkdir(parents=True, exist_ok=True)
        staged = output_key.with_name(f".{output_key.name}.tmp-{os.getpid()}")
        try:
            subprocess.run(["cp", str(packed), str(staged)], check=True)
            os.replace(staged, output_key)
        finally:
            if staged.exists():
                staged.unlink()
