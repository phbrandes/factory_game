extends Node

## Standalone test runner for ProgressionManager and ResearchEntity logic.

const TechResourceRef = preload("res://src/core/resources/tech_resource.gd")
const ProgressionManagerRef = preload("res://src/core/progression/progression_manager.gd")
const ResearchEntityRef = preload("res://src/core/progression/research_entity.gd")

func run_tests() -> void:
	print("Running Progression System Tests...")
	
	_test_dependencies()
	_test_research_entity_consumption()
	_test_item_rejection()
	
	print("All Progression System tests passed.")

func _test_dependencies() -> void:
	var prog = ProgressionManagerRef.new()
	
	var tech_basic = TechResourceRef.new("automation", [], {"red_science": 10}, ["recipe_assembler"])
	var tech_adv = TechResourceRef.new("logistics", ["automation"], {"red_science": 20}, ["recipe_splitter"])
	
	assert(prog.set_active_research(tech_adv) == false, "Allowed setting research without meeting prerequisites.")
	assert(prog.set_active_research(tech_basic) == true, "Failed to set valid base research.")

func _test_research_entity_consumption() -> void:
	var prog = ProgressionManagerRef.new()
	# Tech requires 2 red science
	var tech = TechResourceRef.new("optics", [], {"red_science": 2}, ["recipe_lamp"])
	prog.set_active_research(tech)
	
	var lab = ResearchEntityRef.new("lab_1", prog, 10)
	
	# Push 2 science packs into the lab via logistics
	assert(lab.can_accept_item("red_science") == true, "Lab rejected needed science.")
	lab.receive_item("red_science")
	lab.receive_item("red_science")
	
	# Tick 1: Consumes 1 pack
	lab.tick()
	assert(prog.research_progress["red_science"] == 1, "Lab failed to advance progress.")
	assert(prog.is_unlocked("optics") == false, "Tech unlocked prematurely.")
	
	# Tick 2: Consumes 2nd pack
	lab.tick()
	assert(prog.is_unlocked("optics") == true, "Tech failed to unlock after costs met.")
	assert(prog.active_research == null, "Active research didn't clear after completion.")

func _test_item_rejection() -> void:
	var prog = ProgressionManagerRef.new()
	var tech = TechResourceRef.new("steel", [], {"red_science": 1}, ["recipe_steel"])
	prog.set_active_research(tech)
	
	var lab = ResearchEntityRef.new("lab_1", prog, 10)
	
	# Try pushing blue science (which is NOT required)
	assert(lab.can_accept_item("blue_science") == false, "Lab accepted an unneeded item type.")
	assert(lab.receive_item("blue_science") == false, "Lab logistics failed to block unneeded item.")