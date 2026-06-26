# **ADR-003: Deterministic Replay System**

## **Status**

Accepted

## **Context**

To ensure bug reproducibility, cheat prevention, and perfectly consistent save states, the game requires a replay system capable of reconstructing the exact factory state from a blank slate.

## **Decision**

We will implement an Input-Log Replay System.

* The save file will primarily store the **initial random seed** and a **chronological log of player actions** (inputs), mapped to precise integer tick numbers.  
* The ReplaySystem will act as the single source of truth for all simulation RNG.  
* During load/replay, the game runs the simulation forward, injecting the logged actions at their corresponding ticks.

## **Rationale**

1. **Save File Size:** Saving 10,000 user clicks is vastly smaller than serializing 500,000 individual conveyor belt states and inventories.  
2. **Determinism Guarantee:** If the simulation logic is truly deterministic, executing the same inputs on the same ticks with the same RNG seed will mathematically guarantee identical outcomes.  
3. **Debugging:** Allows developers to step through a factory's history tick-by-tick to isolate the exact moment a bug occurred.

## **Consequences**

* **Load Times:** Late-game factories may take a few seconds to "fast-forward" through millions of ticks upon loading. If load times exceed 5 seconds, we will introduce a Phase 7 ADR for "State Snapshotting" (saving the full grid state every 100,000 ticks to serve as a fast-forward checkpoint).