#!/bin/bash
set -euo pipefail

WARPI_BIN="${WARPI_BIN:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/bin/warpi}"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR" /tmp/warpi-f-apply-enter.out /tmp/warpi-f-apply-return.out' EXIT

cat > "$WORK_DIR/state.json" <<'JSON'
{
  "mode": "NORMAL",
  "state": "CONNECTED",
  "reason": "fixture",
  "updated": "2026-08-13T00:00:00Z",
  "network": {
    "field_mode": false,
    "wifi_profile": "CLS Health",
    "wifi_ssid": "CLS Health",
    "interface": "wlan0",
    "ipv4": "192.168.4.78",
    "tailscale": true,
    "tailscale_ip": "100.120.12.107"
  }
}
JSON

PANDA_FIXTURE='[
  {"interface":"wlan0","driver":"brcmfmac","phy":"phy0","mac":"d8:3a:dd:75:b3:30","device_path":"/sys/devices/platform/soc","networkmanager_state":"connected","usb_id":"unknown","manufacturer":"Broadcom","product":"onboard","role":"management","is_management":true,"is_default_route":true,"approved":false},
  {"interface":"wlan1","driver":"mt76x2u","phy":"phy1","mac":"9c:ef:d5:f8:98:83","device_path":"/sys/devices/platform/soc/usb1/1-1/1-1.4","networkmanager_state":"disconnected","usb_id":"0e8d:7612","manufacturer":"MediaTek Inc.","product":"MT7612U 802.11a/b/g/n/ac Wireless Adapter","role":"assessment","is_management":false,"is_default_route":false,"approved":true}
]'

ABSENT_FIXTURE='[
  {"interface":"wlan0","driver":"brcmfmac","phy":"phy0","mac":"d8:3a:dd:75:b3:30","device_path":"/sys/devices/platform/soc","networkmanager_state":"connected","usb_id":"unknown","manufacturer":"Broadcom","product":"onboard","role":"management","is_management":true,"is_default_route":true,"approved":false}
]'

bash -n "$WARPI_BIN"
mkdir -p "$WORK_DIR/run"

run_warpi() {
    STATE_FILE="$WORK_DIR/state.json" \
    WARPI_TRANSITION_RECOVERY_DIR="$WORK_DIR/transitions" \
    WARPI_TRANSITION_LOCK_FILE="$WORK_DIR/run/mode-transition.lock" \
    EXECUTOR_ARM_FILE="$WORK_DIR/run/mode-executor.arm" \
    EXECUTOR_RECOVERY_STATUS_FILE="$WORK_DIR/run/mode-recovery-status.json" \
    "$WARPI_BIN" "$@"
}

ready="$(WARPI_ASSESSMENT_RADIO_FIXTURE_JSON="$PANDA_FIXTURE" run_warpi mode executor-status --json | jq -r '.hardware.eligibility')"
[[ "$ready" == "VALIDATED" ]]

callable="$(WARPI_ASSESSMENT_RADIO_FIXTURE_JSON="$PANDA_FIXTURE" run_warpi mode executor-status --json | jq -r '.callable')"
[[ "$callable" == "false" ]]

blockers="$(WARPI_ASSESSMENT_RADIO_FIXTURE_JSON="$PANDA_FIXTURE" run_warpi mode executor-status --json | jq -r '.blockers[].code' | tr '\n' ' ')"
[[ "$blockers" == *"live-executor-disabled"* ]]
[[ "$blockers" == *"operator-authorization-absent"* ]]
[[ "$blockers" != *"external-wifi-missing"* ]]

absent="$(WARPI_ASSESSMENT_RADIO_FIXTURE_JSON="$ABSENT_FIXTURE" run_warpi mode executor-status --json | jq -r '.hardware.eligibility')"
[[ "$absent" == "PHYSICAL_ACTION_REQUIRED" ]]

printf '{"schema_version":1,"transaction_id":"tx-fixture","expires_at":"2099-01-01T00:00:00Z"}\n' > "$WORK_DIR/run/mode-executor.arm"
WARPI_ASSESSMENT_RADIO_FIXTURE_JSON="$PANDA_FIXTURE" run_warpi mode recovery-status --record >/dev/null
[[ ! -e "$WORK_DIR/run/mode-executor.arm" ]]
jq -e '.recovery_service_mode == "status-only-no-live-mutation"' "$WORK_DIR/run/mode-recovery-status.json" >/dev/null

watchdog="$(WARPI_ASSESSMENT_RADIO_FIXTURE_JSON="$PANDA_FIXTURE" run_warpi mode watchdog-status --json | jq -r '.state')"
[[ "$watchdog" =~ ^(HEALTHY|DEGRADED|LOST)$ ]]

fixtures="$(WARPI_ASSESSMENT_RADIO_FIXTURE_JSON="$PANDA_FIXTURE" run_warpi mode test-fixtures --json | jq -r '.result')"
[[ "$fixtures" == "PASS" ]]

set +e
WARPI_ASSESSMENT_RADIO_FIXTURE_JSON="$PANDA_FIXTURE" run_warpi mode enter-field --apply >/tmp/warpi-f-apply-enter.out 2>&1
enter_rc=$?
WARPI_ASSESSMENT_RADIO_FIXTURE_JSON="$PANDA_FIXTURE" run_warpi mode return-normal --apply >/tmp/warpi-f-apply-return.out 2>&1
return_rc=$?
set -e

[[ "$enter_rc" -eq 2 ]]
[[ "$return_rc" -eq 2 ]]
grep -q 'live executor disabled' /tmp/warpi-f-apply-enter.out
grep -q 'operator authorization absent' /tmp/warpi-f-apply-enter.out
! grep -q 'not enumerated' /tmp/warpi-f-apply-enter.out
grep -q 'live executor disabled' /tmp/warpi-f-apply-return.out

echo "milestone-f-fixtures: PASS"
