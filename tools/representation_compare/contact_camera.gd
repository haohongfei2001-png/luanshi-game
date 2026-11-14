extends RefCounted
## Read-only deterministic focus on an actual opposing contact pair near the
## centroid of live melee contacts. Never changes battle, distance, or lens.
static func observe(battle)->Dictionary:
 var contacts:Array[Vector2]=[];var total:=Vector2.ZERO
 var closest:=INF;var nearest:=Vector2.ZERO;var alive_total:=Vector2.ZERO;var alive:=0
 for u in battle.roster:
  if u.hp<=0 or u.state in [battle.State.DEAD,battle.State.ESCAPED]:continue
  alive_total+=u.pos;alive+=1
  if u.target<0 or u.target>=battle.roster.size():continue
  var v=battle.roster[u.target]
  if v.hp<=0 or v.team==u.team or v.state in [battle.State.DEAD,battle.State.ESCAPED]:continue
  var distance:float=u.pos.distance_to(v.pos);var midpoint:Vector2=(u.pos+v.pos)*.5
  if distance<closest:closest=distance;nearest=midpoint
  if distance<=4.0 and u.state in [battle.State.WINDUP,battle.State.RECOVER,battle.State.STAGGER]:contacts.append(midpoint);total+=midpoint
 var center:=nearest
 if not contacts.is_empty():
  var mean:=total/float(contacts.size());var best:=INF
  for candidate in contacts:
   var distance:=candidate.distance_squared_to(mean)
   if distance<best:best=distance;center=candidate
 elif closest==INF:center=alive_total/maxi(alive,1)
 return {"tick":battle.tick,"center":[center.x,center.y],"live_contact_pairs":contacts.size(),"nearest_target_pair_distance":closest if closest<INF else -1.,"alive":alive,"alive_centroid":[alive_total.x/maxi(alive,1),alive_total.y/maxi(alive,1)],"policy":"actual melee contact nearest contact centroid; closest target pair fallback, no simulation writes"}
