---
title: Add a Sample Presentation as a Separate Demo Target or Product
---

# Add a Sample Presentation as a Separate Demo Target or Product

## Summary
Create a sample Keynote presentation built using KeynoteKit, structured as its own separate target or product within the Swift package, distinct from the core library.

## Motivation
A real, working sample presentation is useful both as a showcase for the README and as a living example for users learning the API. Keeping it as a separate target avoids bloating the core library with demo only code.

## Tasks
- Design a sample presentation that highlights the core features of KeynoteKit
- Build the sample presentation using the KeynoteKit Swift API
- Add a new target or product in Package.swift dedicated to this demo
- Add a short readme or comments within the demo target explaining what it demonstrates

## Acceptance Criteria
- New target or product exists specifically for the demo presentation
- Demo presentation builds successfully and exercises core KeynoteKit features
- Core KeynoteKit target has no new dependencies introduced by this demo
