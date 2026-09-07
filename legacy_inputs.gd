extends Node

# Preserve controls for the pre-existing 2.5D scenes.
func _ready() -> void:
	var bindings = {"move_forward":KEY_W,"move_back":KEY_S,"move_left":KEY_A,"move_right":KEY_D,"interact":KEY_F,"toggle_ui":KEY_TAB,"slice_1":KEY_1,"slice_2":KEY_2,"slice_3":KEY_3}
	for action in bindings:
		if not InputMap.has_action(action): InputMap.add_action(action)
		var event = InputEventKey.new()
		event.physical_keycode = bindings[action]
		InputMap.action_add_event(action,event)
	var mouse = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("interact",mouse)
