extends Node3D


func _enter_tree() -> void:
	_add_key_action("pitch_up", KEY_W)
	_add_key_action("pitch_down", KEY_S)
	_add_key_action("roll_left", KEY_A)
	_add_key_action("roll_right", KEY_D)
	_add_key_action("yaw_left", KEY_Q)
	_add_key_action("yaw_right", KEY_E)
	_add_key_action("yaw_left", KEY_LEFT)
	_add_key_action("yaw_right", KEY_RIGHT)
	_add_key_action("throttle_up", KEY_R)
	_add_key_action("throttle_down", KEY_F)
	_add_key_action("restart", KEY_ENTER)

	# Standard SDL/Godot layout used by most PS2-to-USB adapters.
	# Pulling the left stick down pitches up, matching aircraft controls.
	_add_joy_axis_action("pitch_up", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_axis_action("pitch_down", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis_action("roll_left", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis_action("roll_right", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis_action("yaw_left", JOY_AXIS_RIGHT_X, -1.0)
	_add_joy_axis_action("yaw_right", JOY_AXIS_RIGHT_X, 1.0)
	_add_joy_axis_action("yaw_right", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_add_joy_axis_action("yaw_left", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_joy_button_action("throttle_down", JOY_BUTTON_LEFT_SHOULDER)
	_add_joy_button_action("throttle_up", JOY_BUTTON_RIGHT_SHOULDER)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _add_key_action(action: StringName, physical_keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.15)

	var input_event := InputEventKey.new()
	input_event.physical_keycode = physical_keycode
	if not InputMap.action_has_event(action, input_event):
		InputMap.action_add_event(action, input_event)


func _add_joy_axis_action(
	action: StringName,
	axis: JoyAxis,
	axis_value: float
) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.18)

	var input_event := InputEventJoypadMotion.new()
	input_event.axis = axis
	input_event.axis_value = axis_value
	if not InputMap.action_has_event(action, input_event):
		InputMap.action_add_event(action, input_event)


func _add_joy_button_action(action: StringName, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.18)

	var input_event := InputEventJoypadButton.new()
	input_event.button_index = button
	if not InputMap.action_has_event(action, input_event):
		InputMap.action_add_event(action, input_event)
