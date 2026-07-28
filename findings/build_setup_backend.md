# Build write-backend — user acceptance result

The unattended implementation generated this preserved acceptance artifact:

`samples/build_backend_acceptance.key`

The check was completed on 2026-07-18: the acceptance deck crashes Keynote 15.3
with `EXC_BREAKPOINT (SIGTRAP)` in the Keynote animation framework. Do not reopen
the artifact except for controlled diagnostics. An unmodified Action fixture
round-tripped by the same hybrid parser reopens successfully, isolating the
problem to newly authored build graph state rather than ordinary parser packing.

**Update 2026-07-28 — root-caused, fixed, and awaiting your reopen.** The bisect
(`findings/write_backend_bisect.md`) traced the crash to two missing
document-level invariants: builds were never registered in
`TSP.PackageMetadata.objectUuidMapEntries`, and `lastObjectIdentifier` was left
below the archive ids we minted. Both are fixed and covered by tests.

**Result: ACCEPTED.** The user reopened all five decks in Keynote 15.3 —
`bisect_direction`, `bisect_in`, `bisect_out`, `bisect_action`, and the combined
`build_backend_acceptance` — and every one opens with no crash and no
repair/recovery warning.

The completion gate from `findings/write_backend.md` is met. **No further user
action is needed**; the build write backend is unblocked.
