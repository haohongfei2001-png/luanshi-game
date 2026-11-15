extends RefCounted
## Explicit new-battle-only placement, never a saved/live-battle migration.
const Runtime:=preload("res://scripts/field/maps/authored_field_runtime.gd")
static func apply(b, map:Runtime)->Dictionary:
 if b.started or b.tick!=0 or b.result!="" or map.nav==null:return {"error":ERR_UNAVAILABLE,"reason":"NEW_UNSTARTED_BATTLE_REQUIRED"}
 var proposed:={};var counts:=[]
 for region in map.source.spawn_regions:
  var polygon:=PackedVector2Array();var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
  for point in region.xz_polygon:
   var p:=Vector2(point[0],point[1]);polygon.append(p);low=low.min(p);high=high.max(p)
  var candidates:Array[Vector2]=[];var x:=low.x+.75
  while x<=high.x-.75:
   var z:=low.y+.75
   while z<=high.y-.75:
    var p:=Vector2(x,z);var hit=map.nav.support.support(p)
    if Geometry2D.is_point_in_polygon(p,polygon) and not(z>=region.reserved_corridor_z[0]-.7 and z<=region.reserved_corridor_z[1]+.7) and hit.error==OK:
     var good:bool=not map.nav.obstacles.obstruction(hit.position,.7,3.4,map.nav._gates).blocked
     for d in [Vector2(.7,0),Vector2(-.7,0),Vector2(0,.7),Vector2(0,-.7)]:
      if map.nav.support.support(p+d).error!=OK:good=false
     if good:candidates.append(p)
    z+=1.25
   x+=1.25
  var target:Vector2=map.landmarks().gate
  candidates.sort_custom(func(a:Vector2,c:Vector2):return a.distance_squared_to(target)<c.distance_squared_to(target))
  var used:={};var occupied:={};var team_units:=[]
  for u in b.roster:
   if u.team==int(region.team):team_units.append(u)
  for u in team_units:
   var radius:=.7 if u.mounted else .45;var found:=false
   for slot in candidates.size():
    if used.has(slot):continue
    var p:=candidates[slot];var free:=true
    var cell:=Vector2i(floori(p.x/2.),floori(p.y/2.))
    for dx in range(-1,2):
     for dz in range(-1,2):
      for chosen in occupied.get(cell+Vector2i(dx,dz),[]):
       if p.distance_squared_to(chosen.p)<pow(radius+float(chosen.radius)+.05,2):free=false
    if not free:continue
    proposed[u.id]=p;used[slot]=true
    if not occupied.has(cell):occupied[cell]=[]
    occupied[cell].append({"p":p,"radius":radius});found=true;break
   if not found:return {"error":ERR_OUT_OF_MEMORY,"reason":"INSUFFICIENT_REAL_SPAWN_CLEARANCE","team":region.team,"candidates":candidates.size(),"required":team_units.size()}
  counts.append({"team":region.team,"available":candidates.size(),"placed":team_units.size()})
 if proposed.size()!=b.roster.size():return {"error":ERR_INVALID_DATA,"reason":"INCOMPLETE_ROSTER_PLACEMENT"}
 var homes:=[]
 for index in b.companies.size():
  var home:=Vector2.ZERO;var count:=0
  for u in b.roster:
   if u.squad==index:home+=proposed[u.id];count+=1
  if count==0:return {"error":ERR_INVALID_DATA,"reason":"EMPTY_COMPANY"}
  homes.append(home/float(count))
 # All validation precedes mutation. These are initial stations, not teleports.
 b.map_runtime=map;b.traffic_enabled=false;b.keep_gate_file=false;b.objectives.enabled=false
 b.gate_hp=0.;b.ram_hp=0. # Declared open-gate field scenario; not damage/siege evidence.
 for u in b.roster:
  u.pos=proposed[u.id];u.before=u.pos;u.station=u.pos;u.wall_post=false;u.engineer=false;u.ram_station=-1
 for index in b.companies.size():
  b.companies[index].home=homes[index];b.companies[index].aim=homes[index]
 b.ram=map.retreat_goal(0)
 b.vehicle_pos[1]=map.retreat_goal(0);b.vehicle_pos[2]=map.retreat_goal(0)+Vector2(0,2)
 b._rebuild_grid()
 return {"error":OK,"ordinary_per_side":Array(b.ordinary_counts),"counts":counts,"mode":"INTERNAL_OPEN_GATE_FIELD_BATTLE_NO_SIEGE_NO_WORLD_OBJECTIVE","source_topology":map.source.topology_sha256,"saved_battle_migrated":false}
