class\_name GameConfig extends RefCounted

## **Global constants and configuration for the simulation.**

## **This file strictly contains raw data and no logic.**

const TICKS\_PER\_SECOND: int \= 10

const TICK\_INTERVAL\_SEC: float \= 1.0 / float(TICKS\_PER\_SECOND)

## **Maximum number of items a single conveyor segment can hold internally**

const MAX\_CONVEYOR\_CAPACITY: int \= 4