# Mode-Control Investigation

Status: investigated read-only on 2026-08-09.

## Finding

The missing legacy mode scripts should not be blindly restored.

The old paths appear stale, but they are not fully disconnected from the current implementation.

## Current Owner

Current mode/state reporting is owned by:

- `warpi-kernel.service`
- `/opt/warpi/kernel.py`
- `/opt/warpi/modules/network.py`
- `/run/warpi/state.json`
- `warpi-status`
- TFT display state/detail files

`warpi-startup` owns boot readiness and explicitly prevents Field Mode from taking over automatically at boot.

## Remaining Legacy Dependencies

`/opt/warpi/kernel.py` still defaults to external transition scripts:

- `FIELD_MODE_SCRIPT` -> `<legacy-user-home>/scripts/fieldmode`
- `NORMAL_MODE_SCRIPT` -> `<legacy-user-home>/scripts/normalmode`

`enter_field_mode()` and `return_to_normal_mode()` still call those external scripts. If a transition is required while those paths are missing, the transition should fail rather than silently work.

Other historical or intentionally gated references:

- `/usr/local/bin/fieldmode` is a shim to the missing legacy path.
- local WARPi system overview documents the old commands and logs.

## Recommendation

Do not recreate the old scripts as-is.

Preferred future direction:

- continue the maintained mode-control surface through `warpi mode status`, `warpi mode enter-field`, and `warpi mode return-normal`
- move script references away from user-home paths
- design the real `kernel.py` apply workflow deliberately instead of pointing apply logic at dry-run planners
- document the approved command surface before enabling automated transitions

## Current Command Surface

As of 2026-08-11, `warpi mode enter-field` and `warpi mode return-normal` are dry-run planners only. They are intended to describe the transition and recovery expectations without changing live networking, services, routes, radios, marker files, or NetworkManager profiles. Apply mode remains gated until the real workflow and rollback path are approved.

The dispatcher source is now tracked in the WARPi repository at `bin/warpi`; the live `/usr/local/bin/warpi` file is the deployed artifact. Future dispatcher changes should be made against `bin/warpi`, validated, then deployed intentionally.

Active reporting and audit references were migrated on 2026-08-11:

- `bin/kernel-report` reports `/usr/local/bin/warpi` as the dispatcher, `warpi mode enter-field` and `warpi mode return-normal` as dry-run planners, and apply workflow status as `gated`.
- `bin/kernel-doc-audit` validates the maintained dispatcher and no longer treats missing legacy user-home mode scripts as current requirements.
- `/opt/warpi/kernel.py` still defaults to the legacy external transition script hooks for real mode changes. That remains intentionally fail-closed until the real apply workflow is designed and approved; pointing those hooks at dry-run planners would create false-positive transitions.
