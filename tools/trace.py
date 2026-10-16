#!/usr/bin/env python3
"""Runs the TraceTests against the Apple app and collects what they leave.

    trace.py --udid <sim> --out traces --project apple/AppleReference.xcodeproj \
             --derived build/dd [--only testTab01TapFar,testMorph1Menu]

Records the simulator screen for the whole run (<out>/trace.mp4), then
copies the app's per-case frame traces (Documents/traces/*.jsonl) and the
test's step marks into <out>, with meta.json holding the video's frame-0
wall time so a trace frame can be found in the clip.
"""

import argparse
import json
import os
import shutil
import signal
import subprocess
import sys
import time

from record import start_recorder

BUNDLE = "dev.lgcompare.apple"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--udid", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--project", required=True)
    ap.add_argument("--derived", required=True)
    ap.add_argument("--only", default="")
    ap.add_argument("--lite", action="store_true",
                    help="geometry only: no private properties or animation objects")
    args = ap.parse_args()

    out = os.path.abspath(args.out)
    os.makedirs(out, exist_ok=True)
    marks = os.path.join(out, "marks.txt")
    if os.path.exists(marks):
        os.remove(marks)

    rec, t0 = start_recorder(args.udid, os.path.join(out, "trace.mp4"))

    tests = [t.strip() for t in args.only.split(",") if t.strip()]
    only = [f"-only-testing:CompareUITests/TraceTests/{t}" for t in tests] or \
           ["-only-testing:CompareUITests/TraceTests"]
    env = dict(os.environ)
    env["TEST_RUNNER_TRACE_RUN"] = "1"
    env["TEST_RUNNER_MARKS_FILE"] = marks
    if args.lite:
        env["TEST_RUNNER_TRACE_LITE"] = "1"
    cmd = [
        "xcodebuild", "test-without-building",
        "-project", args.project,
        "-scheme", "AppleReference",
        "-destination", f"id={args.udid}",
        "-derivedDataPath", args.derived,
        "-resultBundlePath", os.path.join(args.derived, "trace.xcresult"),
        *only,
    ]
    log = open(os.path.join(out, "xcodebuild.log"), "w")
    test = subprocess.Popen(cmd, env=env, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True)
    for line in test.stdout:
        sys.stdout.write(line)
        log.write(line)
    test.wait()
    log.close()

    time.sleep(1.0)
    rec.send_signal(signal.SIGINT)
    try:
        rec.wait(60)
    except subprocess.TimeoutExpired:
        rec.kill()

    data = subprocess.check_output(
        ["xcrun", "simctl", "get_app_container", args.udid, BUNDLE, "data"], text=True).strip()
    src = os.path.join(data, "Documents", "traces")
    if os.path.isdir(src):
        shutil.copytree(src, os.path.join(out, "traces"), dirs_exist_ok=True)
    else:
        print(f"no traces at {src}", file=sys.stderr)

    with open(os.path.join(out, "meta.json"), "w") as f:
        json.dump({"video_t0_wall": t0, "tests": tests or "all",
                   "xcodebuild_exit": test.returncode}, f, indent=2)
    for name in sorted(os.listdir(os.path.join(out, "traces"))) if os.path.isdir(os.path.join(out, "traces")) else []:
        print(name, os.path.getsize(os.path.join(out, "traces", name)))
    if test.returncode != 0:
        print(f"xcodebuild exited {test.returncode} (traces kept anyway)", file=sys.stderr)


if __name__ == "__main__":
    main()
