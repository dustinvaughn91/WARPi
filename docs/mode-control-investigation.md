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

- `FIELD_MODE_SCRIPT` -> `/home/anangrybull/scripts/fieldmode`
- `NORMAL_MODE_SCRIPT` -> `/home/anangrybull/scripts/normalmode`

`enter_field_mode()` and `return_to_normal_mode()` still call those external scripts. If a transition is required while those paths are missing, the transition should fail rather than silently work.

Other remaining references:

- `/usr/local/bin/fieldmode` is a shim to the missing legacy path.
- `kernel-report` tracks the old paths.
- `kernel-doc-audit` audits the old paths.
- local WARPi system overview documents the old commands and logs.

## Recommendation

Do not recreate the old scripts as-is.

Preferred future direction:

- create a maintained mode-control surface such as `warpi mode status`, `warpi mode enter-field`, and `warpi mode return-normal`
- move script references away from user-home paths
- update `kernel.py`, `kernel-report`, and `kernel-doc-audit` to track the new truth
- document the approved command surface before enabling automated transitions

