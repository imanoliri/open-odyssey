extends Node3D

enum ViewMode {
	FIXED_LEFT,
	CHASE,
}

@export var target_path: NodePath
@export var fixed_world_offset := Vector3(14.0, 5.0, 0.0)
@export var fixed_rotation_degrees := Vector3(-14.0, 90.0, 0.0)
@export var chase_local_offset := Vector3(0.0, 5.0, 14.0)
@export var chase_local_look_offset := Vector3(0.0, 1.0, 0.0)
@export var position_smoothing := 4.0
@export var view_mode := ViewMode.FIXED_LEFT

var target: Node3D


func _ready() -> void:
	target = get_node_or_null(target_path) as Node3D
	if target == null:
		target = get_parent().get_node_or_null("PlayerAircraft") as Node3D
	if target != null:
		global_position = _desired_position()
	_apply_desired_rotation()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_view"):
		toggle_view_mode()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if target == null:
		return

	var position_blend := 1.0 - exp(-position_smoothing * delta)
	global_position = global_position.lerp(_desired_position(), position_blend)
	_apply_desired_rotation()


func toggle_view_mode() -> void:
	view_mode = (
		ViewMode.CHASE
		if view_mode == ViewMode.FIXED_LEFT
		else ViewMode.FIXED_LEFT
	)
	if target != null:
		global_position = _desired_position()
	_apply_desired_rotation()


func _desired_position() -> Vector3:
	if view_mode == ViewMode.CHASE:
		return target.global_transform * chase_local_offset
	return target.global_position + fixed_world_offset


func _apply_desired_rotation() -> void:
	if view_mode == ViewMode.FIXED_LEFT or target == null:
		global_rotation_degrees = fixed_rotation_degrees
		return
	var look_target := (
		target.global_position
		+ target.global_basis * chase_local_look_offset
	)
	if not global_position.is_equal_approx(look_target):
		look_at(look_target, Vector3.UP)
