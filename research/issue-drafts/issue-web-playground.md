---
title: Prototype a Web Based Playground for Markdown to Keynote Conversion
---

# Prototype a Web Based Playground for Markdown to Keynote Conversion

## Summary
Build a web based proof of concept where a user can paste or write Markdown into a text box and receive a downloadable Keynote file generated from it, with no installation or account required.

## Motivation
A browser based playground is a low friction way for people to try out KeynoteKit's markdown authoring format without writing Swift code or installing any tools. This can serve as both a demo and a lightweight product on its own.

## Implementation Notes
This will be built entirely in Swift, using Hummingbird as the server framework. This allows the backend to directly reuse the same markdown parsing and Keynote conversion pipeline used elsewhere in the package, without needing a separate language or runtime.

## Dependencies
- Depends on the markdown authoring and parsing issue, since this playground is a front end for that conversion pipeline

## Tasks
- Design a simple web page with a text box for markdown input
- Set up a Hummingbird based server to handle conversion requests
- Wire up conversion of submitted markdown into a Keynote presentation using the markdown parser and conversion pipeline
- Add a download button that returns a generated dot key file, or optionally a movie export, to the user
- Keep the initial flow account free and installation free

## Open Questions
- Where will this be hosted, for example a VPS, a Mac based host, or another Swift friendly hosting option
- Should there be any file size or complexity limits for this free playground flow

## Acceptance Criteria
- A user can paste or type markdown into a web text box
- Submitting produces a downloadable Keynote file generated from that markdown
- No account creation or local installation required for this basic flow
- Server is implemented in Swift using Hummingbird
