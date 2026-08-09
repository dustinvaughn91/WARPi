# Backlog

## P0

- Accept Day 1 baseline as starting point.
- Define backup/checkpoint method before modifying WARPi.
- Resolve mode-control drift without blindly restoring legacy scripts.
- Validate Mission Control reachability from WARPi, OpenClaw, and `mission01`.
- Update documentation after live truths are confirmed.

## P1

- Define the K.E.R.N.E.L./WARPi command contract.
- Add structured `warpi` command surface if not already present.
- Validate field readiness: cold boot, trusted network, offline behavior, Tailscale reconnect, display status, logs/storage.
- Review Bettercap service restart warning.
- Review netplan permission warning.

## P2

- Design optional WiFi Pineapple NANO backend.
- Detect NANO attachment safely.
- Query NANO status without active wireless behavior.
- Prototype passive authorized survey workflow.

## Stretch

- Generic wireless backend abstraction.
- Mission job/telemetry workflows.
- Improved TFT field UX.

