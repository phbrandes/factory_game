# **ADR-010: Deterministic Power Grid**

## **Status**

Accepted

## **Context**

Phase 4 requires a system to simulate energy generation and consumption. Calculating power as a global percentage (e.g., 85% satisfaction \= machines run 15% slower) relies on floating-point math, which introduces severe risks to replay determinism due to hardware-level rounding differences.

## **Decision**

We will implement an **Integer Buffer Distribution System**.

1. **Components:** PowerGeneratorComponent (produces flat integer energy) and PowerConsumerComponent (holds an internal energy buffer).  
2. **The Network:** A PowerNetwork pools all generated energy each tick.  
3. **Distribution:** The network iterates through registered consumers deterministically (by array index) and transfers energy from the pool to fill their internal buffers.  
4. **Consumption:** When a machine attempts to tick (e.g., a CraftingComponent processing an item), it queries its PowerConsumerComponent. If the buffer contains at least drain\_per\_tick energy, the energy is subtracted, and the machine ticks. If not, it stalls.

## **Rationale**

* Completely eliminates floating-point math from the simulation layer.  
* Naturally simulates "brownouts." If a network produces 50 energy but 2 machines need 50 energy each, they will essentially take turns operating every other tick as their buffers fill up, maintaining a perfectly deterministic progression.

## **Consequences**

* Network merge/split logic (when power poles are placed or destroyed) must reliably preserve the deterministic array order of consumers.