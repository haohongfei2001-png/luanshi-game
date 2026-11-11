#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$PWD/.local-data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$PWD/.local-config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$PWD/.local-cache}"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" artifacts
# Evidence images are outputs, never imported game resources.
touch artifacts/.gdignore
./tools/prepare-font.sh
"$GODOT" --version | tee artifacts/engine-version.log
"$GODOT" --headless --path . --editor --import 2>&1 | tee artifacts/import.log
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/import.log; then exit 1; fi
"$GODOT" --headless --path . --check-only --script scripts/youth_ui.gd
"$GODOT" --headless --path . --script tests/field_simulation.gd 2>&1 | tee artifacts/field-simulation.log
grep -q '^FIELD_SIM_PASS' artifacts/field-simulation.log
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/field-simulation.log; then exit 1; fi
"$GODOT" --headless --path . --script tests/test_battle.gd 2>&1 | tee artifacts/simulation-tests.log
"$GODOT" --headless --path . --script tests/test_world.gd 2>&1 | tee artifacts/world-tests.log
"$GODOT" --headless --path . --script tests/tests_economy.gd 2>&1 | tee artifacts/economy-tests.log
"$GODOT" --headless --path . --script tests/tests_hunger.gd 2>&1 | tee artifacts/hunger-tests.log
"$GODOT" --headless --path . --script tests/test_hunger_properties.gd 2>&1 | tee artifacts/hunger-properties.log
"$GODOT" --headless --path . --script tests/test_economy_properties.gd 2>&1 | tee artifacts/economy-properties.log
"$GODOT" --headless --path . --script tests/test_battle_transactions.gd 2>&1 | tee artifacts/transaction-tests.log
"$GODOT" --headless --path . --script tests/test_campaign_saves.gd 2>&1 | tee artifacts/save-tests.log
"$GODOT" --headless --path . --script tests/test_profile_saves.gd 2>&1 | tee artifacts/profile-save-tests.log
grep -q '"failures":\[\]' artifacts/profile-save-tests.log
"$GODOT" --headless --path . --script tests/test_campaign_save_history.gd 2>&1 | tee artifacts/save-history.log
for state in active committed dead; do
  "$GODOT" --headless --path . --script tests/test_save_invalid_types.gd -- "$state" 2>&1 | tee "artifacts/save-invalid-$state.log"
  grep -q 'SAVE_INVALID_TYPES .* cases / 0 failures' "artifacts/save-invalid-$state.log"
done
"$GODOT" --headless --path . --script tests/test_save_boundaries.gd 2>&1 | tee artifacts/save-boundaries.log
SAVE_TEST_ID="test_restart_$(date +%s)_${RANDOM}_${RANDOM}"
"$GODOT" --headless --path . --script tests/test_campaign_save_restart.gd -- prepare "$SAVE_TEST_ID" 2>&1 | tee artifacts/save-restart-prepare.log
"$GODOT" --headless --path . --script tests/test_campaign_save_restart.gd -- resume "$SAVE_TEST_ID" 2>&1 | tee artifacts/save-restart-resume.log
for profile in late_v1 legacy_test_v0; do
  for phase in prepare resume; do
    "$GODOT" --headless --path . --script tests/test_campaign_save_restart.gd -- "$phase" "${SAVE_TEST_ID}_${profile%%_*}" "$profile" 2>&1 | tee "artifacts/save-restart-${profile}-${phase}.log"
    grep -q '"failures":0' "artifacts/save-restart-${profile}-${phase}.log"
  done
done
"$GODOT" --headless --path . --fixed-fps 60 --script tests/test_scene.gd -- --campaign-save-id="${SAVE_TEST_ID}_scene" 2>&1 | tee artifacts/scene-tests.log
"$GODOT" --headless --path . --fixed-fps 60 --script tests/test_strategy.gd -- --campaign-save-id="${SAVE_TEST_ID}_strategy" 2>&1 | tee artifacts/strategy-tests.log
"$GODOT" --headless --path . --fixed-fps 60 --script tests/test_campaign_scene.gd -- --campaign-save-id="${SAVE_TEST_ID}_campaign" 2>&1 | tee artifacts/campaign-tests.log
"$GODOT" --headless --path . --fixed-fps 60 --script tests/test_campaign_save_scene.gd 2>&1 | tee artifacts/save-scene-tests.log
for profile in early_v1 late_v1; do
  "$GODOT" --headless --path . --fixed-fps 60 --script tests/test_profile_scene.gd -- "--training-profile=$profile" 2>&1 | tee "artifacts/profile-scene-$profile.log"
  grep -q '"failures":\[\]' "artifacts/profile-scene-$profile.log"
done
"$GODOT" --headless --path . --fixed-fps 60 -- --smoke-scene --campaign-save-id="${SAVE_TEST_ID}_training" 2>&1 | tee artifacts/scene-smoke.log
"$GODOT" --headless --path . --fixed-fps 60 -- --campaign-smoke --campaign-save-id="${SAVE_TEST_ID}_battle" 2>&1 | tee artifacts/campaign-smoke.log
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/{import,profile-scene-early_v1,profile-scene-late_v1,profile-save-tests,save-restart-late_v1-prepare,save-restart-late_v1-resume,save-restart-legacy_test_v0-prepare,save-restart-legacy_test_v0-resume,simulation-tests,world-tests,economy-tests,hunger-tests,hunger-properties,economy-properties,transaction-tests,save-tests,save-history,save-invalid-active,save-invalid-committed,save-invalid-dead,save-boundaries,save-scene-tests,save-restart-prepare,save-restart-resume,scene-tests,strategy-tests,campaign-tests,scene-smoke,campaign-smoke}.log; then
  echo 'Godot logged an error despite process exit code.' >&2
  exit 1
fi
grep -q '"failures":0' artifacts/simulation-tests.log
grep -q '"failures":0' artifacts/scene-tests.log
grep -q 'World tests: .* assertions, 0 failures' artifacts/world-tests.log
grep -q 'Economy tests: .* assertions, 0 failures' artifacts/economy-tests.log
grep -q '"failures":0' artifacts/strategy-tests.log
grep -q '"failures":0' artifacts/transaction-tests.log
grep -q '"failures":0' artifacts/campaign-tests.log
grep -q SCENE_SMOKE_PASS artifacts/scene-smoke.log
grep -q CAMPAIGN_SMOKE_PASS artifacts/campaign-smoke.log
grep -q "INDEPENDENT_ECO_REVIEW .* assertions / 0 failures" artifacts/economy-properties.log

grep -q 'Hunger tests: .* assertions, 0 failures' artifacts/hunger-tests.log

grep -q "INDEPENDENT_HUNGER_AUDIT .* checks / 0 failures" artifacts/hunger-properties.log
grep -q 'Campaign save tests: .* assertions, 0 failures' artifacts/save-tests.log
grep -q 'Save restart prepare: .* assertions, 0 failures' artifacts/save-restart-prepare.log
grep -q 'Save restart resume: .* assertions, 0 failures' artifacts/save-restart-resume.log

grep -q "Save history tests: .* assertions, 0 failures" artifacts/save-history.log

grep -q "BOUNDARY_AUDIT .* checks 0 failures" artifacts/save-boundaries.log
grep -q '"failures":0' artifacts/save-scene-tests.log

bash tools/test_youth_runtime.sh

# World7 youth-life causal slice plus genuine World6 migrations and process restart.
bash tools/test_youth.sh
