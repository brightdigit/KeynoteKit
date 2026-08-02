---
title: Support Markdown as an Alternative Authoring Format for Presentations
---

# Support Markdown as an Alternative Authoring Format for Presentations

## Summary
Allow presentations to be authored using Markdown as an alternative to the Swift builder API, giving users a lightweight, non-Swift way to define Keynote presentations with KeynoteKit.

## Motivation
Not everyone building a presentation wants to write Swift code. Supporting Markdown as an input format lowers the barrier to entry and provides a foundation other tools, such as a future web playground, can build on.

## Format Spec

### Single file or multiple files
Support both. A single markdown file with heading based slide breaks for quick simple decks, and a folder of numbered markdown files, one per slide, for larger presentations that benefit from being split up.

### Front matter
Each file, or the top of a single file, can include a front matter block for presentation level or slide level metadata, such as title, theme, or transition style.

### Slide structure
Within a file, a top level heading marks the start of a new slide. Content below that heading, such as body text, bullet points, and images, maps to the corresponding elements on that slide.

### Non mappable features
Features that do not translate cleanly to Markdown, such as animations or complex custom layouts, should have a documented fallback or be explicitly marked as unsupported in version one.

## Tasks
- Finalize the markdown slide and front matter spec described above
- Build a parser that converts markdown, whether single file or multi file, into the underlying presentation model
- Build the conversion pipeline from parsed model to an actual Keynote file
- Decide where this lives, core target versus separate target or product
- Add documentation and example markdown files, including at least one multi file example

## Open Questions
- Should this live in the core KeynoteKit target or as its own separate target or product
- How much presentation styling and layout control should be exposed through markdown versus left to defaults

## Acceptance Criteria
- A markdown file, or folder of markdown files, can be parsed into a valid KeynoteKit presentation
- Output presentation is visually equivalent to the same content authored in Swift, within reason
- Documented example included, covering both single file and multi file cases
