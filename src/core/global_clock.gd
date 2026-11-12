extends Node

## Converts deterministic ticks from TickScheduler into simulated Sol (day), hour, and minute values.
## At 10 ticks/sec (1x speed), 1 tick = 1 simulated minute -> 1 hour = 60 ticks (6s), 1 Sol = 1440 ticks (2m 24s).

const MINUTES_PER_TICK: int = 1
const MINUTES_PER_HOUR: int = 60
const HOURS_PER_DAY: int = 24
const MINUTES_PER_DAY: int = MINUTES_PER_HOUR * HOURS_PER_DAY # 1440

func get_total_minutes() -> int:
	return TickScheduler.get_current_tick() * MINUTES_PER_TICK

func get_total_hours() -> int:
	@warning_ignore("integer_division")
	return get_total_minutes() / MINUTES_PER_HOUR

func get_current_day() -> int:
	@warning_ignore("integer_division")
	return (get_total_minutes() / MINUTES_PER_DAY) + 1

func get_current_hour() -> int:
	return get_total_hours() % HOURS_PER_DAY

func get_current_minute() -> int:
	return get_total_minutes() % MINUTES_PER_HOUR

func get_day_progress() -> float:
	var minutes_into_day: int = get_total_minutes() % MINUTES_PER_DAY
	return float(minutes_into_day) / float(MINUTES_PER_DAY)

func get_time_string() -> String:
	return "%02d:%02d" % [get_current_hour(), get_current_minute()]

