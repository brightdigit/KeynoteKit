---
title: Add a SwiftUI Style API for Defining Custom Themes With Environment Based Propagation
---

# Add a SwiftUI Style API for Defining Custom Themes With Environment Based Propagation

## Summary
Add a declarative, SwiftUI inspired API for defining custom presentation themes in code, along with an environment style property wrapper so a theme set at the top of a presentation or slide tree is automatically accessible by nested slides and elements.

## Motivation
Users building presentations may want to define their own theme entirely in code rather than relying on an installed Keynote theme. A SwiftUI style approach keeps this consistent with idioms Swift developers already know, and environment style propagation means nested slide elements can read styling information without every layer needing it explicitly passed in.

## Research Needed Before Implementation
Before committing to an approach, a deep dive into how Keynote's underlying theme and file internals actually work is needed. This research should determine whether a custom theme can realistically layer on top of an existing installed Keynote theme, or whether custom themes and installed themes need to remain two separate, non combinable paths. This decision should not be locked in until that investigation is done.

## Tasks
- Investigate Keynote's theme and file format internals to understand what is technically feasible
- Based on that research, decide whether custom themes can extend or layer on installed themes, or must be fully separate
- Design a declarative API for defining a custom theme in code, covering things like fonts, colors, and slide layout defaults
- Implement an environment style property wrapper so a theme, once set, is accessible by any nested slide or element without manual passing
- Support reading individual pieces of theme information downstream, such as a specific slide type's styling or a particular color or font, not just the whole theme object
- Handle the case where a child requests theme information not present in a given custom theme, with a sensible default or fallback behavior

## Open Questions
- How closely should the custom theme API mirror Keynote's own theme model, versus introducing new abstractions
- Should this custom theme API be able to layer on top of, or extend, an existing installed Keynote theme, pending the research above

## Acceptance Criteria
- A presentation can define a custom theme via a SwiftUI style declarative API
- Theme information propagates to nested slide elements via an environment style mechanism, without requiring explicit manual passing at every level
- Nested elements can read specific style values from the active theme, such as fonts or colors for a given slide type
