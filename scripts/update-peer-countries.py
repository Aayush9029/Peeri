#!/usr/bin/env python3
import argparse
import csv
import gzip
import hashlib
import io
import ipaddress
import pathlib
import re
import struct
import urllib.request


def main():
    parser = argparse.ArgumentParser(description="Update Peeri's bundled offline country database from DB-IP Lite.")
    parser.add_argument("month", help="DB-IP release month, YYYY-MM")
    parser.add_argument("--source", type=pathlib.Path, help="Use an already downloaded CSV gzip file")
    args = parser.parse_args()
    if not re.fullmatch(r"\d{4}-(0[1-9]|1[0-2])", args.month):
        parser.error("month must be YYYY-MM")
    source_url = f"https://download.db-ip.com/free/dbip-country-lite-{args.month}.csv.gz"
    archive = args.source.read_bytes() if args.source else urllib.request.urlopen(source_url, timeout=60).read()
    records = {4: [], 6: []}
    for start, end, country in csv.reader(io.TextIOWrapper(gzip.GzipFile(fileobj=io.BytesIO(archive)))):
        start_ip = ipaddress.ip_address(start)
        end_ip = ipaddress.ip_address(end)
        if start_ip.version != end_ip.version or start_ip > end_ip or not re.fullmatch(r"[A-Z]{2}", country):
            raise ValueError(f"Invalid range: {start}, {end}, {country}")
        records[start_ip.version].append((start_ip.packed, end_ip.packed, country.encode("ascii")))
    for version in records:
        records[version].sort()
        if any(left[1] >= right[0] for left, right in zip(records[version], records[version][1:])):
            raise ValueError(f"Overlapping IPv{version} ranges")
    binary = bytearray(b"PEERIC01" + struct.pack(">II", len(records[4]), len(records[6])))
    for version in (4, 6):
        for start, end, country in records[version]:
            binary.extend(start + end + country)
    resources = pathlib.Path(__file__).resolve().parents[1] / "Peeri" / "Resources"
    resources.mkdir(exist_ok=True)
    (resources / "PeerCountries.bin").write_bytes(binary)
    (resources / "PeerCountries-LICENSE.txt").write_text(
        f"IP Geolocation by DB-IP\nhttps://db-ip.com/\n\n"
        f"DB-IP Country Lite, {args.month}\n{source_url}\n\n"
        "Licensed under Creative Commons Attribution 4.0 International.\n"
        "https://creativecommons.org/licenses/by/4.0/\n\n"
        "Modified for Peeri: CSV ranges converted to a compact binary format.\n"
        "Location estimates have reduced coverage and accuracy and may be outdated.\n\n"
        f"Source archive SHA-256: {hashlib.sha256(archive).hexdigest()}\n"
        f"Binary SHA-256: {hashlib.sha256(binary).hexdigest()}\n"
    )
    print(f"Saved {len(records[4])} IPv4 and {len(records[6])} IPv6 ranges ({len(binary):,} bytes).")


if __name__ == "__main__":
    main()
