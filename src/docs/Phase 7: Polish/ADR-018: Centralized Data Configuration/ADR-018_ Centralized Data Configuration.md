# **ADR-018: Centralized Data Configuration**

## **Status**

Accepted

## **Context**

As the game expands in Phase 7, hardcoding entity stats (health, crafting speed, inventory capacity) inside scripts becomes unmaintainable and violates the initialization prompt constraints. We need a centralized way for designers to balance the game without touching code.

## **Decision**

We will implement a GameConfigRegistry that loads all balance data from JSON files.

1. **JSON Format:** JSON is natively supported by Godot, lightweight, and easily editable by external tools or designers.  
2. **Schema:** The master JSON contains top-level keys like recipes, entities, and tech\_tree.  
3. **Data Injection:** When a factory pattern instantiates a ProductionEntity (e.g., a "furnace\_t1"), it queries the GameConfigRegistry for the configuration dictionary mapped to "furnace\_t1" and uses those values to initialize its internal InventoryComponent and HealthComponent.

## **Rationale**

* Completely eliminates hardcoded magic numbers from the codebase.  
* Sets the foundation for modding support later.  
* Guarantees consistent initialization across the entire grid.

## **Consequences**

* The Registry must be fully loaded and parsed before the TickScheduler or GridManager are allowed to begin their simulation loops.