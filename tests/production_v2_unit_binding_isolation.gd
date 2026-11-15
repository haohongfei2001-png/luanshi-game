extends SceneTree
const Actor=preload('res://scripts/field/experimental/production_v2/shared_skeletal_actor.gd')
const Binding=preload('res://scripts/field/experimental/production_v2/mh_spear_battle_binding.gd')
const Battle=preload('res://scripts/field/battle.gd')
func ground(p:Vector2)->Vector3:return Vector3(p.x,0.,p.y)
func _initialize():run.call_deferred()
func run():
 var args=OS.get_cmdline_user_args();assert(args.size()==3)
 var battle=Battle.new();battle.setup(20,61112,Battle.Arms.Kit.SPEAR,true,true,20,false);battle.start()
 var ids=Binding.select_ordinary_ids(battle,999);assert(ids.size()<=8)
 var packed=load(args[0]);var metadata=JSON.parse_string(FileAccess.get_file_as_string(args[1]));var sha=FileAccess.get_sha256(args[0])
 var a=Actor.new();var b=Actor.new();root.add_child(a);root.add_child(b);assert(a.setup(packed)==OK and b.setup(packed)==OK)
 assert(a.skeleton!=b.skeleton and a.player!=b.player)
 var ma=a.model.find_children('*','MeshInstance3D',true,false);var mb=b.model.find_children('*','MeshInstance3D',true,false)
 assert(ma.size()==mb.size())
 for i in ma.size():assert(ma[i].mesh==mb[i].mesh)
 var dead_unit;var live_unit;var stagger_seen=false
 for step in 4000:
  battle.step()
  for u in battle.roster:
   if u.hero or u.officer or u.mounted or u.kit!=Battle.Arms.Kit.SPEAR:continue
   if u.state==Battle.State.STAGGER:stagger_seen=true
   if u.hp<=0:dead_unit=u
   elif u.state==Battle.State.MARCH:live_unit=u
  if dead_unit!=null and live_unit!=null:break
  if battle.result!='':break
 assert(dead_unit!=null and live_unit!=null,'No naturally dead/live ordinary spear pair in actual Battle')
 var x=Binding.new();var y=Binding.new()
 for binding in [x,y]:binding.enabled=true;binding.ground_point=ground;assert(binding.configure_timing(metadata,sha)==OK)
 var before=[battle.tick,dead_unit.hp,live_unit.hp,dead_unit.pos,live_unit.pos]
 var ra=x.update_unit(battle,dead_unit,a,.4,1.);assert(ra.semantic=='death' and not ra.unit_is_hero)
 var poses=[]
 for i in a.skeleton.get_bone_count():poses.append(a.skeleton.get_bone_pose(i))
 var rb=y.update_unit(battle,live_unit,b,.05,1.);assert(rb.supported and rb.semantic!='death' and rb.unit_id!=ra.unit_id)
 for i in a.skeleton.get_bone_count():assert(poses[i]==a.skeleton.get_bone_pose(i),'Another actor mutated first skeleton')
 assert(not x.update_unit(battle,live_unit,b,.05,1.).supported,'Identity reuse must reject')
 assert(before==[battle.tick,dead_unit.hp,live_unit.hp,dead_unit.pos,live_unit.pos],'Presentation changed real state')
 var out={'actual_tick':battle.tick,'ordinary_ids_cap':ids,'dead':ra,'alive':rb,'ordinary_stagger_observed':stagger_seen,'resources_shared':true,'skeleton_and_player_independent':true,'input_and_battle_mutations_by_binding':false,'scope':'actual legacy Battle natural ordinary death plus imported source18 resource isolation, NOT new-map/GPU/art acceptance'}
 FileAccess.open(args[2],FileAccess.WRITE).store_string(JSON.stringify(out,'  '));print('ORDINARY_UNIT_SKELETON_ISOLATION_PASS ',JSON.stringify(out));a.free();b.free();quit()
