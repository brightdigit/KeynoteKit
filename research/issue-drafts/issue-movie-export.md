---
title: Add Movie Export Support as a Separate Package Target
---

# Add Movie Export Support as a Separate Package Target

## Summary
Add the ability to export a Keynote presentation as a movie file, implemented as a separate target or product within the Swift package rather than bundled into the core library.

## Motivation
Exporting presentations as video is useful for demos, documentation, and sharing, but it is a distinct concern from the core KeynoteKit functionality. Keeping it as a separate target keeps the main library lean for consumers who do not need export capabilities.

## Implementation Notes
This will use the Scripting Bridge, consistent with how KeynoteKit already communicates with Keynote elsewhere in the library, rather than introducing a new integration mechanism.

## Tasks
- Design the API for triggering a movie export from a Keynote presentation
- Implement the export logic using the Scripting Bridge, wrapping Keynote's built in export to movie functionality
- Add a new target or product in Package.swift dedicated to this export capability
- Add documentation and a small usage example

## Acceptance Criteria
- New target or product exists in Package.swift specifically for movie export
- Export produces a playable movie file from a KeynoteKit built presentation
- Core KeynoteKit target has no new dependencies introduced by this feature
