# The `.iwa` archive stream: `TSP.ArchiveInfo`-delimited records (#17)

The inner layout of a decompressed `.iwa` stream was never written down in
this repo (the outer chunk framing is in `snappy_survey.md` §1). Recorded
here as implemented by `TSPArchiveStream` in `KeynoteKitProtobuf` and
verified against keynote-parser 1.14.4.0's `codec.py`
(`get_archive_info_and_remainder`, `IWAArchiveSegment.from_buffer`) plus the
24-fixture round-trip gate.

## Layout

Repeat until the stream is exhausted:

1. a base-128 **varint**: the byte length of a `TSP.ArchiveInfo` message;
2. that many bytes of `ArchiveInfo` (decode `partial: true` — proto2
   `required` fields are routinely absent);
3. for each `ArchiveInfo.messageInfos[i]` in order: exactly
   `messageInfos[i].length` bytes of serialized payload.

There is no checksum and no padding at this layer. On write, each
`MessageInfo.length` must be recomputed from the payload actually emitted.

## Resolving payload types

- `MessageInfo.type` is the Keynote registry identifier
  (`TSPRegistryMapping`, 631 ids; **not injective** — ids 5 and 6 both name
  `KN.SlideArchive`).
- **Patch records:** a `MessageInfo` with `type == 0` inside a record whose
  `ArchiveInfo.shouldMerge` is set is a *patch*: its payload is a sparse
  message of the type found at
  `messageInfos[messageInfo.baseMessageIndex].type`. keynote-parser models
  this as `ProtobufPatch`; `TSPArchiveRecord.decodedMessages()` mirrors it.
  Measured: `build_cat_appear` is the one fixture exercising this
  (`ViewState.iwa`-class records); decoding it via the plain registry lookup
  throws `unknownIdentifier(0)`.
- `TSP.ArchiveInfo` / `TSP.MessageInfo` themselves are framing-level
  messages: they are **not** in the registry table (its `TSP.*` entries
  start at 11000) and are decoded directly.

## Fidelity rule

For round-trips, payloads are carried as opaque bytes end to end — nothing
re-encodes them. `TSPArchiveStream.serialize` re-encodes only the
`ArchiveInfo` header (SwiftProtobuf emits fields in number order, which need
not match Apple's byte order); the semantic gate therefore compares parsed
records, while byte-level identity of the *decompressed stream* holds on the
read → reframe path because repack never re-serializes records at all. See
`iwa_byte_identity.md` for what is and is not byte-identical.
