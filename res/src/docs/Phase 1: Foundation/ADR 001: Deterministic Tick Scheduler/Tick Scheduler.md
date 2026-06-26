extends Node

## **Autoload: TickScheduler**

## **The central heartbeat of the deterministic simulation loop.**

## **Converts engine frame time into strict simulation ticks.**

signal tick\_started(tick\_number: int)  
signal tick\_completed(tick\_number: int)  
enum Mode {  
REALTIME, \#\# Driven by \_process and wall-clock time.  
MANUAL \#\# Driven externally by the Replay System or Tests.  
}  
var \_current\_tick: int \= 0  
var \_accumulator: float \= 0.0  
var \_is\_running: bool \= false  
var \_mode: Mode \= Mode.REALTIME

## **Array of Callables to execute sequentially every tick.**

var \_subscribers: Array\[Callable\] \= \[\]  
func \_ready() \-\> void:  
process\_priority \= \-100 \# Ensure this runs before other visual nodes  
func start(mode: Mode \= Mode.REALTIME) \-\> void:  
\_mode \= mode  
\_is\_running \= true  
func pause() \-\> void:  
\_is\_running \= false  
func reset() \-\> void:  
\_is\_running \= false  
\_current\_tick \= 0  
\_accumulator \= 0.0  
\_subscribers.clear()  
func register\_subscriber(callable: Callable) \-\> void:  
if not \_subscribers.has(callable):  
\_subscribers.append(callable)  
func unregister\_subscriber(callable: Callable) \-\> void:  
var index: int \= \_subscribers.find(callable)  
if index \!= \-1:  
\_subscribers.remove\_at(index)  
func \_process(delta: float) \-\> void:  
if not \_is\_running or \_mode \== Mode.MANUAL:  
return  
\_accumulator \+= delta  
var interval: float \= GameConfig.TICK\_INTERVAL\_SEC

\# Catch up loop for lag spikes, maintaining determinism  
while \_accumulator \>= interval:  
	\_accumulator \-= interval  
	\_execute\_tick()

## **Exposed for the Replay System and Unit Tests to force a tick progression**

func manual\_tick() \-\> void:  
if \_mode \== Mode.MANUAL:  
\_execute\_tick()  
func \_execute\_tick() \-\> void:  
\_current\_tick \+= 1  
tick\_started.emit(\_current\_tick)

for callable: Callable in \_subscribers:  
	if callable.is\_valid():  
		callable.call(\_current\_tick)  
		  
tick\_completed.emit(\_current\_tick)

func get\_current\_tick() \-\> int:  
return \_current\_tick