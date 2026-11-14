extends RefCounted
## Static, one-real-unit visual replacement only. No animation or crowd acceptance.
const Actor:=preload('res://scripts/field/experimental/controlled_author_actor.gd')
const Store:=preload('res://scripts/field/save.gd')
static func bind(field:Node,folder:String)->Dictionary:
 if field.battle.vehicle!=0 or field.view.review_hidden_actor_id!=-1:return {'error':ERR_INVALID_PARAMETER}
 var before=var_to_bytes(Store.snapshot(field.battle))
 var actor=Actor.new();field.add_child(actor)
 var configured=actor.configure_author_oracle(folder)
 if configured!=OK:actor.queue_free();return {'error':configured}
 var applied=actor.apply_author_phase('walk',0.)
 if applied!=OK:actor.queue_free();return {'error':applied}
 var unit=field.battle.hero
 # Same unit world point, heading and existing hero presentation stature. No lift.
 actor.transform=Transform3D(Basis(Vector3.UP,atan2(unit.facing.x,unit.facing.y)).scaled(Vector3.ONE*1.07),field.Ground.unit_point(unit.pos,field.battle.bridgehead))
 if var_to_bytes(Store.snapshot(field.battle))!=before:actor.queue_free();return {'error':ERR_INVALID_DATA}
 field.view.review_hidden_actor_id=unit.id
 var receipt=actor.receipt()
 receipt.merge({'unit_id':unit.id,'unit_is_real_hero':true,'unit_pos':[unit.pos.x,unit.pos.y],'unit_facing':[unit.facing.x,unit.facing.y],'stature':1.07,'ground_lift_m':0.,'pose':'author walk frame0, NOT a verified Battle-state animation mapping','scope':'STATIC_ONE_REAL_UNIT_VISUAL_REPLACEMENT_ONLY; no formal character/story decision','metadata_sha256':FileAccess.get_sha256(folder.path_join('character.json'))})
 return {'error':OK,'actor':actor,'receipt':receipt}
static func projected_body(actor:Node3D,camera:Camera3D)->Dictionary:
 var top:=INF;var bottom:=-INF;var feet_min_world_y:=INF;var points:=0
 for child in actor.get_children():
  if not child is MeshInstance3D:continue
  var head=child.name.begins_with('Helmet') or child.name.begins_with('Young complete author face')
  var boots=child.name.begins_with('GEO-boots')
  if not head and not boots:continue
  for surface in child.mesh.get_surface_count():
   var vertices:PackedVector3Array=child.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
   for vertex in vertices:
    var world:Vector3=child.global_transform*vertex
    if camera.is_position_behind(world):return {'error':'BODY_BEHIND_CAMERA'}
    var screen=camera.unproject_position(world)
    if head:top=minf(top,screen.y)
    if boots:bottom=maxf(bottom,screen.y);feet_min_world_y=minf(feet_min_world_y,world.y)
    points+=1
 if not is_finite(top) or not is_finite(bottom) or bottom<=top:return {'error':'BODY_MARKERS_MISSING'}
 return {'projection_viewport':[camera.get_viewport().get_visible_rect().size.x,camera.get_viewport().get_visible_rect().size.y],'display_backend':DisplayServer.get_name(),'top_y':top,'boot_bottom_y':bottom,'height_px':bottom-top,'height_fraction':(bottom-top)/camera.get_viewport().get_visible_rect().size.y,'vertices_checked':points,'boot_min_world_y':feet_min_world_y,'scope':'actual selected author frame0 helmet/face and boot vertices; excludes spear/horse/ring/shadow; not valid for other cached phases'}
