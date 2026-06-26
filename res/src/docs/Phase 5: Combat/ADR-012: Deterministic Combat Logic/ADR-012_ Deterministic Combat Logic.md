# **ADR-012: Deterministic Combat Logic**

## **Status**

Accepted

## **Context**

Combat must be as deterministic as logistics. Turret targeting and enemy behavior often involve "choosing" between multiple valid targets or paths. If this choice relies on non-deterministic data, replays will diverge.

## **Decision**

1. **Targeting Stability:** Turrets and enemies will not use RandomNumberGenerator for targeting. They will target based on:  
   * Priority 1: Oldest entity\_id (the entity that has existed for the most ticks).  
   * Priority 2: Lowest current\_health.  
   * Priority 3: Distance from the core (as defined by the FlowField distance field).  
2. **Combat Resolution:** All damage, armor, and regeneration calculations will be handled as integers.  
3. **Movement:** Enemies do not "steer" with physics. They teleport-move by 1 tile index toward their FlowField vector at a defined "speed" (ticks per tile).

## **Rationale**

* Sorting targets by stable IDs ensures that if two enemies are identical in distance/health, the decision is still identical every time the turret scans.  
* Integer-only combat avoids the "float-rounding" bug entirely.

## **Consequences**

* Every entity must track its creation\_tick.