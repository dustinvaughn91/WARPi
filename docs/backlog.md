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
- Build staged real action adapters behind an explicit hard manual safety gate, still default-disabled, before any real mode apply path is approved. Milestone E/F control-plane readiness is complete; first live transition testing still requires explicit future approval.
- Implement the reversible mode-transition design in staged milestones; Milestone A transition-status, Milestone B preflight rollback-snapshot capture, Milestone C rollback planning, Milestone D executor simulation, and Milestone E disabled live-gate/watchdog/recovery architecture are complete, while live apply remains gated.
- Validate field readiness: cold boot, trusted network, offline behavior, Tailscale reconnect, display status, logs/storage.
- Review Bettercap service restart warning.
- Review netplan permission warning.

## P2

- Design optional WiFi Pineapple NANO backend.
- Detect NANO attachment safely through `warpi wireless status`.
- Query NANO status without active wireless behavior.
- Prototype passive authorized survey workflow.
- Keep the Panda assessment radio validation in the regular readiness checklist: approved USB `0e8d:7612`, driver `mt76x2u`, MAC `9c:ef:d5:f8:98:83`, distinct `phy1`/`wlan1`, disconnected/idle, not default route, not management uplink.
- Restore and revalidate NANO/ASIX sidecar stability before scheduling the first controlled live NORMAL -> FIELD test. Final Milestone F closeout saw ASIX re-enumeration, `eth1` without expected IPv4 sidecar address, route to `172.16.42.1` falling back to `wlan0`, and NANO ping/UI unreachable.
- Schedule the first controlled live NORMAL -> FIELD test in a fresh approved session only after Panda, NANO, Mission Control, watchdog, preflight, rollback, and recovery checks are all clean. Do not enable live executor or arm a transaction as routine development work.

## Stretch

- Generic wireless backend abstraction.
- Mission job/telemetry workflows.
- Improved TFT field UX.
