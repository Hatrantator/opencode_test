@tool
extends EditorPlugin

var dock

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	dock = preload("res://addons/gd_shader_lib/dock/include_browser_dock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_RIGHT_UR, dock)
	print("Godot Shader Library loaded")


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_control_from_docks(dock)
	dock.queue_free()
	print("Godot Shader Library unloaded")
