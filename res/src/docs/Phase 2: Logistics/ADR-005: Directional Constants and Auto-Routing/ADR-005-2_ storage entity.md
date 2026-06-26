### **STEP 1: ARCHITECTURE VERIFICATION**

* **Data-First Simulation:** `StorageEntity` will be a pure data class extending `GridEntity`. It will contain a fixed-size `InventoryComponent` to hold items.  
* **Deterministic Logistics:** It must implement `can_accept_item()` and `receive_item()` to cleanly terminate a conveyor network, adhering to the Two-Phase Logistics Law. It will act as a buffer/sink.  
* **ADR Update:** No new ADR is strictly required for basic storage as it follows the existing `GridEntity` and Two-Phase Logistics patterns established in ADR-002 and ADR-004. We will document its component usage.

### **STEP 2: TEST-FIRST IMPLEMENTATION**

I am creating `test_storage_entity.gd` to verify:

1. **Capacity Constraints:** The storage must accept items up to its maximum capacity and accurately report `can_accept_item()` as `false` when full.  
2. **Network Termination:** A `BeltSegment` must be able to successfully push items into the `StorageEntity`, and those items must be removed from the belt.

