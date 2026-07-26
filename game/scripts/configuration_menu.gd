class_name FlightConfigurationMenu
extends CanvasLayer

const CONFIGURATION_FILENAME := "open_odyssey_configuration.json"
const AIRCRAFT_FAMILY_CATALOG_PATH := "res://data/aircraft_families.json"
const DEFAULT_AIRCRAFT_ID := "test-airplane"
const DEFAULT_MAP_ID := "test-playground"

static var _remembered_aircraft_id := DEFAULT_AIRCRAFT_ID
static var _remembered_map_id := DEFAULT_MAP_ID

var _aircraft_configurations: Array[Dictionary] = []
var _map_configurations: Array[Dictionary] = []
var _aircraft_families: Dictionary = {}
var _overlay: Control
var _aircraft_selector: OptionButton
var _map_selector: OptionButton
var _play_button: Button
var _cancel_button: Button
var _current_configuration_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_aircraft_family_catalog()
	_aircraft_configurations.append(_default_configuration(
		DEFAULT_AIRCRAFT_ID
	))
	_map_configurations.append(_default_configuration(DEFAULT_MAP_ID))
	_discover_configurations("res://")
	_sort_optional_configurations(_aircraft_configurations)
	_sort_optional_configurations(_map_configurations)
	_build_menu()
	_apply_remembered_configuration()


func _unhandled_input(event: InputEvent) -> void:
	var menu_button_pressed: bool = (
		event is InputEventJoypadButton
		and event.button_index == JOY_BUTTON_START
		and event.pressed
	)
	var keyboard_menu_pressed: bool = (
		event is InputEventKey
		and event.physical_keycode == KEY_TAB
		and event.pressed
		and not event.echo
	)
	if menu_button_pressed or keyboard_menu_pressed:
		get_viewport().set_input_as_handled()
		if _overlay.visible:
			_confirm_and_restart()
		else:
			_open_menu()
		return

	if (
		_overlay.visible
		and event is InputEventKey
		and event.physical_keycode == KEY_ESCAPE
		and event.pressed
		and not event.echo
	):
		get_viewport().set_input_as_handled()
		_back_or_cancel()


func _input(event: InputEvent) -> void:
	if (
		not _overlay.visible
		or not event is InputEventJoypadButton
		or not event.pressed
	):
		return
	if event.button_index == JOY_BUTTON_A:
		get_viewport().set_input_as_handled()
		var popup_selector := _visible_selector_popup()
		if popup_selector != null:
			_confirm_popup_selection(popup_selector)
		else:
			_activate_focused_control()
	elif event.button_index == JOY_BUTTON_Y:
		get_viewport().set_input_as_handled()
		_back_or_cancel()


func selected_aircraft_label() -> String:
	return _label_for_id(_aircraft_configurations, _remembered_aircraft_id)


func selected_map_label() -> String:
	return _label_for_id(_map_configurations, _remembered_map_id)


func aircraft_family_display_name(family_id: String) -> String:
	var family := _aircraft_families.get(family_id, {}) as Dictionary
	return family.get("display_name", "")


func stock_parts_label_for_family(family_id: String) -> String:
	var family := _aircraft_families.get(family_id, {}) as Dictionary
	if family.is_empty():
		return ""
	if family.get("configuration", "") == "fixed":
		return "Fixed factory configuration"
	var labels: Array[String] = []
	for part_value in family.get("part_families", []):
		var part := part_value as Dictionary
		labels.append(
			"%s %d"
			% [
				part.get("display_name", part.get("id", "Part")),
				int(part.get("stock_variant", 1))
			]
		)
	return ", ".join(labels)


func _default_configuration(configuration_id: String) -> Dictionary:
	return {
		"id": configuration_id,
		"label": configuration_id,
		"component_scene": "",
	}


func _load_aircraft_family_catalog() -> void:
	var file := FileAccess.open(
		AIRCRAFT_FAMILY_CATALOG_PATH,
		FileAccess.READ
	)
	if file == null:
		push_error("Aircraft family catalog is unavailable.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not parsed.has("families"):
		push_error("Aircraft family catalog is invalid.")
		return
	for family_value in parsed["families"]:
		if not family_value is Dictionary:
			push_error("Aircraft family catalog contains a non-object entry.")
			continue
		var family := family_value as Dictionary
		if (
			not family.get("id") is String
			or not family.get("display_name") is String
			or not family.get("part_families") is Array
			or not family.get("optional_parts") is Array
		):
			push_error("Aircraft family catalog contains an invalid entry.")
			continue
		_aircraft_families[family["id"]] = family


func _discover_configurations(directory_path: String) -> void:
	if FileAccess.file_exists(directory_path.path_join(".gdignore")):
		return
	for entry in ResourceLoader.list_directory(directory_path):
		var entry_path := directory_path.path_join(
			entry.trim_suffix("/")
		)
		if entry.ends_with("/"):
			_discover_configurations(entry_path)
		elif entry == CONFIGURATION_FILENAME:
			_read_configuration(entry_path)


func _read_configuration(configuration_path: String) -> void:
	var file := FileAccess.open(configuration_path, FileAccess.READ)
	if file == null:
		push_warning(
			"Could not read local flight configuration: %s"
			% configuration_path
		)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		for entry in parsed:
			_register_configuration(entry, configuration_path)
		return
	if not parsed is Dictionary:
		push_warning(
			"Local flight configuration is not an object or array: %s"
			% configuration_path
		)
		return
	var document := parsed as Dictionary
	if document.has("configurations"):
		if not document["configurations"] is Array:
			push_warning(
				"Local flight configuration catalog is not an array: %s"
				% configuration_path
			)
			return
		for entry in document["configurations"]:
			_register_configuration(entry, configuration_path)
		return
	_register_configuration(document, configuration_path)


func _register_configuration(
	value: Variant,
	configuration_path: String
) -> void:
	if not value is Dictionary:
		push_warning(
			"Local flight configuration entry is not an object: %s"
			% configuration_path
		)
		return
	var configuration := (value as Dictionary).duplicate(true)
	for required_key in ["kind", "id", "label", "component_scene"]:
		if not configuration.has(required_key):
			push_warning(
				"Local flight configuration lacks '%s': %s"
				% [required_key, configuration_path]
			)
			return
	if (
		not configuration["kind"] is String
		or not configuration["id"] is String
		or not configuration["label"] is String
		or not configuration["component_scene"] is String
	):
		push_warning(
			"Local flight configuration has invalid field types: %s"
			% configuration_path
		)
		return
	if (
		configuration.has("component_properties")
		and not configuration["component_properties"] is Dictionary
	):
		push_warning(
			"Local flight component properties are not an object: %s"
			% configuration_path
		)
		return
	if configuration.has("aircraft_family_id"):
		if not configuration["aircraft_family_id"] is String:
			push_warning(
				"Aircraft family id is not a string: %s"
				% configuration_path
			)
			return
		var family_id := configuration["aircraft_family_id"] as String
		if not _aircraft_families.has(family_id):
			push_warning(
				"Unknown aircraft family '%s': %s"
				% [family_id, configuration_path]
			)
			return
		configuration["label"] = aircraft_family_display_name(family_id)
	if not ResourceLoader.exists(configuration["component_scene"]):
		push_warning(
			"Local flight configuration component is missing: %s"
			% configuration["component_scene"]
		)
		return

	match configuration["kind"]:
		"aircraft":
			_append_unique_configuration(
				_aircraft_configurations,
				configuration
			)
		"map":
			_append_unique_configuration(_map_configurations, configuration)
		_:
			push_warning(
				"Unknown local flight configuration kind: %s"
				% configuration["kind"]
			)


func _append_unique_configuration(
	configurations: Array[Dictionary],
	configuration: Dictionary
) -> void:
	for existing in configurations:
		if existing["id"] == configuration["id"]:
			push_warning(
				"Duplicate local flight configuration id: %s"
				% configuration["id"]
			)
			return
	configurations.append(configuration)


func _sort_optional_configurations(
	configurations: Array[Dictionary]
) -> void:
	if configurations.size() <= 2:
		return
	var optional := configurations.slice(1)
	optional.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			return left["label"].nocasecmp_to(right["label"]) < 0
	)
	configurations.resize(1)
	configurations.append_array(optional)


func _build_menu() -> void:
	_overlay = Control.new()
	_overlay.name = "ConfigurationOverlay"
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	add_child(_overlay)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.015, 0.025, 0.04, 0.82)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(dimmer)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -260.0
	panel.offset_top = -190.0
	panel.offset_right = 260.0
	panel.offset_bottom = 190.0
	_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var title := Label.new()
	title.text = "FLIGHT CONFIGURATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	content.add_child(title)

	var hint := Label.new()
	hint.text = (
		"Choose with the D-pad. Cross selects.\n"
		+ "Start launches. Triangle goes back."
	)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override(
		"font_color",
		Color(0.72, 0.82, 0.9)
	)
	content.add_child(hint)

	content.add_child(_selector_label("AIRCRAFT"))
	_aircraft_selector = OptionButton.new()
	_populate_selector(
		_aircraft_selector,
		_aircraft_configurations,
		_remembered_aircraft_id
	)
	_aircraft_selector.get_popup().window_input.connect(
		_on_selector_popup_input.bind(_aircraft_selector)
	)
	content.add_child(_aircraft_selector)

	content.add_child(_selector_label("MAP"))
	_map_selector = OptionButton.new()
	_populate_selector(
		_map_selector,
		_map_configurations,
		_remembered_map_id
	)
	_map_selector.get_popup().window_input.connect(
		_on_selector_popup_input.bind(_map_selector)
	)
	content.add_child(_map_selector)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	content.add_child(actions)

	_play_button = Button.new()
	_play_button.text = "Play / Restart"
	_play_button.pressed.connect(_confirm_and_restart)
	actions.add_child(_play_button)

	_cancel_button = Button.new()
	_cancel_button.text = "Cancel"
	_cancel_button.pressed.connect(_cancel_and_close_menu)
	actions.add_child(_cancel_button)

	_aircraft_selector.item_selected.connect(
		func(_index: int) -> void:
			_map_selector.call_deferred("grab_focus")
	)
	_map_selector.item_selected.connect(
		func(_index: int) -> void:
			_play_button.call_deferred("grab_focus")
	)

	_current_configuration_label = Label.new()
	_current_configuration_label.position = Vector2(24.0, 535.0)
	_current_configuration_label.add_theme_color_override(
		"font_color",
		Color(0.75, 0.9, 1.0)
	)
	_current_configuration_label.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.9)
	)
	_current_configuration_label.add_theme_constant_override(
		"shadow_offset_x",
		2
	)
	_current_configuration_label.add_theme_constant_override(
		"shadow_offset_y",
		2
	)
	_current_configuration_label.add_theme_font_size_override(
		"font_size",
		15
	)
	add_child(_current_configuration_label)
	_update_current_configuration_label()


func _selector_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(0.55, 0.8, 0.95))
	label.add_theme_font_size_override("font_size", 14)
	return label


func _populate_selector(
	selector: OptionButton,
	configurations: Array[Dictionary],
	selected_id: String
) -> void:
	var selected_index := 0
	for index in configurations.size():
		var configuration := configurations[index]
		selector.add_item(configuration["label"])
		selector.set_item_metadata(index, configuration["id"])
		if configuration["id"] == selected_id:
			selected_index = index
	selector.select(selected_index)


func _open_menu() -> void:
	_overlay.visible = true
	get_tree().paused = true
	_aircraft_selector.grab_focus()


func _close_menu() -> void:
	_overlay.visible = false
	get_tree().paused = false


func _cancel_and_close_menu() -> void:
	_restore_selector(_aircraft_selector, _remembered_aircraft_id)
	_restore_selector(_map_selector, _remembered_map_id)
	_close_menu()


func _activate_focused_control() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused is OptionButton:
		var selector := focused as OptionButton
		selector.show_popup()
		selector.get_popup().set_focused_item(selector.selected)
	elif focused is BaseButton:
		(focused as BaseButton).pressed.emit()


func _confirm_popup_selection(selector: OptionButton) -> void:
	var popup := selector.get_popup()
	var selected_index := popup.get_focused_item()
	if selected_index < 0 or selected_index >= selector.item_count:
		selected_index = selector.selected
	popup.hide()
	selector.select(selected_index)
	selector.item_selected.emit(selected_index)


func _on_selector_popup_input(
	event: InputEvent,
	selector: OptionButton
) -> void:
	if not event is InputEventJoypadButton or not event.pressed:
		return
	if event.button_index == JOY_BUTTON_A:
		selector.get_popup().get_viewport().set_input_as_handled()
		_confirm_popup_selection(selector)
	elif event.button_index == JOY_BUTTON_Y:
		selector.get_popup().get_viewport().set_input_as_handled()
		selector.get_popup().hide()
		selector.call_deferred("grab_focus")


func _back_or_cancel() -> void:
	var popup_selector := _visible_selector_popup()
	if popup_selector != null:
		popup_selector.get_popup().hide()
		popup_selector.grab_focus()
		return

	var focused := get_viewport().gui_get_focus_owner()
	if focused == _play_button or focused == _cancel_button:
		_map_selector.grab_focus()
		return
	if focused == _map_selector:
		if not _selector_matches_id(_map_selector, _remembered_map_id):
			_restore_selector(_map_selector, _remembered_map_id)
		else:
			_aircraft_selector.grab_focus()
		return
	if focused == _aircraft_selector:
		if not _selector_matches_id(
			_aircraft_selector,
			_remembered_aircraft_id
		):
			_restore_selector(
				_aircraft_selector,
				_remembered_aircraft_id
			)
		else:
			_cancel_and_close_menu()
		return
	_cancel_and_close_menu()


func _visible_selector_popup() -> OptionButton:
	for selector in [_aircraft_selector, _map_selector]:
		if selector != null and selector.get_popup().visible:
			return selector
	return null


func _selector_matches_id(
	selector: OptionButton,
	configuration_id: String
) -> bool:
	return (
		selector.get_item_metadata(selector.selected)
		== configuration_id
	)


func _restore_selector(
	selector: OptionButton,
	configuration_id: String
) -> void:
	for index in selector.item_count:
		if selector.get_item_metadata(index) == configuration_id:
			selector.select(index)
			return


func _confirm_and_restart() -> void:
	_remembered_aircraft_id = _aircraft_selector.get_item_metadata(
		_aircraft_selector.selected
	)
	_remembered_map_id = _map_selector.get_item_metadata(
		_map_selector.selected
	)
	get_tree().paused = false
	get_tree().reload_current_scene()


func _apply_remembered_configuration() -> void:
	_remembered_aircraft_id = _validated_selection_id(
		_aircraft_configurations,
		_remembered_aircraft_id,
		DEFAULT_AIRCRAFT_ID
	)
	_remembered_map_id = _validated_selection_id(
		_map_configurations,
		_remembered_map_id,
		DEFAULT_MAP_ID
	)
	_instantiate_component(
		_configuration_for_id(
			_aircraft_configurations,
			_remembered_aircraft_id
		),
		"AircraftConfiguration"
	)
	_instantiate_component(
		_configuration_for_id(_map_configurations, _remembered_map_id),
		"MapConfiguration"
	)
	_update_current_configuration_label()


func _instantiate_component(
	configuration: Dictionary,
	component_name: String
) -> void:
	var component_path: String = configuration["component_scene"]
	if component_path.is_empty():
		return
	var packed_scene := load(component_path) as PackedScene
	if packed_scene == null:
		push_error(
			"Could not load flight configuration component: %s"
			% component_path
		)
		return
	var component := packed_scene.instantiate()
	component.name = component_name
	var component_properties: Dictionary = configuration.get(
		"component_properties",
		{}
	)
	for property_key in component_properties:
		var property_name := str(property_key)
		if not _set_object_property(
			component,
			property_name,
			component_properties[property_key]
		):
			push_warning(
				"Flight component lacks property '%s': %s"
				% [property_name, component_path]
			)
	get_parent().add_child.call_deferred(component)


func _set_object_property(
	object: Object,
	property_name: String,
	value: Variant
) -> bool:
	for property in object.get_property_list():
		if property["name"] != property_name:
			continue
		match property["type"]:
			TYPE_INT:
				value = int(value)
			TYPE_FLOAT:
				value = float(value)
			TYPE_BOOL:
				value = bool(value)
			TYPE_STRING:
				value = str(value)
		object.set(property_name, value)
		return true
	return false


func _validated_selection_id(
	configurations: Array[Dictionary],
	selected_id: String,
	fallback_id: String
) -> String:
	for configuration in configurations:
		if configuration["id"] == selected_id:
			return selected_id
	return fallback_id


func _configuration_for_id(
	configurations: Array[Dictionary],
	selected_id: String
) -> Dictionary:
	for configuration in configurations:
		if configuration["id"] == selected_id:
			return configuration
	return configurations[0]


func _label_for_id(
	configurations: Array[Dictionary],
	selected_id: String
) -> String:
	return _configuration_for_id(configurations, selected_id)["label"]


func _update_current_configuration_label() -> void:
	if _current_configuration_label == null:
		return
	var aircraft_configuration := _configuration_for_id(
		_aircraft_configurations,
		_remembered_aircraft_id
	)
	var parts_label := "Standard prototype"
	if aircraft_configuration.has("aircraft_family_id"):
		parts_label = stock_parts_label_for_family(
			aircraft_configuration["aircraft_family_id"]
		)
	_current_configuration_label.text = (
		"CONFIG  %s  /  %s    [Start or Tab: configure]\nPARTS  %s"
		% [
			selected_aircraft_label(),
			selected_map_label(),
			parts_label
		]
	)
