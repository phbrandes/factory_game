extends Node

## MainTestRunner.gd
## Dynamically discovers and executes all scripts ending in "_test.gd" within the tests folder.

func _ready() -> void:
	print("--- Starting Full Project Test Suite ---")
	run_all_tests("res://tests/")
	print("--- All tests finished. Quitting. ---")
	get_tree().quit()

func run_all_tests(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		push_error("Could not open tests directory: " + path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				run_all_tests(path + file_name + "/")
		elif file_name.ends_with("_test.gd"):
			execute_test_file(path + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

func execute_test_file(file_path: String) -> void:
	print("Executing: " + file_path)
	var test_script = load(file_path)
	var test_instance = test_script.new()
	add_child(test_instance)
	
	# Assuming every test script implements a 'run_tests' function
	# If you want to keep your current _ready() approach, 
	# just ensure your test files handle their own logic.
	if test_instance.has_method("run_tests"):
		test_instance.run_tests()
	
	remove_child(test_instance)
	test_instance.queue_free()