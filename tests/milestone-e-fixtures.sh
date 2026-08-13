#!/bin/bash
set -euo pipefail

WARPI_BIN="${WARPI_BIN:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/bin/warpi}"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR" /tmp/warpi-e-apply-enter.out /tmp/warpi-e-apply-return.out' EXIT

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
    "tailscale": true,
    "tailscale_ip": "100.64.0.1"
  }
}
JSON

bash -n "$WARPI_BIN"

run_warpi() {
    STATE_FILE="$WORK_DIR/state.json" WARPI_TRANSITION_RECOVERY_DIR="$WORK_DIR/transitions" "$WARPI_BIN" "$@"
}

adapters_count="$(run_warpi mode adapters --json | jq 'length')"
[[ "$adapters_count" -ge 15 ]]

fixture_result="$(run_warpi mode test-fixtures --json | jq -r '.result')"
[[ "$fixture_result" == "PASS" ]]

executor_callable="$(run_warpi mode executor-status --json | jq -r '.callable')"
[[ "$executor_callable" == "false" ]]

feature_flag="$(run_warpi mode executor-status --json | jq -r '.live_executor_feature_flag')"
[[ "$feature_flag" == "disabled" ]]

watchdog_state="$(run_warpi mode watchdog-status --json | jq -r '.state')"
[[ "$watchdog_state" =~ ^(HEALTHY|DEGRADED|LOST)$ ]]

recovery_decision="$(run_warpi mode recovery-status --json | jq -r '.decision')"
[[ "$recovery_decision" =~ ^(SAFE_IDLE|RESUME_NOT_ALLOWED|ROLLBACK_REQUIRED|MANUAL_INTERVENTION_REQUIRED)$ ]]

set +e
run_warpi mode enter-field --apply >/tmp/warpi-e-apply-enter.out 2>&1
enter_rc=$?
run_warpi mode return-normal --apply >/tmp/warpi-e-apply-return.out 2>&1
return_rc=$?
set -e

[[ "$enter_rc" -eq 2 ]]
[[ "$return_rc" -eq 2 ]]
grep -q 'live executor disabled' /tmp/warpi-e-apply-enter.out
grep -q 'live executor disabled' /tmp/warpi-e-apply-return.out

echo "milestone-e-fixtures: PASS"
