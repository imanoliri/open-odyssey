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

	var configuration_menu := scene.get_node_or_null(
		"ConfigurationMenu"
	) as FlightConfigurationMenu
	if configuration_menu == null:
		push_error("Smoke test could not find the flight configuration menu.")
		quit(1)
		return
	if (
		configuration_menu.selected_aircraft_label() != "test-airplane"
		or configuration_menu.selected_map_label() != "test-playground"
	):
		push_error("Default flight configuration labels changed.")
		quit(1)
		return
	var ground := scene.get_node_or_null("Ground") as StaticBody3D
	var runway := scene.get_node_or_null("Runway") as MeshInstance3D
	var ground_collision := scene.get_node_or_null(
		"Ground/CollisionShape3D"
	) as CollisionShape3D
	if (
		ground == null
		or runway == null
		or ground_collision == null
		or not ground.visible
		or not runway.visible
		or ground_collision.disabled
	):
		push_error("Testing grounds did not retain its floor and runway.")
		quit(1)
		return
	scene.set_test_environment_enabled(false)
	if ground.visible or runway.visible or not ground_collision.disabled:
		push_error("Generated-map environment retained testing-ground nodes.")
		quit(1)
		return
	scene.set_test_environment_enabled(true)
	if (
		configuration_menu.aircraft_family_display_name("bf-109")
		!= "Bf-109"
		or configuration_menu.stock_parts_label_for_family("bf-109")
		!= (
			"Wing 1, Tail 1, Engine 1, Body 1, Canopy 1, "
			+ "Propeller 1"
		)
		or configuration_menu.stock_parts_label_for_family("twin-wing")
		!= (
			"Wing 1, Tail 1, Engine 1, Body 1, Canopy 1, "
			+ "Propeller 1, Tire 1"
		)
		or configuration_menu.stock_parts_label_for_family("f-117")
		!= "Fixed factory configuration"
	):
		push_error("Aircraft family or stock-part catalog is invalid.")
		quit(1)
		return
	var property_probe := Node.new()
	if (
		not configuration_menu._set_object_property(
			property_probe,
			"process_priority",
			7.0
		)
		or property_probe.process_priority != 7
		or configuration_menu._set_object_property(
			property_probe,
			"missing_property",
			1
		)
	):
		push_error("Configuration component property assignment failed.")
		quit(1)
		return
	for restart_event in InputMap.action_get_events("restart"):
		if (
			restart_event is InputEventJoypadButton
			and restart_event.button_index == JOY_BUTTON_START
		):
			push_error("Start is still bound directly to restart.")
			quit(1)
			return

	var open_menu_event := InputEventKey.new()
	open_menu_event.physical_keycode = KEY_TAB
	open_menu_event.pressed = true
	configuration_menu._unhandled_input(open_menu_event)
	if not paused:
		push_error("Configuration menu did not pause flight.")
		quit(1)
		return
	var cross_event := InputEventJoypadButton.new()
	cross_event.button_index = JOY_BUTTON_A
	cross_event.pressed = true
	configuration_menu._input(cross_event)
	var aircraft_selector: OptionButton = configuration_menu.get(
		"_aircraft_selector"
	)
	if not aircraft_selector.get_popup().visible:
		push_error("Cross did not open the focused aircraft selector.")
		quit(1)
		return
	configuration_menu._on_selector_popup_input(
		cross_event,
		aircraft_selector
	)
	if aircraft_selector.get_popup().visible:
		push_error("Cross did not confirm the highlighted aircraft option.")
		quit(1)
		return
	configuration_menu._input(cross_event)
	if not aircraft_selector.get_popup().visible:
		push_error("Cross did not reopen the aircraft selector.")
		quit(1)
		return
	var triangle_event := InputEventJoypadButton.new()
	triangle_event.button_index = JOY_BUTTON_Y
	triangle_event.pressed = true
	configuration_menu._on_selector_popup_input(
		triangle_event,
		aircraft_selector
	)
	if not paused or aircraft_selector.get_popup().visible:
		push_error("Triangle did not back out of the aircraft selector.")
		quit(1)
		return
	configuration_menu._input(triangle_event)
	if paused:
		push_error("Triangle did not close the configuration menu.")
		quit(1)
		return

	var aircraft := scene.get_node_or_null("PlayerAircraft") as PrototypeAircraft
	if aircraft == null:
		push_error("Smoke test could not find PlayerAircraft.")
		quit(1)
		return

	var physics_text := aircraft.physical_characteristics_text()
	for required_text in [
		"MAX THRUST",
		"THRUST / WEIGHT",
		"ROLL TORQUE",
		"YAW TORQUE",
		"BOX W x H x L",
		"2.00 x 0.80 x 5.40 m",
		"INERTIA P/Y/R",
		"2359.17 / 2625.17 /  367.33",
		"PITCH RATE",
		"YAW RATE",
		"ROLL RATE"
	]:
		if not physics_text.contains(required_text):
			push_error(
				"Aircraft physics panel is missing: %s" % required_text
			)
			quit(1)
			return

	for removed_text in [
		"AIRCRAFT PHYSICS",
		"[ENGINE]",
		"STARTING THROTTLE",
		"AIR DENSITY",
		"GRAVITY SCALE",
		"ROTATIONAL STATE",
		"RATE P/Y/R",
		"MOMENTUM P/Y/R"
	]:
		if physics_text.contains(removed_text):
			push_error(
				"Aircraft physics panel still contains: %s" % removed_text
			)
			quit(1)
			return

	var audio := aircraft.get_node_or_null(
		"AudioController"
	) as AircraftAudioController
	if audio == null:
		push_error("Smoke test could not find AudioController.")
		quit(1)
		return

	if (
		audio.engine_player.global_position.distance_to(
			aircraft.global_position
		) > 0.01
	):
		push_error("Engine sound source is not following the aircraft.")
		quit(1)
		return

	if not audio.engine_player.playing or not audio.wind_player.playing:
		push_error("Aircraft audio players are not running.")
		quit(1)
		return

	if (
		audio.engine_amplitude_for_throttle(1.0)
		<= audio.engine_amplitude_for_throttle(0.25)
	):
		push_error("Engine sound is not proportional to throttle.")
		quit(1)
		return

	if (
		audio.engine_frequency_for_throttle(1.0)
		<= audio.engine_frequency_for_throttle(0.25)
	):
		push_error("Propeller frequency is not proportional to throttle.")
		quit(1)
		return

	if (
		audio.wind_amplitude_for_speed(60.0)
		<= audio.wind_amplitude_for_speed(15.0)
	):
		push_error("Wind sound is not proportional to airspeed.")
		quit(1)
		return

	if (
		audio.wind_whistle_frequency_for_speed(60.0)
		<= audio.wind_whistle_frequency_for_speed(15.0)
	):
		push_error("Wind whistle pitch is not proportional to airspeed.")
		quit(1)
		return

	if audio.wind_whistle_mix > 0.10:
		push_error("Wind whistle is not mixed as a background element.")
		quit(1)
		return

	if audio.wind_noise_interpolation_samples < 16:
		push_error("Wind airflow interpolation is too short to sound smooth.")
		quit(1)
		return

	var camera_rig := scene.get_node_or_null("CameraRig") as Node3D
	if camera_rig == null:
		push_error("Smoke test could not find CameraRig.")
		quit(1)
		return
	var camera_offset: Vector3 = camera_rig.get("fixed_world_offset")
	var camera_rotation: Vector3 = camera_rig.get("fixed_rotation_degrees")
	if not camera_offset.is_equal_approx(Vector3(14.0, 5.0, 0.0)):
		push_error("Default camera is not positioned for the left-facing view.")
		quit(1)
		return
	if not camera_rotation.is_equal_approx(Vector3(-14.0, 90.0, 0.0)):
		push_error("Default camera is not rotated 90 degrees left.")
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

	if (
		audio.current_engine_amplitude <= 0.0
		or audio.current_wind_amplitude <= 0.0
	):
		push_error("Aircraft audio levels did not respond during simulation.")
		quit(1)
		return

	print(
		"SMOKE PASS: propulsion, fixed camera, engine audio, and wind audio advanced."
	)
	scene.queue_free()
	await process_frame
	quit(0)
