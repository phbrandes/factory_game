# **ADR-014: Decoupled Rendering Bridge**

## **Status**

Accepted

## **Context**

Phase 7 requires displaying the mathematical GridManager and its simulation state on the screen using isometric art. Mixing node graphics with simulation logic violates Architecture Law 1\.

## **Decision**

We will implement an Observer pattern using Godot signals.

1. GridManager (RefCounted) broadcasts entity\_placed and entity\_removed.  
2. FactoryRenderer (Node2D) subscribes to these signals.  
3. FactoryRenderer maintains a visual dictionary mapping GridEntity references to instantiated Node2D visuals.  
4. Visuals run in \_process (60 FPS) and read state from their attached GridEntity (like progress\_ticks or held\_item) to smoothly interpolate animations between the 10 TPS simulation ticks.

## **Rationale**

* Completely protects simulation determinism. If the FactoryRenderer is destroyed or disabled, the factory continues to run flawlessly in memory.  
* Allows headless testing and server authority in the future.

## **Consequences**

* The renderer requires an Isometric TileMapLayer strictly for its map\_to\_local() math to align sprites to the diamond grid.