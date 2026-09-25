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
const GLASS_STREAM: AudioStream = preload("res://glass_shatter.ogg")

const BOARD = [
	["THE BOARD","The last two cards go up within the same hour. He does not choose the moment, any more than a man chooses the instant a held breath tops out.\n\nBehan's line about inherited money inventing its own reason, beside the ship's name. A cough that answers to nothing living. A passage beneath the sea that no drawing admits."],
	["IN HIS OWN HAND","Beneath them, in handwriting he does not remember producing, two lines have appeared.\n\nTHEY DID NOT SUMMON A MOTHER.\nTHEY SUMMONED SOMETHING AND CALLED IT ONE."],
	["THE ROOM","He checks them against everything he has gathered. They are true, whoever wrote them.\n\nThe board is whole enough. Not the courtroom kind of whole. The other kind."]
]

func board_cards(g: Node) -> Array:
	var lead_line: String
	if g.state.evidence.has("behan_name") or g.state.dialogue_state.topic_done("behan", "behan_name"):
		lead_line = "Behan's line about inherited money inventing its own reason, beside the ship's name."
	else:
		lead_line = "The steward's words about what the gentlemen gathered for in secret, beside Kessler's name."
	return [
		["THE BOARD", "The last two cards go up within the same hour. He does not choose the moment, any more than a man chooses the instant a held breath tops out.\n\n" + lead_line + " A cough that answers to nothing living. A passage beneath the sea that no drawing admits."],
		["IN HIS OWN HAND", "Beneath them, in handwriting he does not remember producing, two lines have appeared.\n\nTHEY DID NOT SUMMON A MOTHER.\nTHEY SUMMONED SOMETHING AND CALLED IT ONE."],
		["THE ROOM", "He checks them against everything he has gathered. They are true, whoever wrote them.\n\nThe board is whole enough. Not the courtroom kind of whole. The other kind."]
	]

var glass_player: AudioStreamPlayer
var running := false
var quiet_time := 0.0

func setup(g: Node) -> void:
	glass_player = AudioStreamPlayer.new()
	glass_player.volume_db = -6
	glass_player.stream = GLASS_STREAM
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
	g.playthrough_log.day3_bed_reached()
	g._cards(board_cards(g), func(): _play(g), "examine")

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
	# The glass is the final authored story beat. The tester questions that follow
	# are explicitly outside the fiction; no dialogue card softens or explains the
	# break after the player hears it.
	_finish(g)

func _break_glass(g: Node, room: Node) -> void:
	var flags = g.state.dialogue_state
	flags.set_flag(FLAG_DONE, true)
	# The point of no return: a save from here on resumes at the ending, never
	# inside the beat, so the beat can only ever be seen whole.
	g.state.finished = true
	_caption(g, "[Glass breaking.]")
	if g.rig.has_method("play_surprise"): g.rig.play_surprise()
	glass_player.play()
	if room.has_method("shatter_glass"): room.shatter_glass()
	g.presentation.return_color(0.75, 4.0 * _scale(g))
	g._save_game()

func _finish(g: Node) -> void:
	running = false
	if g.rig.has_method("finish_context_animation"): g.rig.finish_context_animation()
	g.staging.debrief(g)
