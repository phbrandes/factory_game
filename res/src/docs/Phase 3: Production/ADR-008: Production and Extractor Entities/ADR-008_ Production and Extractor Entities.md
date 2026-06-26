# **ADR-008: Production and Extractor Entities**

## **Status**

Accepted

## **Context**

Phase 3 requires tangible entities to place on the grid that produce and consume resources. We need to distinguish between standard assemblers (which consume items to make new items) and miners (which generate items "from nothing" based on the grid tile they are placed upon).

## **Decision**

1. **ProductionEntity:** A generic machine (Furnace, Assembler) that uses composition. It holds an input\_inventory, an output\_inventory, and a CraftingComponent linking them. It implements receive\_item to route incoming logistics to the input inventory.  
2. **MinerEntity:** A specialized machine that acts as a resource source. It holds only an output\_inventory and a CraftingComponent.  
3. **Infinite Mining via Null-Input Recipes:** Instead of building a custom "MiningComponent", we reuse CraftingComponent. A miner is simply assigned a RecipeResource where inputs is empty {} and outputs contains the mined resource. The CraftingComponent naturally sees "no inputs required" and continuously crafts the output.

## **Rationale**

* Maximizes code reuse. The complex backpressure logic built in ADR-007 naturally applies to miners without writing custom logic.  
* Avoids creating "God Object" buildings. An Assembler is just a generic ProductionEntity given an Assembler recipe.

## **Consequences**

* Miners must have their recipe assigned by the GridManager or placement logic based on the geological resource patch they are placed upon.