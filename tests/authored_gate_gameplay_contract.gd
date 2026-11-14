extends SceneTree
## Visual integration contract, not full siege outcome or graphical acceptance.
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 var scene=load('res://scenes/game.tscn').instantiate()
 root.add_child(scene)
 await process_frame
 var field=scene.field
 field.selections=20
 field.opposing_selection=20
 field.hud.plan_requested.emit(5)
 field.set_process(false)
 field.set_physics_process(false)
 var model=(load('res://assets/river_authored/architecture/architecture.glb') as PackedScene).instantiate()
 field.add_child(model)
 var pivot=model.find_child('GateDoor',true,false) as Node3D
 var door=model.find_child('GateDoor_Structure',true,false) as MeshInstance3D
 assert(pivot!=null and door!=null,'Both gameplay pivot and renderable door required')
 assert(pivot.global_position.distance_to(Vector3(48,0,0))<.001,'Surveyed gate anchor changed')
 field.map.master.visible=false
 field.map.ram.reparent(field)
 field.map.sun.reparent(field)
 field.map.gate=door
 field.hud.go.pressed.emit()
 var tick_before:int=int(field.battle.tick)
 var untouched={}
 for name in ['GateHall','GateBridge','WestBridge','WallWalk']:
  var part=model.find_child(name,true,false) as Node3D
  assert(part!=null)
  untouched[name]=part.transform
 var original_hp:float=float(field.battle.gate_hp)
 var origin:Vector3=door.global_position
 var receipts=[]
 for health:float in [260.,130.,0.,260.]:
  field.battle.gate_hp=health
  field.map.update_battle(field.battle)
  assert(door.visible==(health>0),'New door did not follow actual gate health')
  var expected_y:float=-(1.-health/260.)*.45
  assert(absf(door.position.y-expected_y)<.00001,'New door damage displacement differs')
  assert(absf(door.global_position.x-origin.x)<.00001 and absf(door.global_position.z-origin.z)<.00001,'Gate damage moved surveyed x/z anchor')
  assert(pivot.visible and pivot.global_position.distance_to(Vector3(48,0,0))<.001,'Damage hid or moved the whole architectural pivot')
  for name:String in untouched:
   var part=model.find_child(name,true,false) as Node3D
   assert(part.visible and part.transform.is_equal_approx(untouched[name]),'Gate health modified surrounding architecture')
  assert(field.map.ram.is_visible_in_tree(),'Siege ram became hidden by replacing old master')
  assert(field.map.sun.is_visible_in_tree(),'Scene sun became hidden by replacing old master')
  receipts.append({'gate_hp':health,'door_visible':door.visible,'door_y':door.position.y})
 field.battle.gate_hp=original_hp
 field.map.update_battle(field.battle)
 assert(field.battle.tick==tick_before,'Visual contract advanced simulation')
 assert(Array(field.battle.ordinary_counts)==[20,20],'Contract did not keep actual 20v20')
 print('AUTHORED_GATE_GAMEPLAY_CONTRACT_PASS ',JSON.stringify({'scope':'HEADLESS_VISUAL_BINDING_ONLY_NOT_FULL_SIEGE_OR_ART','counts':Array(field.battle.ordinary_counts),'tick':field.battle.tick,'samples':receipts,'renderer':'headless'}))
 scene.queue_free()
 await process_frame
 await process_frame
 await create_timer(.15).timeout
 quit()
