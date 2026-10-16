#!/usr/bin/env python3
"""Reads one FrameTracer trace and says what moved.

    trace_report.py <run dir> <case>                 # rank the layers that moved
    trace_report.py <run dir> <case> --layers a,b    # per-frame CSV of those layers
    trace_report.py <run dir> <case> --tree          # the tree at the first frame

<run dir> holds traces/<case>.jsonl and marks.txt (what tools/trace.py
leaves). Times are milliseconds from the case's "start" mark.
"""

import argparse
import csv
import json
import math
import os
import re
import sys


BAD_NUMBER = re.compile(r"(?<=[:\[,])-?(?:nan|inf)(?=[,\]}])")


def load(run, case):
    path = os.path.join(run, "traces", f"{case}.jsonl")
    header, frames = None, []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            # The tracer prints nan/inf as is (UIKit's capsule corner radius is nan).
            line = BAD_NUMBER.sub("null", line)
            try:
                d = json.loads(line)
            except json.JSONDecodeError:
                continue  # a frame cut off by the app being killed
            if d.get("hdr"):
                header = d
            else:
                frames.append(d)
    marks = []
    mpath = os.path.join(run, "marks.txt")
    if os.path.exists(mpath):
        for m in re.finditer(r"MARK (\S+) (\S+) ([0-9.]+)", open(mpath).read()):
            if m.group(1) == case:
                marks.append((m.group(2), float(m.group(3))))
    return header, frames, marks


def replay(frames):
    """Per layer: identity, and its full state on every frame it changed."""
    info, series, lastx = {}, {}, {}
    for fr in frames:
        for l in fr.get("l", []):
            lid = l["id"]
            if "c" in l:
                info[lid] = {k: l[k] for k in ("p", "d", "c", "v", "nm")}
                series.setdefault(lid, [])
                lastx.pop(lid, None)
            # Properties are only written when they change: carry them on.
            if "x" in l:
                lastx[lid] = l["x"]
            elif lid in lastx:
                l = dict(l, x=lastx[lid])
            series.setdefault(lid, []).append((fr["t"], l))
        for g in fr.get("gone", []):
            series.setdefault(g, []).append((fr["t"], None))
    return info, series


def chain(info, lid, n=4):
    out, cur = [], lid
    while cur in info and len(out) < n:
        i = info[cur]
        out.append(i["v"] or i["c"])
        cur = i["p"]
    return " < ".join(out)


def to_trace_time(frames, wall):
    best = min(frames, key=lambda f: abs(f["wall"] - wall))
    return best["t"] + (wall - best["wall"])


def scale(state):
    m = state.get("m") or [1, 0, 0, 1]
    return math.hypot(m[0], m[1]), math.hypot(m[2], m[3])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("run")
    ap.add_argument("case")
    ap.add_argument("--layers", default="")
    ap.add_argument("--top", type=int, default=40)
    ap.add_argument("--tree", action="store_true")
    ap.add_argument("--csv", default="")
    args = ap.parse_args()

    header, frames, marks = load(args.run, args.case)
    info, series = replay(frames)
    tmarks = [(n, to_trace_time(frames, w)) for n, w in marks]
    t0 = dict(tmarks).get("start", frames[0]["t"])
    print(f"{args.case}: {len(frames)} frames, {len(info)} layers, screen {header and (header['w'], header['h'], header['scale'])}")
    print("marks:", ", ".join(f"{n}@{(t - t0) * 1000:.0f}ms" for n, t in tmarks))
    dts = [b["t"] - a["t"] for a, b in zip(frames, frames[1:])]
    if dts:
        dts.sort()
        print(f"frame interval median {dts[len(dts) // 2] * 1000:.1f} ms, p95 {dts[int(len(dts) * .95)] * 1000:.1f} ms")

    if args.tree:
        for lid, i in info.items():
            first = series[lid][0][1]
            if first is None:
                continue
            extra = f" cr={first['cr']}" if "cr" in first else ""
            print("  " * i["d"] + f"{i['v'] or '-'} [{i['c']}] {lid} r={first['r']}{extra}" + (f" x={first['x']}" if "x" in first else ""))
        return

    if not args.layers:
        rows = []
        for lid, s in series.items():
            states = [st for t, st in s if st is not None and t >= t0]
            if len(states) < 3 or lid not in info:
                continue
            def spread(k):
                vals = [st["r"][k] for st in states]
                return max(vals) - min(vals)
            crs = [st.get("cr") or 0 for st in states]
            sc = [scale(st)[0] for st in states]
            score = spread(0) + spread(1) + 2 * spread(2) + 2 * spread(3) + 4 * (max(crs) - min(crs)) + 100 * (max(sc) - min(sc))
            if score < 0.5 and not any("x" in st for st in states):
                continue
            rows.append((score, lid, len(states), spread(0), spread(2), spread(3), max(crs) - min(crs), max(sc) - min(sc)))
        rows.sort(reverse=True)
        print(f"\n{'score':>7} {'id':>14} {'n':>4} {'dx':>6} {'dw':>6} {'dh':>6} {'dcr':>5} {'dsc':>5}  class < parents")
        for r in rows[: args.top]:
            print(f"{r[0]:7.1f} {r[1]:>14} {r[2]:4d} {r[3]:6.1f} {r[4]:6.1f} {r[5]:6.1f} {r[6]:5.1f} {r[7]:5.2f}  {info[r[1]]['c']} | {chain(info, r[1])}")
        return

    ids = args.layers.split(",")
    last = {lid: None for lid in ids}
    feed = {lid: iter(series.get(lid, [])) for lid in ids}
    pending = {lid: next(feed[lid], None) for lid in ids}
    out = open(args.csv, "w", newline="") if args.csv else sys.stdout
    w = csv.writer(out)
    cols = ["t_ms", "touch_x", "touch_y", "touch_phase"]
    for k, lid in enumerate(ids):
        cols += [f"L{k}_{c}" for c in ("x", "y", "w", "h", "cx", "cy", "sx", "sy", "cr", "cr_screen", "opacity")]
    w.writerow(cols)
    touch = ("", "", "")
    for fr in frames:
        for lid in ids:
            while pending[lid] is not None and pending[lid][0] <= fr["t"]:
                last[lid] = pending[lid][1]
                pending[lid] = next(feed[lid], None)
        if fr.get("touch"):
            tt = fr["touch"][-1]
            touch = (tt["x"], tt["y"], tt["ph"])
        row = [round((fr["t"] - t0) * 1000, 1), *touch]
        for lid in ids:
            st = last[lid]
            if st is None:
                row += [""] * 11
                continue
            x, y, ww, hh = st["r"]
            sx, sy = scale(st)
            cr = st.get("cr", 0)
            if cr is None:  # nan: a capsule, half the short side
                cr = min(st["b"]) / 2
            row += [x, y, ww, hh, round(x + ww / 2, 2), round(y + hh / 2, 2), round(sx, 4), round(sy, 4),
                    cr, round(cr * min(sx, sy), 2), st.get("o", 1)]
        w.writerow(row)
        if touch[2] in (3, 4):
            touch = ("", "", "")
    if args.csv:
        out.close()
        print("wrote", args.csv)


if __name__ == "__main__":
    main()
