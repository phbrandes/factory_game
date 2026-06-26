class\_name TestTickScheduler extends Node

## **Standalone test runner for the TickScheduler.**

## **Attach this to an empty Node2D and run the scene to execute.**

var \_scheduler: Node  
var \_ticks\_received: int \= 0  
func \_ready() \-\> void:  
print("Running TickScheduler Tests...")  
\_scheduler \= load("res://src/core/tick\_scheduler.gd").new()  
add\_child(\_scheduler)  
\_test\_manual\_tick()  
\_test\_accumulator\_math()

print("All TickScheduler tests passed.")  
get\_tree().quit()

func \_on\_test\_tick(tick\_number: int) \-\> void:  
\_ticks\_received \+= 1  
assert(tick\_number \== \_ticks\_received, "Tick number mismatch.")  
func \_test\_manual\_tick() \-\> void:  
\_scheduler.reset()  
\_scheduler.register\_subscriber(\_on\_test\_tick)  
\_scheduler.start(\_scheduler.Mode.MANUAL)  
\_ticks\_received \= 0

for i in range(5):  
	\_scheduler.manual\_tick()  
	  
assert(\_scheduler.get\_current\_tick() \== 5, "Manual mode failed to advance exact ticks.")  
assert(\_ticks\_received \== 5, "Subscriber did not receive correct amount of manual ticks.")

func \_test\_accumulator\_math() \-\> void:  
\_scheduler.reset()  
\_scheduler.register\_subscriber(\_on\_test\_tick)  
\_scheduler.start(\_scheduler.Mode.REALTIME)  
\_ticks\_received \= 0

\# Simulate passing exactly 0.05 seconds (half a tick at 10 TPS)  
\_scheduler.\_process(0.05)  
assert(\_scheduler.get\_current\_tick() \== 0, "Scheduler ticked prematurely.")

\# Simulate passing another 0.06 seconds (crosses the 0.1s threshold)  
\_scheduler.\_process(0.06)  
assert(\_scheduler.get\_current\_tick() \== 1, "Scheduler failed to tick after crossing threshold.")

\# Simulate a massive lag spike (0.25 seconds)  
\_scheduler.\_process(0.25)  
assert(\_scheduler.get\_current\_tick() \== 3, "Scheduler failed to catch up multiple ticks during lag spike.")  
