extends RefCounted
## Density is sampled on the ground in small cells. A close duel receives no
## correction. A dense formation gradually expands towards less occupied ground.
const STEP := 3.0
const WIDTH := 82
const DEPTH := 46
const LAYER := WIDTH*DEPTH
var mass := PackedFloat32Array()
var centers := PackedVector2Array()
var touched := PackedInt32Array()

func _init() -> void:
	mass.resize(LAYER*2)
	centers.resize(LAYER*2)

func clear() -> void:
	for key in touched:
		mass[key]=0.0
		centers[key]=Vector2.ZERO
	touched.clear()

func register(pos: Vector2,load_weight: float,upper: bool) -> int:
	var col:=clampi(floori(pos.x/STEP)+WIDTH/2,1,WIDTH-2)
	var row:=clampi(floori(pos.y/STEP)+DEPTH/2,1,DEPTH-2)
	var key:=col+row*WIDTH+(LAYER if upper else 0)
	if mass[key]==0: touched.append(key)
	mass[key]+=load_weight
	centers[key]+=pos*load_weight
	return key

func ease(pos: Vector2,key: int,id: int) -> Vector2:
	var weight:=mass[key]
	if weight<7.0: return Vector2.ZERO
	var radial:=pos-centers[key]/weight
	var slope:=Vector2(mass[key-1]-mass[key+1],mass[key-WIDTH]-mass[key+WIDTH])
	if radial.length_squared()<0.0064:
		radial=Vector2.from_angle(id*2.39996323)
	var steering: Vector2=radial.normalized()+slope.limit_length(4.0)*0.26
	return steering.limit_length(1.0)*smoothstep(6.0,15.0,weight)

