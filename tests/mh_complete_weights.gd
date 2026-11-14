extends SceneTree
const SourceWeights=preload("res://scripts/field/experimental/full_source_weights.gd")
const Palette=preload("res://scripts/field/experimental/native_rig_palette.gd")
var checks:=0
var failures:=0
func check(value:bool,detail:String) -> void:
	checks+=1
	if not value:failures+=1;push_error(detail)
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var path:=OS.get_environment("MH_WEIGHT_FIXTURE")
	if path.is_empty():path="res://assets/mh_lab"
	var sidecar:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path+"/full-influences.json"))
	var actor:Node3D=load(path+"/mh_natural_fullweights.glb").instantiate();root.add_child(actor)
	var skeleton:Skeleton3D=actor.find_children("*","Skeleton3D",true,false)[0]
	check(skeleton.get_bone_count()==163,"complete skeleton missing")
	var reports:=[];var full_tail_vertices:=0
	for instance:MeshInstance3D in actor.find_children("*","MeshInstance3D",true,false):
		var recovered:=SourceWeights.recover(instance,sidecar)
		check(not recovered.has("error"),str(recovered.get("error")))
		if recovered.has("error"):quit(1);return
		var packed:=Palette.pack_textured_mesh(instance.mesh,instance.skin.get_bind_count(),recovered.surfaces)
		check(not packed.has("error"),str(packed.get("error")))
		if packed.has("error"):quit(1);return
		var capture:=Palette.capture(skeleton,instance.skin)
		check(not capture.has("error"),"intact native bind capture failed")
		if capture.has("error"):quit(1);return
		var rest_error:=0.0
		for surface in instance.mesh.get_surface_count():
			var original:=instance.mesh.surface_get_arrays(surface)
			var actual:Array=packed.mesh.surface_get_arrays(surface)
			for attribute in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_TEX_UV2,Mesh.ARRAY_INDEX]:
				check(original[attribute]==actual[attribute],"authored geometry/UV/ID/index changed")
			var weights:PackedFloat32Array=recovered.surfaces[surface].weights
			var joints:PackedInt32Array=recovered.surfaces[surface].joints
			var slots:int=recovered.surfaces[surface].slots
			var vertices:PackedVector3Array=original[Mesh.ARRAY_VERTEX]
			for vertex in vertices.size():
				var p:=Vector3.ZERO
				for slot in slots:
					var pair:=Palette.unpack_weight(packed.tables[surface],vertex,slot)
					check(pair==Vector2(joints[vertex*slots+slot],weights[vertex*slots+slot]),"full source tail or bind altered")
					p+=(capture.transforms[int(pair.x)]*vertices[vertex])*pair.y
				rest_error=maxf(rest_error,p.distance_to(vertices[vertex]))
		check(rest_error<.00002,"rest bind disagreement")
		full_tail_vertices+=recovered.more_than_eight
		reports.append({"node":String(instance.name),"render_vertices":recovered.vertices,"source_more_than8":recovered.more_than_eight,"maximum_source_influences":recovered.max_influences,"rest_position_error_m":rest_error})
	check(full_tail_vertices==33,"expected exact current mother source tail count changed")
	var report:={"source_glb_sha256":FileAccess.get_sha256(path+"/mh_natural_fullweights.glb"),"sidecar_sha256":FileAccess.get_sha256(path+"/full-influences.json"),"checks":checks,"failures":failures,"native_bones":163,"parts":reports,"full_tail_vertices":full_tail_vertices,"graphics":"NOT_RUN","native_8_weight_renderer_is_complete":false,"weights_recovered_by":"exact explicit UV2 sourceID + native named Skin bind","weights_truncated":false,"renormalized_in_adapter":false,"upstream_normalization":"explicit v2 source-transfer factor; raw groups retained","art_pass":false,"shipping_enabled":false}
	DirAccess.make_dir_recursive_absolute("res://artifacts/native-character-parity")
	var f:=FileAccess.open("res://artifacts/native-character-parity/mh-full-source.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
	print("MH_COMPLETE_WEIGHTS ",JSON.stringify(report));actor.queue_free();await process_frame
	quit(0 if failures==0 else 1)
