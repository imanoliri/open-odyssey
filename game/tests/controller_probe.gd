extends SceneTree


func _initialize() -> void:
	call_deferred("_probe")


func _probe() -> void:
	for frame in 30:
		await process_frame

	var connected := Input.get_connected_joypads()
	if connected.is_empty():
		print("CONTROLLER PROBE: no controller detected by this Godot process.")
		quit(0)
		return

	for device_id in connected:
		print(
			"CONTROLLER PROBE: id=%d name=\"%s\" guid=\"%s\""
			% [
				device_id,
				Input.get_joy_name(device_id),
				Input.get_joy_guid(device_id)
			]
		)

	quit(0)
