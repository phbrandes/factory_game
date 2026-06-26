# **ADR-013: Progression and Tech Tree**

## **Status**

Accepted

## **Context**

Phase 6 introduces a technology tree to gate content and provide long-term goals. The player must automate the production of specific "science/research" items and route them into laboratories to unlock new recipes and buildings.

## **Decision**

1. **TechResource:** A Godot Resource that defines a single technology. It contains an ID, an array of prerequisite Tech IDs, a dictionary of required items (cost), and an array of unlocked recipe IDs.  
2. **ProgressionManager:** A RefCounted state machine that tracks unlocked\_techs, the active\_research resource, and the current integer research\_progress.  
3. **ResearchEntity:** A GridEntity that acts as a laboratory. It connects to the grid's logistics network. It queries the ProgressionManager to see what items are currently needed. If an incoming item matches the requirement, it accepts it. On its tick(), it consumes buffered items and adds progress to the ProgressionManager.

## **Rationale**

* Decoupling the ProgressionManager (state) from TechResource (data) allows designers to easily build vast tech trees in the Godot Inspector without touching code.  
* Using GridEntity for the lab ensures research relies on the deterministic factory logistics and power grids established in earlier phases.

## **Consequences**

* The ProgressionManager state (unlocked\_techs, active\_research\_id, research\_progress) must be serialized into the master save file.  
* ResearchEntity instances require a reference to the ProgressionManager upon instantiation to know what to research.