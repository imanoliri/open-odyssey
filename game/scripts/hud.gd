extends Control

@export var aircraft_path: NodePath

@onready var telemetry_label: Label = %Telemetry
var aircraft: PrototypeAircraft


func _ready() -> void:
	aircraft = get_node_or_null(aircraft_path) as PrototypeAircraft
	if aircraft == null:
		aircraft = get_parent().get_node_or_null(
			"PlayerAircraft"
		) as PrototypeAircraft


func _process(_delta: float) -> void:
	if aircraft != null:
		telemetry_label.text = (
			aircraft.telemetry_text()
			+ "\nCONTROLLER %s" % _controller_name()
		)


func _controller_name() -> String:
	var connected := Input.get_connected_joypads()
	if connected.is_empty():
		return "keyboard only"
	return Input.get_joy_name(connected[0])
