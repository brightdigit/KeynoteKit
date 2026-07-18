# Build write-backend — remaining user acceptance check

The unattended implementation generated this preserved acceptance artifact:

`samples/build_backend_acceptance.key`

Please open it in Keynote Creator Studio 15.3, do not save over it, and:

1. Report any repair/recovery warning verbatim.
2. If it opens without a warning, play slide 1 and confirm the three objects
   perform Dissolve In, Dissolve Out, and a horizontal Move Action in that order.
3. Advance to slide 2 and confirm the Move In transition uses the authored
   non-default direction.

The check was completed on 2026-07-18: the acceptance deck crashes Keynote 15.3
with `EXC_BREAKPOINT (SIGTRAP)` in the Keynote animation framework. Do not reopen
the artifact except for controlled diagnostics. An unmodified Action fixture
round-tripped by the same hybrid parser reopens successfully, isolating the
problem to newly authored build graph state rather than ordinary parser packing.
