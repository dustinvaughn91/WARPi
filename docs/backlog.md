# Backlog

## P0

- Accept Day 1 baseline as starting point.
- Define backup/checkpoint method before modifying WARPi.
- Resolve mode-control drift without blindly restoring legacy scripts.
- Validate Mission Control reachability from WARPi, OpenClaw, and `mission01`.
- Update documentation after live truths are confirmed.

## P1

- Define the K.E.R.N.E.L./WARPi command contract.
- Keep `warpi mode enter-field` and `warpi mode return-normal` in dry-run planner mode until the apply workflow and recovery path are explicitly approved.
- Extend the Milestone A transition control plane into a non-mutating preflight executor that captures rollback snapshots to temporary/test metadata only.
- Implement the reversible mode-transition design in staged milestones; Milestone A state-machine and transaction-status framework is complete, while live apply remains gated.
- Validate field readiness: cold boot, trusted network, offline behavior, Tailscale reconnect, display status, logs/storage.
- Review Bettercap service restart warning.
- Review netplan permission warning.

## P2

- Design optional WiFi Pineapple NANO backend.
- Detect NANO attachment safely through `warpi wireless status`.
- Query NANO status without active wireless behavior.
- Prototype passive authorized survey workflow.

## Stretch

- Generic wireless backend abstraction.
- Mission job/telemetry workflows.
- Improved TFT field UX.
