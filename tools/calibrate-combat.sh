#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$PWD/.local-config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$PWD/.local-cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-/workspace/shared/godot-data}"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" artifacts
touch artifacts/.gdignore
"$GODOT" --version | tee artifacts/calibration-engine.log
"$GODOT" --headless --path . --editor --import > artifacts/calibration-import.log 2>&1
# Read-only baseline evidence. Remove global class registration to avoid conflicts.
git show 4d9c702263e016d78e92aed0d817c801e3d31078:scripts/battle_sim.gd | sed '/^class_name BattleSimulation$/d' > artifacts/legacy_reference.gd
for test in test_hero_profiles test_combat_calibration test_legacy_profile_parity; do
  "$GODOT" --headless --path . --script "tests/$test.gd" 2>&1 | tee "artifacts/$test.log"
done
"$GODOT" --headless --path . --script tests/run_combat_calibration.gd > artifacts/calibration-run1.log 2>&1
cp artifacts/combat-calibration.json artifacts/combat-calibration-run1.json
"$GODOT" --headless --path . --script tests/run_combat_calibration.gd > artifacts/calibration-run2.log 2>&1
cmp artifacts/combat-calibration-run1.json artifacts/combat-calibration.json
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/calibration-{import,run1,run2}.log artifacts/test_{hero_profiles,combat_calibration,legacy_profile_parity}.log; then
  exit 1
fi
grep -q '"failures":\[\]' artifacts/test_hero_profiles.log
grep -q '"failures":\[\]' artifacts/test_combat_calibration.log
grep -q '"failures":\[\]' artifacts/test_legacy_profile_parity.log
grep -q 'CALIBRATION_COMPLETE runs=270 focused_contact=120 organized_surround=40' artifacts/calibration-run2.log
sha256sum artifacts/combat-calibration.json | tee artifacts/combat-calibration.sha256
printf 'COMBAT_CALIBRATION_REPEAT_PASS\n'
