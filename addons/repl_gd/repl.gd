extends VBoxContainer

enum OptionMenuType {
	NONE = 0,
	
	FILE,
	HELP
}

const TREE_COL: int = 0
onready var tree := $Body/State/Tree as Tree
const INITIAL_PAGE := "General"

onready var output := $Body/IO/Output as TextEdit
onready var input := $Body/IO/Input as TextEdit

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

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

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
					print_debug("Reset not yet implemented")
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

func _on_tree_item_selected(pages: Dictionary) -> void:
	var item := tree.get_selected()
	var text: String = item.get_text(tree.get_selected_column())
	
	for page in pages.values():
		page.hide()
	
	pages[text].show()

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

static func _setup_file_button(b: MenuButton) -> void:
	var popup: PopupMenu = b.get_popup()

static func _setup_help_button(b: MenuButton) -> void:
	var popup: PopupMenu = b.get_popup()

## Utility function for setting SplitContainer offsets
static func _set_half_size_split(c: SplitContainer, use_x: bool, amount: float = 0.5) -> void:
	c.split_offset = (c.rect_size.x if use_x else c.rect_size.y) * amount

## Creates `TreeItem`s for each page
##
## @param: t: Tree - The Tree to create TreeItems on
## @param: pages: Array - An Array of page names
## @param: starting_page: String - The page to initially select
static func _setup_state_menu(t: Tree, pages: Array, starting_page: String) -> void:
	var root := t.create_item()
	
	for page in pages:
		var item := t.create_item(root)
		item.set_text(TREE_COL, page)
		
		if page == starting_page:
			item.select(TREE_COL)

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
