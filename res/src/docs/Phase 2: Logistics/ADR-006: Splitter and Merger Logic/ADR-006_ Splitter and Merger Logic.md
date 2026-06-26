# **ADR-006: Splitter and Merger Logic**

## **Status**

Accepted

## **Context**

Factory networks require the ability to split single item streams into multiple streams to balance production, and merge multiple streams into a single high-throughput line.

## **Decision**

We will implement a unified SplitterEntity that handles both splitting and merging via a simple set of connected input/output references.

1. **Splitting (1-to-N):** \- The splitter maintains a list of valid output\_targets.  
   * It uses a deterministic round-robin counter (\_current\_output\_index) to select the next output.  
   * If the selected output cannot accept an item (can\_accept\_item() \== false), the splitter checks the next output in the list.  
   * If all outputs are blocked, the splitter itself becomes blocked.

   

2. **Merging (N-to-1):**  
   * The splitter simply accepts items from any connected input via receive\_item().  
   * It holds a tiny internal buffer (capacity of 1).  
   * On its tick(), if it holds an item, it attempts to push it to its sole output.  
   * If multiple inputs attempt to push on the exact same tick, the order is determined by the TickScheduler's iteration order. Since the grid state is deterministic, this iteration order is also deterministic.

   

## **Rationale**

* Combining splitters and mergers into one logical entity simplifies the routing network and allows for complex n-to-m balancers using standard components.  
* Round-robin guarantees an even 50/50 split on a free-flowing belt.

## **Consequences**

* The \_current\_output\_index must be serialized in save files to guarantee perfect replay determinism.