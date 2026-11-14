extends RefCounted
## Uncapped wall-clock measurement, separate from waiting for initial contact.
## A deadline never changes the minimum number of real frames required to pass.
const MIN_FRAMES := 20
const MIN_US := 2800000
const MAX_US := 120000000

static func keep_sampling(elapsed_us: int, frames: int) -> bool:
	return elapsed_us<MAX_US and (elapsed_us<MIN_US or frames<MIN_FRAMES)
