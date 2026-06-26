# **ADR-005: Directional Constants and Auto-Routing**

## **Status**

Accepted

## **Context**

Players need to build continuous conveyor lines by dragging the cursor. The system must automatically detect adjacent conveyor segments and link their output\_target references based on their placement orientation.

## **Decision**

1. **Direction Enums/Constants:** We establish a universal mapping of 4-way direction vectors (North, South, East, West) in GridDirection.  
2. **Auto-Routing Rules:** When a new BeltSegment is placed:  
   * It looks at the tile strictly ![][image1] unit ahead in its facing\_direction.  
   * If an entity exists, and that entity has\_method("receive\_item"), and is not facing the opposite direction, the new segment links its output\_target to it.  
   * It also checks the tile ![][image1] unit behind its tail. If a belt there is pointing at the new segment, the previous belt's output\_target updates to point at the new segment.

## **Rationale**

* Standardizing direction vectors as Vector2i guarantees integer-perfect grid lookups.  
* By looking one tile ahead and one tile behind on placement, we avoid iterating over the entire grid to recalculate networks.

## **Consequences**

* Complex merge scenarios (e.g., three belts pushing into one tile) will be handled by a dedicated Splitter/Merger entity in later Phase 2 milestones, rather than simple belt-to-belt auto-routing.

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAaCAYAAACO5M0mAAAAaElEQVR4XmNgGLpAHl0AGXABsRUQbwLiLWhycJAJxK+AeCsQ/2HAoxAZ/GAYZgpBvicISFK4HV0QGwAp3IEuiA2AFO5EF0QHLED8E4gPokvAgDcQ3wXi90D8H4pfAPEdIBZEUjcKsAMAhiUd8FGUIDsAAAAASUVORK5CYII=>