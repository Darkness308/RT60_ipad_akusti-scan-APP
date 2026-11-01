#!/usr/bin/env python3
# index_check.py — validiert governance.json (maschinenlesbarer SSOT-Doku-Index).
# Prueft: jeder referenzierte Pfad existiert; Querverweise zeigen auf echte Node-IDs.
# Kein Drift, keine Behauptung. Nur stdlib. Exit 1 bei Fehlern -> CI-tauglich.
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INDEX = ROOT / "governance.json"


def main() -> int:
    try:
        data = json.loads(INDEX.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print("FEHLER: governance.json nicht gefunden")
        return 1
    except json.JSONDecodeError as e:
        print(f"FEHLER: governance.json ist kein gueltiges JSON: {e}")
        return 1

    problems = []
    nodes = data.get("nodes", [])
    ids = {n.get("id") for n in nodes}
    checked = 0

    for n in nodes:
        for key in ("path", "validator"):
            rel = n.get(key)
            if not rel:
                continue
            checked += 1
            if not (ROOT / rel).exists():
                problems.append(f"node '{n.get('id','?')}': {key} fehlt auf Platte: {rel}")

    for m in data.get("milestones", []):
        ref = m.get("defined_by")
        if ref and ref not in ids:
            problems.append(f"milestone '{m.get('id','?')}': defined_by unbekannt: {ref}")

    for layer in data.get("layers", []):
        ref = layer.get("evidence")
        if ref and ref not in ids:
            problems.append(f"layer '{layer.get('id','?')}': evidence unbekannt: {ref}")

    known = ids | {m.get("id") for m in data.get("milestones", [])} \
                | {b.get("id") for b in data.get("bottlenecks", [])} \
                | {layer.get("id") for layer in data.get("layers", [])}
    for e in data.get("edges", []):
        for side in ("from", "to"):
            ref = e.get(side)
            if ref and ref not in known:
                problems.append(f"edge {e.get('from')}->{e.get('to')}: '{side}' unbekannt: {ref}")

    for b in data.get("bottlenecks", []):
        ref = b.get("ref")
        if ref and ref not in known:
            problems.append(f"bottleneck '{b.get('id','?')}': ref unbekannt: {ref}")

    print(f"governance.json: {len(nodes)} Nodes, {checked} Pfade geprueft, {len(problems)} Problem(e).")
    for p in problems:
        print(f"  ! {p}")
    if not problems:
        print("  OK — Index konsistent, keine toten Verweise.")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
