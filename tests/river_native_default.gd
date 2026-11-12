extends SceneTree
const Field := preload("res://scripts/field/controller.gd")
const Battle := preload("res://scripts/field/battle.gd")
var failures: Array[String] = []
var states: Array = []

func _initialize() -> void:
	_run.call_deferred()

func _expect(field: Field, preset: int, size: Vector2i) -> void:
	var pixels := root.get_texture().get_image().get_size()
	var actual := {"preset":field.detail_preset,"msaa":root.msaa_3d,"scale":root.scaling_3d_scale,"screen_aa":root.screen_space_aa,"taa":root.use_taa,"shadows":field.map.sun.shadow_enabled,"window":[root.size.x,root.size.y],"image":[pixels.x,pixels.y]}
	states.append(actual)
	if field.detail_preset!=preset or not is_equal_approx(root.scaling_3d_scale,[1.0,.85,.70,1.0][preset]) or root.msaa_3d!=(Viewport.MSAA_4X if preset==0 else Viewport.MSAA_DISABLED) or root.screen_space_aa!=0 or root.use_taa or root.size!=size or pixels!=size or field.map.sun.shadow_enabled!=(preset!=2):
		failures.append(JSON.stringify(actual))

func _game() -> Node:
	var shell=load("res://scenes/game.tscn").instantiate()
	root.add_child(shell)
	var field: Field=shell.field
	field.set_physics_process(false)
	field.set_process(false)
	return shell

func _draws(n: int) -> void:
	for i in n: await RenderingServer.frame_post_draw

func _run() -> void:
	var small:=Vector2i(1280,800)
	var large:=Vector2i(1920,1200)
	var shell:=_game()
	var field: Field=shell.get("field")
	await _draws(3)
	_expect(field,0,small)
	# Start with a normal window, then exercise native resizing without relaunch.
	root.size=large
	await _draws(5)
	_expect(field,0,large)
	for quality: int in [3,2,1]:
		field.hud.quality_changed.emit(quality)
		await _draws(3)
		_expect(field,quality,large)
	shell.queue_free()
	await process_frame
	await process_frame
	shell=_game()
	field=shell.get("field")
	await _draws(3)
	_expect(field,1,large)
	field.hud.quality_changed.emit(0)
	await _draws(3)
	_expect(field,0,large)
	field.hud.plan_requested.emit(1)
	field.hud.go.pressed.emit()
	if not field.battle.started or field.battle.ordinary_counts!=PackedInt32Array([512,512]): failures.append("muster")
	var battle:=field.battle
	if not battle.mount(1): failures.append("horse")
	var combat: Dictionary={}
	for tick in [8,9,65,66,80]:
		while battle.tick<tick and battle.result=="":
			battle.input_state(Vector2.ZERO,Vector2.RIGHT)
			battle.step()
		combat[str(tick)]={"hits":[battle.hits[0],battle.hits[1]],"losses":[battle.losses[0],battle.losses[1]],"arrows":battle.arrow_count,"tick":battle.tick}
	if combat["66"].hits==combat["8"].hits: failures.append("combat receipt did not advance")
	print("CLAR_TICK_LEDGER ",JSON.stringify(combat))
	print("CLAR_NATIVE_DEFAULT ",JSON.stringify({"passes":states,"failures":failures,"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"hidpi":ProjectSettings.get_setting("display/window/dpi/allow_hidpi",true)}))
	shell.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
