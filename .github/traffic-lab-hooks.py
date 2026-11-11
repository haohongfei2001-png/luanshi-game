from pathlib import Path
import json
path = Path("scripts/field/battle.gd")
source = path.read_text()
hooks = json.loads("[[\"Traffic.waypoint(u.pos,goal,u.station.y-c.home.y,u.id,gate_hp<=0)\",\"Traffic.waypoint(u.pos,goal,u.station.y-c.home.y,u.id,gate_hp<=0,ram_hp>0 and ram.x>Ground.WALL_X-6.0)\"],[\"Traffic.around_ram(u.pos,next,ram,u.id)\",\"Traffic.around_ram(u.pos,next,ram,u.id,gate_hp<=0)\"],[\"\\tvar at_post := u.wall_post\",\"\\tvar gate_face := Traffic.gate_face(u.pos) if traffic_enabled else Ground.GATE\\n\\tvar at_post := u.wall_post\"],[\"elif u.team == 0 and gate_hp > 0 and u.pos.distance_to(Ground.GATE) < 3.9 and u.fatigue <= 0:\\n\\t\\t\\t_begin(u, 0, u.pos.direction_to(Ground.GATE))\",\"elif u.team == 0 and gate_hp > 0 and u.fatigue <= 0 and u.pos.distance_to(gate_face) < (minf(3.9, _basic(u).reach + 0.20) if traffic_enabled else 3.9):\\n\\t\\t\\t_begin(u, 0, u.pos.direction_to(gate_face))\"],[\"if u.team == 0 and gate_hp > 0 and u.pos.distance_to(Ground.GATE) <= move.reach + 1.0 and u.locked.x > 0.4:\",\"var struck_gate := false\\n\\tif u.team == 0 and gate_hp > 0:\\n\\t\\tif traffic_enabled:\\n\\t\\t\\tstruck_gate = Traffic.hits_gate(u.pos, u.locked, move.reach, move.width, move.shape == Arms.Shape.LINE or (move.shape == Arms.Shape.DOUBLE and u.kit == Arms.Kit.SPEAR))\\n\\t\\telse:\\n\\t\\t\\tstruck_gate = u.pos.distance_to(Ground.GATE) <= move.reach + 1.0 and u.locked.x > 0.4\\n\\tif struck_gate:\"]]")
for old, new in hooks:
    assert source.count(old) == 1, old
    source = source.replace(old, new)
path.write_text(source)
