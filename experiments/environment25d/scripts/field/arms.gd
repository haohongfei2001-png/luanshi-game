extends RefCounted
## Distances are map units, timings are simulation seconds. The active contact is
## the transition from windup to recovery. Projectiles resolve later on impact.
enum Kit { SWORD, DAO, STAFF, SPEAR, GLAIVE, BOW, CROSSBOW, SHIELD, DUAL }
enum Shape { CUT, LINE, SWEEP, BASH, DOUBLE, ARROW, BOLT, FAN, PIERCE, PARRY, EVADE, BRACE }
const NAMES := ["剑", "刀", "棍", "枪", "长刀", "弓", "弩", "剑盾", "双剑"]
const LABELS := [
	["直斩", "回身斩", "进步刺", "拨剑"], ["劈刀", "横断", "抢步劈", "侧闪"],
	["横击", "推棍", "点棍", "架棍"], ["突刺", "连点", "进枪", "定枪"],
	["重劈", "卷刃", "拖刀斩", "立刃"], ["放箭", "散射", "退步箭", "疾避"],
	["发弩", "贯穿矢", "快弩", "稳身"], ["掩盾刺", "盾击", "压盾进", "举盾"],
	["交替斩", "连斩", "错步剪", "滑步"]]

const ARROWS_PER_QUIVER := 20
const BOLTS_PER_CASE := 12

static func issue(kit: int) -> int:
	if kit==Kit.BOW: return ARROWS_PER_QUIVER
	if kit==Kit.CROSSBOW: return BOLTS_PER_CASE
	return 0

class Move:
	var shape: int
	var reach: float
	var width: float
	var wind: float
	var recovery: float
	var power: float
	var limit: int
	var step: float
	func _init(kind: int, distance: float, spread: float, prepare: float, recover: float, strength: float, count: int, stride: float = 0.0) -> void:
		shape = kind
		reach = distance
		width = spread
		wind = prepare
		recovery = recover
		power = strength
		limit = count
		step = stride

# Width is a half angle in radians for cuts and a half width for thrusts.
static func library() -> Array:
	var s := Shape
	return [
		[Move.new(s.CUT,2.1,0.72,0.20,0.34,20,1), Move.new(s.SWEEP,2.3,1.75,0.29,0.46,24,3), Move.new(s.LINE,2.8,0.48,0.19,0.43,28,1,1.25), Move.new(s.PARRY,0,0,0.05,0.58,0,0)],
		[Move.new(s.CUT,2.2,0.92,0.28,0.41,25,2), Move.new(s.SWEEP,2.6,1.55,0.39,0.57,32,4), Move.new(s.CUT,2.3,0.68,0.24,0.54,34,2,1.75), Move.new(s.EVADE,0,0,0.08,0.30,0,0,-1.8)],
		[Move.new(s.SWEEP,2.7,1.28,0.28,0.45,19,3), Move.new(s.BASH,2.8,0.9,0.3,0.54,19,3), Move.new(s.LINE,3.0,0.48,0.17,0.36,23,1,0.8), Move.new(s.BRACE,0,0,0.08,0.86,0,0)],
		[Move.new(s.LINE,3.25,0.5,0.22,0.48,23,1), Move.new(s.DOUBLE,3.15,0.52,0.16,0.54,17,1), Move.new(s.LINE,3.6,0.56,0.34,0.54,33,2,1.65), Move.new(s.BRACE,0,0,0.06,1.12,0,0)],
		[Move.new(s.CUT,3.05,0.74,0.43,0.63,34,2), Move.new(s.SWEEP,3.35,1.78,0.52,0.68,37,5), Move.new(s.BASH,3.1,0.82,0.43,0.59,31,3,1.3), Move.new(s.PARRY,0,0,0.10,0.67,0,0)],
		[Move.new(s.ARROW,22,0.24,0.50,0.54,19,1), Move.new(s.FAN,18,0.22,0.65,0.66,17,3), Move.new(s.ARROW,19,0.24,0.32,0.55,18,1,-1.65), Move.new(s.EVADE,0,0,0.08,0.35,0,0,-2.2)],
		[Move.new(s.BOLT,28,0.24,0.22,1.43,30,1), Move.new(s.PIERCE,26,0.28,0.49,1.65,37,2), Move.new(s.BOLT,15,0.28,0.12,0.94,21,1), Move.new(s.BRACE,0,0,0.09,0.72,0,0)],
		[Move.new(s.LINE,1.8,0.53,0.22,0.46,18,1), Move.new(s.BASH,2.15,1.05,0.20,0.65,16,2,0.6), Move.new(s.LINE,2.15,0.60,0.30,0.56,26,1,1.55), Move.new(s.BRACE,0,0,0.05,1.45,0,0)],
		[Move.new(s.DOUBLE,1.7,0.9,0.12,0.36,12,1), Move.new(s.DOUBLE,1.9,1.1,0.17,0.46,18,2), Move.new(s.SWEEP,2.0,1.35,0.18,0.38,22,3,1.1), Move.new(s.EVADE,0,0,0.07,0.30,0,0,-1.55)]]
