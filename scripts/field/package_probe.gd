extends RefCounted
## Runs through the exported main scene and shared command/weapon entry points.
const Save := preload("res://scripts/field/save.gd")
const Arms := preload("res://scripts/field/arms.gd")
const Battle := preload("res://scripts/field/battle.gd")
const Field := preload("res://scripts/field/controller.gd")

static func run(tree: SceneTree,scene: Field) -> void:
	await tree.process_frame
	scene.hud.weapon.select(Arms.Kit.BOW)
	scene.hud.weapon.item_selected.emit(Arms.Kit.BOW)
	scene.hud.go.pressed.emit()
	var b:=scene.battle
	b.command(0,Battle.Mission.PRESS,Battle.Channel.HORN)
	var limit := Time.get_ticks_msec()+45000
	while b.tick<100 and b.result=="" and Time.get_ticks_msec()<limit:
		await tree.physics_frame
		if b.tick==35: scene.pan_to(Vector2(0,-20))
		if b.tick==70: scene.pan_to(Vector2(0,20))
	var saved := Save.snapshot(b)
	var loaded := Save.restore(bytes_to_var(var_to_bytes(saved)))
	var ok := b.side_size==512 and b.roster.size()==1057 and b.hits[0]>0 and b.hits[1]>0 and b.arrow_count>0 and b.tick>=100 and b.messages_arrived>0
	ok=ok and scene.view.visible_soldiers>0 and loaded!=null and Save.snapshot(loaded)==saved
	var image_path:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--field-proof="): image_path=arg.trim_prefix("--field-proof=")
	if image_path!="":
		ok=ok and DisplayServer.get_name()!="headless"
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			var img:=tree.root.get_texture().get_image()
			var colors:={}
			for x in range(16,img.get_width(),16):
				for y in range(12,img.get_height(),16):
					colors[img.get_pixel(x,y).to_rgba32()]=true
			ok=ok and colors.size()>50 and img.save_png(image_path)==OK
	var row:=b.report()
	row.merge({"display":DisplayServer.get_name(),"device":RenderingServer.get_video_adapter_name(),"visible":scene.view.visible_soldiers,"resume_equal":loaded!=null and Save.snapshot(loaded)==saved})
	print("FIELD_PACKAGE_"+("PASS" if ok else "FAIL")+" "+JSON.stringify(row))
	tree.quit(0 if ok else 1)
