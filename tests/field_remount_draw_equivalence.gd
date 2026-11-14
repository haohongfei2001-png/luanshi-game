extends SceneTree
## Actual draw transforms including near/rank horses form a camera-order independent signature.
const Field:=preload("res://scripts/field/battle.gd")
const View:=preload("res://scripts/field/presentation.gd")
const Ground:=preload("res://scripts/field/ground.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var b:=Field.new()
	b.setup(512,Field.SEED,3,true,true,512,true)
	b.start()
	for i in 210: b.step()
	var cam:=Camera3D.new()
	cam.projection=Camera3D.PROJECTION_ORTHOGONAL
	cam.size=22.
	root.add_child(cam)
	cam.make_current()
	var center:=Ground.BRIDGE_VIEW
	var p:=Ground.unit_point(center,true)
	var yaw:=deg_to_rad(-33.)
	var pitch:=.886198
	cam.position=p+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*77.5
	cam.look_at(p)
	var view:=View.new()
	root.add_child(view)
	view.configure(b)
	var tags:=PackedStringArray()
	var captures:=0
	for tick in 118:
		if tick>0: b.step()
		for alpha:float in [0.,.42,.97]:
			# Alternate the regular bridgehead shot and an empty verge, including a
			# camera whose visible horses have no rider corpse in its padded view.
			var anchor:=center if tick%3 else center+Vector2(-1.5,20.)
			cam.position=p+Vector3(anchor.x-center.x,0.,anchor.y-center.y)+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*77.5
			view.sync_view(anchor,Vector2(30,27),alpha,22.)
			for batch in [view.horse,view.horse_rank]:
				var figures:=PackedStringArray()
				for k in batch.used:
					var transform:Transform3D=batch.mesh.get_instance_transform(k)
					var data:Color=batch.mesh.get_instance_custom_data(k)
					figures.append(str(transform," ",data))
				figures.sort()
				tags.append(" ".join(figures).sha256_text())
			captures+=1
	print("HORSE_DRAW ",JSON.stringify({"frames":captures,"batch_signatures":tags.size(),"signature":"".join(tags).sha256_text(),"damage":Array(b.hits),"losses":Array(b.losses),"visible":view.visible_soldiers}))
	view.free()
	cam.free()
	quit()
