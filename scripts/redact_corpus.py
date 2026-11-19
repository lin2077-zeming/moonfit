#!/usr/bin/env python3
"""Redact the activity corpus before it is committed.

The raw exports contain two things that must not be published: the device
serial number, present as a uint32z[8] in every `file_id` and `device_info`
message, and the absolute coordinates of the author's home and regular routes.

Redaction is surgical rather than a re-encode. Once a FIT definition message is
known, the byte span of every field in every data message that uses it is known
too, so the serial can be zeroed and the positions shifted in place while every
other byte stays untouched. That keeps the corpus internally consistent:
counts, timestamps, distances, durations and summary fields still agree with
the record stream, which is what makes the files usable as gate fixtures.

Coordinates move by an exact integer number of semicircles in FIT and by the
equivalent number of degrees in the XML exports, preserving each file's own
decimal precision. `session.swc_lat` and `session.swc_long` are deliberately
left at 0: they are 0 in the raw export too, and that contradiction with
`nec_*` is defect B1 in docs/spec-notes.md, which a gate asserts.

Run with --self-test to verify the CRC routine, the walker and the patcher
against the raw corpus before trusting any output.
"""
from __future__ import annotations

import argparse
import hashlib
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

CRC_TABLE = [
    0x0000, 0xCC01, 0xD801, 0x1400, 0xF001, 0x3C00, 0x2800, 0xE401,
    0xA001, 0x6C00, 0x7800, 0xB401, 0x5000, 0x9C01, 0x8801, 0x4400,
]

# Shift applied to every coordinate. A round number of semicircles keeps the
# FIT side exact; the XML side uses the degree equivalent. At the corpus
# latitude this is roughly 5.6 km north and 6.2 km west.
DLAT_SEMICIRCLES = 600000
DLON_SEMICIRCLES = -800000
SEMICIRCLE_DEGREES = 180.0 / 2 ** 31
DLAT_DEGREES = DLAT_SEMICIRCLES * SEMICIRCLE_DEGREES
DLON_DEGREES = DLON_SEMICIRCLES * SEMICIRCLE_DEGREES

SERIAL_FIELDS = {0: {3}, 23: {3}}
# session.swc_lat (31) and session.swc_long (32) are intentionally absent.
LAT_FIELDS = {20: {0}, 18: {3, 29}, 19: {3, 5}}
LON_FIELDS = {20: {1}, 18: {4, 30}, 19: {4, 6}}

MESSAGE_NAMES = {
    0: "file_id", 18: "session", 19: "lap", 20: "record",
    21: "event", 23: "device_info", 34: "activity", 49: "file_creator",
}


def fit_crc16(data: bytes, crc: int = 0) -> int:
    """FIT protocol CRC-16. Verified against the stored value of every corpus file."""
    for byte in data:
        tmp = CRC_TABLE[crc & 0xF]
        crc = ((crc >> 4) & 0x0FFF) ^ tmp ^ CRC_TABLE[byte & 0xF]
        tmp = CRC_TABLE[crc & 0xF]
        crc = ((crc >> 4) & 0x0FFF) ^ tmp ^ CRC_TABLE[(byte >> 4) & 0xF]
    return crc & 0xFFFF


def wrap_sint32(value: int) -> int:
    value &= 0xFFFFFFFF
    return value - 0x100000000 if value >= 0x80000000 else value


def parse(data: bytes):
    """Walk a FIT file. Returns (header_size, data_size, messages).

    Each message is (global_number, spans) where spans lists
    (field_def_num, byte_offset, byte_size) for every field in the definition.
    Raises if the stream does not consume the data section exactly.
    """
    if len(data) < 14 or data[8:12] != b".FIT":
        raise ValueError("missing .FIT signature")
    header_size = data[0]
    if header_size not in (12, 14):
        raise ValueError(f"unexpected header size {header_size}")
    data_size = struct.unpack("<I", data[4:8])[0]
    end = header_size + data_size
    if end + 2 != len(data):
        raise ValueError(f"header size {header_size} + data {data_size} + crc 2 != {len(data)}")
    offset = header_size
    definitions: dict[int, tuple[int, list[tuple[int, int]]]] = {}
    messages: list[tuple[int, list[tuple[int, int, int]]]] = []
    while offset < end:
        header_byte = data[offset]
        if header_byte & 0x80:
            local = (header_byte >> 5) & 0x3
            if local not in definitions:
                raise ValueError("compressed timestamp header with no definition")
            global_number, fields = definitions[local]
            cursor = offset + 1
            spans = []
            for def_num, size in fields:
                spans.append((def_num, cursor, size))
                cursor += size
            messages.append((global_number, spans))
            offset = cursor
            continue
        is_definition = bool(header_byte & 0x40)
        has_dev = bool(header_byte & 0x20)
        local = header_byte & 0x0F
        if is_definition:
            offset += 1
            big_endian = bool(data[offset + 1] & 0x80)
            global_number = struct.unpack(
                ">H" if big_endian else "<H", data[offset + 2 : offset + 4]
            )[0]
            field_count = data[offset + 4]
            offset += 5
            fields = []
            for _ in range(field_count):
                fields.append((data[offset], data[offset + 1]))
                offset += 3
            if has_dev:
                dev_count = data[offset]
                offset += 1 + 3 * dev_count
            definitions[local] = (global_number, fields)
        else:
            if local not in definitions:
                raise ValueError("data message with no preceding definition")
            global_number, fields = definitions[local]
            cursor = offset + 1
            spans = []
            for def_num, size in fields:
                spans.append((def_num, cursor, size))
                cursor += size
            messages.append((global_number, spans))
            offset = cursor
    if offset != end:
        raise ValueError(f"walker stopped at {offset}, expected {end}")
    return header_size, data_size, messages


def verify_crc(data: bytes) -> tuple[bool, bool]:
    header_size = data[0]
    file_ok = fit_crc16(data[:-2]) == struct.unpack("<H", data[-2:])[0]
    header_ok = True
    if header_size >= 14:
        header_ok = fit_crc16(data[0:12]) == struct.unpack("<H", data[12:14])[0]
    return file_ok, header_ok


def is_invalid(data: bytes, offset: int, size: int) -> bool:
    """A FIT field is invalid when every byte is 0xFF."""
    return all(byte == 0xFF for byte in data[offset : offset + size])


def redact_fit(data: bytes, report: dict) -> bytes:
    out = bytearray(data)
    header_size, data_size, messages = parse(data)
    for global_number, spans in messages:
        for def_num, offset, size in spans:
            if def_num in SERIAL_FIELDS.get(global_number, set()):
                if not is_invalid(data, offset, size):
                    report["serials_zeroed"] += 1
                out[offset : offset + size] = b"\x00" * size
                continue
            if is_invalid(data, offset, size) or size != 4:
                continue
            if def_num in LAT_FIELDS.get(global_number, set()):
                value = wrap_sint32(struct.unpack("<i", data[offset : offset + 4])[0])
                struct.pack_into("<i", out, offset, wrap_sint32(value + DLAT_SEMICIRCLES))
                report["lat_shifted"] += 1
            elif def_num in LON_FIELDS.get(global_number, set()):
                value = wrap_sint32(struct.unpack("<i", data[offset : offset + 4])[0])
                struct.pack_into("<i", out, offset, wrap_sint32(value + DLON_SEMICIRCLES))
                report["lon_shifted"] += 1
    # The header itself is untouched, so only the trailing file CRC changes.
    struct.pack_into("<H", out, len(out) - 2, fit_crc16(bytes(out[:-2])))
    report["bytes"] = len(out)
    return bytes(out)


def decimals_of(text: str) -> int:
    return len(text.split(".")[1]) if "." in text else 0


def shift_number(text: str, delta: float) -> str:
    places = decimals_of(text)
    return f"{float(text) + delta:.{places}f}" if places else str(int(float(text)) + int(delta))


def redact_tcx(text: str, report: dict) -> str:
    def lat(match):
        report["xml_lat"] += 1
        return f"{match.group(1)}{shift_number(match.group(2), DLAT_DEGREES)}{match.group(3)}"

    def lon(match):
        report["xml_lon"] += 1
        return f"{match.group(1)}{shift_number(match.group(2), DLON_DEGREES)}{match.group(3)}"

    text = re.sub(
        r"(<LatitudeDegrees>)(-?[\d.]+)(</LatitudeDegrees>)", lat, text
    )
    return re.sub(
        r"(<LongitudeDegrees>)(-?[\d.]+)(</LongitudeDegrees>)", lon, text
    )


def redact_gpx(text: str, report: dict) -> str:
    def lat(match):
        report["xml_lat"] += 1
        return f'{match.group(1)}{shift_number(match.group(2), DLAT_DEGREES)}"'

    def lon(match):
        report["xml_lon"] += 1
        return f'{match.group(1)}{shift_number(match.group(2), DLON_DEGREES)}"'

    text = re.sub(r'(lat=")(-?[\d.]+)"', lat, text)
    return re.sub(r'(lon=")(-?[\d.]+)"', lon, text)


def redact_kml(text: str, report: dict) -> str:
    def coord(match):
        parts = match.group(1).split()
        out = []
        for point in parts:
            components = point.split(",")
            if len(components) < 2:
                out.append(point)
                continue
            report["xml_lon"] += 1
            report["xml_lat"] += 1
            shifted = [
                shift_number(components[0], DLON_DEGREES),
                shift_number(components[1], DLAT_DEGREES),
            ] + components[2:]
            out.append(",".join(shifted))
        return f"<coordinates>{' '.join(out)}</coordinates>"

    return re.sub(r"<coordinates>([^<]*)</coordinates>", coord, text)


REDACTORS = {".tcx": redact_tcx, ".gpx": redact_gpx, ".kml": redact_kml}


def write_lf(path, text):
    """Write text with LF endings regardless of host platform.

    Path.write_text translates newlines using the host default, so on Windows it
    emits CRLF. The recorded digests are of the bytes on disk, while
    .gitattributes normalises these files to LF in the repository, so a CRLF
    write produces a checksum that no fresh clone can reproduce. Gate 0 exists
    to catch exactly this, and on the first push it did.
    """
    path.write_bytes(text.replace("\r\n", "\n").encode("utf-8"))


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def collect(source: Path) -> list[tuple[str, Path]]:
    """Map each raw file to an ASCII output name, keeping activity grouping."""
    entries: list[tuple[str, Path]] = []
    for directory in sorted(p for p in source.iterdir() if p.is_dir()):
        if directory.name.startswith("igp"):
            for path in sorted(directory.rglob("*")):
                if path.is_file() and path.suffix.lower() == ".fit":
                    day = path.parent.name
                    entries.append((f"ride-{day}{path.suffix.lower()}", path))
                elif path.is_file() and path.suffix.lower() in REDACTORS:
                    day = path.parent.name
                    entries.append((f"ride-{day}{path.suffix.lower()}", path))
        elif directory.name.startswith("华为"):
            for path in sorted(directory.iterdir()):
                if not path.is_file() or path.suffix.lower() not in REDACTORS:
                    continue
                stem = re.sub(r"[^\d]", "", path.stem)[:8]
                suffix = "b" if path.stem.endswith("(1)") else ""
                entries.append((f"run-{stem}{suffix}{path.suffix.lower()}", path))
    return entries


def redact_all(source: Path, out_dir: Path) -> dict:
    out_dir.mkdir(parents=True, exist_ok=True)
    report: dict = {
        "serials_zeroed": 0, "lat_shifted": 0, "lon_shifted": 0,
        "xml_lat": 0, "xml_lon": 0, "bytes": 0, "files": [],
    }
    sums: list[tuple[str, str]] = []
    manifest: list[tuple[str, str, str]] = []
    for name, raw_path in collect(source):
        target = out_dir / name
        suffix = raw_path.suffix.lower()
        if suffix == ".fit":
            data = redact_fit(raw_path.read_bytes(), report)
            target.write_bytes(data)
        else:
            text = raw_path.read_text(encoding="utf-8-sig" if suffix == ".gpx" else "utf-8")
            bom = raw_path.read_bytes()[:3] == b"\xef\xbb\xbf"
            redacted = REDACTORS[suffix](text, report)
            target.write_bytes((b"\xef\xbb\xbf" if bom else b"") + redacted.encode("utf-8"))
        digest = sha256(target)
        sums.append((name, digest))
        manifest.append((name, raw_path.name, digest))
        report["files"].append(name)

    # The manifest is written before SHA256SUMS so that it is covered by it.
    # SHA256SUMS is the only file in the directory that does not checksum
    # itself, which keeps the integrity gate free of cycles and still able to
    # flag any file that appears without a recorded digest.
    lines = ["redacted_name,raw_name,sha256"]
    for name, raw_name, digest in manifest:
        lines.append(f"{name},{raw_name},{digest}")
    write_lf(out_dir / "manifest.csv", "\n".join(lines) + "\n")

    entries = [f"{digest}  {name}" for name, digest in sums]
    entries.append(f"{sha256(out_dir / 'manifest.csv')}  manifest.csv")
    write_lf(
        out_dir / "SHA256SUMS",
        "\n".join(sorted(entries, key=lambda line: line.split("  ")[1])) + "\n",
    )
    report["manifest"] = manifest
    return report


def allowed_offsets(data: bytes):
    """Every byte offset the redactor is permitted to touch."""
    header_size, data_size, messages = parse(data)
    allowed: set[int] = set(range(len(data) - 2, len(data)))
    touched: dict[int, str] = {}
    for global_number, spans in messages:
        for def_num, offset, size in spans:
            for index in range(offset, offset + size):
                allowed.add(index)
            if def_num in SERIAL_FIELDS.get(global_number, set()):
                touched[offset] = "serial"
            elif size == 4 and not is_invalid(data, offset, size):
                if def_num in LAT_FIELDS.get(global_number, set()):
                    touched[offset] = "lat"
                elif def_num in LON_FIELDS.get(global_number, set()):
                    touched[offset] = "lon"
    return allowed, touched


def self_test(source: Path) -> int:
    failures: list[str] = []
    entries = collect(source)
    fits = sorted(raw for _, raw in entries if raw.suffix.lower() == ".fit")
    if not fits:
        print(f"  FAIL no raw .fit files found under {source}")
        return 1

    print(f"  checking {len(fits)} raw FIT files")
    for path in fits:
        raw = path.read_bytes()
        label = path.parent.name

        file_ok, header_ok = verify_crc(raw)
        if not (file_ok and header_ok):
            failures.append(f"{label}: raw CRC does not verify (file={file_ok} header={header_ok})")
        try:
            parse(raw)
        except ValueError as error:
            failures.append(f"{label}: raw walker failed: {error}")
            continue

        report: dict = {"serials_zeroed": 0, "lat_shifted": 0, "lon_shifted": 0}
        red = redact_fit(raw, report)

        if len(red) != len(raw):
            failures.append(f"{label}: length changed {len(raw)} -> {len(red)}")
        red_file_ok, red_header_ok = verify_crc(red)
        if not (red_file_ok and red_header_ok):
            failures.append(f"{label}: redacted CRC does not verify")
        try:
            _, _, red_messages = parse(red)
        except ValueError as error:
            failures.append(f"{label}: redacted walker failed: {error}")
            continue
        _, _, raw_messages = parse(raw)
        if [(g, [(d, s) for d, _, s in spans]) for g, spans in red_messages] != \
           [(g, [(d, s) for d, _, s in spans]) for g, spans in raw_messages]:
            failures.append(f"{label}: message structure changed after redaction")

        allowed, touched = allowed_offsets(raw)
        stray = [i for i in range(len(raw)) if i not in allowed and raw[i] != red[i]]
        if stray:
            failures.append(f"{label}: {len(stray)} bytes changed outside serial/coordinate/CRC spans")

        serial_bad = lat_bad = lon_bad = 0
        for offset, kind in touched.items():
            if kind == "serial":
                if any(red[offset + i] != 0 for i in range(4)):
                    serial_bad += 1
            else:
                before = struct.unpack("<i", raw[offset : offset + 4])[0]
                after = struct.unpack("<i", red[offset : offset + 4])[0]
                delta = DLAT_SEMICIRCLES if kind == "lat" else DLON_SEMICIRCLES
                if wrap_sint32(before + delta) != after:
                    (lat_bad, lon_bad) = (lat_bad + 1, lon_bad) if kind == "lat" else (lat_bad, lon_bad + 1)
        if serial_bad or lat_bad or lon_bad:
            failures.append(
                f"{label}: patch mismatch serial={serial_bad} lat={lat_bad} lon={lon_bad}"
            )
        if report["serials_zeroed"] < 1:
            failures.append(f"{label}: no serial number was found to zero")
        print(
            f"    {label}: serials_zeroed={report['serials_zeroed']} "
            f"lat_shifted={report['lat_shifted']} lon_shifted={report['lon_shifted']} "
            f"bytes_untouched={len(raw) - len(allowed)}"
        )

    # XML: structure must survive, only coordinate text may change.
    xml_files = [raw for _, raw in entries if raw.suffix.lower() in REDACTORS]
    count_tags = {".tcx": "Trackpoint", ".gpx": "trkpt", ".kml": "Placemark"}
    for path in sorted(xml_files):
        suffix = path.suffix.lower()
        raw_text = path.read_bytes().decode("utf-8-sig")
        report = {"xml_lat": 0, "xml_lon": 0}
        red_text = REDACTORS[suffix](raw_text, report)
        tag = count_tags[suffix]
        before = len(re.findall(f"<{tag}[ >]", raw_text))
        after = len(re.findall(f"<{tag}[ >]", red_text))
        if before != after:
            failures.append(f"{path.name}: {tag} count changed {before} -> {after}")
        if report["xml_lat"] == 0:
            failures.append(f"{path.name}: no latitude was shifted")
        for needle in ("<Time>", "<time>", "DistanceMeters", "TotalTimeSeconds", "totalDistance"):
            if raw_text.count(needle) != red_text.count(needle):
                failures.append(f"{path.name}: {needle} occurrence count changed")
    print(f"  checked {len(xml_files)} raw XML files")

    if failures:
        print("redact_corpus self-test FAILED:")
        for item in failures:
            print(f"  - {item}")
        return 1
    print("redact_corpus self-test OK")
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--source", required=False, help="directory holding the raw exports")
    parser.add_argument("--out", default=str(ROOT / "corpus" / "redacted"))
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args(argv)

    if args.self_test:
        if not args.source:
            print("--self-test needs --source pointing at the raw exports")
            return 2
        print("redact_corpus self-test (R4: verify the ruler first)")
        return self_test(Path(args.source))

    if not args.source:
        print("--source is required: the directory holding the raw device exports")
        return 2
    source = Path(args.source)
    out_dir = Path(args.out)
    report = redact_all(source, out_dir)
    print(f"redacted {len(report['files'])} files into {out_dir}")
    print(f"  serial numbers zeroed : {report['serials_zeroed']}")
    print(f"  FIT latitudes shifted : {report['lat_shifted']}")
    print(f"  FIT longitudes shifted: {report['lon_shifted']}")
    print(f"  XML latitudes shifted : {report['xml_lat']}")
    print(f"  XML longitudes shifted: {report['xml_lon']}")
    print(f"  coordinate shift      : lat {DLAT_DEGREES!r} deg, lon {DLON_DEGREES!r} deg")
    for name, raw_name, digest in report["manifest"]:
        print(f"  {name:<28} <- {raw_name:<40} {digest[:16]}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
