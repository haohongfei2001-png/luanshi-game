extends RefCounted
## Exact affine palette reconstruction for unmounted regular spear test actors.
## Deliberately excludes shader cloth flutter/approach-lean: experimental limits.
var bank:Image
var native_pike:=false

func _init(image:Image) -> void:
	bank=image
	assert(bank.get_width()==528 and bank.get_height() in [1684,1756])
	native_pike=bank.get_height()==1756

func address(data:Color) -> Vector3:
	var code:=floori(data.r*128.)
	assert(code<64)
	var state:=code%8
	var slot:=(code/8)%4
	var phase:=data.g
	var clip:=1
	if state==0:
		clip=floori(phase*32.) if phase>.001 or slot==3 else 1
		phase=data.b
	elif state in [1,2]: clip=(2 if state==1 else 6)+slot
	elif state in [3,4]: clip=state+7
	elif state==5:
		clip=12
		phase=data.b
	else: clip=state+7
	var kit:=2 if (code/32)%2==1 and state in [1,2] else 3
	var strip:=kit*31+clip
	var lot:=floori(data.a*8.)
	var variant:=1 if lot in [1,4] else (2 if lot in [2,5,7] else 0)
	var carry:=0 if clip==1 else (1 if clip==0 else (clip-14 if clip>=16 and clip<=22 else (clip+7 if clip>=2 and clip<=9 else -1)))
	if kit==3 and variant>0 and carry>=0: strip=279+(variant-1)*17+carry
	if clip in [10,11] and slot in [1,2]: strip=381+kit*4+(0 if clip==10 else 2)+slot-1
	phase=clampf(phase,0.,1.)
	var frame:=phase*(32. if clip in [0,1,12] or clip>=15 else 31.)
	if native_pike and kit==3 and clip in [2,6]:
		var segment:=mini(floori(phase*8.),7)
		strip=423+(8 if clip==6 else 0)+segment
		frame=(phase*8.-segment)*31.
	return Vector3(strip,frame,clip)

func _raw(bone:int,strip:int,frame:float,row:int) -> Color:
	var x:=bone*33+floori(frame)
	var a:=bank.get_pixel(x,strip*4+row)
	return a.lerp(bank.get_pixel(x+1,strip*4+row),fposmod(frame,1.)) if fposmod(frame,1.)>0. else a

func poses(data:Color) -> Array[Transform3D]:
	var at:=address(data)
	var result:Array[Transform3D]=[]
	for bone:int in 16:
		var hi:=_raw(bone,int(at.x),at.y,0)
		var lo:=_raw(bone,int(at.x),at.y,1)
		var q:=Quaternion((hi.r*256.+lo.r)*2./257.-1.,(hi.g*256.+lo.g)*2./257.-1.,(hi.b*256.+lo.b)*2./257.-1.,(hi.a*256.+lo.a)*2./257.-1.).normalized()
		hi=_raw(bone,int(at.x),at.y,2)
		lo=_raw(bone,int(at.x),at.y,3)
		var origin:=Vector3((hi.r*256.+lo.r)/257.-.5,(hi.g*256.+lo.g)/257.-.5,(hi.b*256.+lo.b)/257.-.5)*6.
		result.append(Transform3D(Basis(q),origin))
	return result
