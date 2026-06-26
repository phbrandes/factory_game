# **ADR-011: Combat Flow Fields**

## **Status**

Accepted

## **Context**

Phase 5 introduces enemy units. Pathfinding for dozens or hundreds of enemies individually (A\*) would be computationally prohibitive at 10 TPS. We need a performant, scalable approach.

## **Decision**

We will implement a FlowField system.

1. **Distance Field:** A BFS traversal starting from the "Player Core" tile maps the shortest distance (in tiles) to every reachable grid tile.  
2. **Direction Field:** A secondary pass converts these distances into unit vectors pointing from each tile to its lowest-neighbor-distance tile.  
3. **Unit Logic:** Enemy units only need to read the direction vector of the tile they occupy to move toward the core.

## **Rationale**

* O(N) complexity (where N is grid tiles) regardless of enemy count.  
* Perfectly deterministic: BFS order is controlled by grid coordinate iteration.  
* Dynamically updates as the player adds/removes buildings (which act as obstacles).

## **Consequences**

* The grid must be re-calculated only when the topology changes (building placement/destruction), not every frame.