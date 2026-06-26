# **ADR-007: Deterministic Crafting Cycle**

## **Status**

Accepted

## **Context**

Production entities (Furnaces, Assemblers) need to transform inputs into outputs over time. This process must be immune to framerate drops, completely deterministic for replays, and properly handle logistics backpressure.

## **Decision**

1. **Tick-Based Recipes:** All RecipeResource time costs are defined in ticks\_to\_craft (int) rather than seconds (float). At a simulation rate of 10 TPS, a 5-second craft takes 50 ticks.  
2. **State Machine Component:** CraftingComponent manages the cycle across three distinct states:  
   * IDLE: Waiting for sufficient items in the input InventoryComponent.  
   * CRAFTING: Inputs consumed. Progressing tick counter.  
   * STALLED: Ticks complete, but output InventoryComponent is full. Waits indefinitely without losing the crafted items.  
3. **Upfront Consumption:** Inputs are consumed from the input inventory at tick 0 of the crafting cycle to prevent them from being extracted by other logistical systems while a craft is processing.

## **Rationale**

* Using strictly integer tick counting guarantees identical outcomes across platforms and replay files.  
* The STALLED state elegantly handles backpressure, preventing factory deadlocks or items "popping" out of existence when lines back up.

## **Consequences**

* Recipe design must be mathematically divisible by the 10 TPS rate.