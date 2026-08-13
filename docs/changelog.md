# Changelog

## 2026-08-09

- Created private WARPi GitHub repository.
- Added initial documentation structure.
- Recorded read-only Day 1 baseline.
- Documented stale mode-script investigation and recommended future mode-control direction.

## 2026-08-10

- Accepted the Day 1 baseline and captured a private checkpoint backup in VaughnLab evidence storage.
- Added live `kernel` administrative validation identity on WARPi with key-based SSH, locked password, and passwordless sudo.
- Preserved `kernel-agent` as the constrained read/status identity for future bounded command-surface work.
- Configured the WiFi Pineapple NANO connection as a sidecar network so WARPi keeps trusted Wi-Fi as its default route.
- Hardened OpenSSH to key-only access with root SSH disabled, while validating fresh `kernel` admin and `kernel-agent` status connections after reload.
- Added the initial `warpi` command dispatcher with an updated help menu and read-only `warpi mode status`; mode switching commands remain intentionally disabled pending transition redesign.
- Added dry-run `warpi mode enter-field` planning output that reports current state, Field profile settings, proposed apply sequence, rollback expectation, and next enablement gate without changing live networking or mode state.

## 2026-08-11

- Added and validated dry-run `warpi mode return-normal` planning output alongside the existing Field Mode planner; apply mode remains disabled.
- Added `bin/warpi` as the canonical tracked source for the deployed `/usr/local/bin/warpi` dispatcher and validated the live deployment without performing a real mode transition.
- Added `bin/kernel-report` and `bin/kernel-doc-audit` as tracked sources for the deployed reporting tools.
- Migrated active reporting and audit expectations away from obsolete user-home `fieldmode` / `normalmode` scripts to the maintained `warpi mode` dispatcher surface.
- Validated that `kernel-report` reports the dispatcher, both dry-run planners, and the gated apply workflow; validated that `kernel-doc-audit` no longer treats missing legacy user-home scripts as current requirements.
- Documented the live documentation source-of-truth model, added `bin/warpi-docs-sync`, and taught `kernel-doc-audit` to validate the deployed documentation manifest under `/opt/warpi/docs`.
- Added the reversible mode-transition design for future real `enter-field --apply` and `return-normal --apply` work. Apply mode remains disabled.

## 2026-08-13

- Added `warpi wireless status` as a read-only WiFi Pineapple NANO sidecar reachability check. The command reports interface state, sidecar route, ping reachability, management UI TCP reachability, default-route safety, and confirms wireless actions remain disabled.
- Added Milestone A mode-transition control-plane status through `warpi mode transition-status`, including human-readable and JSON output for transition state, active transaction detection, direction, lock status, transaction metadata paths, rollback metadata, validation status, and the current apply gate.
- Integrated the transition framework summary into the existing `warpi mode enter-field` and `warpi mode return-normal` dry-run planners without creating live transition metadata or enabling `--apply`.
- Added Milestone B non-mutating preflight commands: `warpi mode preflight enter-field` and `warpi mode preflight return-normal`. Preflight creates a transaction ID, acquires the transition lock, validates live prerequisites, captures a versioned rollback snapshot under `/var/lib/warpi/mode-transitions/<transition-id>/`, writes transaction metadata, releases the lock, and returns active transition state to `IDLE` without changing networking or mode.
- Extended `warpi mode transition-status` to report latest preflight transaction ID, direction, result, blocker/warning counts, snapshot path, snapshot validity, completion timestamp, and staleness marker.
- Added Milestone C non-mutating rollback planning through `warpi mode rollback-plan`, including snapshot verification, current-state comparison, deterministic drift analysis, preview-only recovery actions marked `NOT EXECUTED`, JSON output, persisted plan metadata, and transition-status integration.
- Documented the Milestone C read-only external Wi-Fi adapter finding: the expected adapter was not enumerated as a USB device or wireless netdev during live inspection, while `wlan0` and the ASIX sidecar Ethernet remained visible.
- Added Milestone D simulation-only staged executor commands: `warpi mode simulate enter-field`, `warpi mode simulate return-normal`, and `warpi mode simulate-status`. Simulations consume verified preflight/snapshot/rollback-plan artifacts, persist per-phase checkpoints, support controlled failure injection, decide whether rollback is required, simulate rollback from the Milestone C recovery plan, and keep live execution disabled.
- Extended `warpi mode transition-status` with simulation executor status, including backend, live-enabled gate, latest simulation ID/result/checkpoint, rollback requirement/result, blockers, and warnings.
