#!/usr/bin/env python3
"""Per-frame geometry of the glass in a trace, as CSV.

    glass_series.py <run dir> <case> [--out file.csv]

Tab bar cases (tab_*): the selection pill, i.e. the _UILiquidLensView in the
tab bar platter. Morph cases (morph_*): every glass shape (CASDFElementLayer)
taking part in the morph, plus their union's box.

Times are ms from the frame that delivered the first touch-down. Boxes are on screen, in points
(window space, y down). w/h already include the layer's transform; sx/sy
are that transform's scale, bw/bh the untransformed bounds.
"""

import argparse
import csv
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from trace_report import load, replay, scale  # noqa: E402


def radii_of(state):
    """The shape's corner radius in its own points: per-corner radii when the
    layer has them, else cornerRadius (nan = a capsule, half the short side)."""
    if state.get("radii"):
        nums = [float(v) for v in state["radii"].split()]
        return max(nums) if nums else 0.0
    cr = state.get("cr", 0)
    if cr is None:
        return min(state["b"]) / 2
    return cr


def walk(frames, series, ids):
    """Yields (frame, {id: state}) with every id's latest state carried on."""
    cur = {i: None for i in ids}
    feeds = {i: iter(series.get(i, [])) for i in ids}
    pend = {i: next(feeds[i], None) for i in ids}
    for fr in frames:
        for i in ids:
            while pend[i] is not None and pend[i][0] <= fr["t"]:
                cur[i] = pend[i][1]
                pend[i] = next(feeds[i], None)
        yield fr, cur


def subtree(info, root):
    kids = {}
    for k, v in info.items():
        kids.setdefault(v["p"], []).append(k)
    out, todo = [], [root]
    while todo:
        i = todo.pop()
        out.append(i)
        todo += kids.get(i, [])
    return out


PHASES = ["began", "moved", "stationary", "ended", "cancelled"]


def touch_columns(fr, last):
    """The finger as of this frame. When a stalled frame delivers several
    events at once (a quick tap: began and ended together), all their
    phases are listed."""
    if fr.get("touch"):
        events = fr["touch"]
        phases = []
        for e in events:
            name = PHASES[e["ph"]] if e["ph"] < 5 else str(e["ph"])
            if name not in phases:
                phases.append(name)
        last = ("+".join(phases), events[-1]["x"], events[-1]["y"])
    return last


def tab_rows(frames, info, series, t0):
    lens = next(k for k, v in info.items() if v["v"] == "_UILiquidLensView")
    sel = next((k for k in subtree(info, lens)
                if info[k]["c"] == "CABackdropLayer" and info.get(info[k]["p"], {}).get("v") == "_UITabSelectionView"), None)
    ids = [lens] + ([sel] if sel else [])
    head = ["t_ms", "touch", "touch_x", "touch_y", "lifted", "cx", "cy", "w", "h", "bw", "bh", "sx", "sy",
            "corner_radius", "corner_rx_screen", "corner_ry_screen"]
    rows, touch = [], ("", "", "")
    for fr, cur in walk(frames, series, ids):
        touch = touch_columns(fr, touch)
        s = cur[lens]
        if s is None:
            continue
        x, y, w, h = s["r"]
        sx, sy = scale(s)
        # The glass is a capsule of the lens bounds; the selection backdrop's
        # corner radius (half its height) confirms it while it animates.
        cr = (cur[sel].get("cr") if sel and cur[sel] else None) or s["b"][1] / 2
        lifted = (s.get("x") or {}).get("view.lifted", "")
        rows.append([round((fr["t"] - t0) * 1000, 1), *touch, lifted,
                     round(x + w / 2, 2), round(y + h / 2, 2), w, h, s["b"][0], s["b"][1],
                     round(sx, 4), round(sy, 4), round(cr, 2), round(cr * sx, 2), round(cr * sy, 2)])
        if touch[0].endswith(("ended", "cancelled")):
            touch = ("", "", "")
    return head, rows


def ancestors(info, i):
    out, cur = [], info[i]["p"]
    while cur in info:
        out.append(cur)
        cur = info[cur]["p"]
    return out


def morph_rows(frames, info, series, t0):
    # Only shapes that move or resize: the bar/background glass stays put.
    def moves(i):
        rs = [tuple(s["r"]) + (scale(s)[0],) for _, s in series[i] if s]
        return len(set(rs)) > 2
    # SwiftUI morphs inside its own SDF renderer: all that shows in the
    # layer tree is the SDFLayer sized to the morphing shape's box (no
    # per-frame corner radius).
    els = [k for k, v in info.items() if v["c"] == "SwiftUI.SDFLayer" and moves(k)]
    if not els:
        els = [k for k, v in info.items() if v["c"] == "CASDFElementLayer" and moves(k)]
        # Every UIKit shape is drawn twice, as glass (under a backdrop
        # layer) and as its highlight: keep the glass copy.
        els = [i for i in els if any(info[a]["c"] == "CABackdropLayer" for a in ancestors(info, i))] or els
    chains = {i: ancestors(info, i) for i in els}
    watched = sorted(set(els) | {a for c in chains.values() for a in c})
    names = {i: f"shape{n}" for n, i in enumerate(els)}
    head = ["t_ms", "touch", "touch_x", "touch_y", "union_x", "union_y", "union_w", "union_h"]
    for i in els:
        n = names[i]
        head += [f"{n}_cx", f"{n}_cy", f"{n}_w", f"{n}_h", f"{n}_bw", f"{n}_bh", f"{n}_scale",
                 f"{n}_corner_radius", f"{n}_corner_radius_screen", f"{n}_opacity"]
        # corner_radius_screen is what shows: radius x scale, capped at half
        # the short side (a larger radius just means fully round).
    rows, touch = [], ("", "", "")
    for fr, cur in walk(frames, series, watched):
        touch = touch_columns(fr, touch)
        row, boxes = [], []
        for i in els:
            s = cur[i]
            if s is None or s["r"][2] <= 0.01:
                row += [""] * 10
                continue
            # What the shape really shows: its own and every ancestor's
            # opacity, and nothing at all if any of them is hidden.
            op = 1.0
            for a in [i] + chains[i]:
                sa = cur.get(a)
                if sa is None:
                    continue
                if sa.get("h"):
                    op = 0.0
                    break
                op *= sa.get("o", 1)
            x, y, w, h = s["r"]
            sx, sy = scale(s)
            k = math.sqrt(abs(sx * sy))
            cr = radii_of(s) if info[i]["c"] != "SwiftUI.SDFLayer" else None
            if op > 0.01:
                boxes.append((x, y, x + w, y + h))
            row += [round(x + w / 2, 2), round(y + h / 2, 2), w, h, s["b"][0], s["b"][1],
                    round(k, 4), "" if cr is None else round(cr, 2),
                    "" if cr is None else round(min(cr * k, min(w, h) / 2), 2), round(op, 3)]
        if boxes:
            ux0, uy0 = min(b[0] for b in boxes), min(b[1] for b in boxes)
            ux1, uy1 = max(b[2] for b in boxes), max(b[3] for b in boxes)
            union = [round(ux0, 2), round(uy0, 2), round(ux1 - ux0, 2), round(uy1 - uy0, 2)]
        else:
            union = [""] * 4
        rows.append([round((fr["t"] - t0) * 1000, 1), *touch, *union, *row])
        if touch[0].endswith(("ended", "cancelled")):
            touch = ("", "", "")
    return head, rows, {names[i]: info[i]["v"] for i in els}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("run")
    ap.add_argument("case")
    ap.add_argument("--out", default="")
    args = ap.parse_args()

    header, frames, marks = load(args.run, args.case)
    info, series = replay(frames)
    # Time zero is the frame that delivered the touch-down: UIKit reacts on
    # delivery, and the test runner sometimes queues events (a tap's down
    # and up can land together, up to a second after their timestamps).
    # Touches before the "start" mark are the warm-up.
    start_wall = dict(marks).get("start", 0)
    # A scene that drives itself (no touches) marks the frame its
    # animation starts.
    t0 = next((f["t"] for f in frames if f.get("touch") and f["wall"] >= start_wall), None)
    if t0 is None:
        t0 = next(f["t"] for f in frames if f.get("mark"))
    frames = [f for f in frames if f["t"] >= t0 - 0.1]
    if args.case.startswith("tab_"):
        head, rows = tab_rows(frames, info, series, t0)
    else:
        head, rows, names = morph_rows(frames, info, series, t0)
        for n, v in names.items():
            print(f"{n}: {re.sub(r'_TtC.*P33_[0-9A-F]+', '', v)}", file=sys.stderr)

    # Drop the still tail: stop 300 ms after the last change.
    last = 0
    for k in range(1, len(rows)):
        if rows[k][4:] != rows[k - 1][4:]:
            last = k
    end_t = rows[last][0] + 300 if rows else 0
    rows = [r for r in rows if r[0] <= end_t]

    out = open(args.out, "w", newline="") if args.out else sys.stdout
    w = csv.writer(out)
    w.writerow(head)
    w.writerows(rows)
    if args.out:
        out.close()
        print(f"{args.case}: {len(rows)} frames -> {args.out}", file=sys.stderr)


if __name__ == "__main__":
    main()
