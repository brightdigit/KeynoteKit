# Build write-backend — remaining user acceptance check

The unattended implementation generated this preserved acceptance artifact:

`samples/build_backend_acceptance.key`

Please open it in Keynote Creator Studio 15.3, do not save over it, and:

1. Report any repair/recovery warning verbatim.
2. If it opens without a warning, play slide 1 and confirm the three objects
   perform Dissolve In, Dissolve Out, and a horizontal Move Action in that order.
3. Advance to slide 2 and confirm the Move In transition uses the authored
   non-default direction.

This visual check is currently also a blocker investigation: unattended Keynote
automation opens the file and reports two slides, but object access fails with
AppleEvent `-10000` (and the minimal one-build artifact invalidated the Keynote
connection with `-609`). An unmodified Action fixture round-tripped by the same
hybrid parser reopens and reports its five text items successfully, isolating the
problem to newly authored build archives rather than ordinary parser packing.
