extends RefCounted
## PROVISIONAL compressed Anping scenario, not an approved historical balance.
## One food unit supplies ten military person-hours; civilians use the same rate.
## Monthly capacity accrues hourly, so interrupted work cannot generate a full harvest.

const RULES := {
	"hours_per_day": 24,
	"days_per_month": 30,
	"person_hours_per_food": 10,
	"condition_scale": 100,
}

# Civilian population excludes the separately conserved city garrison/field armies.
# Farmland and workshops each support one worker. Farming has first labor priority.
# Anping is an import-dependent fortified town without secured farmland in this slice.
const CITIES := {
	"anping": {"population": 20, "workable_population": 10, "arable_land": 0, "workshop_capacity": 2, "stability": 100},
	"pingling": {"population": 20, "workable_population": 10, "arable_land": 8, "workshop_capacity": 2, "stability": 100},
	"hequ": {"population": 10, "workable_population": 6, "arable_land": 4, "workshop_capacity": 2, "stability": 100},
}

const PRODUCTION_RATES := {"food_per_farmer_month": 360, "weapons_per_crafter_month": 15}
