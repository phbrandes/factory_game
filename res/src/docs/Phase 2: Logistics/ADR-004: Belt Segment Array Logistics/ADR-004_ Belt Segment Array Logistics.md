# **ADR-004: Belt Segment Array Logistics**

## **Status**

Accepted

## **Context**

Phase 2 requires a logistics system capable of transporting items across the grid deterministically. Evaluating every single 1x1 belt tile individually is computationally expensive. We need a system that groups straight lines into single processing units and prevents items from overlapping or teleporting.

## **Decision**

We will implement BeltSegment, a GridEntity that contains an internal Array of size ![][image1] (representing its physical length).

1. **Array Shifting:** Items shift their index from ![][image2] to ![][image3] every tick. To process this safely without items overwriting each other, the array is iterated *backwards* (from length-2 down to 0).  
2. **Two-Phase Logistics:** When an item reaches the end of the array (length-1), the segment queries its output\_target using can\_accept\_item(). If true, it pushes the item via receive\_item().  
3. **Backpressure:** If can\_accept\_item() is false, the item at length-1 stops. The backward iteration naturally causes trailing items to stack up tightly behind it.

## **Rationale**

* **Performance:** Shifting array indices is exceptionally fast in GDScript and avoids heavy physics body evaluations.  
* **Determinism:** The backward-iteration logic mathematically guarantees that two items can never occupy the same array index simultaneously.

## **Consequences**

* **Iteration Order Variance:** If Belt A outputs to Belt B, and Belt A ticks before Belt B, the item may experience a 1-tick delay compared to Belt B ticking first. For Phase 2, this deterministically consistent delay is acceptable. If maximum throughput becomes an issue, Phase 7 optimization will introduce topological sorting for the update loop.

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABMAAAAaCAYAAABVX2cEAAABDElEQVR4XmNgGAXDFzgD8S0gfg/E/4H4IKo0GJwF4n8MEPlvQDwbVRoTbAHiewwQDZZociCQDcTLgJgJXQIdsALxGSCOYIAYthZVGgymMEB8QRDYAPFkIGYG4vtA/BeIVVBUQCxjRxPDChqB2A/KzmWAuG4aQppBCoi3I/HxggNAzAtlcwHxGwZIQItAxeKBuAjKxgv4GCCGIYMmBojr6qD85UCsi5DGDfyBuB5NTBSIvwPxKyDmBuLLqNK4ASiWrNEFgWA6A8R1c4B4EZocTnAOiFnQBRkgsQmKVZCBMWhyWIEdEJ9GF0QCoPQGMkwCXQIZuAHxAwZEFnkCxPbICqDAnAGSlUbBKBhQAADIFjDhxd8YOAAAAABJRU5ErkJggg==>

[image2]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAcAAAAaCAYAAAB7GkaWAAAAfUlEQVR4XmNgGMrAHojfAHEgugQIeAPxSSBWR5cgD7gB8XYgvgnEnsgS0kC8BYiZgfgsEK9DlswGYhsgVgDif0CcjywJA61A/AOIhdAlWID4ORAvQZcAgWAg/g/EtkCsBMQtyJL9QPwEyp4NxNpIcgwmDBBvbADiEGSJkQAA9EAS9Xxtj/4AAAAASUVORK5CYII=>

[image3]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACsAAAAaCAYAAAAue6XIAAABLUlEQVR4Xu2WTStEYRiGn8IfEKvZSImSneXIRhNZiX9hYWthObb8AFtrWSg2s9aIH0BW8rGhLAip4Xo6Ft6nY84zxzlH6r3qqum+m+nuPfWeEYlEIr9hxAZlMWADJ/q9CdzCR9N1ZRbvcckWGczgug0dTOEDHuMVPoV1dxaxjeO2yGAON2zYI0fS49i8NOQfjZ2XCsfqyRziOS6YzkNlY2t4gH14hnth7aKysatYl+SO6+Ba0IYM4wmeGi/wJiVX9abwoGOfbfgTm/iKg7ZwUNTJvtgwjX68w11bOClqrB5WJsv4IckjG8VmWGdS1Ng3G6axjddfn3dw8lvnoYixLXwXx2t7WpJrax9XTOch79ghvMRbSZ6sqv8PNNPfLIW8Y/8EvUHGbBiJRCLl8Alzt0KTnt3uywAAAABJRU5ErkJggg==>