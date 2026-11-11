extends Node
## Original, deterministic instrument and contact one-shots. Three stereo prints of
## each waveform keep the event's direction without one audio node per soldier.
var streams: Dictionary={}
var voices: Array[AudioStreamPlayer]=[]
var next:=0

func _ready() -> void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=803
	for kind: String in ["clash","shot","horn","wood","shield","step","hoof","drum","swing","impact","wind"]:
		var length:=0.23
		if kind=="horn": length=1.14
		elif kind=="drum": length=0.68
		elif kind=="wind": length=2.1
		var count:=ceili(22050*length)
		var mono:=PackedFloat32Array()
		mono.resize(count)
		var low:=0.0
		for i in count:
			var t:=i/22050.0
			var noise:=rng.randf_range(-1,1)
			low=lerpf(low,noise,0.12)
			var v:=0.0
			match kind:
				"horn":
					var pitch:=TAU*(181*t+2.7*t*t+0.16*sin(11*t))
					v=(sin(pitch)+0.38*sin(2*pitch)+0.13*sin(3*pitch))*minf(1,t*11)*pow(1.0-t/length,1.2)
				"shot": v=(0.76*noise+0.4*sin(TAU*(640-900*t)*t))*exp(-t*31)
				"wood": v=(sin(TAU*(116-54*t)*t)+0.7*low)*exp(-t*20)
				"shield": v=(0.68*sin(TAU*218*t)+0.62*low+0.21*sin(TAU*843*t))*exp(-t*23)
				"step": v=(1.6*low+0.44*sin(TAU*(97-85*t)*t))*exp(-t*35)
				"hoof":
					var t2:=maxf(0,t-0.080)
					v=(sin(TAU*139*t)+1.2*low)*exp(-t*42)
					if t>0.080: v+=(0.56*sin(TAU*121*t2)+0.75*low)*exp(-t2*42)
				"drum": v=(sin(TAU*(93*t+0.49*(1-exp(-16*t))))+0.28*sin(TAU*158*t)+0.32*low)*exp(-t*8.6)
				"swing": v=low*3.2*sin(PI*t/length)*exp(-t*3)
				"impact": v=(0.72*noise+0.67*sin(TAU*181*t)+0.53*sin(TAU*936*t))*exp(-t*29)
				"wind": v=2.7*low*sin(PI*t/length)*(0.7+0.23*sin(3.7*t))
				_: v=(0.47*noise+0.4*sin(TAU*1327*t)+0.18*sin(TAU*2184*t))*exp(-t*28)
			mono[i]=clampf(v,-1.0,1.0)*minf(1.0,t*1300.0)
		var stereo: Array[AudioStreamWAV]=[]
		for direction in 3:
			var clip:=AudioStreamWAV.new()
			clip.format=AudioStreamWAV.FORMAT_16_BITS
			clip.mix_rate=22050
			clip.stereo=true
			var bytes:=PackedByteArray()
			bytes.resize(count*4)
			for i in count:
				bytes.encode_s16(i*4,roundi(mono[i]*20400*(0.47 if direction==2 else 0.94)))
				bytes.encode_s16(i*4+2,roundi(mono[i]*20400*(0.47 if direction==0 else 0.94)))
			clip.data=bytes
			stereo.append(clip)
		streams[kind]=stereo
	# Dedicated voices let a horn, drum and breeze finish over clustered contacts.
	for i in 10:
		var voice:=AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)

func cue(kind: String,volume: float,pan: float=0.0) -> void:
	var index:=next
	match kind:
		"horn": index=7
		"drum": index=8
		"wind": index=9
		_: next=(next+1)%7
	var voice:=voices[index]
	voice.stream=streams[kind][0 if pan< -0.20 else (2 if pan>0.20 else 1)]
	voice.volume_db=volume
	voice.play()
