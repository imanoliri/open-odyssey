extends Node3D

@export var target_path: NodePath
@export var follow_distance := 14.0
@export var follow_height := 5.0
@export var position_smoothing := 4.0
@export var heading_smoothing := 6.0
@export_range(-45.0, 0.0, 0.5) var fixed_pitch_degrees := -14.0

var target: Node3D
var smoothed_heading := Vector3.FORWARD


func _ready() -> void:
	target = get_node_or_null(target_path) as Node3D
	if target != null:
		smoothed_heading = _horizontal_heading()
		global_position = _desired_position()
		_apply_fixed_camera_angle()


func _process(delta: float) -> void:
	if target == null:
		return

	var heading_blend := 1.0 - exp(-heading_smoothing * delta)
	smoothed_heading = smoothed_heading.slerp(
		_horizontal_heading(),
		heading_blend
	)
	smoothed_heading.y = 0.0
	smoothed_heading = smoothed_heading.normalized()

	var position_blend := 1.0 - exp(-position_smoothing * delta)
	global_position = global_position.lerp(_desired_position(), position_blend)
	_apply_fixed_camera_angle()


func _desired_position() -> Vector3:
	return (
		target.global_position
		- smoothed_heading * follow_distance
		+ Vector3.UP * follow_height
	)


func _horizontal_heading() -> Vector3:
	var heading := -target.global_transform.basis.z
	heading.y = 0.0
	if heading.length_squared() < 0.0001:
		return smoothed_heading
	return heading.normalized()


func _apply_fixed_camera_angle() -> void:
	var heading_yaw := atan2(-smoothed_heading.x, -smoothed_heading.z)
	global_rotation = Vector3(
		deg_to_rad(fixed_pitch_degrees),
		heading_yaw,
		0.0
	)
