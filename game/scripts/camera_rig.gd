extends Node3D

@export var target_path: NodePath
@export var fixed_world_offset := Vector3(14.0, 5.0, 0.0)
@export var fixed_rotation_degrees := Vector3(-14.0, 90.0, 0.0)
@export var position_smoothing := 4.0

var target: Node3D


func _ready() -> void:
	target = get_node_or_null(target_path) as Node3D
	if target == null:
		target = get_parent().get_node_or_null("PlayerAircraft") as Node3D
	if target != null:
		global_position = _desired_position()
	global_rotation_degrees = fixed_rotation_degrees


func _physics_process(delta: float) -> void:
	if target == null:
		return

	var position_blend := 1.0 - exp(-position_smoothing * delta)
	global_position = global_position.lerp(_desired_position(), position_blend)
	global_rotation_degrees = fixed_rotation_degrees


func _desired_position() -> Vector3:
	return target.global_position + fixed_world_offset
