class_name PrototypeAircraft
extends RigidBody3D

@export_category("Mass and propulsion")
@export var maximum_thrust_newtons := 16000.0
@export var throttle_change_per_second := 0.35
@export var starting_throttle := 0.0

@export_category("Aerodynamics")
@export var air_density := 1.225
@export var wing_area_square_metres := 16.0
@export var lift_coefficient := 1.05
@export var drag_coefficient := 0.045
@export var lateral_drag_coefficient := 1.8
@export var stall_speed_metres_per_second := 24.0
@export var full_control_speed_metres_per_second := 35.0

@export_category("Control torque")
@export var pitch_torque_newton_metres := 9500.0
@export var roll_torque_newton_metres := 4375.0
@export var yaw_torque_newton_metres := 4500.0

var throttle := 0.0
var indicated_airspeed := 0.0
var forward_airspeed := 0.0
var is_stalling := false


func _ready() -> void:
	throttle = clampf(starting_throttle, 0.0, 1.0)
	contact_monitor = true
	max_contacts_reported = 8


func _physics_process(delta: float) -> void:
	var throttle_input := Input.get_axis("throttle_down", "throttle_up")
	throttle = clampf(
		throttle + throttle_input * throttle_change_per_second * delta,
		0.0,
		1.0
	)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var basis := state.transform.basis.orthonormalized()
	var forward := -basis.z
	var up := basis.y
	var right := basis.x
	var velocity := state.linear_velocity
	var local_velocity := basis.inverse() * velocity

	forward_airspeed = maxf(-local_velocity.z, 0.0)
	indicated_airspeed = velocity.length()
	is_stalling = forward_airspeed < stall_speed_metres_per_second

	var dynamic_pressure := 0.5 * air_density * forward_airspeed * forward_airspeed
	var stall_ratio := clampf(
		forward_airspeed / maxf(stall_speed_metres_per_second, 0.1),
		0.0,
		1.0
	)
	var effective_lift_coefficient := lift_coefficient * stall_ratio * stall_ratio

	var thrust := forward * maximum_thrust_newtons * throttle
	var lift := up * dynamic_pressure * wing_area_square_metres * effective_lift_coefficient
	var drag := Vector3.ZERO
	if velocity.length_squared() > 0.001:
		var drag_magnitude := (
			0.5
			* air_density
			* velocity.length_squared()
			* drag_coefficient
			* wing_area_square_metres
		)
		drag = -velocity.normalized() * drag_magnitude

	var lateral_velocity := right * local_velocity.x + up * local_velocity.y
	var lateral_drag := -lateral_velocity * lateral_drag_coefficient * mass

	state.apply_central_force(thrust + lift + drag + lateral_drag)

	var pitch_input := Input.get_axis("pitch_down", "pitch_up")
	var roll_input := Input.get_axis("roll_left", "roll_right")
	var yaw_input := Input.get_axis("yaw_left", "yaw_right")
	var control_authority := clampf(
		forward_airspeed / maxf(full_control_speed_metres_per_second, 0.1),
		0.12,
		1.0
	)
	var control_torque := (
		right * pitch_input * pitch_torque_newton_metres
		+ forward * -roll_input * roll_torque_newton_metres
		+ up * yaw_input * yaw_torque_newton_metres
	) * control_authority

	state.apply_torque(control_torque)


func telemetry_text() -> String:
	var stall_text := "STALL" if is_stalling else "FLYING"
	return (
		"AIRSPEED  %5.1f m/s\nALTITUDE  %5.1f m\nTHROTTLE   %3.0f%%\nSTATE      %s"
		% [indicated_airspeed, global_position.y, throttle * 100.0, stall_text]
	)


func physical_characteristics_text() -> String:
	var box_size := _collision_box_size()
	var moments_of_inertia := _box_moments_of_inertia(box_size)
	var weight_newtons := maxf(mass * 9.80665 * gravity_scale, 0.001)
	var thrust_to_weight_ratio := maximum_thrust_newtons / weight_newtons
	var local_angular_velocity := (
		global_transform.basis.orthonormalized().inverse()
		* angular_velocity
	)
	var rotation_rates_degrees := Vector3(
		rad_to_deg(local_angular_velocity.x),
		rad_to_deg(local_angular_velocity.y),
		rad_to_deg(local_angular_velocity.z)
	)
	var surface_friction := 0.0
	var surface_bounce := 0.0
	if physics_material_override != null:
		surface_friction = physics_material_override.friction
		surface_bounce = physics_material_override.bounce

	var template := (
		"MAX THRUST          %8.0f N\n"
		+ "THROTTLE RATE       %8.2f /s\n"
		+ "THRUST / WEIGHT     %8.3f\n"
		+ "\n"
		+ "WING AREA           %8.2f m^2\n"
		+ "LIFT COEFF          %8.3f\n"
		+ "DRAG COEFF          %8.3f\n"
		+ "LATERAL DRAG        %8.3f\n"
		+ "STALL SPEED         %8.2f m/s\n"
		+ "FULL CONTROL        %8.2f m/s\n"
		+ "\n"
		+ "PITCH TORQUE        %8.0f N*m\n"
		+ "ROLL TORQUE         %8.0f N*m\n"
		+ "YAW TORQUE          %8.0f N*m\n"
		+ "\n"
		+ "MASS                %8.1f kg\n"
		+ "LINEAR DAMP         %8.3f\n"
		+ "ANGULAR DAMP        %8.3f\n"
		+ "BOX W x H x L  %4.2f x %4.2f x %4.2f m\n"
		+ "FRICTION / BOUNCE %6.2f / %6.2f\n"
		+ "INERTIA P/Y/R %7.2f / %7.2f / %7.2f kg*m^2\n"
		+ "PITCH RATE          %8.2f deg/s\n"
		+ "YAW RATE            %8.2f deg/s\n"
		+ "ROLL RATE           %8.2f deg/s"
	)
	return template % [
			maximum_thrust_newtons,
			throttle_change_per_second,
			thrust_to_weight_ratio,
			wing_area_square_metres,
			lift_coefficient,
			drag_coefficient,
			lateral_drag_coefficient,
			stall_speed_metres_per_second,
			full_control_speed_metres_per_second,
			pitch_torque_newton_metres,
			roll_torque_newton_metres,
			yaw_torque_newton_metres,
			mass,
			linear_damp,
			angular_damp,
			box_size.x,
			box_size.y,
			box_size.z,
			surface_friction,
			surface_bounce,
			moments_of_inertia.x,
			moments_of_inertia.y,
			moments_of_inertia.z,
			rotation_rates_degrees.x,
			rotation_rates_degrees.y,
			rotation_rates_degrees.z
		]


func _collision_box_size() -> Vector3:
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null:
		return Vector3.ZERO
	var box := collision.shape as BoxShape3D
	if box == null:
		return Vector3.ZERO
	return box.size


func _box_moments_of_inertia(box_size: Vector3) -> Vector3:
	var width_squared := box_size.x * box_size.x
	var height_squared := box_size.y * box_size.y
	var length_squared := box_size.z * box_size.z
	return Vector3(
		mass * (height_squared + length_squared) / 12.0,
		mass * (width_squared + length_squared) / 12.0,
		mass * (width_squared + height_squared) / 12.0
	)
