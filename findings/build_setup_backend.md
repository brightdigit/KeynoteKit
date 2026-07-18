# Build write-backend — user setup and acceptance checks

This file is the handoff for the few steps that cannot be completed reliably
without a person looking at Keynote. Everything else in the Option A
pack/write-backend implementation runs unattended.

## Nothing needed yet

No fixture creation or other preparatory work is currently required from the
user. The existing build and direction fixtures are sufficient to implement and
exercise the backend.

## What I may need after unattended implementation

I will generate a named `.key` acceptance fixture and report its exact path.
Only then:

1. Open that file in Keynote 15.3 if macOS automation cannot open it unattended.
2. Start the slideshow or preview the selected object's animation.
3. Confirm that the object visibly performs the requested build and that the
   deck otherwise looks intact.
4. Report any repair/recovery warning verbatim and do not save over the fixture.

If macOS displays an Automation or Files-and-Folders permission prompt while I
run the acceptance check, approve access for the invoking terminal/Codex process
to control Keynote.

## Optional follow-up evidence

These are not blockers for the first write-backend milestone:

- Re-shoot the ambiguous Fly In fixture to reconcile `apple:sidezoom` with the
  older `apple:move in character` observation.
- Create one fixture per remaining transition direction if a complete direction
  integer map is desired.

## Completion signal

The backend milestone is accepted when the generated deck:

- packs without an error;
- opens in Keynote without a repair warning;
- retains its expected slide and object counts;
- contains the injected `KN.BuildArchive` when unpacked again; and
- visibly plays the requested build in Keynote.
