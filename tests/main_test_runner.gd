extends Node

## Headless CLI & Editor Test Runner
## Discovers all *_test.gd scripts under res://tests/ and executes run_tests().
## Safely attaches Node-based tests to the SceneTree during execution.

const TESTS_DIR := "res://tests"

var _total_tests := 0
var _passed_tests := 0
var _failed_tests := 0
var _start_time := 0.0

func _ready() -> void:
	_start_time = Time.get_ticks_msec()
	print("\n==================================================")
	print("       FACTORY GAME: AUTOMATED TEST SUITE       ")
	print("==================================================\n")
	
	var test_files := _discover_test_files(TESTS_DIR)
	if test_files.is_empty():
		push_warning("Test Runner: No *_test.gd files discovered in %s" % TESTS_DIR)
		_finish_execution()
		return

	for file_path in test_files:
		# Prevent the runner from recursively executing itself
		if file_path.ends_with("main_test_runner.gd"):
			continue
			
		_execute_test_script(file_path)

	_finish_execution()

func _discover_test_files(dir_path: String) -> Array[String]:
	var discovered: Array[String] = []
	var dir := DirAccess.open(dir_path)
	
	if dir == null:
		push_error("Test Runner: Failed to open directory: " + dir_path)
		return discovered

	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with("."):
			var sub_dir_path := dir_path.path_join(file_name)
			discovered.append_array(_discover_test_files(sub_dir_path))
		elif file_name.ends_with("_test.gd"):
			discovered.append(dir_path.path_join(file_name))
			
		file_name = dir.get_next()
		
	dir.list_dir_end()
	return discovered

func _execute_test_script(script_path: String) -> void:
	print("--> Loading test suite: ", script_path)
	var script_res := load(script_path)
	
	if not script_res is Script:
		_record_failure(script_path, "Failed to load resource as Script.")
		return

	var instance: Variant = script_res.new()
	
	if not instance.has_method("run_tests"):
		_record_failure(script_path, "Script missing required public run_tests() method.")
		_safe_destroy(instance)
		return

	_total_tests += 1

	# If the test script extends Node, it must sit inside the SceneTree to function
	var is_node := instance is Node
	if is_node:
		add_child(instance)

	# Execute the suite
	instance.run_tests()
	
	_passed_tests += 1
	print("    [PASS] Suite completed successfully.\n")

	# Tear down instance synchronously
	if is_node:
		remove_child(instance)
	_safe_destroy(instance)

func _safe_destroy(instance: Variant) -> void:
	if instance is Node:
		instance.free()
	# Note: Standard GDScript test classes inherit RefCounted and auto-free themselves here.

func _record_failure(context: String, reason: String) -> void:
	_total_tests += 1
	_failed_tests += 1
	printerr("    [FAIL] %s | Reason: %s\n" % [context, reason])

func _finish_execution() -> void:
	var duration_ms := Time.get_ticks_msec() - _start_time
	print("==================================================")
	print("               EXECUTION SUMMARY                  ")
	print("==================================================")
	print(" Total Suites : ", _total_tests)
	print(" Passed       : ", _passed_tests)
	print(" Failed       : ", _failed_tests)
	print(" Time Elapsed : %.2f ms" % duration_ms)
	print("==================================================\n")

	var exit_code := 0 if _failed_tests == 0 else 1
	
	if Engine.is_editor_hint():
		# In the editor, we can't exit the process, but we can log the result
		if exit_code == 0:
			print("All tests passed successfully.")
		else:
			push_error("%d test suite(s) failed." % _failed_tests)
	else:
		# In headless mode, we can exit with a code
		get_tree().quit(exit_code)