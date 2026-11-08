#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
app_path="$1"
label="$2"
executable=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app_path/Contents/Info.plist")
output="build/performance/$label"
mkdir -p build/performance
"$app_path/Contents/MacOS/$executable" > "$output-metal.jsonl" 2> "$output-stderr.txt" &
profile_pid=$!
trap 'kill -TERM "$profile_pid" 2>/dev/null || true; wait "$profile_pid" 2>/dev/null || true' EXIT
echo "Profiling $label (PID $profile_pid)"
sleep 10
kill -0 "$profile_pid"
top -pid "$profile_pid" -l 21 -s 1 -stats pid,command,cpu,mem,threads,power,csw > "$output-top.txt"
footprint -p "$profile_pid" -j "$output-footprint.json" > "$output-footprint.txt"
python3 - "$output" "$profile_pid" <<'PY'
import json, re, statistics, sys
prefix, pid = sys.argv[1:]
with open(prefix + '-top.txt') as f:
    values = [float(v) for v in re.findall(r'^' + pid + r'\s+SnowfallApp\s+([\d.]+)', f.read(), re.M)][1:]
with open(prefix + '-metal.jsonl') as f:
    rows = [json.loads(line) for line in f if line.startswith('{')][2:]
with open(prefix + '-footprint.json') as f:
    footprint = json.load(f)['processes'][0]['footprint'] / 2**20
summary = {'cpu_mean_percent_one_core': statistics.mean(values), 'cpu_median': statistics.median(values),
           'cpu_min': min(values), 'cpu_max': max(values), 'samples': len(values), 'footprint_mib': footprint,
           'metal': {k: statistics.mean(row[k] for row in rows) for k in rows[0]}}
with open(prefix + '-summary.json', 'w') as f:
    json.dump(summary, f, indent=2)
print(json.dumps(summary, indent=2))
PY
