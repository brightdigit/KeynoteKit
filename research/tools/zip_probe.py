#!/usr/bin/env python3
"""Survey structural properties of KeynoteKit's .key zip corpus.

Reads every .key in research/fixtures, research/goldens, and
Sources/KeynoteKit/Resources/blank.key and reports:
- entry counts, compress_type histogram
- data-descriptor flag (general-purpose bit 3) prevalence
- zip64 markers (EOCD64 locator signature, zip64 extra field 0x0001,
  0xFFFFFFFF sentinels in central directory)
- archive comment lengths
- entry ordering pattern (top-level prefix sequence per archive)
- duplicate names
- directory entries (names ending in '/')
- local header vs central directory agreement (sizes, CRC, method, flags)
- extra-field IDs seen in local + central headers
- CRC-32 verification of every entry's data
"""
import glob
import io
import struct
import sys
import zipfile
import zlib
from collections import Counter, OrderedDict

ROOT = "/Users/leo/Documents/Projects/KeynoteKit/wt-iwa"
FILES = (
    sorted(glob.glob(ROOT + "/research/fixtures/*.key"))
    + sorted(glob.glob(ROOT + "/research/goldens/*.key"))
    + [ROOT + "/Sources/KeynoteKit/Resources/blank.key"]
)

EOCD64_LOC_SIG = b"PK\x06\x07"
EOCD64_SIG = b"PK\x06\x06"

def parse_extra_ids(extra: bytes):
    ids = []
    i = 0
    while i + 4 <= len(extra):
        (hid, sz) = struct.unpack("<HH", extra[i:i+4])
        ids.append(hid)
        i += 4 + sz
    return ids

def top_prefix(name: str) -> str:
    return name.split("/", 1)[0] + "/" if "/" in name else "(root)"

total_entries = 0
method_hist = Counter()
dd_flag_count = 0
zip64_files = []
comment_lens = Counter()
dup_files = []
dir_entry_files = []
lh_cd_mismatches = []
extra_ids_local = Counter()
extra_ids_central = Counter()
crc_failures = []
order_patterns = Counter()
per_file = []
made_by_hist = Counter()
version_needed_hist = Counter()
first_entry_names = Counter()
utf8_flag_count = 0
prefix_hist = Counter()

for path in FILES:
    raw = open(path, "rb").read()
    zf = zipfile.ZipFile(io.BytesIO(raw))
    infos = zf.infolist()
    total_entries += len(infos)

    names = [i.filename for i in infos]
    dupes = [n for n, c in Counter(names).items() if c > 1]
    if dupes:
        dup_files.append((path, dupes))
    dirs = [n for n in names if n.endswith("/")]
    if dirs:
        dir_entry_files.append((path, dirs))

    comment_lens[len(zf.comment)] += 1

    # zip64 markers
    has_z64 = EOCD64_LOC_SIG in raw or EOCD64_SIG in raw
    for i in infos:
        ids = parse_extra_ids(i.extra)
        for hid in ids:
            extra_ids_central[hid] += 1
        if 0x0001 in ids or i.file_size >= 0xFFFFFFFF or i.compress_size >= 0xFFFFFFFF or i.header_offset >= 0xFFFFFFFF:
            has_z64 = True
    if has_z64:
        zip64_files.append(path)

    # ordering pattern: sequence of top-level prefixes with runs collapsed
    seq = []
    for n in names:
        p = top_prefix(n)
        prefix_hist[p] += 1
        if not seq or seq[-1] != p:
            seq.append(p)
    order_patterns[" -> ".join(seq)] += 1
    first_entry_names[names[0]] += 1

    # per-entry checks against local headers
    buf = io.BytesIO(raw)
    for info in infos:
        method_hist[info.compress_type] += 1
        made_by_hist[info.create_version] += 1
        version_needed_hist[info.extract_version] += 1
        if info.flag_bits & 0x8:
            dd_flag_count += 1
        if info.flag_bits & 0x800:
            utf8_flag_count += 1
        buf.seek(info.header_offset)
        lh = buf.read(30)
        (sig, ver, flags, method, mtime, mdate, crc, csize, usize,
         nlen, elen) = struct.unpack("<IHHHHHIIIHH", lh)
        assert sig == 0x04034B50, (path, info.filename)
        lname = buf.read(nlen).decode("utf-8", "replace")
        lextra = buf.read(elen)
        for hid in parse_extra_ids(lextra):
            extra_ids_local[hid] += 1
        problems = []
        if lname != info.filename:
            problems.append("name")
        if method != info.compress_type:
            problems.append("method")
        if flags != info.flag_bits:
            problems.append(f"flags lh={flags:#x} cd={info.flag_bits:#x}")
        if not (flags & 0x8):
            if crc != info.CRC:
                problems.append("crc")
            if csize != info.compress_size:
                problems.append("csize")
            if usize != info.file_size:
                problems.append("usize")
        else:
            # sizes may be zero in LH when data descriptor is used
            if crc not in (0, info.CRC):
                problems.append("crc(dd)")
        if problems:
            lh_cd_mismatches.append((path, info.filename, problems))
        # CRC verify actual data
        data = zf.read(info.filename)
        if zlib.crc32(data) & 0xFFFFFFFF != info.CRC:
            crc_failures.append((path, info.filename))
        if len(data) != info.file_size:
            crc_failures.append((path, info.filename, "size"))

    per_file.append((path.replace(ROOT + "/", ""), len(infos)))

print(f"archives: {len(FILES)}")
print(f"total entries: {total_entries}")
print(f"compress_type histogram: {dict(method_hist)}  (0=STORED, 8=DEFLATED)")
print(f"data-descriptor (bit 3) entries: {dd_flag_count}")
print(f"utf-8 flag (bit 11) entries: {utf8_flag_count}")
print(f"zip64 archives: {len(zip64_files)} {zip64_files}")
print(f"archive comment length histogram: {dict(comment_lens)}")
print(f"duplicate-name archives: {len(dup_files)} {dup_files}")
print(f"directory-entry archives: {len(dir_entry_files)} {dir_entry_files}")
print(f"LH/CD mismatches: {len(lh_cd_mismatches)}")
for m in lh_cd_mismatches[:20]:
    print("   ", m)
print(f"CRC failures: {len(crc_failures)} {crc_failures[:5]}")
print(f"extra-field IDs local: {dict(extra_ids_local)}")
print(f"extra-field IDs central: {dict(extra_ids_central)}")
print(f"version made by histogram: {dict(made_by_hist)}")
print(f"version needed histogram: {dict(version_needed_hist)}")
print(f"top-level prefix entry counts: {dict(prefix_hist)}")
print(f"first entry name histogram: {dict(first_entry_names)}")
print("ordering patterns (collapsed prefix runs):")
for pat, c in order_patterns.most_common():
    print(f"  {c:3d}x  {pat}")
print("\nper-file entry counts:")
for p, n in per_file:
    print(f"  {n:4d}  {p}")

# size envelope (zip64 relevance)
max_entry = 0
max_archive = 0
max_count = 0
import os
for path in FILES:
    max_archive = max(max_archive, os.path.getsize(path))
    zf = zipfile.ZipFile(path)
    max_count = max(max_count, len(zf.infolist()))
    for i in zf.infolist():
        max_entry = max(max_entry, i.file_size)
print(f"\nmax entry uncompressed size: {max_entry} bytes")
print(f"max archive size: {max_archive} bytes")
print(f"max entry count: {max_count}")
