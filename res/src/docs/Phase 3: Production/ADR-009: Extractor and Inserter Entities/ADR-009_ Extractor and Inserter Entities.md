# **ADR-009: Extractor and Inserter Entities**

## **Status**

Accepted

## **Context**

Phase 3 requires a dedicated mechanism to move items between production/storage entities and conveyor belts. Rather than machines auto-ejecting, a dedicated bridging entity (Inserter/Extractor) provides granular player control over throughput and sorting.

## **Decision**

We will implement an ExtractorEntity that acts as a bridge between a specific source\_pos and target\_pos.

1. **State Machine:** The extractor operates in a loop:  
   * WAITING\_FOR\_SOURCE: Polling source for an available item.  
   * EXTRACTING: Item grabbed. Taking ![][image1] ticks to swing to target.  
   * WAITING\_FOR\_TARGET: Swing complete. Polling target to see if it can accept the item.  
   * INSERTING: Item deposited. Taking ![][image1] ticks to swing back to source.  
2. **Strict Adherence to Two-Phase Logistics:** Items are officially extract\_item()'d from the source at the start of the EXTRACTING phase and held in an internal buffer. They are receive\_item()'d into the target at the start of the INSERTING phase.

## **Rationale**

* Decouples machine output logic from conveyor logic.  
* Creates a new layer of optimization (throughput limits based on extractor speed).  
* The internal state machine handles source starvation and target backpressure gracefully.

## **Consequences**

* Extractors must correctly identify their source and target entities via the GridManager when placed or updated.

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABMAAAAaCAYAAABVX2cEAAABDElEQVR4XmNgGAXDFzgD8S0gfg/E/4H4IKo0GJwF4n8MEPlvQDwbVRoTbAHiewwQDZZociCQDcTLgJgJXQIdsALxGSCOYIAYthZVGgymMEB8QRDYAPFkIGYG4vtA/BeIVVBUQCxjRxPDChqB2A/KzmWAuG4aQppBCoi3I/HxggNAzAtlcwHxGwZIQItAxeKBuAjKxgv4GCCGIYMmBojr6qD85UCsi5DGDfyBuB5NTBSIvwPxKyDmBuLLqNK4ASiWrNEFgWA6A8R1c4B4EZocTnAOiFnQBRkgsQmKVZCBMWhyWIEdEJ9GF0QCoPQGMkwCXQIZuAHxAwZEFnkCxPbICqDAnAGSlUbBKBhQAADIFjDhxd8YOAAAAABJRU5ErkJggg==>