extends SceneTree
const Surface:=preload("res://tools/art/authored_reset/surface_authoring.gd")
func _initialize() -> void:build.call_deferred()
func build() -> void:
	var master:=Node3D.new();master.name="AuthoredResetSupport_NOT_FINAL_ART"
	master.set_meta("stage","PRODUCTION_SUPPORT_NOT_ART_CANDIDATE")
	var group:=Node3D.new();group.name="ContinuousSurveySurface";master.add_child(group);group.owner=master
	var material:=StandardMaterial3D.new();material.albedo_color=Color("8f7957");material.roughness=1.
	var triangles:=0
	for x:int in range(-48,96,16):
		for z:int in range(-64,64,16):
			var node:=MeshInstance3D.new();node.name="Surface_%s_%s"%[x,z]
			node.mesh=Surface.tile(Vector2(x,z));node.mesh.surface_set_material(0,material)
			group.add_child(node);node.owner=master;triangles+=2048
	# Production sockets are transforms, NOT fabricated replacement art.
	for key:String in ["BridgeMain","BridgeNorth","BridgeSouth","BridgeMoat","Gate","NorthWall","SouthWall"]:
		var socket:=Marker3D.new();socket.name=key
		socket.position={"BridgeMain":Vector3(-32,.13,0),"BridgeNorth":Vector3(-32,.13,-35),"BridgeSouth":Vector3(-32,.13,35),"BridgeMoat":Vector3(24,.13,0),"Gate":Vector3(48,0,0),"NorthWall":Vector3(48,0,-15.75),"SouthWall":Vector3(48,0,15.75)}[key]
		master.add_child(socket);socket.owner=master
	var packed:=PackedScene.new();assert(packed.pack(master)==OK)
	var out:="user://authored-reset-support.scn";assert(ResourceSaver.save(packed,out,ResourceSaver.FLAG_COMPRESS)==OK)
	print("SUPPORT_SCENE_BAKED ",JSON.stringify({"path":ProjectSettings.globalize_path(out),"tiles":group.get_child_count(),"triangles":triangles,"normal_game_changed":false,"art_status":"NOT_ACCEPTED"}))
	master.free();quit()
