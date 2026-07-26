extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/main.tscn") as PackedScene
	if packed_scene == null:
		push_error("Smoke test could not load the main scene.")
		quit(1)
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame

	var aircraft := scene.get_node_or_null("PlayerAircraft") as PrototypeAircraft
	if aircraft == null:
		push_error("Smoke test could not find PlayerAircraft.")
		quit(1)
		return

	var camera_rig := scene.get_node_or_null("CameraRig") as Node3D
	if camera_rig == null:
		push_error("Smoke test could not find CameraRig.")
		quit(1)
		return

	var starting_position := aircraft.global_position
	var camera_starting_position := camera_rig.global_position
	var camera_starting_rotation := camera_rig.global_rotation
	print(
		"SMOKE camera setup: physics_processing=%s start=%s"
		% [
			camera_rig.is_physics_processing(),
			camera_starting_position
		]
	)
	Input.action_press("throttle_up")
	for frame in 180:
		await physics_frame
	Input.action_release("throttle_up")
	await process_frame

	var distance_travelled := aircraft.global_position.distance_to(starting_position)
	var camera_distance_travelled := camera_rig.global_position.distance_to(
		camera_starting_position
	)
	var camera_rotation_change := camera_rig.global_rotation.distance_to(
		camera_starting_rotation
	)
	print(
		"SMOKE telemetry: speed=%.2f m/s plane_distance=%.2f m camera_distance=%.2f m altitude=%.2f m throttle=%.2f"
		% [
			aircraft.indicated_airspeed,
			distance_travelled,
			camera_distance_travelled,
			aircraft.global_position.y,
			aircraft.throttle
		]
	)

	if distance_travelled < 1.0:
		push_error("Aircraft did not accelerate during the smoke test.")
		quit(1)
		return

	if aircraft.indicated_airspeed < 1.0 or aircraft.indicated_airspeed > 500.0:
		push_error("Aircraft airspeed is outside the smoke-test safety range.")
		quit(1)
		return

	if camera_distance_travelled < 1.0:
		push_error("Camera did not follow the aircraft's position.")
		quit(1)
		return

	if camera_rotation_change > 0.0001:
		push_error("Camera angle changed while following the aircraft.")
		quit(1)
		return

	print(
		"SMOKE PASS: propulsion advanced and camera followed with fixed rotation."
	)
	quit(0)
