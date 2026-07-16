extends Node

const MIX_RATE := 22050

var _streams: Dictionary[StringName, AudioStreamWAV] = {}


func _ready() -> void:
	_streams[&"ui"] = _make_tone(520.0, 650.0, 0.07, 0.16)
	_streams[&"shot"] = _make_tone(680.0, 220.0, 0.08, 0.14, true)
	_streams[&"pickup"] = _make_tone(520.0, 980.0, 0.12, 0.18)
	_streams[&"repair"] = _make_tone(160.0, 430.0, 0.42, 0.22)
	_streams[&"upgrade"] = _make_chime()
	_streams[&"launch"] = _make_tone(90.0, 240.0, 0.36, 0.2, true)
	_streams[&"defeat"] = _make_noise_burst(0.14, 0.16)
	_streams[&"boss_defeat"] = _make_noise_burst(0.55, 0.25)


func play_ui() -> void:
	_play(&"ui", -8.0)


func play_shot() -> void:
	_play(&"shot", -13.0, randf_range(0.96, 1.04))


func play_pickup() -> void:
	_play(&"pickup", -10.0, randf_range(0.96, 1.08))


func play_repair() -> void:
	_play(&"repair", -7.0)


func play_upgrade() -> void:
	_play(&"upgrade", -6.0)


func play_launch() -> void:
	_play(&"launch", -8.0)


func play_defeat(is_boss: bool = false) -> void:
	_play(&"boss_defeat" if is_boss else &"defeat", -10.0 if not is_boss else -5.0)


func stop_all() -> void:
	for child: Node in get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()
		child.free()


func _play(cue: StringName, volume_db: float, pitch_scale: float = 1.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var stream: AudioStreamWAV = _streams.get(cue)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


func _make_tone(
	start_frequency: float,
	end_frequency: float,
	duration: float,
	volume: float,
	square_wave: bool = false
) -> AudioStreamWAV:
	var sample_count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var phase := 0.0
	for index in sample_count:
		var progress := float(index) / float(sample_count)
		var frequency := lerpf(start_frequency, end_frequency, progress)
		phase += TAU * frequency / MIX_RATE
		var carrier := signf(sin(phase)) if square_wave else sin(phase)
		var envelope := _envelope(progress)
		data.encode_s16(index * 2, int(carrier * envelope * volume * 32767.0))
	return _stream_from_data(data)


func _make_chime() -> AudioStreamWAV:
	var duration := 0.48
	var sample_count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in sample_count:
		var time := float(index) / MIX_RATE
		var progress := time / duration
		var sample := sin(TAU * 523.25 * time) * 0.45
		sample += sin(TAU * 659.25 * time) * 0.32
		sample += sin(TAU * 783.99 * time) * 0.23
		sample *= _envelope(progress) * 0.22
		data.encode_s16(index * 2, int(sample * 32767.0))
	return _stream_from_data(data)


func _make_noise_burst(duration: float, volume: float) -> AudioStreamWAV:
	var sample_count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(duration * 10000.0) + 8472
	for index in sample_count:
		var progress := float(index) / float(sample_count)
		var low_rumble := sin(TAU * lerpf(110.0, 38.0, progress) * float(index) / MIX_RATE)
		var noise := rng.randf_range(-1.0, 1.0)
		var sample := (noise * 0.7 + low_rumble * 0.3) * pow(1.0 - progress, 2.0) * volume
		data.encode_s16(index * 2, int(sample * 32767.0))
	return _stream_from_data(data)


func _stream_from_data(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream


func _envelope(progress: float) -> float:
	var attack := smoothstep(0.0, 0.06, progress)
	var release := 1.0 - smoothstep(0.58, 1.0, progress)
	return attack * release
