extends CanvasLayer

var show_repl := true
var debug_console: CanvasLayer

#-----------------------------------------------------------------------------#
# Builtin functions                                                           #
#-----------------------------------------------------------------------------#

func _init() -> void:
	OS.center_window()

func _ready() -> void:
	debug_console = preload("res://addons/repl_gd/debug_console.tscn").instance()
	get_tree().root.call_deferred("add_child", debug_console)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	
	if event.pressed:
		if event.scancode == KEY_ESCAPE:
			show_repl = not show_repl
			if show_repl:
				debug_console.transform.origin = Vector2.ZERO
			else:
				debug_console.transform.origin = -OS.window_size

#-----------------------------------------------------------------------------#
# Connections                                                                 #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Private functions                                                           #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# Public functions                                                            #
#-----------------------------------------------------------------------------#
