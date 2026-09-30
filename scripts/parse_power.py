"""Summarize the nine FFT8-SAIF power runs and their simulation evidence."""
import csv
import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "build" / "power"
ROWS = []
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--allow-incomplete", action="store_true",
                    help="Summarize only finished configurations; default requires all nine.")
args = parser.parse_args()


def field(text, label):
    match = re.search(re.escape(label) + r"[^\n]*?\|\s*([^|\n]+?)\s*\|", text)
    if not match:
        raise ValueError(f"missing {label}")
    return match.group(1).strip()


for adder in ("RCA", "CSLA", "KSA"):
    for multiplier in ("ARRAY", "WALLACE", "VEDIC"):
        name = f"{adder}_{multiplier}"
        report = BASE / name / "power_report.rpt"
        if args.allow_incomplete and not report.exists():
            continue
        text = report.read_text(errors="replace")
        log = (BASE / name / "simulation.log").read_text(errors="replace")
        checksum = re.search(r"Benchmark Checksum \(a0/x10\):\s*(\d+)", log)
        if not checksum or checksum.group(1) != "248" or "BENCHMARK PASS" not in log:
            raise ValueError(f"{name}: FFT8 simulation did not pass with checksum 248")
        with (BASE / name / "activity.saif").open(errors="replace") as file:
            header = file.read(1000)
        duration = re.search(r"\(DURATION\s+(\d+)\)", header)
        if not duration:
            raise ValueError(f"{name}: missing SAIF duration")
        multiplier = re.search(r"^\|\s+u_mul\s+\|\s*([0-9.]+)\s*\|", text, re.M)
        if not multiplier:
            raise ValueError(f"{name}: missing multiplier hierarchy power")
        ROWS.append({
            "configuration": name,
            "total_w": field(text, "Total On-Chip Power (W)"),
            "dynamic_w": field(text, "Dynamic (W)"),
            "static_w": field(text, "Device Static (W)"),
            "multiplier_w": multiplier.group(1),
            "confidence": field(text, "Confidence Level"),
            "nets_matched": field(text, "Design Nets Matched"),
            "fft8_checksum": checksum.group(1),
            "saif_duration_ps": duration.group(1),
        })

if not ROWS:
    raise ValueError("no completed power reports")
output = BASE / "power_summary.csv"
with output.open("w", newline="") as file:
    writer = csv.DictWriter(file, fieldnames=ROWS[0].keys())
    writer.writeheader()
    writer.writerows(ROWS)
print(output)
