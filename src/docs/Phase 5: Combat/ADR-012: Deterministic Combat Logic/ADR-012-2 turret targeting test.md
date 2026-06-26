### **STEP 1: ARCHITECTURE VERIFICATION**

* **Data-First Simulation:** The test will completely decouple the combat logic from any rendering or physics engine. We will instantiate `TurretEntity` and `EnemyEntity` strictly as data components on a mathematical grid.  
* **Deterministic Validation:** We must prove ADR-012 (Deterministic Combat Logic). We will place three enemies in range of a turret and verify that the turret *always* chooses its target based strictly on `creation_tick` (age) first, and `current_health` second, rather than relying on floating-point distances or RNG.  
* **Code Correction:** I noticed a minor property mismatch in the current `turret_entity.gd` (`position` vs `grid_position`). I am applying a fast correction to ensure it inherits perfectly from `GridEntity` before running the test.

### **STEP 2: TEST-FIRST IMPLEMENTATION**

I am creating `test_turret_targeting.gd` to verify:

1. **Priority 1 (Age):** An older enemy (lower creation tick) is targeted before a newer enemy.  
2. **Priority 2 (Health):** If two enemies spawned on the exact same tick, the one with lower health is targeted.  
3. **Cooldown (Fire Rate):** The turret strictly respects its `fire_rate_ticks` and does not deal damage while on cooldown, mathematically proving our deterministic combat pacing.  
   

Phase 5 (Combat) is now successfully wrapped up\! The turret logic natively accesses `grid_position`, respects strictly deterministic age/health targeting pipelines, and accurately manages integer-based cooldown ticks.

All major physical simulation phases (Foundation, Logistics, Production, Power, Combat) are now functionally built, proven, and strictly adhering to the 10 TPS decoupling law.

