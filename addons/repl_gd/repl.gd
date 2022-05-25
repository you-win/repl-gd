extends VBoxContainer

class Env:
	const AdvExp := preload("res://addons/advanced-expression/advanced_expression.gd")
	
	const BUILTIN_VARS := {}
	
	## Variables to be injected into the script on each run
	## @type: Dictionary<String, Variant>
	var variables := {}
	## User-defined functions to be injected into the script on each run
	## @type: Dictionary<String, String>
	var functions := {}
	## The scene tree to use in the script on each run
	var scene_tree: SceneTree
	
	func _init() -> void:
		scene_tree = SceneTree.new()
		scene_tree.multiplayer_poll = false
		
		BUILTIN_VARS["__stored_vars__"] = variables
		BUILTIN_VARS["__tree__"] = scene_tree
	
	func apply_to_expression(ae: AdvExp) -> int:
		ae.add_function("__store_var__") \
			.add_param("name") \
			.add_param("value") \
			.add("__stored_vars__[name] = value")
		
		#region Node funcs
		
		ae.add_function("add_child") \
			.add_param("node") \
			.add_param("legible_unique_name = false") \
			.add("__tree__.root.add_child(node, legible_unique_name)")
		
		ae.add_function("add_child_below_node") \
			.add_param("node") \
			.add_param("child_node") \
			.add_param("legible_unique_name = false") \
			.add("__tree__.root.add_child_below_node(node, child_node, legible_unique_name)")

		ae.add_function("add_to_group") \
			.add_param("group") \
			.add_param("persistent = false") \
			.add("__tree__.root.add_to_group(group, persistent)")

		ae.add_function("find_node") \
			.add_param("mask") \
			.add_param("recursive = true") \
			.add_param("owned = true") \
			.add("return __tree__.root.find_node(mask, recursive, owned)")

		ae.add_function("get_child") \
			.add_param("idx") \
			.add("return __tree__.root.get_child(idx)")

		ae.add_function("get_child_count").add("return __tree__.root.get_child_count()")

		ae.add_function("get_children").add("return __tree__.root.get_children()")

		ae.add_function("get_groups").add("return __tree__.root.get_groups()")

		ae.add_function("get_node") \
			.add_param("path") \
			.add("return __tree__.root.get_node(path)")

		ae.add_function("get_node_and_resource") \
			.add_param("path") \
			.add("return __tree__.root.get_node_and_resource(path)")

		ae.add_function("get_node_or_null") \
			.add_param("path") \
			.add("return __tree__.root.get_node_or_null(path)")

		ae.add_function("get_path_to") \
			.add_param("node") \
			.add("return __tree__.root.get_path_to(node)")

		ae.add_function("get_parent").add("return __tree__.root")

		ae.add_function("get_tree").add("return __tree__")

		ae.add_function("move_child") \
			.add_param("child_node") \
			.add_param("to_position") \
			.add("__tree__.root.move_child(child_node, to_position)")

		ae.add_function("print_stray_nodes").add("__tree__.root.print_stray_nodes()")

		ae.add_function("print_tree").add("__tree__.root.print_tree()")

		ae.add_function("print_tree_pretty").add("__tree__.root.print_tree_pretty()")
		
		ae.add_function("remove_child") \
			.add_param("node") \
			.add("__tree__.root.remove_child(node)")
		
		#endregion
		
		for val in functions.values():
			ae.add_raw(val)
		
		# Must be done _before_ compiling the script
		for dict in [BUILTIN_VARS, variables]:
			for key in dict.keys():
				ae.add_variable(key, "null")
		
		var err: int = ae.compile()
		if err != OK:
			return err
		
		# Must be done _after_ compiling the script
		for dict in [BUILTIN_VARS, variables]:
			err = ae.inject_variables(dict)
			if err != OK:
				return err
		
		return OK

var env := Env.new()

const AdvExp := preload("res://addons/advanced-expression/advanced_expression.gd")

enum OptionMenuType {
	NONE = 0,
	
	FILE,
	HELP
}

const TREE_COL: int = 0
onready var tree := $Body/State/Tree as Tree
const INITIAL_PAGE := "General"

onready var output := $Body/IO/Output as TextEdit
onready var input := $Body/IO/Inputs/Input as TextEdit

const MAX_HISTORY: int = 100
var history_pointer: int = 0
var history := []

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	pass

func _ready() -> void:
	var file_popup: PopupMenu = $Options/File.get_popup()
	file_popup.add_item("Save")
	file_popup.add_item("Save as")
	file_popup.add_item("Load gdscript")
	file_popup.add_separator()
	file_popup.add_item("Reset")
	if not Engine.editor_hint:
		file_popup.add_separator()
		file_popup.add_item("Quit")
	file_popup.connect("index_pressed", self, "_on_popup_index_pressed",
		[OptionMenuType.FILE, file_popup])
	
	var help_popup: PopupMenu = $Options/Help.get_popup()
	help_popup.add_item("GitHub repo")
	help_popup.add_item("About")
	help_popup.connect("index_pressed", self, "_on_popup_index_pressed",
		[OptionMenuType.HELP, help_popup])
	
	var pages := {}
	var state_container := $Body/State as VSplitContainer
	for c in state_container.get_children():
		if c is Tree:
			continue
		
		pages[c.name] = c
	
	var root := tree.create_item()
	for page in pages.keys():
		var item := tree.create_item(root)
		item.set_text(TREE_COL, page)
		
		if page == INITIAL_PAGE:
			item.select(TREE_COL)
	
	tree.connect("item_selected", self, "_on_tree_item_selected", [pages])
	
	_set_half_size_split(state_container, false)
	_set_half_size_split($Body, true, 0.3)
	_set_half_size_split($Body/IO, false, 0.7)
	
	input.connect("gui_input", self, "_on_input_gui_input")
	$Body/IO/Inputs/Send.connect("pressed", self, "_on_input_submit")
	
	output.text = "%s\nReady\n" % _current_time()

func _exit_tree() -> void:
	if env != null:
		env.scene_tree.free()

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

## Mega handler for menu buttons
func _on_popup_index_pressed(index: int, menu_id: int, popup: PopupMenu) -> void:
	var text: String = popup.get_item_text(index)
	
	match menu_id:
		OptionMenuType.FILE:
			match text:
				"Save":
					print_debug("Save not yet implemented")
				"Save as":
					print_debug("Save as not yet implemented")
				"Load gdscript":
					print_debug("Load gdscript not yet implemented")
				"Reset":
					_reset_repl()
				"Quit":
					get_tree().quit()
				_:
					printerr("Unhandled option %s" % text)
		OptionMenuType.HELP:
			match text:
				"GitHub repo":
					OS.shell_open("https://github.com/you-win/repl-gd")
				"About":
					print_debug("About not yet implemented")
				_:
					printerr("Unhandled option %s" % text)
		_:
			printerr("Unhandled menu button %s" % OptionMenuType.keys()[menu_id])

## Callback for hiding and showing pages
func _on_tree_item_selected(pages: Dictionary) -> void:
	var item := tree.get_selected()
	var text: String = item.get_text(tree.get_selected_column())
	
	for page in pages.values():
		page.hide()
	
	pages[text].show()

func _on_input_gui_input(ie: InputEvent) -> void:
	if not ie is InputEventKey:
		return
	if not ie.pressed:
		return
	
	if ie.control:
		match ie.scancode:
			KEY_ENTER: # Submit code
				input.text = input.text.trim_suffix("\n")
				_on_input_submit()
			KEY_UP: # Previous history
				history_pointer -= 1
				if history_pointer >= 0:
					_set_from_history()
				else:
					history_pointer += 1
			KEY_DOWN: # Next history
				history_pointer += 1
				if history_pointer < history.size():
					_set_from_history()
				elif history_pointer == history.size():
					input.text = ""
				else:
					history_pointer -= 1

func _on_input_submit() -> void:
	if input.text.strip_edges().empty():
		return
	
	_add_history(input.text)
	
	_add_output(input.text)
	
	var ae := AdvExp.new()
	
	var code: PoolStringArray = input.text.split("\n")
	if code.size() == 1:
		match code[0]:
			"exit":
				if not Engine.editor_hint:
					get_tree().quit()
				else:
					_add_output("Ignoring `exit` in editor plugin")
					_clear_input()
				return
			"reset":
				_reset_repl()
				_add_output("REPL state reset")
				_clear_input()
				return
			"clear":
				output.text = ""
				_clear_input()
				return
			_:
				# Single line commands are still valid gdscript snippets
				for i in code:
					ae.add(i)
	else:
		if code[0].begins_with("func"):
			var func_header: PoolStringArray = code[0].split(" ", false, 1)
			if func_header.size() < 2:
				_add_output("Invalid function definition")
				_clear_input()
				return
			var func_name: PoolStringArray = func_header[1].split("(", false, 1)
			if func_name.size() < 2:
				_add_output("Invalid function definition")
				_clear_input()
				return
			env.functions[func_name[0]] = code.join("\n")
			ae.add("pass")
		else:
			for i in code:
				ae.add(i)
	
	if env.apply_to_expression(ae) != OK:
		_add_output("Invalid input")
		output.scroll_vertical = output.get_line_count()
		return
	
	var res = ae.execute()
	
	_add_output(str(res) if res else "null")
	_clear_input()

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

static func _current_time() -> String:
	var time: Dictionary = OS.get_time()
	
	return "[%02d:%02d:%02d]" % [time.hour, time.minute, time.second]

## Utility function for setting SplitContainer offsets
static func _set_half_size_split(c: SplitContainer, use_x: bool, amount: float = 0.5) -> void:
	c.split_offset = (c.rect_size.x if use_x else c.rect_size.y) * amount

func _add_output(text: String) -> void:
	output.text += "\n%s\n%s\n" % [_current_time(), text]

## Resets the env for the REPL
func _reset_repl() -> void:
	if env != null:
		env.scene_tree.free()
	env = Env.new()

## Clears REPL input and scrolls output to the last line
func _clear_input() -> void:
	input.text = ""
	output.scroll_vertical = output.get_line_count()

func _add_history(text: String) -> void:
	history.push_back(text)
	if history.size() > MAX_HISTORY:
		history.pop_front()
	
	history_pointer = history.size()

func _set_from_history() -> void:
	input.text = history[history_pointer]
	input.cursor_set_column(input.get_line(input.cursor_get_line()).length())

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
