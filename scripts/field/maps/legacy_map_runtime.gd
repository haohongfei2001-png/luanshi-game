extends RefCounted
## Exact legacy delegation. Never changes Ground globals or an existing save.
## Per-battle bridgehead context, not a process-wide "current map".
const Ground:=preload("res://scripts/field/ground.gd")
var _bridgehead:bool
func _init(bridgehead:bool=false):_bridgehead=bridgehead
func height(p:Vector2)->float:return Ground.height(p,_bridgehead)
func deck_height(p:Vector2)->float:return Ground.deck_height(p,_bridgehead)
func unit_point(p:Vector2)->Vector3:return Ground.unit_point(p,_bridgehead)
func pace(p:Vector2,mounted:bool)->float:return Ground.pace(p,mounted,_bridgehead)
func blocked(p:Vector2,gate_open:bool)->bool:return Ground.blocked(p,gate_open,_bridgehead)
func can_step(p:Vector2,q:Vector2,gate_open:bool)->bool:return Ground.can_step(p,q,gate_open,_bridgehead)
func travel(p:Vector2,offset:Vector2,gate_open:bool)->Vector2:return Ground.travel(p,offset,gate_open,_bridgehead)
func waypoint(p:Vector2,goal:Vector2)->Vector2:return Ground.waypoint(p,goal,_bridgehead)
func retreat_waypoint(p:Vector2,goal:Vector2,gate_open:bool)->Vector2:return Ground.retreat_waypoint(p,goal,gate_open,_bridgehead)
func restore_bank_position(p:Vector2)->Vector2:return Ground.restore_bank_position(p,_bridgehead)
func muster_ground(p:Vector2,company_x:float)->Vector2:return Ground.muster_ground(p,company_x)
func clear_shot(p:Vector2,q:Vector2,gate_open:bool,elevated:bool=false)->bool:return Ground.clear_shot(p,q,gate_open,elevated)
func parapet(p:Vector2)->float:return Ground.parapet(p)
func crossing(z:float)->float:return Ground.crossing(z)
func needs_moat_crossing(p:Vector2,q:Vector2)->bool:return Ground.needs_moat_crossing(p,q)
func moat_waypoint(p:Vector2,q:Vector2,file:float=0.)->Vector2:return Ground.moat_waypoint(p,q,file)
func landmarks()->Dictionary:
 return {"limit":Ground.LIMIT,"gate":Ground.GATE,"court":Ground.COURT,"camp":Ground.CAMP,"grove":Ground.GROVE,"initial_camera":Ground.BRIDGE_VIEW,"wall_x":Ground.WALL_X,"back_x":Ground.BACK_X,"wall_z":Ground.WALL_Z,"river_x":Ground.RIVER_X,"moat_x":Ground.MOAT_X,"moat_bank":Ground.MOAT_BANK,"moat_end":Ground.MOAT_END}
