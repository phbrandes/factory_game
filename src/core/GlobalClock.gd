extends Node
class_name WorldClock

const Day_Length := 5000 # 5,000 ticks per day (10 tick = 1 second)
const Night_Length := 5000 # 5,000 ticks per night (10 tick = 1 second)
const Total_Day_Cycle := Day_Length + Night_Length

var _current_day: int = 1
var tick_in_cycle: int = 0

func _ready() -> void:
    # Connect to the TickScheduler's tick signal
    TickScheduler.tick_started.connect(_on_tick_started)

func _on_tick_started(tick_number: int) -> void:
    # Update the current day and tick in cycle based on the tick number
    _current_day = tick_number / Total_Day_Cycle + 1

    tick_in_cycle = tick_number % Total_Day_Cycle

func is_daytime() -> bool:
    # Returns true if the current tick is within the day period, false if it's nighttime.
    return tick_in_cycle < Day_Length

func is_nighttime() -> bool:
    # Returns true if the current tick is within the night period, false if it's daytime.
    return tick_in_cycle >= Day_Length

func get_current_day() -> int:
    # Returns the current day number, starting from 1.
    return _current_day

func get_period_name() -> String:
    # Returns "Day" or "Night" based on the current tick in the cycle.
    if is_daytime():
        return "Day"
    else:
        return "Night"

var time_of_day_percentage := "Sol %d - %s" %[
    _current_day,
    get_period_name()
]

func get_time_of_day_percentage() -> float:
    # Returns a float between 0.0 and 1.0 representing the percentage of the current 
    # day/night cycle that has elapsed.
    return float(tick_in_cycle) / float(Total_Day_Cycle)

func get_sun_angle() -> float: 
    # Returns the angle of the sun in degrees based on the current time of day. 
    # 0 degrees is sunrise, 180 degrees is sunset, and 360 degrees is the next sunrise. 
    return get_time_of_day_percentage() * 360.0

func get_total_minutes() -> int:
    # Returns the total minutes elapsed in the current day/night cycle,
    # with 0 being midnight and 1439 being 11:59 PM.

    var progress = float(tick_in_cycle) / Total_Day_Cycle

    var minutes = int(progress * 1440)

    minutes += 360

    return minutes % 1440


func get_hour() -> int:
    # Returns the current hour in 24-hour format 
    # (0-23) based on the total minutes elapsed.
    return get_total_minutes() / 60


func get_minute() -> int:
    # Returns the current minute (0-59) based on the total minutes elapsed.
    return get_total_minutes() % 60


func get_display_hour() -> int:
    # Returns the current hour in 12-hour format (1-12) 
    # based on the total minutes elapsed.
    var h = get_hour()

    if h == 0:
        return 12

    if h > 12:
        return h - 12

    return h


func get_meridian() -> String:
    # Returns "AM" or "PM" based on the current hour.
    return "AM" if get_hour() < 12 else "PM"


func get_time_string() -> String:
    # Returns a formatted string 
    # representing the current time in 12-hour format with AM/PM.
    return "%02d:%02d %s" % [
        get_display_hour(),
        get_minute(),
        get_meridian()
    ]