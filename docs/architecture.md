# Architecture

WARPi combines local field hardware, local status automation, and private VaughnLab integration.

## Core Components

- Raspberry Pi 4: field compute platform.
- Debian: base operating system.
- NetworkManager: Wi-Fi and field profile control.
- Tailscale: private remote management path.
- OpenSSH: standard remote administration path.
- WARPi K.E.R.N.E.L.: local state engine and mode decision service.
- TFT UI: local field status display.
- GPSD: GPS receiver integration.
- Bettercap/Kismet tooling: local wireless/security tooling, gated by approved workflows.
- Mission Control: VaughnLab backend role for health and future mission data.
- K.E.R.N.E.L./OpenClaw: remote orchestration through constrained commands.

## Live State

The canonical runtime state is `/run/warpi/state.json`, written by `warpi-kernel.service`.

User-facing status is provided by:

- `warpi help`
- `warpi status`
- `warpi mode status`
- `warpi mode enter-field` dry-run plan
- `warpi mode return-normal` dry-run plan
- `warpi-status`
- `kernel-report --json`
- TFT display state/detail files

The maintained dispatcher source is tracked at `bin/warpi`. The live deployed artifact is `/usr/local/bin/warpi` on WARPi and should be updated from the tracked source after validation, not edited as an undocumented source of truth. Reporting and audit tool sources are tracked at `bin/kernel-report` and `bin/kernel-doc-audit`, with live deployed artifacts at `/usr/local/bin/kernel-report` and `/usr/local/bin/kernel-doc-audit`.

The canonical documentation source is the tracked repository `docs/` tree. The live `/opt/warpi/docs` directory is a deployed copy for on-device visibility and audit. It is populated with `bin/warpi-docs-sync`, which writes `.warpi-docs-manifest.sha256`; `kernel-doc-audit` validates that manifest to detect live documentation drift. See [live documentation](live-documentation.md).

## Mode Model

WARPi currently has two intended operating modes:

- `NORMAL`: trusted network client mode.
- `FIELD`: portable field assessment mode.

Current mode reporting is implemented by `warpi-kernel.service`, supporting modules, and the `warpi mode status` command. `kernel-report` and `kernel-doc-audit` report the maintained dispatcher and dry-run planners as the current mode-control surface. `warpi mode enter-field` and `warpi mode return-normal` currently render dry-run transition plans only; they do not change files, services, routes, radios, or NetworkManager profiles. Real mode transition implementation remains gated because the apply workflow and rollback path are not approved yet. `warpi mode enter-field --apply` and `warpi mode return-normal --apply` are not enabled yet.

See [mode-control investigation](mode-control-investigation.md).

## Diagram

```mermaid
flowchart TD
    Human[Dustin / operator] --> WebShell[Local webshell or console]
    Kernel[K.E.R.N.E.L. / OpenClaw] --> SSH[OpenSSH to dedicated automation identity]
    SSH --> WARPi[WARPi Raspberry Pi]
    WebShell --> WARPi

    WARPi --> State[/run/warpi/state.json]
    WARPi --> UI[TFT status UI]
    WARPi --> GPS[GPSD / u-blox GPS]
    WARPi --> WiFi[Wireless adapters]
    WARPi --> Tools[Bettercap / Kismet / approved tools]
    WARPi --> Mission[Mission Control health endpoint]

    State --> Reports[kernel-report / warpi-status]
    Reports --> Kernel

    Nano[Optional WiFi Pineapple NANO] -. future optional wireless backend .-> WARPi
```
