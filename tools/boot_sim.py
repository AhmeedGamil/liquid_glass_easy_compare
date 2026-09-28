#!/usr/bin/env python3
"""Boots the wanted iPhone on the newest iOS runtime and prints its UDID.

    boot_sim.py "iPhone 17 Pro"

Falls back to the newest "Pro" iPhone, then to any iPhone, when the named
model is not installed on the runner.
"""

import json
import re
import subprocess
import sys


def version(runtime):
    m = re.search(r"iOS-(\d+)-(\d+)(?:-(\d+))?", runtime)
    return tuple(int(x or 0) for x in m.groups()) if m else (0, 0, 0)


def main():
    wanted = sys.argv[1] if len(sys.argv) > 1 else "iPhone 17 Pro"
    data = json.loads(subprocess.check_output(
        ["xcrun", "simctl", "list", "devices", "available", "-j"]))
    runtimes = sorted((r for r in data["devices"] if "iOS" in r),
                      key=version, reverse=True)
    if not runtimes:
        sys.exit("no iOS simulator runtime installed")
    newest = data["devices"][runtimes[0]]
    phones = [d for d in newest if d["name"].startswith("iPhone")]
    pick = (next((d for d in phones if d["name"] == wanted), None)
            or next((d for d in phones if "Pro" in d["name"] and "Max" not in d["name"]), None)
            or (phones[0] if phones else None))
    if pick is None:
        sys.exit(f"no iPhone on {runtimes[0]}")

    udid = pick["udid"]
    print(f"{pick['name']} on {runtimes[0]}", file=sys.stderr)
    if pick["state"] != "Booted":
        subprocess.check_call(["xcrun", "simctl", "boot", udid])
    subprocess.check_call(["xcrun", "simctl", "bootstatus", udid, "-b"],
                          stdout=subprocess.DEVNULL)
    print(udid)


if __name__ == "__main__":
    main()
