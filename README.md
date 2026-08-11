# W.A.R.P.I.

W.A.R.P.I. is the Wireless Assessment and Reconnaissance Platform: a portable Raspberry Pi based field system for authorized wireless assessment, field telemetry, local status display, and VaughnLab/K.E.R.N.E.L. integration.

The current priority is reliability before new features. WARPi should boot predictably, report its state clearly, stay recoverable, and expose a small approved command surface to K.E.R.N.E.L. before adding more advanced wireless automation.

## Current Status

Baseline date: 2026-08-09

- Platform: Raspberry Pi 4 Model B
- OS: Debian 13
- Role: portable cybersecurity field platform
- Current mode: normal/trusted-client operation
- Remote access: standard OpenSSH over approved private management path
- K.E.R.N.E.L. access: dedicated automation identity with approved wrappers
- Live state source: `/run/warpi/state.json`
- Primary service: `warpi-kernel.service`
- Field UI: `warpi-ui.service`

## Start Here

- [Operating model](docs/operating-model.md)
- [Architecture](docs/architecture.md)
- [Baseline: 2026-08-09](docs/baseline-2026-08-09.md)
- [Mode-control investigation](docs/mode-control-investigation.md)
- [Mode transition design](docs/mode-transition-design.md)
- [Security model](docs/security.md)
- [Backlog](docs/backlog.md)
- [Changelog](docs/changelog.md)

## Safety

Wireless testing is limited to systems and networks explicitly authorized for VaughnLab testing. Do not commit secrets, private keys, API tokens, OAuth material, Tailscale auth material, sensitive captures, or generated private evidence.

## Current Rule

Make WARPi boring and reliable first. Then make it ridiculous.
