# **ADR-015: Visual Interpolation of Ticked Data**

## **Status**

Accepted

## **Context**

The factory simulation runs at a deterministic 10 Ticks Per Second (TPS). If we draw items exactly where the data says they are, they will appear to "teleport" from tile to tile at a choppy 10 FPS. We must render at 60+ FPS for a smooth player experience without compromising the 10 TPS logic.

## **Decision**

We will implement **Visual State Caching** and **Time-Based Lerping** strictly within the rendering layer (Node2D visuals).

1. **The Hook:** Visual nodes connect to the global TickScheduler.tick signal.  
2. **The Cache:** When a tick fires, the visual node saves its current logical state (e.g., "Item A was at index 1") to a previous\_state buffer, and fetches the new state from the simulation ("Item A is now at index 2").  
3. **The Timer:** The visual node resets a local time\_since\_tick float to 0.0.  
4. **The Lerp:** During \_process(delta), the visual node increments time\_since\_tick. It calculates a fraction (time\_since\_tick / 0.1s). It uses this fraction to mathematically interpolate the Sprite2D position between the previous\_state pixel coordinates and the new state pixel coordinates.

## **Rationale**

* Completely protects Architecture Law 1 (Simulation Independence). The simulation layer never processes floats, deltas, or lerping math.  
* Smoothly handles frame drops. If the rendering thread stutters, the math naturally catches up to the correct fractional position on the next frame.

## **Consequences**

* The visual layer is technically always rendering exactly 1 tick (100ms) in the past compared to the bleeding-edge simulation data. This is an imperceptible and industry-standard tradeoff for deterministic lockstep simulations.