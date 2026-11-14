extends SceneTree
## Actual retargeted mother poses, including all >8 source influences. CPU data
## verification only; not image parity, contact quality, art or performance proof.
const SourceWeights=preload("res://scripts/field/experimental/full_source_weights.gd")
const Palette=preload("res://scripts/field/experimental/native_rig_palette.gd")
const Reference=preload("res://scripts/field/experimental/full_weight_reference.gd")
var checks:=0;var failures:=0
func check(value:bool,detail:String) -> void:
	checks+=1
	if not value:failures+=1;push_error(detail)
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var folder:=OS.get_environment("MH_WEIGHT_FIXTURE")
	if folder.is_empty():folder="res://assets/mh_lab"
	var source_path:=folder+"/mh_natural_animated_full.glb"
	var sidecar_path:=folder+"/full-influences.json"
	var source_hash:=FileAccess.get_sha256(source_path);var sidecar_hash:=FileAccess.get_sha256(sidecar_path)
	var sidecar:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(sidecar_path))
	var actor:Node3D=load(source_path).instantiate();root.add_child(actor)
	var skeleton:Skeleton3D=actor.find_children("*","Skeleton3D",true,false)[0]
	var player:AnimationPlayer=actor.find_children("*","AnimationPlayer",true,false)[0]
	player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	check(skeleton.get_bone_count()==163,"complete skeleton missing")
	var entries:=[];var original_arrays:=[];var rows:=[]
	for instance:MeshInstance3D in actor.find_children("*","MeshInstance3D",true,false):
		var recovered:=SourceWeights.recover(instance,sidecar)
		check(not recovered.has("error"),str(recovered))
		if recovered.has("error"):quit(1);return
		entries.append({"instance":instance,"full":recovered})
		var surfaces:=[]
		for surface in instance.mesh.get_surface_count():surfaces.append(instance.mesh.surface_get_arrays(surface))
		original_arrays.append(surfaces)
	var clips:=["Idle","Walk","Jog_Fwd","Sprint","Sword_Idle","Sword_Attack","Hit_Chest","Hit_Head","Death01"]
	for clip:String in clips:
		check(player.has_animation(clip),"missing actual mother clip "+clip)
		if not player.has_animation(clip):continue
		for phase:float in [0.,.35,.7]:
			player.play(clip);player.seek(player.get_animation(clip).length*phase,true);player.advance(0.)
			var row:={"clip":clip,"phase":phase,"parts":[],"complete_vertices":0,"complete_tail_vertices":0}
			for index in entries.size():
				var entry:Dictionary=entries[index];var instance:MeshInstance3D=entry.instance
				var captured:=Palette.capture(skeleton,instance.skin)
				check(not captured.has("error"),str(captured.get("error")))
				if captured.has("error"):quit(1);return
				var reference:=Reference.deform(instance.mesh,entry.full.surfaces,captured.transforms)
				check(not reference.has("error"),str(reference.get("error")))
				if reference.has("error"):quit(1);return
				for surface in instance.mesh.get_surface_count():
					var original:Array=original_arrays[index][surface]
					var current:Array=instance.mesh.surface_get_arrays(surface)
					var posed:Array=reference.mesh.surface_get_arrays(surface)
					for attribute in Mesh.ARRAY_MAX:check(original[attribute]==current[attribute],"oracle mutated original source arrays")
					for attribute in [Mesh.ARRAY_TEX_UV,Mesh.ARRAY_TEX_UV2,Mesh.ARRAY_COLOR,Mesh.ARRAY_CUSTOM0,Mesh.ARRAY_CUSTOM1,Mesh.ARRAY_CUSTOM2,Mesh.ARRAY_CUSTOM3,Mesh.ARRAY_INDEX]:check(original[attribute]==posed[attribute],"reference changed original non-deforming attributes")
					check(reference.mesh.surface_get_material(surface)==instance.mesh.surface_get_material(surface),"reference replaced author material")
					check(posed[Mesh.ARRAY_BONES]==null and posed[Mesh.ARRAY_WEIGHTS]==null,"CPU reference would be double-skinned")
					var vertices:PackedVector3Array=posed[Mesh.ARRAY_VERTEX]
					for position in vertices:check(position.is_finite() and position.length()<20.,"nonfinite or explosive actual pose")
				row.complete_vertices+=reference.vertices;row.complete_tail_vertices+=reference.more_than_eight
				var bounds:AABB=reference.mesh.get_aabb()
				row.parts.append({"node":String(instance.name),"vertices":reference.vertices,"tail_vertices":reference.more_than_eight,"aabb_position":[bounds.position.x,bounds.position.y,bounds.position.z],"aabb_size":[bounds.size.x,bounds.size.y,bounds.size.z]})
			check(row.complete_vertices==20159 and row.complete_tail_vertices==33,"frozen full mother counts changed")
			rows.append(row);print("MH_FULL_POSE_REFERENCE ",clip," ",phase," vertices=",row.complete_vertices," tail=",row.complete_tail_vertices)
	check(FileAccess.get_sha256(source_path)==source_hash and FileAccess.get_sha256(sidecar_path)==sidecar_hash,"frozen input files changed")
	var report:={"source_glb_sha256":source_hash,"sidecar_sha256":sidecar_hash,"native_bones":163,"clips":clips,"samples":rows,"checks":checks,"failures":failures,"graphics":"NOT_RUN","feet_contacts":"NOT_VALIDATED","weapon_contacts":"NOT_VALIDATED","art_pass":false,"shipping_enabled":false,"full_source_weights":true,"eight_slot_native_skin_used_as_oracle":false,"reference_kind":"CPU per-influence affine skin with original material/topology/UV preserved"}
	DirAccess.make_dir_recursive_absolute("res://artifacts/native-character-parity")
	var file:=FileAccess.open("res://artifacts/native-character-parity/mh-full-pose-reference.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	print("MH_FULL_POSE_REFERENCE_DONE ",checks," checks ",failures," failures")
	actor.queue_free();await process_frame;quit(0 if failures==0 else 1)
