extends RefCounted
## Equipment reserved by the river-gate world transaction. Rows are counts per
## real company and weapon. Mount casualties, wounds and remaining ammunition
## are battle state and never change the weapon originally issued.
const Field := preload("res://scripts/field/battle.gd")
const Arms := preload("res://scripts/field/arms.gd")

static func pieces(kit: int) -> int:
	return 2 if kit==Arms.Kit.DUAL else 1

static func from_battle(battle: Field) -> Dictionary:
	var kits:=Arms.NAMES.size()
	var counts:=PackedInt32Array()
	counts.resize(battle.companies.size()*kits)
	var principals: Array[Dictionary]=[]
	var people:=PackedInt32Array([0,0])
	var weapons:=PackedInt32Array([0,0])
	var ammunition: Array=[PackedInt32Array([0,0]),PackedInt32Array([0,0])]
	for index in battle.roster.size():
		var u:=battle.roster[index]
		if u.id!=index or u.squad<0 or u.squad>=battle.companies.size() or u.kit<0 or u.kit>=kits:
			return {}
		if u.team<0 or u.team>1 or battle.companies[u.squad].team!=u.team:
			return {}
		people[u.team]+=1
		weapons[u.team]+=pieces(u.kit)
		if u.kit==Arms.Kit.BOW:
			ammunition[u.team][0]+=Arms.ARROWS_PER_QUIVER
		elif u.kit==Arms.Kit.CROSSBOW:
			ammunition[u.team][1]+=Arms.BOLTS_PER_CASE
		if u.officer or u.hero:
			principals.append({"id":u.id,"team":u.team,"squad":u.squad,"kit":u.kit,"hero":u.hero,"officer":u.officer})
		else:
			counts[u.squad*kits+u.kit]+=1
	return {"kit_counts":counts,"principals":principals,"people":people,"weapons":weapons,"ammunition":ammunition}
