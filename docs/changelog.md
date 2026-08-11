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
