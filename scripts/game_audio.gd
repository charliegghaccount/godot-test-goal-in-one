extends Node
var muted = false
var voice: AudioStreamPlayer
var last_effect = {}
static func announcement_for(shots: int, par: int, thresholds: Vector2i) -> String:
	if shots==1: return "goal-in-one"
	var stars = 3 if shots<=thresholds.x else (2 if shots<=thresholds.y else 1)
	if stars==2: return "goal"
	if stars==1: return "should-have-done-better" if shots>=par+2 else "solid-effort"
	return ""
func _ready():
	voice = AudioStreamPlayer.new()
	voice.volume_db = -3
	add_child(voice)
func toggle():
	muted = not muted
	if muted:
		voice.stop()
		for child in get_children():
			if child!=voice: child.queue_free()
func announce(shots: int, par: int, thresholds: Vector2i):
	voice.stop()
	var name = announcement_for(shots,par,thresholds)
	if muted or name.is_empty() or DisplayServer.get_name()=="headless": return
	voice.stream = load("res://assets/announcer/"+name+".mp3")
	voice.play()
func effect(kind: String):
	if muted or DisplayServer.get_name()=="headless": return
	var now = Time.get_ticks_msec()
	if now-int(last_effect.get(kind,-1000))<90 or get_child_count()>6: return
	last_effect[kind] = now
	var frequency = {"shot":600,"hit":190,"net":210,"spring":230,"boost":340,"switch":950,"reset":150}.get(kind,400)
	var sound = AudioStreamPlayer.new()
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var data = PackedByteArray()
	var count = 3307
	data.resize(count*2)
	for i in count:
		var t = float(i)/count
		data.encode_s16(i*2,int(sin(TAU*frequency*(1-t*0.2)*i/22050.0)*4000*(1-t)))
	wav.data = data
	sound.stream = wav
	sound.volume_db = -10 if voice.playing else -4
	add_child(sound)
	sound.finished.connect(sound.queue_free)
	sound.play()

func _exit_tree():
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
