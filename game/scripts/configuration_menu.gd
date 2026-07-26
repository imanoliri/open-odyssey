class_name FlightConfigurationMenu
extends CanvasLayer

const CONFIGURATION_FILENAME := "open_odyssey_configuration.json"
const DEFAULT_AIRCRAFT_ID := "test-airplane"
const DEFAULT_MAP_ID := "test-playground"

static var _remembered_aircraft_id := DEFAULT_AIRCRAFT_ID
static var _remembered_map_id := DEFAULT_MAP_ID

var _aircraft_configurations: Array[Dictionary] = []
var _map_configurations: Array[Dictionary] = []
var _overlay: Control
var _aircraft_selector: OptionButton
var _map_selector: OptionButton
var _play_button: Button
var _cancel_button: Button
var _current_configuration_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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


func _default_configuration(configuration_id: String) -> Dictionary:
	return {
		"id": configuration_id,
		"label": configuration_id,
		"component_scene": "",
	}


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
	if not parsed is Dictionary:
		push_warning(
			"Local flight configuration is not a JSON object: %s"
			% configuration_path
		)
		return
	var configuration := parsed as Dictionary
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
	get_parent().add_child.call_deferred(component)


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
	_current_configuration_label.text = (
		"CONFIG  %s  /  %s    [Start or Tab: configure]"
		% [selected_aircraft_label(), selected_map_label()]
	)
