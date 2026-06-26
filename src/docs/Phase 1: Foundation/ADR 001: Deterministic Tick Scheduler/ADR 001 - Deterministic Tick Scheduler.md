# **ADR 001: Deterministic Tick Scheduler**

## **Status**

Accepted

## **Context**

Phase 1 requires a 10 TPS deterministic simulation loop to ensure replays and factory math remain consistent regardless of frame rate fluctuations. Relying on Godot's \_process(delta) or \_physics\_process(delta) directly within factory nodes violates the Data-First Architecture and introduces floating-point non-determinism.

## **Decision**

We will implement a centralized TickScheduler (Autoload Node).

1. It will be the **only** script in the simulation domain allowed to read \_process(delta).  
2. It will accumulate time and emit discrete tick events (tick\_started, tick\_completed) and call tick(tick\_number) on registered subscribers.  
3. It will expose a manual ticking API to allow the Replay System to drive the game loop independent of wall-clock time.

## **Consequences**

* **Positive:** Complete decoupling of visual frame rate from factory logic. Perfect determinism. Highly testable.  
* **Negative:** Developers must remember to register simulation objects with the scheduler rather than relying on Godot's built-in tree callbacks.