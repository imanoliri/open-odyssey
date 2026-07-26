class_name AircraftAudioController
extends Node3D

@export var aircraft_path: NodePath
@export var mix_rate := 22050.0
@export var engine_idle_frequency_hz := 42.0
@export var engine_full_frequency_hz := 135.0
@export var engine_idle_amplitude := 0.045
@export var engine_max_amplitude := 0.34
@export var wind_full_level_speed_metres_per_second := 75.0
@export var wind_max_amplitude := 0.34
@export var wind_whistle_min_frequency_hz := 420.0
@export var wind_whistle_max_frequency_hz := 1500.0
@export var wind_whistle_mix := 0.08
@export_range(8, 64, 1) var wind_noise_interpolation_samples := 24
@export var level_smoothing := 5.0

@onready var engine_player: AudioStreamPlayer3D = $Engine
@onready var wind_player: AudioStreamPlayer = $Wind

var aircraft: PrototypeAircraft
var engine_playback: AudioStreamGeneratorPlayback
var wind_playback: AudioStreamGeneratorPlayback
var engine_phase := 0.0
var wind_noise_from := 0.0
var wind_noise_target := 0.0
var wind_noise_samples_remaining := 0
var wind_baseline_sample := 0.0
var wind_whistle_phase := 0.0
var wind_whistle_secondary_phase := 0.0
var wind_wander_phase := 0.0
var current_engine_amplitude := 0.0
var current_wind_amplitude := 0.0
var current_engine_frequency_hz := 0.0
var current_wind_whistle_frequency_hz := 0.0


func _ready() -> void:
	aircraft = get_node_or_null(aircraft_path) as PrototypeAircraft
	if aircraft == null:
		aircraft = get_parent() as PrototypeAircraft

	var engine_stream := AudioStreamGenerator.new()
	engine_stream.mix_rate = mix_rate
	engine_stream.buffer_length = 0.25
	engine_player.stream = engine_stream
	engine_player.play()
	engine_playback = (
		engine_player.get_stream_playback()
		as AudioStreamGeneratorPlayback
	)

	var wind_stream := AudioStreamGenerator.new()
	wind_stream.mix_rate = mix_rate
	wind_stream.buffer_length = 0.25
	wind_player.stream = wind_stream
	wind_player.play()
	wind_playback = (
		wind_player.get_stream_playback()
		as AudioStreamGeneratorPlayback
	)


func _physics_process(delta: float) -> void:
	if aircraft == null:
		return

	var level_blend := 1.0 - exp(-level_smoothing * delta)
	current_engine_amplitude = lerpf(
		current_engine_amplitude,
		engine_amplitude_for_throttle(aircraft.throttle),
		level_blend
	)
	current_wind_amplitude = lerpf(
		current_wind_amplitude,
		wind_amplitude_for_speed(aircraft.indicated_airspeed),
		level_blend
	)
	current_engine_frequency_hz = lerpf(
		current_engine_frequency_hz,
		engine_frequency_for_throttle(aircraft.throttle),
		level_blend
	)
	current_wind_whistle_frequency_hz = lerpf(
		current_wind_whistle_frequency_hz,
		wind_whistle_frequency_for_speed(aircraft.indicated_airspeed),
		level_blend
	)

	_fill_engine_buffer()
	_fill_wind_buffer()


func _exit_tree() -> void:
	if engine_player != null:
		engine_player.stop()
	if wind_player != null:
		wind_player.stop()
	engine_playback = null
	wind_playback = null


func engine_amplitude_for_throttle(throttle_value: float) -> float:
	return lerpf(
		engine_idle_amplitude,
		engine_max_amplitude,
		clampf(throttle_value, 0.0, 1.0)
	)


func engine_frequency_for_throttle(throttle_value: float) -> float:
	return lerpf(
		engine_idle_frequency_hz,
		engine_full_frequency_hz,
		clampf(throttle_value, 0.0, 1.0)
	)


func wind_amplitude_for_speed(speed_metres_per_second: float) -> float:
	return _normalized_wind_speed(speed_metres_per_second) * wind_max_amplitude


func wind_whistle_frequency_for_speed(
	speed_metres_per_second: float
) -> float:
	return lerpf(
		wind_whistle_min_frequency_hz,
		wind_whistle_max_frequency_hz,
		_normalized_wind_speed(speed_metres_per_second)
	)


func _normalized_wind_speed(speed_metres_per_second: float) -> float:
	return clampf(
		speed_metres_per_second
		/ maxf(wind_full_level_speed_metres_per_second, 0.001),
		0.0,
		1.0
	)


func _fill_engine_buffer() -> void:
	if engine_playback == null:
		return

	for frame in engine_playback.get_frames_available():
		engine_phase = fmod(
			engine_phase
			+ TAU * current_engine_frequency_hz / mix_rate,
			TAU
		)
		var propeller_wave := (
			sin(engine_phase)
			+ 0.32 * sin(engine_phase * 2.0)
			+ 0.14 * sin(engine_phase * 3.0)
		) / 1.46
		var sample := propeller_wave * current_engine_amplitude
		engine_playback.push_frame(Vector2(sample, sample))


func _fill_wind_buffer() -> void:
	if wind_playback == null:
		return

	for frame in wind_playback.get_frames_available():
		var clean_air_noise := _next_interpolated_airflow_sample()

		wind_whistle_phase = fmod(
			wind_whistle_phase
			+ TAU * current_wind_whistle_frequency_hz / mix_rate,
			TAU
		)
		wind_whistle_secondary_phase = fmod(
			wind_whistle_secondary_phase
			+ TAU
			* current_wind_whistle_frequency_hz
			* 1.43
			/ mix_rate,
			TAU
		)
		wind_wander_phase = fmod(
			wind_wander_phase + TAU * 0.65 / mix_rate,
			TAU
		)

		var whistle_envelope := 0.72 + 0.28 * sin(wind_wander_phase)
		var whistle := (
			sin(wind_whistle_phase)
			+ 0.32 * sin(wind_whistle_secondary_phase)
		) / 1.32
		var sample := (
			clean_air_noise * 0.78
			+ whistle * wind_whistle_mix * whistle_envelope
		) * current_wind_amplitude
		wind_playback.push_frame(Vector2(sample, sample))


func _next_interpolated_airflow_sample() -> float:
	var interval := maxi(wind_noise_interpolation_samples, 1)
	if wind_noise_samples_remaining <= 0:
		wind_noise_from = wind_noise_target
		wind_noise_target = randf_range(-1.0, 1.0)
		wind_noise_samples_remaining = interval

	var progress := (
		1.0
		- float(wind_noise_samples_remaining) / float(interval)
	)
	var smooth_progress := progress * progress * (3.0 - 2.0 * progress)
	var interpolated_noise := lerpf(
		wind_noise_from,
		wind_noise_target,
		smooth_progress
	)
	wind_noise_samples_remaining -= 1

	wind_baseline_sample = lerpf(
		wind_baseline_sample,
		interpolated_noise,
		0.004
	)
	return (interpolated_noise - wind_baseline_sample) * 1.25
