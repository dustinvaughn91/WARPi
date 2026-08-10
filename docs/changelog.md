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
