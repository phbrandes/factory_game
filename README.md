# factory_game

[![Godot](https://img.shields.io/badge/Godot-4.7-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![Project](https://img.shields.io/badge/Project-factory__game-2f855a)](https://github.com/phbrandes/factory_game)
[![Tests](https://img.shields.io/badge/tests-centralized%20runner-8b5cf6)](https://github.com/phbrandes/factory_game/tree/main/tests)

Godot 4.x factory automation roguelike focused on deterministic simulation, replayability, and testable data-first gameplay systems.

## Overview

The project is built around a strict separation between simulation and rendering:

- Simulation lives in `src/core/` and related data-oriented folders.
- Rendering and UI live in `src/visuals/`, `src/ui/`, and `src/controllers/`.
- Automated tests live in `tests/` and are discovered by the central test runner.
- Design and roadmap notes live in `src/docs/`.

## Repository Layout

```text
project.godot        Godot project configuration
src/                 Runtime game code
    core/              Simulation, entities, components, config, resources
    controllers/       Input and interaction bridges
    ui/                UI scenes and controls
    visuals/           Rendering and visual presentation
    docs/              Project documentation and ADRs
tests/               Automated test scripts
res/                 Legacy duplicate tree to ignore in favor of top-level src/ and tests/
```

The top-level `src/` and `tests/` folders are the canonical locations for runtime code and tests.

## Quick Start

1. Open the repository folder in Godot 4.7.
2. Use `project.godot` as the project root.
3. Inspect the design docs under `src/docs/factory_game_production_docs/`.
4. Run the automated tests through `tests/main_test_runner.gd`.
5. Keep new runtime code in `src/` and new tests in `tests/`.

## Core Principles

- Deterministic simulation driven by `TickScheduler`.
- Data-first architecture with simulation isolated from rendering.
- No random gameplay logic without a seeded `RandomNumberGenerator`.
- Tests should be deterministic and reproducible.
- Prefer composition over deep inheritance.

## Features

Current project focus:

- Deterministic tick-driven simulation.
- Replay system support for reproducible runs.
- Grid-based world and entity placement.
- Logistics and production systems under active development.
- Automated test coverage for core simulation behavior.

## Roadmap

The project roadmap is organized into phases:

1. Foundation: grid, tick scheduler, replay system, save system.
2. Logistics: conveyors, splitters, storage.
3. Production: miners, furnaces, assemblers.
4. Power: power grid and consumption simulation.
5. Combat: flow fields, swarms, turrets.
6. Progression: unlock tree and meta progression.
7. Polish: UX, art pass, optimization.

## Running the Game

The repository currently focuses on simulation and test development. Open the project in Godot and use the editor workflow or a scene you add locally when running gameplay code.

## Running Tests

Use `tests/main_test_runner.gd` as the entry point for the automated test suite.

1. Open `tests/main_test_runner.gd` in the Godot editor.
2. Run the scene/script from the editor.
3. The runner recursively loads all `*_test.gd` files under `tests/` and calls `run_tests()` on each one.

Test scripts should follow the naming convention `*_test.gd` and expose a public `run_tests()` method.

## Contributing

- Keep runtime scripts in `src/`.
- Keep tests in `tests/`.
- Use the docs under `src/docs/` as the source of truth for architecture and roadmap decisions.
- Avoid reintroducing files under the legacy nested `res/` tree.
- Prefer preload references for shared scripts when global `class_name` registration would collide.

## Documentation

The main design and workflow references live in `src/docs/factory_game_production_docs/`:

- `01_SYSTEM_PROMPT.md`
- `02_GAME_DESIGN_DOCUMENT.md`
- `03_ART_BIBLE.md`
- `04_ROADMAP.md`
- `05_ASSET_PIPELINE.md`

Additional architecture notes and ADRs are stored under `src/docs/Phase 1: Foundation/` and later phase folders.

## Development Notes

- Keep runtime scripts under `src/`.
- Keep tests under `tests/`.
- Avoid adding new work to the legacy nested `res/` tree.
- Prefer preload-based references for shared scripts when a global `class_name` would cause collisions.
