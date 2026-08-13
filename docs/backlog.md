# Backlog

## P0

- Accept Day 1 baseline as starting point.
- Define backup/checkpoint method before modifying WARPi.
- Resolve mode-control drift without blindly restoring legacy scripts.
- Keep Mission Control health/check-in regression tests in the regular WARPi validation path.
- Update documentation after live truths are confirmed.

## P1

- Define the K.E.R.N.E.L./WARPi command contract.
- Keep `warpi mode enter-field` and `warpi mode return-normal` in dry-run planner mode until the apply workflow and recovery path are explicitly approved.
- Perform an isolated Mission Control restore drill from a scheduled VM backup and application-aware PostgreSQL dump before treating Mission Control as fully production-recoverable.
- Build staged real action adapters behind an explicit hard manual safety gate, still default-disabled, before any real mode apply path is approved.
- Implement the reversible mode-transition design in staged milestones; Milestone A transition-status, Milestone B preflight rollback-snapshot capture, Milestone C rollback planning, and Milestone D executor simulation are complete, while live apply remains gated.
- Validate field readiness: cold boot, trusted network, offline behavior, Tailscale reconnect, display status, logs/storage.
- Review Bettercap service restart warning.
- Review netplan permission warning.

## P2

- Design optional WiFi Pineapple NANO backend.
- Detect NANO attachment safely through `warpi wireless status`.
- Query NANO status without active wireless behavior.
- Prototype passive authorized survey workflow.
- Physically reseat or replace the expected external USB Wi-Fi adapter on WARPi. Repeated read-only checks showed no second wireless netdev and no separate Wi-Fi USB device enumeration; only the VIA USB hub and ASIX Ethernet sidecar are visible.

## Stretch

- Generic wireless backend abstraction.
- Mission job/telemetry workflows.
- Improved TFT field UX.
