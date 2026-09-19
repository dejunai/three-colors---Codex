extends RefCounted

# The slice's final beat (Design Bible Part Three, "the ontological crack"): the
# board goes whole, the frame widens, color begins to return, and a glass breaks.
# That glass is the first ordinary sound in a world that has carried only the
# cough. The slice ends on it: no voice, no entity, no fatal ending.
#
# This is authored timing, not a player-driven degradation system. It reads flags
# and drives presentation only; it cannot alter evidence, links, inventory, or any
# input. Every sound carries a protected caption, and the width and color channels
# are not attenuated by the distortion or flicker settings, so the accessible game
# still breaks (Design Laws 4, 8, 9).
#
# The sound rule: instrument voices are the silent-film pit band. The world itself
# has no footsteps, doors, or interface tones. The cough is the only world sound
# until the glass. Adding any ordinary sound before this beat weakens it.

const QUIET_SECONDS = 7.0
const FLAG_ARMED = "tunnel_retreated"
const FLAG_DONE = "glass_broken"

const BOARD = [
	["THE BOARD","The last two cards go up within the same hour. He does not choose the moment, any more than a man chooses the instant a held breath tops out.\n\nBehan's line about inherited money inventing its own reason, beside the ship's name. A cough that answers to nothing living. A passage beneath the sea that no drawing admits."],
	["IN HIS OWN HAND","Beneath them, in handwriting he does not remember producing, two lines have appeared.\n\nTHEY DID NOT SUMMON A MOTHER.\nTHEY SUMMONED SOMETHING AND CALLED IT ONE."],
	["THE ROOM","He checks them against everything he has gathered. They are true, whoever wrote them.\n\nThe board is whole enough. Not the courtroom kind of whole. The other kind."]
]

const AFTER = [
	["THE ROOM","He stands over the pieces in his stocking feet, not moving, one hand at his ear as though the sound were still in it.\n\nIt was small. It was ordinary. It was the first sound in longer than he can account for that his world simply let him have."],
	["WALTER CORWIN","Is that the way sound works?\n\nIs that the way the world is built, and I have simply never once been given the ordinary use of it?"]
]

var glass_player: AudioStreamPlayer
var running := false
var quiet_time := 0.0

func setup(g: Node) -> void:
	glass_player = AudioStreamPlayer.new()
	glass_player.volume_db = -6
	g.add_child(glass_player)

func pending(g: Node) -> bool:
	var flags = g.state.dialogue_state
	return g.state.world == "room" and flags.flag(FLAG_ARMED) and not flags.flag(FLAG_DONE)

# Called from tick_world, i.e. only while the player is free in the world. The
# quiet interval is deliberate: the room, the board and the glass sit in silence
# before anything happens.
func tick(g: Node, delta: float) -> void:
	if running or not pending(g):
		quiet_time = 0.0
		return
	quiet_time += delta
	if quiet_time >= QUIET_SECONDS: begin(g)

func begin(g: Node) -> void:
	if running: return
	running = true
	quiet_time = 0.0
	if glass_player.stream == null: glass_player.stream = build_glass_stream()
	g.playthrough_log.day3_bed_reached()
	g._cards(BOARD, func(): _play(g), "examine")

func _scale(g: Node) -> float:
	return 0.02 if g.test_mode else 1.0

func _wait(g: Node, seconds: float) -> void:
	await g.get_tree().create_timer(seconds * _scale(g)).timeout

func _caption(g: Node, text: String) -> void:
	g.hazard_caption.text = text

func _cough(g: Node, level_db: float) -> void:
	g.cough_player.volume_db = level_db
	g.cough_player.play()

func _play(g: Node) -> void:
	var scale = _scale(g)
	var room = g.estate
	# A held, unclickable page: no world tick, no interaction, no menu can interrupt.
	g.page = "break"
	# Nothing from the interactive world may linger on screen: a stale "[ E ] ..." prompt
	# would tell the player the world is still theirs.
	g.focused = ""
	g.prompt.text = ""
	g.marker.visible = false
	g.create_tween().tween_property(g, "distance", 3.0, 9.0 * scale).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	g.presentation.widen_frame(6.0 * scale)
	g.presentation.return_color(0.5, 8.0 * scale)
	await _wait(g, 1.5)
	if room.has_method("redden_threads"): room.redden_threads()
	await _wait(g, 1.0)
	_caption(g, "[A dry cough.]")
	_cough(g, -10.0)
	await _wait(g, 1.5)
	if room.has_method("amber_glass"): room.amber_glass()
	await _wait(g, 1.0)
	_cough(g, -6.0)
	await _wait(g, 2.0)
	_caption(g, "")
	# Nothing at all for a moment. The cough has stopped; the world has no other sound.
	await _wait(g, 2.0)
	_break_glass(g, room)
	await _wait(g, 4.5)
	_caption(g, "")
	g.cough_player.volume_db = -12.0
	g._cards(AFTER, func(): _finish(g), "dialogue")

func _break_glass(g: Node, room: Node) -> void:
	var flags = g.state.dialogue_state
	flags.set_flag(FLAG_DONE, true)
	# The point of no return: a save from here on resumes at the ending, never
	# inside the beat, so the beat can only ever be seen whole.
	g.state.finished = true
	_caption(g, "[Glass breaking.]")
	glass_player.play()
	if room.has_method("shatter_glass"): room.shatter_glass()
	g.presentation.return_color(0.75, 4.0 * _scale(g))
	g._save_game()

func _finish(g: Node) -> void:
	running = false
	g.staging.debrief(g)

# A struck tumbler and what follows: one hard crack, the ring of a few inharmonic
# partials, then small pieces landing and thinning out. Synthesized, like the
# cough, so the build needs no audio asset. Deterministic: same sound every run.
func build_glass_stream() -> AudioStreamWAV:
	var rate = 44100
	var length = int(rate * 1.6)
	var rng = RandomNumberGenerator.new()
	rng.seed = 1923
	var buffer = PackedFloat32Array()
	buffer.resize(length)
	# Crack: a very short high-passed noise burst.
	var last_noise = 0.0
	for i in int(rate * 0.06):
		var noise = rng.randf_range(-1.0, 1.0)
		var t = float(i) / rate
		buffer[i] += (noise - last_noise) * 0.5 * exp(-t / 0.011)
		last_noise = noise
	# Ring: frequency, gain, decay seconds.
	for partial in [[2140.0, 0.9, 0.16], [3310.0, 0.6, 0.11], [4980.0, 0.45, 0.08], [6720.0, 0.3, 0.06]]:
		var span = mini(length, int(rate * partial[2] * 6.0))
		for i in span:
			var t = float(i) / rate
			buffer[i] += sin(TAU * partial[0] * t) * partial[1] * exp(-t / partial[2]) * 0.55
	# Pieces landing: many small ticks, fewer as they settle.
	for n in 22:
		var start = int(rate * (0.045 + pow(rng.randf(), 1.7) * 0.95))
		var frequency = rng.randf_range(2400.0, 7200.0)
		var gain = rng.randf_range(0.10, 0.30)
		var decay = rng.randf_range(0.004, 0.016)
		var span = mini(length - start, int(rate * decay * 6.0))
		for i in span:
			var t = float(i) / rate
			buffer[start + i] += sin(TAU * frequency * t) * gain * exp(-t / decay)
	var peak = 0.001
	for sample in buffer: peak = maxf(peak, absf(sample))
	var bytes = PackedByteArray()
	bytes.resize(length * 2)
	for i in length: bytes.encode_s16(i * 2, int(clampf(buffer[i] / peak * 0.9, -1.0, 1.0) * 32767.0))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream
