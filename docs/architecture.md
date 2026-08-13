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
- `warpi mode transition-status`
- `warpi mode preflight enter-field`
- `warpi mode preflight return-normal`
- `warpi mode rollback-plan`
- `warpi mode simulate enter-field`
- `warpi mode simulate return-normal`
- `warpi mode simulate-status`
- `warpi mission status`
- `warpi mission check-in`
- `warpi mode enter-field` dry-run plan
- `warpi mode return-normal` dry-run plan
- `warpi wireless status` read-only sidecar reachability
- `warpi-status`
- `kernel-report --json`
- TFT display state/detail files

The maintained dispatcher source is tracked at `bin/warpi`. The live deployed artifact is `/usr/local/bin/warpi` on WARPi and should be updated from the tracked source after validation, not edited as an undocumented source of truth. Reporting and audit tool sources are tracked at `bin/kernel-report` and `bin/kernel-doc-audit`, with live deployed artifacts at `/usr/local/bin/kernel-report` and `/usr/local/bin/kernel-doc-audit`.

The canonical documentation source is the tracked repository `docs/` tree. The live `/opt/warpi/docs` directory is a deployed copy for on-device visibility and audit. It is populated with `bin/warpi-docs-sync`, which writes `.warpi-docs-manifest.sha256`; `kernel-doc-audit` validates that manifest to detect live documentation drift. See [live documentation](live-documentation.md).

## Mode Model

WARPi currently has two intended operating modes:

- `NORMAL`: trusted network client mode.
- `FIELD`: portable field assessment mode.

Current mode reporting is implemented by `warpi-kernel.service`, supporting modules, and the `warpi mode status` command. `kernel-report` and `kernel-doc-audit` report the maintained dispatcher and dry-run planners as the current mode-control surface. `warpi mode transition-status` reports the transition framework: state-machine status, active transaction detection, lock path/status, transaction metadata paths, rollback metadata presence, latest preflight status, rollback-plan status, simulation-executor status, validation status, and the apply gate. `warpi mode preflight enter-field` and `warpi mode preflight return-normal` create a transaction ID, acquire the transition lock, validate live prerequisites, capture a rollback snapshot, release the lock, and return active transition state to `IDLE` without changing networking or mode. `warpi mode rollback-plan` verifies a saved rollback snapshot, compares it to current read-only state, and generates an ordered preview of recovery actions marked `NOT EXECUTED`. `warpi mode simulate enter-field` and `warpi mode simulate return-normal` execute only simulated action adapters, persist checkpoints, inject controlled failures, and simulate rollback decisions without changing live state. `warpi mode executor-status`, `warpi mode recovery-status`, `warpi mode watchdog-status`, and `warpi mode adapters` expose the Milestone E hard gate, arming framework, external-radio prerequisite, management watchdog, boot/interruption recovery decision, and adapter inventory without mutating live state. `warpi mission status` reports the configured Mission Control endpoints, reachability, health summary, authentication presence, device identity, and last check-in metadata. `warpi mission check-in` sends a bounded heartbeat payload when Mission Control is reachable and records success/failure locally; Mission Control failure never blocks local WARPi operation. `warpi mode enter-field` and `warpi mode return-normal` currently render dry-run transition plans only; they do not change files, services, routes, radios, or NetworkManager profiles. Real mode transition implementation remains gated because live executor enablement, transaction-bound operator authorization, external Wi-Fi hardware, staged live tests, and final recovery validation are not approved yet. `warpi mode enter-field --apply` and `warpi mode return-normal --apply` are not enabled yet.

See [mode-control investigation](mode-control-investigation.md).

Future real mode switching must follow the reversible transaction design in [mode transition design](mode-transition-design.md). That design keeps remote management survivability as a primary safety property and requires state-machine, rollback, boot recovery, observability, and staged tests before apply mode can be enabled.

## Transition Control Plane

Milestone A provides a read-only transition control plane behind `warpi mode`. The state model recognizes `IDLE`, `PREPARING`, `VALIDATING`, `READY`, `APPLYING`, `VERIFYING`, `COMPLETED`, `ROLLING_BACK`, `ROLLED_BACK`, and `FAILED`. Directions are represented as `NORMAL_TO_FIELD` or `FIELD_TO_NORMAL`.

Runtime transition metadata is expected under `/run/warpi`:

- `/run/warpi/mode-transition.lock`
- `/run/warpi/mode-transition-state.json`
- `/run/warpi/mode-transition-current.json`

Persistent recovery metadata is expected under `/var/lib/warpi/mode-transitions`, with pending transition metadata at `/var/lib/warpi/mode-transitions/pending-transition.json`.

`warpi mode transition-status` treats missing active metadata as a clean inactive/IDLE state, but malformed JSON, symlinked metadata paths, unknown states, contradictory source/target directions, existing locks, or interrupted transaction metadata are surfaced clearly and block future apply eligibility. Dry-run planners use this framework for visibility but do not create or clear transition metadata.

Milestone B preflight snapshots live under `/var/lib/warpi/mode-transitions/<transition-id>/rollback-snapshot.json`, with transaction metadata at `/var/lib/warpi/mode-transitions/<transition-id>/transaction.json` and a latest-summary pointer at `/var/lib/warpi/mode-transitions/last-preflight.json`. Snapshot schema version 1 captures safe rollback inputs for WARPi state, NetworkManager-visible connection/profile state, interface addresses, default route, relevant route table data, DNS status, Tailscale service/backend/IP, firewall implementation and safe table reference, critical service states, NANO sidecar reachability, system identity, validation findings, and explicit secret-exclusion metadata. Snapshots intentionally exclude Wi-Fi PSKs, Tailscale auth keys, API tokens, private keys, Pineapple credentials, and environment secrets.

Preflight validation findings are classified as `PASS`, `WARN`, or `BLOCK`. A completed preflight is not approval to apply; it only proves that WARPi can capture and validate a recovery point. Future freshness checks must compare live mode, active Wi-Fi profile, IP/default route, interface inventory, boot/runtime identity, and transition metadata before reusing a saved snapshot.

Milestone C rollback plans live under `/var/lib/warpi/mode-transitions/<transition-id>/rollback-plan.json`. Plan schema version 1 records the selected snapshot path and SHA-256, verifier result, verifier findings, drift analysis, ordered recovery actions, action count, readiness state, and the apply gate. Recovery actions are preview records only; they include phase, component, current state, desired state, proposed action, risk level, connectivity impact, required verification, and command preview text labeled `NOT EXECUTED`.

The rollback verifier checks snapshot schema, transaction ID format, transaction metadata correlation, source/target/direction coherence, hostname, completion marker, required recovery fields, ownership/permissions, symlink safety, and common credential-like patterns. Verifier results are `PASS`, `WARN`, or `BLOCK`; any `BLOCK` prevents the planner from claiming recovery readiness. Drift is classified as `UNCHANGED` or `RESTORE_REQUIRED` in Milestone C, with room for later `EXPECTED_DRIFT`, `WARNING`, and `BLOCKER` classifications as the executor design matures.

Recovery ordering preserves management access first: validate data, confirm the target uplink, restore addressing/routes only after the uplink is known, verify Tailscale, restore firewall state, preserve sidecar isolation, restore service state, restore WARPi mode/control metadata, then perform final health verification. Plan generation does not execute commands and does not authorize future apply.

Milestone D executor simulations live under `/var/lib/warpi/mode-transitions/<simulation-id>/`. The live executor backend is hard-coded as disabled; the only usable backend is `simulation`. Simulation history is written to `simulation.json`, latest simulation status is copied to `/var/lib/warpi/mode-transitions/last-simulation.json`, and per-phase checkpoint state is written atomically to `executor-checkpoint.json`. `warpi mode simulate-status` reports the latest simulation, while `warpi mode transition-status` summarizes backend, live-enabled state, last simulation ID/result/checkpoint, rollback requirement, rollback result, blockers, and warnings.

Simulation phases model the future prepare/verify/commit executor without applying anything: validate recovery data, prepare interface/profile, prepare route/firewall/service/mode metadata changes, verify management path, preserve sidecar isolation, verify target health, then commit. Failure injection through `--fail-at` records controlled failures and uses an explicit decision model: failures before mutation-equivalent phases do not require rollback, while failures after routing/firewall/service/mode/commit-equivalent phases require simulated rollback from the Milestone C recovery plan. `--rollback-fail-at` models rollback failure and requires manual recovery escalation.

Management safety invariants remain active in simulation: rollback metadata must validate before simulated execution, Tailscale management path must be represented, sidecar routing must not be the default path, mode metadata cannot be committed before target health verification, and the external Wi-Fi dependency is reported honestly. If no extra Wi-Fi adapter is enumerated beyond `wlan0`, NORMAL -> FIELD simulation can proceed only as executor logic validation with a `REAL HARDWARE PREREQUISITE MISSING` warning; it is not real FIELD readiness.

Milestone E adds adapter-backed real-executor architecture while keeping every live execute path hard-disabled. The adapter inventory includes validation, rollback capture, assessment-radio preparation, routing, firewall, management verification, service configuration, field health, mode commit, rollback network/routing/firewall/service/mode restoration, and final health adapters. Each adapter has a stable ID, ordered position, mutating flag, preconditions, postconditions, rollback adapter, and the conceptual interface `validate`, `preview`, `execute`, `verify`, `rollback`, and `describe`. Mutating adapters report `execute_gate=disabled`.

`warpi mode executor-status` evaluates the disabled live gate. Future live execution must require a live feature flag, transaction-bound operator authorization, fresh valid preflight, valid rollback snapshot, rollback verifier PASS, no lock conflict, legal source/target mode, external Wi-Fi positively validated for NORMAL -> FIELD, management watchdog HEALTHY, Tailscale healthy, NANO not default route, checkpoint storage, and boot recovery health. In Milestone E the gate is intentionally non-callable.

The arming model is represented by `/run/warpi/mode-executor.arm`, but no command creates a live arm file. A future arm must be root-controlled, transaction-specific, expiring, non-reusable, visible without exposing secret material, and cleared by boot. Any existing arm state is ignored while the live executor feature flag is disabled.

`warpi mode watchdog-status` classifies the management path as `HEALTHY`, `DEGRADED`, or `LOST` using Tailscale backend/IP, route to a management peer, local default route, active uplink, NANO default-route safety, and Mission Control as informational only. The default future LOST threshold is three consecutive failures; DEGRADED should pause/re-evaluate, while persistent LOST marks rollback required.

`warpi mode recovery-status` classifies boot/interruption state as `SAFE_IDLE`, `RESUME_NOT_ALLOWED`, `ROLLBACK_REQUIRED`, or `MANUAL_INTERVENTION_REQUIRED`. It refuses blind forward resume after interruption, treats corrupt or contradictory checkpoint state as manual intervention, and never requires Mission Control for local recovery.

Mission Control observes WARPi health, telemetry, mode safety state, and future mission coordination over Tailscale. WARPi probes `mission01` health endpoints such as `http://mission01:8000/health` and `http://100.71.99.18:8000/health`, then posts authenticated heartbeat payloads to `/api/warpi/check-in`. The WARPi-side check-in payload includes device ID, timestamp, hostname, mode/state, Tailscale state, active interface/profile, transition state, last preflight/rollback readiness, executor backend/live-enabled state, sidecar identity, GPS state, and critical service status. Mission Control failure is bounded and local WARPi operation continues.

As of the Mission Control server-side repair on 2026-08-13, `mission01` is a Debian 13 VM reachable over Tailscale at `100.71.99.18`. Mission Control is deployed under `/srv/mission-control` with Docker Compose services:

- `mission-api`: FastAPI/Uvicorn, bound privately to `100.71.99.18:8000`.
- `mission-postgres`: PostgreSQL 17 on the private Docker network only.
- `mission-redis`: Redis 8 on the private Docker network only.

The API exposes unauthenticated `/health` for dependency status and authenticated WARPi check-in/device endpoints. Bearer authentication uses a server-side secret mounted from `/srv/mission-control/secrets/warpi_api_token` and a WARPi client token at `/etc/warpi/mission-control.token`; secret values must never be printed or committed. PostgreSQL state persists under `/srv/mission-control/postgres`, Redis append-only data under `/srv/mission-control/redis`, and secrets under `/srv/mission-control/secrets`. Mission Control source/config is tracked separately in the private `dustinvaughn91/WARPi-Mission-Control` repository; `/srv/mission-control` remains the live deployment path and must exclude runtime data, secrets, database files, dumps, logs, artifacts, and backups from Git.

The previous TCP/8000 refusal was caused by `mission-api` crash-looping during startup while attempting to resolve/connect to the `postgres` service. PostgreSQL and Redis were healthy; an API-only Docker Compose recreate/rebuild restored Docker network membership and health without touching persistent volumes. The repaired API initializes `devices`, `warpi_device_state`, and `warpi_heartbeats` non-destructively, upserts by stable WARPi device identity, records heartbeat history, and rejects unauthenticated, malformed, missing-field, and invalid-device requests.

Read-only PVE-side inspection identified `mission01` as protected VM `110` on `pve01` with guest agent enabled, 2 vCPU, 8 GiB RAM, a 64 GiB `local-lvm` disk, and a single `vmbr1` virtio NIC. On 2026-08-13, `onboot=1` was enabled without rebooting the VM. A VM-110-only scheduled backup job `mission01-weekly` was added with snapshot mode, zstd compression, local storage, schedule `sat 03:30`, and retention `keep-last=3,keep-weekly=4,keep-monthly=3`; no immediate backup was run. Mission Control also has an application-aware PostgreSQL backup helper at `/srv/mission-control/scripts/mission-control-pg-backup`, tracked in the Mission Control repo, which writes custom-format dumps under `/srv/mission-control/backups/postgres` and validates them with `pg_restore --list`. No Mission Control outage should be allowed to become a WARPi operating dependency.

## Wireless Sidecar Model

The WiFi Pineapple NANO is treated as an optional sidecar, not a default route or required dependency. `warpi wireless status` performs read-only checks for the sidecar interface, NANO management address, management UI TCP reachability, and default-route safety. It does not start scans, change radios, alter routes, or modify NANO configuration.

## Diagram

```mermaid
flowchart TD
    Human[Dustin / operator] --> WebShell[Local webshell or console]
    Kernel[K.E.R.N.E.L. / OpenClaw] --> SSH[OpenSSH to dedicated automation identity]
    SSH --> WARPi[WARPi Raspberry Pi]
    WebShell --> WARPi

    WARPi --> State[/run/warpi/state.json]
    WARPi --> Txn[/run/warpi mode transition metadata]
    WARPi --> UI[TFT status UI]
    WARPi --> GPS[GPSD / u-blox GPS]
    WARPi --> WiFi[Wireless adapters]
    WARPi --> Tools[Bettercap / Kismet / approved tools]
    WARPi --> Mission[Mission Control health endpoint]

    State --> Reports[kernel-report / warpi-status]
    Reports --> Kernel

    Nano[Optional WiFi Pineapple NANO] -. read-only sidecar status / future backend .-> WARPi
```
