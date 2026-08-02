---
title: Prototype a Web Based Playground for Keynote Conversion
---

# Prototype a Web Based Playground for Keynote Conversion

## Summary
Build a web based proof of concept where a user can compose a presentation in the browser and receive a downloadable Keynote file generated from it, with no installation or account required. The input format is an open decision — see Input Format Options.

## Motivation
A browser based playground is a low friction way for people to try out KeynoteKit without installing any tools. This can serve as both a demo and a lightweight product on its own.

## Implementation Notes
The leading option is to build this entirely in Swift, using Hummingbird as the server framework, so the backend can directly reuse the same conversion pipeline used elsewhere in the package without a separate language or runtime. The server stack is not yet fixed — see Open Questions.

## Input Format Options
Three routes, kept open pending a decision:

1. **Markdown input** (default). Inert data the server parses. Depends on the markdown authoring issue, which is unbuilt, so this route cannot ship until that lands.
2. **Swift DSL input**. Ships soonest in principle — the DSL already exists and is render-verified, so no parser is needed. But it turns the playground into a code-execution service: accepting DSL source means compiling untrusted Swift server-side (sandboxing, resource and time limits, a full hostile-input threat model) or shipping a Swift toolchain to the browser via WASM. Both are harder than writing the markdown parser, and this route contradicts the motivation of trying KeynoteKit without writing Swift. Viable only if the execution model is solved first.
3. **Gallery playground**. Pre-authored decks the user selects and adjusts through form controls (title text, theme, slide count), rendered server-side by first-party code. No parser and no untrusted execution, so it can ship before either of the above, and it exercises the same download path. Narrower: users compose within fixed templates rather than authoring freely.

Routes are not mutually exclusive — 3 can ship first as a demo and be replaced or supplemented by 1 once the parser lands.

## Dependencies
- Route 1 depends on the markdown authoring and parsing issue, since that playground is a front end for its conversion pipeline
- Route 2 depends on choosing and hardening an execution model for untrusted Swift
- Route 3 has no unbuilt dependencies

## Tasks
- Decide the input format route before implementation starts
- Design a simple web page with the input surface that route implies
- Set up a server to handle conversion requests
- Wire up conversion of submitted input into a Keynote presentation
- Add a download button that returns a generated dot key file, or optionally a movie export, to the user
- Keep the initial flow account free and installation free

## Open Questions
- Which input format route to take, and whether to ship the gallery first as an interim demo
- Which server stack to use, if not Hummingbird
- Where will this be hosted, for example a VPS, a Mac based host, or another Swift friendly hosting option
- Should there be any file size or complexity limits for this free playground flow
- If the Swift DSL route is taken, what sandboxing model bounds untrusted compilation

## Acceptance Criteria
- A user can author or select presentation content in a web page, by the means the chosen route defines
- Submitting produces a downloadable Keynote file generated from that input
- No account creation or local installation required for this basic flow
- If a route accepting user-supplied source is chosen, untrusted input cannot execute outside a bounded sandbox
