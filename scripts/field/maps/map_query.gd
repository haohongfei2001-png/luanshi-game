extends RefCounted
## Typed per-Battle query boundary. Base methods fail rather than use old terrain.
var is_legacy:=false
func height(_p:Vector2)->float:push_error("Unbound map height");return NAN
func deck_height(p:Vector2)->float:return height(p)
func unit_point(p:Vector2)->Vector3:return Vector3(p.x,height(p),p.y)
func pace(_p:Vector2,_mounted:bool)->float:push_error("Unbound map pace");return 0.
func blocked(_p:Vector2,_open:bool)->bool:push_error("Unbound map obstacle");return true
func can_step(_p:Vector2,_q:Vector2,_open:bool)->bool:push_error("Unbound map travel");return false
func travel(_p:Vector2,_offset:Vector2,_open:bool)->Vector2:push_error("Unbound map travel");return _p
func waypoint(_p:Vector2,_goal:Vector2)->Vector2:push_error("Unbound map route");return _p
func retreat_waypoint(p:Vector2,goal:Vector2,_open:bool)->Vector2:return waypoint(p,goal)
func restore_bank_position(_p:Vector2)->Vector2:push_error("Unbound map restoration");return _p
func muster_ground(_p:Vector2,_company_x:float)->Vector2:push_error("Unbound map spawn");return _p
func clear_shot(_p:Vector2,_q:Vector2,_open:bool,_elevated:bool=false)->bool:push_error("Unbound map sight");return false
func parapet(_p:Vector2)->float:push_error("Unbound map parapet");return NAN
func crossing(_z:float)->float:push_error("Unbound legacy crossing request");return NAN
func needs_moat_crossing(_p:Vector2,_q:Vector2)->bool:push_error("Unbound legacy moat request");return false
func moat_waypoint(_p:Vector2,_q:Vector2,_file:float=0.)->Vector2:push_error("Unbound legacy moat request");return _p
func landmarks()->Dictionary:push_error("Unbound semantic landmarks");return {}
func retreat_goal(_team:int)->Vector2:push_error("Unbound retreat region");return Vector2.ZERO
func identity()->Dictionary:return {}
func objective(_team:int,_mission:String,_home:Vector2,_regrouping:bool)->Vector2:push_error("Unbound semantic objective");return _home
func projectile_clear(p:Vector2,q:Vector2,_launch_height:float,open:bool,elevated:bool=false)->bool:return clear_shot(p,q,open,elevated)
