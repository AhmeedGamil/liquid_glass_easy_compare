#!/usr/bin/env python3
"""Records one app running every scene script, and notes where each scene sits.

    record.py --udid <sim> --app apple|package --out site/clips \
              --project apple/AppleReference.xcodeproj --derived build/dd

Starts the simulator's own screen recorder, runs the UI tests against the
chosen app, stops the recorder, then merges the scene marks into
<out>/manifest.json as seconds from the first frame of <out>/<app>.mp4.
"""

import argparse
import json
import os
import re
import signal
import subprocess
import sys
import threading
import time

MARK = re.compile(r"MARK (\w+) (\w+) (start|end) ([0-9.]+)")


def start_recorder(udid, path):
    rec = subprocess.Popen(
        ["xcrun", "simctl", "io", udid, "recordVideo", "--codec=h264", "--force", path],
        stderr=subprocess.PIPE,
        text=True,
    )
    started = threading.Event()
    stamp = {}

    def watch():
        for line in rec.stderr:
            sys.stderr.write("[recorder] " + line)
            if "Recording started" in line and not started.is_set():
                stamp["t0"] = time.time()
                started.set()

    threading.Thread(target=watch, daemon=True).start()
    if not started.wait(30):
        stamp["t0"] = time.time()
        print("recorder never said it started; using now as frame 0", file=sys.stderr)
    return rec, stamp["t0"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--udid", required=True)
    ap.add_argument("--app", required=True, choices=["apple", "package"])
    ap.add_argument("--out", required=True)
    ap.add_argument("--project", required=True)
    ap.add_argument("--derived", required=True)
    args = ap.parse_args()

    out = os.path.abspath(args.out)
    shots = os.path.join(out, "shots")
    os.makedirs(shots, exist_ok=True)
    marks_file = os.path.join(out, f"{args.app}-marks.txt")
    if os.path.exists(marks_file):
        os.remove(marks_file)
    video = os.path.join(out, f"{args.app}.mp4")

    rec, t0 = start_recorder(args.udid, video)

    env = dict(os.environ)
    env["TEST_RUNNER_TARGET_APP"] = args.app
    env["TEST_RUNNER_MARKS_FILE"] = marks_file
    env["TEST_RUNNER_SHOTS_DIR"] = shots
    cmd = [
        "xcodebuild", "test-without-building",
        "-project", args.project,
        "-scheme", "AppleReference",
        "-destination", f"id={args.udid}",
        "-derivedDataPath", args.derived,
        "-resultBundlePath", os.path.join(args.derived, f"{args.app}.xcresult"),
    ]
    log_lines = []
    test = subprocess.Popen(cmd, env=env, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True)
    for line in test.stdout:
        sys.stdout.write(line)
        log_lines.append(line)
    test.wait()

    time.sleep(1.0)
    rec.send_signal(signal.SIGINT)
    try:
        rec.wait(60)
    except subprocess.TimeoutExpired:
        rec.kill()

    # Marks come from the file the test runner wrote on the host; the
    # xcodebuild log is the fallback if the simulator could not write it.
    text = ""
    if os.path.exists(marks_file):
        with open(marks_file) as f:
            text = f.read()
    if "MARK" not in text:
        text = "".join(log_lines)

    scenes = {}
    for app, scene, phase, t in MARK.findall(text):
        if app != args.app:
            continue
        scenes.setdefault(scene, {})[phase] = round(float(t) - t0, 3)

    manifest_path = os.path.join(out, "manifest.json")
    manifest = {}
    if os.path.exists(manifest_path):
        with open(manifest_path) as f:
            manifest = json.load(f)
    manifest[args.app] = {"video": f"{args.app}.mp4", "scenes": scenes}
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)

    print(f"{args.app}: {len(scenes)} scenes marked -> {manifest_path}")
    if test.returncode != 0:
        print(f"xcodebuild exited {test.returncode} (clips kept anyway)", file=sys.stderr)


if __name__ == "__main__":
    main()
