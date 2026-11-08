#!/usr/bin/env python3
"""Measure the opt-in profiling build's app-local sleep/wake phases."""
import json
from pathlib import Path
import re
import statistics
import subprocess
import sys
import time

app = Path(sys.argv[1]).resolve()
output = Path("build/performance/controlled-idle")
output.parent.mkdir(parents=True, exist_ok=True)
log = Path(str(output) + "-metal.jsonl")

def wait_for(marker, timeout=40):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if marker in log.read_text():
            return
        if process.poll() is not None:
            raise RuntimeError("Profiling app exited")
        time.sleep(0.1)
    raise TimeoutError(marker)

def footprint(label):
    path = Path(str(output) + "-" + label + "-footprint.json")
    subprocess.run(["footprint", "-p", str(process.pid), "-j", str(path)],
                   check=True, stdout=subprocess.DEVNULL)
    return json.loads(path.read_text())["processes"][0]["footprint"] / 2**20

with log.open("w") as stdout, Path(str(output) + "-stderr.txt").open("w") as stderr:
    process = subprocess.Popen([str(app / "Contents/MacOS/SnowfallApp"), "--profile-pause"],
                               stdout=stdout, stderr=stderr)
    try:
        wait_for("NSWorkspaceScreensDidSleepNotification")
        time.sleep(2)  # Let the last in-flight frame finish releasing its resources.
        paused_footprint = footprint("paused")
        before = log.read_text().count("gpu_ms_per_frame")
        top = subprocess.check_output(["top", "-pid", str(process.pid), "-l", "11", "-s", "1",
                                       "-stats", "pid,command,cpu,mem,threads,power,csw"], text=True)
        Path(str(output) + "-top.txt").write_text(top)
        after = log.read_text().count("gpu_ms_per_frame")
        cpu = [float(v) for v in re.findall(r"^" + str(process.pid) + r"\s+SnowfallApp\s+([\d.]+)", top, re.M)][1:]
        assert before == after, "GPU frames continued while the overlay was paused"
        wait_for("NSWorkspaceScreensDidWakeNotification")
        deadline = time.monotonic() + 10
        while log.read_text().count("gpu_ms_per_frame") == after:
            assert time.monotonic() < deadline, "GPU rendering did not resume"
            time.sleep(0.1)
        summary = {"paused_cpu_mean_percent_one_core": statistics.mean(cpu),
                   "paused_cpu_max": max(cpu), "paused_footprint_mib": paused_footprint,
                   "gpu_reports_during_pause": after - before,
                   "resumed_footprint_mib": footprint("resumed")}
        Path(str(output) + "-summary.json").write_text(json.dumps(summary, indent=2))
        print(json.dumps(summary, indent=2))
    finally:
        process.terminate()
        process.wait(timeout=10)
