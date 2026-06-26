updating the `ProductionEntity` and `test_production_entities.gd` to enforce power consumption during crafting

### **STEP 1: ARCHITECTURE VERIFICATION**

* **Logic Integration:** To enforce power consumption, the `ProductionEntity` must query its `PowerConsumerComponent` during the `tick()` phase.  
* **Gateway Logic:** The `CraftingComponent`’s `_process_craft()` method currently updates `progress_ticks` unconditionally. I will modify the `ProductionEntity` to only call `crafter.tick()` if `power_consumer.try_consume()` returns `true`.  
* **Dependency Injection:** The `ProductionEntity` will now take an optional `PowerConsumerComponent` in its constructor. If `null`, it operates without power (e.g., manual/early-game machines).  
* **ADR Update:** `ADR-007` (Crafting Logic) is updated to reflect that `ProductionEntity` acts as a power gateway for the `CraftingComponent`.

### **STEP 2: TEST-FIRST IMPLEMENTATION**

I am creating `test_powered_production.gd` to verify:

1. **Powered Crafting:** Machine consumes power and crafts successfully when power is available.  
2. **Brownout Stalling:** If power consumption fails (`try_consume()` returns false), the `CraftingComponent` must **not** increment its `progress_ticks`, effectively pausing the machine.  
3. **Resumption:** Machine resumes crafting exactly where it left off once power is restored.