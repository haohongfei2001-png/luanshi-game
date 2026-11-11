extends Node
## Short original mono waveforms, generated once; limit simultaneous combat voices.
var streams := {}
var voices: Array[AudioStreamPlayer] = []
var next := 0
func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed=803
	for kind in ["clash","shot","horn","wood"]:
		var clip := AudioStreamWAV.new()
		clip.format=AudioStreamWAV.FORMAT_16_BITS
		clip.mix_rate=22050
		var length := 0.69 if kind=="horn" else 0.16
		var data := PackedByteArray()
		var count := ceili(clip.mix_rate*length)
		data.resize(count*2)
		for i in count:
			var t := float(i)/clip.mix_rate
			var v := 0.0
			match kind:
				"horn": v=(sin(TAU*183*t)+0.42*sin(TAU*366*t))*minf(1,t*19)*pow(1-t/length,1.4)
				"shot": v=rng.randf_range(-1,1)*exp(-t*55)+0.42*sin(TAU*(370-550*t)*t)*exp(-t*33)
				"wood": v=(sin(TAU*108*t)+0.32*rng.randf_range(-1,1))*exp(-t*28)
				_: v=(0.47*rng.randf_range(-1,1)+0.4*sin(TAU*1327*t)+0.18*sin(TAU*2184*t))*exp(-t*34)
			data.encode_s16(i*2,roundi(clampf(v,-1,1)*15000))
		clip.data=data
		streams[kind]=clip
	for i in 4:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
func cue(kind: String,volume: float) -> void:
	var voice := voices[next]
	voice.stream=streams[kind]
	voice.volume_db=volume
	voice.play()
	next=(next+1)%voices.size()
