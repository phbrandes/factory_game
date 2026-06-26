# **ADR-016: Player Input to Deterministic Action Bridge**

## **Status**

Accepted

## **Context**

Phase 7 requires a way for players to interact with the world (placing buildings, drawing belts). Human input occurs at arbitrary times during the 60 FPS render loop, which threatens the 10 TPS deterministic simulation if applied instantly.

## **Decision**

We will implement a PlayerInteractionController that acts as the gateway between the hardware and the simulation.

1. **Grid Snapping:** The controller uses the TileMapLayer's local\_to\_map() function to convert free-floating mouse pixels into strict Vector2i integers.  
2. **Replay Logging:** Before placing an entity, the controller queries the TickScheduler for the current tick\_number. It packages the action (e.g., "place\_belt", Coordinate X, Coordinate Y) and sends it to the ReplaySystem.  
3. **Execution:** The action is then immediately passed to the GridManager to execute the data modification.  
4. **UI Decoupling:** Build selection is handled by a separate RadialMenu UI Control node that emits signals, preventing the interaction controller from becoming a God Object.

## **Rationale**

* Satisfies Architecture Law 1\. The input layer depends on the simulation layer, but the simulation layer remains completely unaware of mice, screens, or UI nodes.  
* Preserves perfectly synchronized replays by forcing arbitrary inputs into strictly logged integer ticks.

## **Consequences**

* The PlayerInteractionController requires references to GridManager, ReplaySystem, TickScheduler, and a visual TileMapLayer to function.