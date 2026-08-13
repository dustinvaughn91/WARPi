# Mode Transition Design

This document designs future real WARPi mode transitions. It does not enable or implement `--apply`.

Current production behavior remains:

- `warpi mode enter-field` prints a dry-run plan only.
- `warpi mode return-normal` prints a dry-run plan only.
- `warpi mode enter-field --apply` exits with refusal.
- `warpi mode return-normal --apply` exits with refusal.

Milestone A is implemented as a read-only state-machine and transaction-status framework with no live mode mutations.

## Current Baseline

Validated baseline for this design:

- Repository branch: `main`
- Baseline commit: `f64566f` (`fix: reconcile WARPi live documentation`)
- Canonical dispatcher source: `bin/warpi`
- Live dispatcher: `/usr/local/bin/warpi`
- Runtime state: `/run/warpi/state.json`
- Live mode before design: `NORMAL`
- Live state before design: `CONNECTED`
- Trusted Wi-Fi profile: `Vaughn Home`
- Tailscale address: `100.120.12.107`
- Default route: `default via 10.0.0.1 dev wlan0 metric 600`
- Sidecar route: `172.16.42.0/24 dev eth1 metric 900`
- `ssh.service`, `tailscaled.service`, `warpi-kernel.service`, and `NetworkManager.service`: active
- `kismet.service`: inactive/disabled in Normal Mode
- Current apply gate: both apply commands refuse with exit `2`

Real mode switching is not approved until this design is implemented, tested, reviewed, and explicitly enabled.

## Transition Scope

### MUST Change

These may be mutated by future apply code.

- `wlan0` NetworkManager active profile when entering or leaving Field Mode.
- `WARPi-Field` activation state.
- Field marker at `/tmp/warpi_fieldmode`.
- Mode transaction files under `/run/warpi`.
- Last-known-good and recovery metadata under `/var/lib/warpi/mode-transitions`.
- Transition logs under `/var/log/warpi/mode-transitions`.
- Field-only firewall table, currently intended as `inet warpi_field`.
- Field-only services such as `kismet.service` when explicitly approved by the workflow.
- WARPi runtime state reporting after each committed state change.

### MAY Change

These may change only when a stage explicitly owns them and validates the result.

- `wlan0` IPv4 address and DNS behavior during field profile activation.
- Field-side DHCP/DNS behavior provided by NetworkManager shared mode.
- IPv4 forwarding when required by the approved Field Mode profile.
- Route metrics associated with `WARPi-Field`.
- Field-side firewall rules for `10.42.0.0/24`.
- Kismet startup or stop state, depending on the final Field Mode service contract.

### MUST NOT Change

These are management and safety boundaries unless a later design explicitly changes them.

- `tailscaled.service` must not be stopped or reconfigured by a mode transition.
- `tailscale0` address and peer reachability must not be intentionally disrupted.
- `ssh.service` must not be stopped.
- The `kernel` administrative SSH path must remain usable.
- Root SSH policy and SSH hardening must not be changed.
- `eth1` Pineapple sidecar route must not become the default route.
- Existing Docker-owned firewall/NAT chains must not be modified by mode transition code.
- Tailscale-owned `ts-*` firewall chains must not be modified by mode transition code.
- Public exposure, router/NAT, household DNS, and external firewall settings are out of scope.
- Mission Control behavior is not required for mode-transition success.

### READ-ONLY Validation

These are observed for health decisions but should not be mutated by transition code.

- `eth0` link state.
- `eth1` sidecar address and route.
- `tailscale0` address.
- `docker0` address and route.
- GPS state.
- Mission Control health.
- Current kernel/doc audit status.
- Current OpenClaw reachability over Tailscale.

## Normal Mode Invariants

Normal Mode means WARPi is a trusted network client with private remote management available.

Required PASS conditions:

- `warpi-kernel.service` is active.
- `/run/warpi/state.json` is valid JSON.
- State reports `mode == "NORMAL"` and a non-error state, preferably `CONNECTED`.
- `wlan0` has a trusted Wi-Fi NetworkManager profile active.
- Active `wlan0` profile is not `WARPi-Field`.
- `/tmp/warpi_fieldmode` is absent.
- `ip -4 addr show dev wlan0` reports a global IPv4 address.
- Default IPv4 route uses `wlan0`.
- Default route does not use `eth1`, `tailscale0`, or `docker0`.
- `tailscaled.service` is active.
- `tailscale status --json` reports the local backend running and a tailnet IPv4 address.
- OpenClaw is reachable with a bounded `tailscale ping`.
- `ssh.service` is active.
- SSH from OpenClaw to `kernel@warpi.tailb46f1.ts.net` succeeds.
- `NetworkManager.service` is active.
- `WARPi-Field` has `connection.autoconnect no`.
- `kismet.service` is inactive unless a later approved design makes it always-on.
- `inet warpi_field` firewall table is absent or inert.

Programmatic tests:

- `jq -e '.mode == "NORMAL"' /run/warpi/state.json`
- `test ! -e /tmp/warpi_fieldmode`
- `nmcli -t -f NAME,TYPE,DEVICE connection show --active`
- `ip route show default`
- `systemctl is-active ssh tailscaled warpi-kernel.service NetworkManager.service`
- `tailscale ping --timeout=5s --c 1 openclaw01`
- OpenClaw-side SSH command using the approved WARPi key.

## Field Mode Invariants

Field Mode means WARPi offers the approved local field access surface while preserving private remote management.

Required PASS conditions:

- `warpi-kernel.service` remains active.
- `/run/warpi/state.json` is valid JSON.
- State reports `mode == "FIELD"` or a clear transitional/degraded state during transition.
- `WARPi-Field` is the active `wlan0` profile.
- `wlan0` is in AP mode through NetworkManager.
- `wlan0` has the field address `10.42.0.1/24`.
- `/tmp/warpi_fieldmode` is present after commit.
- Field-side SSH is reachable from the field subnet.
- Field-side DHCP/DNS behavior is provided only by the approved profile.
- Field firewall rules allow required field access and do not weaken Tailscale or Docker chains.
- `ssh.service` remains active.
- `tailscaled.service` remains active.
- `tailscale0` retains a tailnet address.
- OpenClaw remains reachable over Tailscale or the transition is marked `DEGRADED` and rollback begins.
- `eth1` remains a sidecar network and does not become the default route.
- `kismet.service` is active only if the approved Field Mode service contract requires it.

Expected unavailable or non-required resources:

- Trusted Wi-Fi internet may be unavailable after `wlan0` becomes AP mode.
- Mission Control may remain offline and must not block local field operation.
- Field Mode does not imply active wireless testing, deauth, capture, PineAP, or other offensive behavior.

## Milestone A Transition Status

`warpi mode transition-status` exposes the current transition subsystem state for operators and automation. It reports current WARPi mode, transition state, active transition detection, direction, transaction ID, last attempted/completed transition fields, lock status, metadata paths, rollback metadata presence, validation status, apply blockers, and why live apply remains gated. `warpi mode transition-status --json` emits the same information in a structured form.

Missing transition metadata is treated as clean inactive/IDLE status. Malformed metadata, unsafe symlinked metadata paths, unknown state names, contradictory source/target direction fields, existing locks, pending metadata, or current transaction files are surfaced rather than silently reset.

Milestone A states:

- `IDLE`
- `PREPARING`
- `VALIDATING`
- `READY`
- `APPLYING`
- `VERIFYING`
- `COMPLETED`
- `ROLLING_BACK`
- `ROLLED_BACK`
- `FAILED`

Milestone A transition directions:

- `NORMAL_TO_FIELD`
- `FIELD_TO_NORMAL`

The dry-run planners for `warpi mode enter-field` and `warpi mode return-normal` display transition framework status but do not create, update, or delete transition metadata.

## Milestone B Preflight And Rollback Snapshot

Milestone B adds non-mutating preflight commands:

- `warpi mode preflight enter-field`
- `warpi mode preflight return-normal`

Each preflight creates a unique transaction ID, acquires `/run/warpi/mode-transition.lock`, progresses only through non-mutating states, captures and validates rollback metadata, writes transaction history, releases the lock, and returns active transition status to `IDLE`.

Preflight transaction lifecycle:

1. `PREPARING`: transaction ID created and lock acquired.
2. `VALIDATING`: current state, lock state, mode direction, services, connectivity, storage, and control paths are inspected.
3. `READY`: rollback snapshot capture is allowed because no immediate block prevented metadata capture.
4. `COMPLETED`: transaction metadata and snapshot are written, lock is released, and active transition state returns to `IDLE`.

Preflight never enters `APPLYING`, `VERIFYING`, or `ROLLING_BACK`.

Rollback snapshot storage:

- Transaction directory: `/var/lib/warpi/mode-transitions/<transition-id>/`
- Snapshot: `/var/lib/warpi/mode-transitions/<transition-id>/rollback-snapshot.json`
- Transaction summary: `/var/lib/warpi/mode-transitions/<transition-id>/transaction.json`
- Latest preflight pointer: `/var/lib/warpi/mode-transitions/last-preflight.json`

Snapshot schema version 1 includes:

- `schema_version`, `transition_id`, `captured_at`, `source_mode`, `target_mode`, and `transition_direction`
- `system`: hostname, OS, kernel, architecture, and root disk use
- `warpi`: mode/state, runtime state file, and field marker path/presence
- `network`: NetworkManager identity, active connection/profile, SSID, active interface, addresses, default route, relevant routes, DNS, and active connections
- `tailscale`: service state, backend state, tailnet IP, and management-path presence
- `firewall`: implementation and a safe table/ruleset reference
- `services`: `warpi-kernel`, `tailscaled`, `NetworkManager`, `ssh`, `gpsd`, `warpi-ui`, and `kismet` state
- `sidecar`: NANO interface, management path, UI port, reachability, and whether default route uses the sidecar
- `validation`: snapshot completeness, missing fields, and warnings
- `secret_exclusion`: explicit confirmation that credential classes are excluded

Snapshots must never include Wi-Fi PSKs, Tailscale auth keys, API tokens, private keys, Pineapple credentials, environment secrets, or unrelated credentials. Validation blocks snapshots that contain common credential-like patterns.

Validation levels:

- `PASS`: the check is satisfactory.
- `WARN`: the condition should be reviewed but does not prevent metadata capture.
- `BLOCK`: future apply must not proceed.

Preflight success does not authorize apply. A preflight snapshot becomes stale when live mode, active Wi-Fi profile, IP/default route, interface inventory, reboot/runtime identity, or transition metadata changes materially. Milestone B records a `stale` field for future use; a later verifier must compare the snapshot to live state before any apply can be considered.

## Milestone C Rollback Verifier And Recovery Planner

Milestone C adds the non-mutating rollback-planning command:

- `warpi mode rollback-plan`
- `warpi mode rollback-plan --transaction <transition-id>`
- `warpi mode rollback-plan --json`

If no transaction is supplied, the command explicitly selects the latest preflight snapshot from `/var/lib/warpi/mode-transitions/last-preflight.json`. It never silently selects a malformed or invalid snapshot.

The rollback verifier checks:

- Snapshot schema version support.
- Transaction ID format and requested transaction match.
- Sibling `transaction.json` presence and transition ID correlation.
- Completed PASS preflight metadata.
- Source mode, target mode, and transition direction coherence.
- Required recovery fields for WARPi state, network, Tailscale, services, and sidecar.
- Hostname match.
- Snapshot ownership, mode, and symlink safety.
- Common credential-like strings that would indicate unsafe secret capture.

Verifier results are classified as `PASS`, `WARN`, or `BLOCK`. A `BLOCK` result prevents recovery readiness and future executor eligibility.

The planner captures current state read-only using the same normalized categories as rollback snapshots: WARPi mode/control state, NetworkManager-visible connection state, default route, route/address inventory, DNS, Tailscale service/backend/IP, firewall implementation/reference, critical service states, and sidecar isolation/reachability. It compares current state to the selected snapshot and records deterministic drift entries. Milestone C emits `UNCHANGED` and `RESTORE_REQUIRED` classifications; later executor design can extend this with `EXPECTED_DRIFT`, `WARNING`, and `BLOCKER`.

Generated recovery plans are stored at:

- `/var/lib/warpi/mode-transitions/<transition-id>/rollback-plan.json`

Plan schema version 1 includes:

- `schema_version`
- `generated_at`
- `transaction_id`
- `snapshot_path`
- `snapshot_sha256`
- `verifier`
- `drift_analysis`
- `recovery_plan`
- `recovery_readiness`
- `apply_gate`

Each recovery action includes sequence, phase, component, current state, desired state, proposed action, reason, risk level, connectivity impact, verification requirement, command preview, and `command_status: "NOT EXECUTED"`.

Recovery phases are ordered to preserve management access:

1. Phase 0: validate recovery data.
2. Phase 1: establish or confirm the target uplink.
3. Phase 2: restore addressing and routes only after the target uplink is confirmed.
4. Phase 3: verify Tailscale management connectivity.
5. Phase 4: restore firewall policy.
6. Phase 5: restore sidecar isolation.
7. Phase 6: restore service state.
8. Phase 7: restore WARPi mode/control metadata.
9. Phase 8: final health verification.

Milestone C plans are preview-only. They do not execute commands, change routes, change Wi-Fi state, alter firewall rules, restart services, modify the NANO, enter Field Mode, or authorize any future `--apply`.

Milestone C external Wi-Fi adapter finding: live read-only inspection at CLS showed only `wlan0` as a wireless netdev. `lsusb` showed the root hubs, VIA hub, and ASIX AX88772A sidecar Ethernet, but no separate external Wi-Fi adapter enumeration. `ip link` and NetworkManager device state did not show an additional wireless interface. Current evidence points to hardware not being detected by Linux at that moment, rather than WARPi detection logic missing an existing netdev. No driver reloads, scans, radio changes, or NetworkManager restarts were performed.

## Milestone D Executor Simulation

Milestone D adds the simulation-only staged executor commands:

- `warpi mode simulate enter-field`
- `warpi mode simulate return-normal`
- `warpi mode simulate enter-field --transaction <preflight-id>`
- `warpi mode simulate enter-field --fail-at <phase>`
- `warpi mode simulate enter-field --rollback-fail-at <phase>`
- `warpi mode simulate enter-field --json`
- `warpi mode simulate-status`

The executor backend model is explicit:

- `backend = simulation`
- `live_executor_enabled = false`

No live backend is callable in Milestone D. There is no `--real`, `--force-live`, `--unsafe`, `--experimental-apply`, `--bypass`, or environment override for live execution.

Each simulation creates a distinct `sim-<timestamp>-<random>` transaction correlated with the originating preflight transaction. Simulation artifacts live under:

- `/var/lib/warpi/mode-transitions/<simulation-id>/simulation.json`
- `/var/lib/warpi/mode-transitions/<simulation-id>/executor-checkpoint.json`
- `/var/lib/warpi/mode-transitions/last-simulation.json`

Simulation metadata tracks schema version, simulation ID, source preflight ID, snapshot path, recovery-plan path, direction, source/target mode, backend, state, result, timestamps, failure injection, rollback decision, rollback result, planned/simulated action counts, blockers/warnings, phases, simulated actions, and event history.

Checkpoint schema version 1 includes simulation ID, source preflight ID, state, phase, last completed action, next action, timestamp, rollback-required flag, rollback position, result, and integrity metadata. Resume/continuation is not a live executor path; corrupted or contradictory checkpoints block status/resume decisions and require review.

NORMAL -> FIELD simulation phases:

1. `validate`: verify transaction, snapshot, recovery plan, and safety invariants.
2. `prepare-interface`: prepare and select the future FIELD wireless interface.
3. `prepare-profile`: prepare the target FIELD NetworkManager profile.
4. `prepare-routing`: prepare route preference changes.
5. `prepare-firewall`: prepare field firewall policy.
6. `verify-management`: verify management/recovery path.
7. `prepare-sidecar`: ensure NANO remains sidecar-only.
8. `prepare-services`: prepare field service changes.
9. `prepare-mode-metadata`: prepare mode/control metadata update.
10. `verify-target-health`: verify target FIELD health before commit.
11. `commit`: commit final simulated FIELD transition.

FIELD -> NORMAL simulation uses the corresponding restoration sequence: validate, prepare original uplink, prepare addressing, prepare routing, verify management, prepare firewall, prepare sidecar isolation, prepare service restoration, prepare mode metadata, verify target health, and commit.

Each action records action ID, phase, component, description, current state, desired state, `simulation_behavior`, `future_live_operation: disabled-not-callable`, risk level, management-path risk, verification requirement, rollback action, dependencies, and `command_status: NOT EXECUTED`.

Automatic rollback decisioning is explicit:

- Failures in validation/interface/profile preparation do not require rollback because no future mutation-equivalent phase has been reached.
- Failures in routing, firewall, management verification, sidecar, services, mode metadata, target health, or commit require simulated rollback using the Milestone C recovery plan.
- Rollback failure injection produces `ROLLBACK_FAILED` and manual recovery escalation.

Management-path invariants:

- Tailscale management path cannot be intentionally destroyed before an alternate verified path exists.
- Current uplink cannot be removed before target uplink validation where possible.
- Default route cannot be changed blindly.
- NANO/sidecar cannot become the default route.
- Firewall changes cannot precede recovery/management-path safety checks if they could block access.
- Mode metadata cannot be committed before health verification passes.
- Rollback metadata must validate before any future mutating phase starts.

The external Wi-Fi adapter remains a real hardware prerequisite for FIELD readiness. If no extra Wi-Fi interface beyond `wlan0` is enumerated, the simulator reports `REAL HARDWARE PREREQUISITE MISSING` and treats the run as executor-logic validation only.

## Milestone E Disabled Live Adapter Architecture

Milestone E adds the real executor shape without making live execution callable.

New read-only/status commands:

- `warpi mode executor-status`
- `warpi mode executor-status --json`
- `warpi mode recovery-status`
- `warpi mode recovery-status --json`
- `warpi mode watchdog-status`
- `warpi mode watchdog-status --json`
- `warpi mode adapters`
- `warpi mode adapters --json`
- `warpi mode test-fixtures`
- `warpi mode test-fixtures --json`

The adapter inventory defines future bounded action adapters with stable IDs, ordering, component, mutating flag, preconditions, postconditions, rollback adapter, and the conceptual interface `validate`, `preview`, `execute`, `verify`, `rollback`, and `describe`.

Adapter IDs:

- `validate-hardware`
- `capture-rollback`
- `prepare-assessment-radio`
- `prepare-routing`
- `prepare-firewall`
- `verify-management-path`
- `configure-field-services`
- `verify-field-health`
- `commit-mode`
- `restore-network`
- `restore-routing`
- `restore-firewall`
- `restore-services`
- `restore-mode`
- `final-health`

Every mutating adapter has `execute_gate=disabled`. There is no documented or hidden CLI/config/environment bypass that can execute live mutation in Milestone E.

The live gate remains non-callable unless all future prerequisites are met: live executor feature flag, transaction-bound operator authorization, fresh valid preflight, valid rollback snapshot, rollback verifier `PASS`, no lock conflict, legal source/target state, positively validated external Wi-Fi for `NORMAL_TO_FIELD`, management watchdog `HEALTHY`, Tailscale healthy, NANO not default route, Mission Control not required for local recovery, writable checkpoint storage, and boot recovery health.

The arming model is represented by `/run/warpi/mode-executor.arm`, but no Milestone E command creates a live arm. A future arm must be root-owned, transaction-bound, expiring, non-reusable, visible without exposing secret material, and cleared by boot. While the live executor feature flag is disabled, any arm state is informational only.

The external assessment-radio prerequisite is first-class. `NORMAL_TO_FIELD` live eligibility is false unless a second wireless device distinct from `wlan0` exists, has a distinct phy, has recordable driver/hardware identity, and is not the management uplink or default route. As of Milestone E, WARPi still does not enumerate an external Wi-Fi USB device, so FIELD readiness remains blocked by physical hardware.

The management watchdog classifies state as `HEALTHY`, `DEGRADED`, or `LOST` using Tailscale backend/IP, route to a management peer, default route/interface, active uplink, NANO default-route safety, and Mission Control as informational only. The default future threshold is three consecutive LOST checks. DEGRADED should pause and re-evaluate; persistent LOST should stop forward execution and mark rollback required.

Boot/interruption recovery reports one of `SAFE_IDLE`, `RESUME_NOT_ALLOWED`, `ROLLBACK_REQUIRED`, or `MANUAL_INTERVENTION_REQUIRED`. The policy is conservative: do not resume forward toward FIELD after interruption, prefer rollback to the last known-good source state, and require manual intervention for corrupt or contradictory metadata.

Mission Control check-in includes bounded Milestone E telemetry: armed state, hardware readiness, watchdog state, recovery decision, live-callable flag, and blocker count. Mission Control remains observational and is not required for local recovery.

## Future Runtime Mode State Machine

Future live mode states:

- `NORMAL`: trusted-client mode.
- `ENTERING_FIELD`: apply transaction is moving toward Field Mode.
- `FIELD`: field mode committed and healthy enough for operation.
- `RETURNING_NORMAL`: apply transaction is restoring Normal Mode invariants.
- `ROLLING_BACK`: automatic or manual rollback is active.
- `DEGRADED`: core management survived, but one or more mode invariants failed.
- `RECOVERY_REQUIRED`: local/operator recovery is needed.

Allowed commands:

- `NORMAL`: allow `status`, `report`, `docs audit`, dry-run planners, and future `enter-field --apply`.
- `ENTERING_FIELD`: allow read-only status/report/audit; reject new mode apply commands.
- `FIELD`: allow `status`, `report`, `docs audit`, dry-run planners, and future `return-normal --apply`.
- `RETURNING_NORMAL`: allow read-only status/report/audit; reject new mode apply commands.
- `ROLLING_BACK`: allow read-only status/report/audit and local recovery commands only.
- `DEGRADED`: allow read-only commands and the safest applicable recovery command.
- `RECOVERY_REQUIRED`: require local console or explicitly approved recovery path.

Valid transitions:

- `NORMAL -> ENTERING_FIELD -> FIELD`
- `ENTERING_FIELD -> ROLLING_BACK -> NORMAL`
- `ENTERING_FIELD -> DEGRADED`
- `FIELD -> RETURNING_NORMAL -> NORMAL`
- `RETURNING_NORMAL -> ROLLING_BACK -> FIELD` when Field Mode is still healthier than partial Normal Mode
- `RETURNING_NORMAL -> DEGRADED`
- Any transitional state may move to `RECOVERY_REQUIRED` when management recovery cannot be proven.

Invalid transitions:

- `NORMAL -> FIELD` without `ENTERING_FIELD`
- `FIELD -> NORMAL` without `RETURNING_NORMAL`
- Any new apply command while a transition lock exists
- Any transition that skips rollback metadata capture

Concurrent transitions are prevented by an exclusive lock such as `/run/warpi/mode-transition.lock`.

## Transaction Files

Runtime files should live under `/run/warpi`:

- `mode-transition.lock`
- `mode-transition-state.json`
- `mode-transition-current.json`

Persistent recovery files should live under `/var/lib/warpi/mode-transitions`:

- `last-known-good-normal.json`
- `last-known-good-field.json`
- `pending-transition.json`
- `rollback-plan.json`

Logs should live under `/var/log/warpi/mode-transitions` and use a unique transition ID.

Persistent files must avoid secrets. Saved NetworkManager metadata should include profile names and safe state summaries, not Wi-Fi PSKs.

## Enter Field Transaction

Every stage must have a transition ID, timeout, validation, and failure behavior.

1. Preflight
   - Action: verify current state, command identity, sudo/root, active services, field profile, and recovery metadata path.
   - Expected result: Normal Mode invariants pass or known acceptable degraded preconditions are documented.
   - Timeout: 30 seconds.
   - Failure: abort with no mutation.

2. Acquire transition lock
   - Action: create exclusive lock.
   - Expected result: no concurrent mode operation.
   - Timeout: 5 seconds.
   - Failure: abort with exit `2`.

3. Capture current state
   - Action: save interface, route, service, state JSON, active NM profiles, firewall summary, and Tailscale status.
   - Expected result: last-known-good Normal snapshot written.
   - Timeout: 15 seconds.
   - Failure: release lock and abort.

4. Validate recovery path
   - Action: prove SSH, Tailscale, and local rollback command availability before first mutation.
   - Expected result: OpenClaw reachable or explicit local-console-only approval exists.
   - Timeout: 30 seconds.
   - Failure: abort with no mutation.

5. Mark `ENTERING_FIELD`
   - Action: write transition state.
   - Expected result: `kernel-report` can display transitional state.
   - Timeout: 5 seconds.
   - Failure: abort with no mutation.

6. Prepare field firewall and forwarding
   - Action: create/update only `inet warpi_field`; enable required IPv4 forwarding if needed.
   - Expected result: field rules exist and Tailscale/Docker chains are unchanged.
   - Timeout: 15 seconds.
   - Failure: rollback to Normal.

7. Activate field profile
   - Action: bring up `WARPi-Field` on `wlan0`.
   - Expected result: `wlan0` has `10.42.0.1/24` and AP mode is active.
   - Timeout: 45 seconds.
   - Failure: rollback to Normal.

8. Validate management survivability
   - Action: check `ssh.service`, `tailscaled.service`, `tailscale0`, and bounded OpenClaw reachability.
   - Expected result: management path survives.
   - Timeout: 60 seconds.
   - Failure: rollback immediately.

9. Start required field services
   - Action: start or validate approved field-only services such as Kismet.
   - Expected result: required services active.
   - Timeout: 30 seconds.
   - Failure: rollback unless service is explicitly noncritical.

10. Write field marker
    - Action: create `/tmp/warpi_fieldmode`.
    - Expected result: collector reports `field_mode == true`.
    - Timeout: 5 seconds.
    - Failure: rollback.

11. Final Field health validation
    - Action: test all Field Mode invariants.
    - Expected result: pass or controlled `DEGRADED` with management intact.
    - Timeout: 60 seconds.
    - Failure: rollback if management is at risk.

12. Commit transition
    - Action: mark `FIELD`, write final summary, clear pending transition.
    - Expected result: committed state visible in report.
    - Timeout: 10 seconds.
    - Failure: mark `DEGRADED` and preserve metadata.

13. Release lock
    - Action: release lock after state is committed or rollback is complete.
    - Expected result: future commands may run.
    - Timeout: 5 seconds.
    - Failure: leave lock with stale-owner metadata and report `RECOVERY_REQUIRED`.

## Return Normal Transaction

`return-normal --apply` restores Normal Mode invariants. It must not simply reverse commands blindly.

1. Preflight
   - Accept starting states `FIELD`, `DEGRADED`, `ENTERING_FIELD`, or partial field state.
   - Refuse if another live transition lock is valid.

2. Capture current state
   - Save field interface, route, marker, services, firewall, and Tailscale state.

3. Validate recovery target
   - Confirm trusted profile exists and field profile autoconnect can be disabled.

4. Mark `RETURNING_NORMAL`
   - Write transition state before mutation.

5. Preserve management services
   - Confirm SSH and Tailscale are active. Start them if stopped.

6. Disable field autoconnect
   - Ensure `WARPi-Field` will not auto-take-over after boot.

7. Restore trusted client networking
   - Bring up trusted `wlan0` client profile and wait for IPv4.

8. Validate Normal management
   - Confirm default route on `wlan0`, Tailscale address, OpenClaw reachability, and SSH.

9. Remove field marker
   - Remove `/tmp/warpi_fieldmode` only after trusted networking is healthy.

10. Stop field-only services
    - Stop Kismet only if the service contract says Field Mode owns it.

11. Remove or neutralize field firewall table
    - Delete only the WARPi-owned field table.

12. Final Normal health validation
    - Test all Normal Mode invariants.

13. Commit `NORMAL`
    - Clear pending transition, save recovery summary, release lock.

If partial Field Mode is broken, return-normal should still try the safest Normal restoration path. If both Field and Normal management paths are impaired, mark `RECOVERY_REQUIRED`.

## Automatic Rollback Policy

Rollback starts automatically when any high-risk condition occurs:

- Default route disappears unexpectedly.
- Default route moves to `eth1`, `tailscale0`, or `docker0` without explicit approval.
- `tailscale0` address disappears.
- OpenClaw is unreachable beyond 60 seconds when it was reachable before transition.
- `ssh.service` is inactive and cannot be restarted.
- `NetworkManager.service` becomes unhealthy.
- Expected `wlan0` profile or address fails to appear within timeout.
- Field firewall validation fails.
- Required service fails and is marked critical.
- State JSON becomes invalid or internally inconsistent.
- A transition stage exceeds timeout.
- The transition process receives an interrupt after first mutation.
- Boot finds an old `APPLYING`, `ENTERING_FIELD`, or `RETURNING_NORMAL` marker.

Rollback priority:

1. Keep the local system stable.
2. Restore management connectivity.
3. Restore Tailscale.
4. Restore SSH.
5. Restore known-good network state.
6. Restore noncritical services.
7. Preserve logs and evidence.

Safe-to-retry rollback operations:

- Start `ssh.service`.
- Start `tailscaled.service`.
- Set `WARPi-Field` autoconnect off.
- Bring up the saved trusted Wi-Fi profile.
- Remove `/tmp/warpi_fieldmode`.
- Delete the WARPi-owned field firewall table.

Rollback must not delete Tailscale or Docker firewall chains.

## Boot And Out-Of-Band Recovery

On boot, WARPi should inspect persistent transition metadata before normal service decisions.

Recommended boot behavior:

- If no pending transition exists, continue normal startup.
- If a pending transition is older than its timeout and state is `ENTERING_FIELD`, attempt automatic return to last-known-good Normal once.
- If state is `RETURNING_NORMAL`, continue Normal recovery once.
- If state is `ROLLING_BACK`, continue rollback once.
- If one automatic boot recovery attempt already failed, mark `RECOVERY_REQUIRED`.
- Never loop endlessly between field and normal profiles.

Local operator recovery should provide a single safe command such as:

```bash
sudo warpi recovery status
sudo warpi recovery return-normal
```

Those commands are future design targets only. They should show pending transition ID, last stage, saved last-known-good metadata, and the exact recovery action before changing anything.

Recovery logs must be preserved under `/var/log/warpi/mode-transitions`.

## Safety Gates

The `--apply` gate may only be enabled after all are true:

- Dry-run output exists and matches implemented stages.
- Root or approved passwordless sudo path is available.
- Explicit `--apply` syntax is required.
- Optional confirmation flag is considered for remote use, such as `--confirm <transition-id>`.
- Transition lock is implemented.
- Last-known-good capture is implemented.
- Rollback command path is verified before first mutation.
- Timeouts are implemented for every stage.
- State machine prevents concurrent mode operations.
- Fail-closed behavior is tested.
- Logs are written without secrets.
- Kernel report can display transition state.
- Boot recovery behavior is documented and tested.
- Levels 1 through 4 of the test plan pass.
- Supervised live validation is approved before Levels 5 through 7.

## Observability

Each transition log entry should include:

- transition ID
- requested target mode
- initiating identity
- command arguments excluding secrets
- start and end timestamps
- stage name
- stage result
- timeout result
- before and after state summaries
- rollback trigger if applicable
- final mode state
- health validation result

`kernel-report` should eventually show:

- current state machine state
- active transition ID when present
- last transition summary
- last rollback reason
- last-known-good timestamp

`kernel-doc-audit` does not need mode-transition health logic beyond validating that transition tools and docs exist.

Guardian/Wazuh telemetry should be limited to existing safe local logs or future approved log shipping. Do not add a new telemetry dependency just to enable mode switching.

## Test Plan

Level 1: static validation

- `bash -n` and ShellCheck for shell code.
- Python syntax checks for Python helpers.
- Markdown lint for docs.
- State schema examples validate with `jq`.
- PASS: no syntax/lint failures.

Level 2: mocked transaction tests

- Use a mocked command executor for `nmcli`, `ip`, `systemctl`, `tailscale`, and firewall commands.
- Verify state transitions and command ordering.
- PASS: no live mutation commands are executed.

Level 3: failure injection

- Simulate timeouts, failed profile activation, failed Tailscale, failed SSH, bad state JSON, interrupted process, and reboot markers.
- PASS: rollback or `RECOVERY_REQUIRED` occurs exactly as designed.

Level 4: controlled live no-op/preflight

- Run future `--apply --preflight-only` or equivalent.
- Verify recovery path and last-known-good capture without changing network state.
- PASS: default route, Tailscale, SSH, and dry-run behavior remain unchanged.

Level 5: supervised real enter-field

- Human approves local console availability and real network mutation.
- Enter Field Mode once under observation.
- PASS: Field Mode invariants pass and management survives.

Level 6: supervised real return-normal

- Return from Field Mode under observation.
- PASS: Normal Mode invariants pass.

Level 7: deliberate safe rollback

- Trigger a controlled failure that cannot strand management.
- PASS: automatic rollback restores Normal Mode and preserves evidence.

Levels 5 through 7 are not authorized by this design checkpoint.

## Implementation Milestones

Milestone A: state machine and transaction framework, no live mutations.

Milestone B: state capture and last-known-good rollback metadata.

Milestone C: rollback verifier and recovery planner.

Milestone D: simulation-only staged executor, checkpointing, failure injection, and rollback simulation.

Milestone E: disabled live adapter architecture, hard gate, arming framework, external-radio prerequisite, management watchdog, boot/interruption recovery status, and fixture tests.

Milestone F: controlled live readiness and hardware validation after the external Wi-Fi adapter positively enumerates.

Milestone G: staged live adapter validation under explicit approval, still not end-to-end FIELD apply.

Milestone H: supervised live transition rehearsal with local recovery path and management watchdog.

Milestone I: enable production apply gate after successful review.

## Open Questions For Implementation

- Whether Field Mode should require Kismet to start or treat it as optional.
- Whether `WARPi-Field` should set `ipv4.never-default yes` to preserve management routing when feasible.
- Whether a second management path should be required before real Field Mode when trusted Wi-Fi will be replaced by AP mode.
- Whether field-side DNS should be limited to NetworkManager shared mode or owned by a WARPi-specific service.
- Whether `kernel.py` should own transitions directly or the dispatcher should call a dedicated transaction helper.

Do not answer these by changing live behavior. Resolve them in implementation design and tests.
