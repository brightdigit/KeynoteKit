---
title: Support Using Existing Keynote Themes Installed on the User's Machine
---

# Support Using Existing Keynote Themes Installed on the User's Machine

## Summary
Allow a KeynoteKit presentation to reference and apply a theme that is already installed in the user's local Keynote application, rather than only supporting themes defined in code.

## Motivation
Many users already have a preferred Keynote theme, whether built in or custom installed. Supporting these existing themes means users do not have to redefine styling they already have, and their generated presentations can match the rest of their existing deck library.

## Tasks
- Investigate how installed Keynote themes can be discovered and referenced programmatically
- Support enumerating available installed themes by name
- Support applying a chosen installed theme to a KeynoteKit built presentation
- Handle the case where a referenced theme name does not exist on the machine, with a clear error or fallback

## Open Questions
- Should installed themes be enumerable and selectable by name, or does the user need to already know the exact theme to reference it
- Where should this live within the package, core target versus its own target, given it may require system level access

## Acceptance Criteria
- A presentation can reference an existing installed Keynote theme by name and apply it
- Available installed themes can be listed
- Clear error or fallback behavior exists when a requested theme is not found
