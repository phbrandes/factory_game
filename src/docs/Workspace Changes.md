# Workspace Changes

This document summarizes the filesystem and code-layout changes made to align the project with its `res://` paths and test runner expectations.

## File Extension Migration

- Renamed all script files from `.gdscript` to `.gd`.
- Kept file contents unchanged during the extension migration.

## Source Tree Alignment

- Consolidated runtime scripts under `src/` so project preload paths resolve correctly.
- Ensured core systems live under `src/core/` with supporting folders such as:
  - `src/core/components/`
  - `src/core/resources/`
  - `src/core/combat/`
  - `src/core/progression/`
  - `src/core/config/`
- Moved UI and visual scripts into the matching runtime folders under `src/`.

## Test Layout Alignment

- Moved the centralized test runner into `tests/main_test_runner.gd`.
- Moved all `_test.gd` files into `tests/` so the runner can discover them recursively.
- Updated the tests to use `run_tests()` instead of running from `_ready()`.
- Removed global `class_name` registrations from test scripts to avoid class cache collisions.

## Code Fixes Applied During Reorganization

- Renamed `ReplaySystem.seed` to `_seed` to avoid clashing with the built-in `seed()` name.
- Removed `class_name` from `TickScheduler` to avoid conflict with the autoload singleton.
- Relaxed type annotations in `PlayerInteractionController` where they depended on global script classes that were no longer needed.
- Renamed shadowing constructor parameters such as `size` to `p_size` in several entities.

## Outcome

- Project paths now match the existing `res://src/...` and `res://tests/...` layout.
- The test runner and test scripts are organized in the documented folder structure.
- The repository is easier to navigate and less dependent on stale editor cache state.
