@tool
extends EditorPlugin
var menu: MenuButton
var save_dialog: EditorFileDialog
var mode = 0

func _enter_tree():
	menu = MenuButton.new()
	menu.text = "Goal In One"
	menu.get_popup().add_item("New level from template",0)
	menu.get_popup().add_item("Duplicate current level",1)
	menu.get_popup().id_pressed.connect(choose_path)
	add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU,menu)
	save_dialog = EditorFileDialog.new()
	save_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	save_dialog.add_filter("*.tscn", "Godot level scene")
	save_dialog.current_dir = "res://levels"
	save_dialog.file_selected.connect(create_level)
	get_editor_interface().get_base_control().add_child(save_dialog)

func _exit_tree():
	remove_control_from_container(CONTAINER_CANVAS_EDITOR_MENU,menu)
	menu.queue_free()
	save_dialog.queue_free()

func choose_path(id: int):
	mode = id
	save_dialog.current_file = "my_level.tscn"
	save_dialog.popup_centered_ratio(0.6)

func create_level(path: String):
	if FileAccess.file_exists(path):
		push_warning("Choose a new filename; existing levels are never overwritten by this tool.")
		return
	if not path.begins_with("res://levels/"):
		push_warning("Save playable levels inside res://levels/.")
		return
	var node: Node
	if mode == 1:
		var current = get_editor_interface().get_edited_scene_root()
		if not current or current.get_script() != preload("res://scripts/level.gd"):
			push_warning("Open a level scene first.")
			return
		node = current.duplicate()
	else: node = load("res://levels/starter.tscn").instantiate()
	node.level_id = "level-" + Crypto.new().generate_random_bytes(12).hex_encode()
	node.level_name = path.get_file().get_basename().capitalize()
	var scene = PackedScene.new()
	var error = scene.pack(node)
	if error == OK: error = ResourceSaver.save(scene,path)
	node.free()
	if error != OK:
		push_error("Could not save level: " + error_string(error))
		return
	get_editor_interface().get_resource_filesystem().scan()
	get_editor_interface().open_scene_from_path(path)
