extends RefCounted
## PROVISIONAL compressed military-hour balance, shared by every faction.
## 1000 hunger points = one whole hourly ration missed. No civilian demography.

const RULES := {
	"ration_scale": 1000,
	"hunger_limit": 6000,
	"weakened_at": 2000,
	"attrition_at": 3000,
	"fatigue_per_missed_ration": 12,
	"morale_per_missed_ration": 10,
	"fatigue_recovery": 6,
	"morale_recovery": 4,
	"attrition_per_hour": 1,
	"low_food_hours": 3,
	"fatigue_penalty_above": 40,
	"morale_penalty_below": 70,
	"max_speed_penalty": 20,
	"max_damage_penalty": 25,
}
const ACTIVITIES := {"rest": 0, "alert": 0, "siege": 1, "march": 2, "battle": 3}
