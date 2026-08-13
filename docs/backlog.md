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
- Put Mission Control server source/configuration under a canonical Git repository; `/srv/mission-control` is currently a live deployment path, not a Git working tree.
- Enable and document Mission Control VM startup/onboot behavior if desired; 2026-08-13 read-only PVE config did not show an `onboot` flag for VM `110`.
- Create and document Mission Control backup coverage; 2026-08-13 read-only PVE inspection returned no cluster backup jobs and no recent local dump files for VM `110`.
- Define an application-aware PostgreSQL backup/restore procedure for Mission Control device/mission state.
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
- Re-check the external USB Wi-Fi adapter on WARPi. Milestone C read-only inspection showed no second wireless netdev and no separate Wi-Fi USB device enumeration, despite the adapter being physically expected.

## Stretch

- Generic wireless backend abstraction.
- Mission job/telemetry workflows.
- Improved TFT field UX.
