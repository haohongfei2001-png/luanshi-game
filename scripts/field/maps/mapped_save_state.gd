extends RefCounted
## Version5-only continuation state. No legacy Ground placement or Campaign.
const MapQuery := preload("res://scripts/field/maps/map_query.gd")
const Runtime := preload("res://scripts/field/maps/authored_field_runtime.gd")
const Identity := preload("res://scripts/field/maps/map_identity.gd")
const MODE := "open_gate_field_no_campaign"

static func supports_runtime(runtime: MapQuery) -> bool:
 # MapQuery deliberately has no navigation/configuration contract. Other map
 # implementations remain diagnostic-only; never invent mode/agent geometry.
 if not runtime is Runtime or runtime.is_legacy: return false
 if runtime.nav==null or not runtime.nav._configured or runtime.nav._gates!={"gate_main":true}: return false
 if runtime.source.get("battle_mode")!=MODE: return false
 if not runtime.source.get("map_id") is String or runtime.source.map_id.is_empty() or runtime.source.map_id==Identity.LEGACY_ID: return false
 return Identity.positive_integer(runtime.source.get("topology_revision")) and Identity.valid_sha(runtime.source.get("topology_sha256"))

static func snapshot(b) -> Dictionary:
 if not supports_runtime(b.map_runtime): return {}
 var units := []
 var homes := []
 for u in b.roster: units.append([u.station,u.wall_post,u.engineer,u.ram_station])
 for c in b.companies: homes.append(c.home)
 return {"schema":1,"mode":MODE,"units":units,"company_homes":homes,
  "muster_slots":b.muster_slots.duplicate(),"sprinting":b.sprinting,
  "agent_radius":b.map_runtime.nav._radius,"agent_height":b.map_runtime.nav._height}

static func accepts(data: Variant, runtime: Runtime) -> bool:
 # This must precede Battle allocation and all input-dependent setup.
 if not supports_runtime(runtime): return false
 if not data is Dictionary or not data.get("version") is int or data.version!=5: return false
 var identity=data.get("map_identity")
 if not identity is Dictionary or identity.size()!=3: return false
 if not identity.get("map_id") is String or identity.map_id.is_empty() or identity.map_id==Identity.LEGACY_ID: return false
 if not identity.get("topology_revision") is int or not Identity.positive_integer(identity.topology_revision) or not Identity.valid_sha(identity.get("topology_sha256")): return false
 for key in ["map_id","topology_revision","topology_sha256"]:
  if not runtime.source.has(key): return false
 if identity!=runtime.identity(): return false
 var state=data.get("mapped_state")
 if not state is Dictionary or not state.get("schema") is int or state.schema!=1 or state.get("mode")!=MODE: return false
 for key in ["agent_radius","agent_height"]:
  if not state.get(key) is float or not is_finite(state[key]): return false
 if state.agent_radius!=runtime.nav._radius or state.agent_height!=runtime.nav._height: return false
 if data.get("terrain_revision")!=3 or data.get("world_patrol")!=false or data.get("bridgehead",false)!=false: return false
 if data.get("traffic_enabled")!=false or data.get("keep_gate_file")!=false: return false
 if data.get("aftermath_hours")!=0 or data.get("at_camp")!=false or data.get("camp_actions")!=[]: return false
 if not data.get("objectives") is Dictionary or data.objectives.get("enabled")!=false: return false
 if not state.get("sprinting") is bool: return false
 # Only the already supported open-gate/no-vehicle internal mode is resumable.
 var head=data.get("battle")
 return head is Array and head.size()==20 and head[9]==0.0 and head[10]==0.0 and head[16]==0

static func point(value: Variant) -> bool:
 return value is Vector2 and value.is_finite() and value.abs().x<10000 and value.abs().y<10000

static func restore_layout(b, data: Dictionary, runtime: Runtime) -> bool:
 var state:Dictionary=data.mapped_state
 if not state.get("units") is Array or state.units.size()!=b.roster.size(): return false
 if not state.get("company_homes") is Array or state.company_homes.size()!=b.companies.size(): return false
 if not state.get("muster_slots") is Array or state.muster_slots.size()!=b.companies_per_side: return false
 var muster=data.get("muster")
 if not muster is Array or muster.size()!=b.companies_per_side: return false
 var seen:Dictionary={}
 for row in muster:
  if not row is Array or row.size()!=3: return false
  for v in row:
   if not v is int: return false
  if row[0]<0 or row[0]>=b.companies_per_side or seen.has(row[0]) or row[1]<0 or row[1]>=b.FORMATIONS.size() or row[2]<0 or row[2]>=b.VANGUARDS.size(): return false
  seen[row[0]]=true
 for p in state.muster_slots:
  if not point(p): return false # Inert original predeployment slots; never relocate.
 for p in state.company_homes:
  if not point(p): return false # A formation centroid need not itself be support.
 for row in state.units:
  if not row is Array or row.size()!=4 or not point(row[0]) or runtime.blocked(row[0],true): return false
  if not row[1] is bool or row[1] or not row[2] is bool or row[2] or not row[3] is int or row[3]!=-1: return false
 b.map_runtime=runtime
 b.sprinting=state.sprinting
 b.muster_slots.assign(state.muster_slots)
 for i in b.companies.size(): b.companies[i].home=state.company_homes[i]
 for i in b.companies_per_side:
  b.companies[i].slot=muster[i][0];b.companies[i].shape=muster[i][1];b.companies[i].front=muster[i][2]
 for i in b.roster.size(): b.roster[i].station=state.units[i][0]
 return restore_jobs(b,data)

static func restore_jobs(b, data: Dictionary) -> bool:
 for i in b.roster.size():
  b.roster[i].wall_post=data.mapped_state.units[i][1]
  b.roster[i].engineer=data.mapped_state.units[i][2]
  b.roster[i].ram_station=data.mapped_state.units[i][3]
 return true
