# **ADR-002: Grid Data Structure**

## **Status**

Accepted

## **Context**

The factory simulation requires a structure to map logical coordinates (Vector2i) to machines and logistics networks. The structure must support rapid querying, deterministic overlap prevention for multi-tile structures, and theoretically infinite bounds.

## **Decision**

We will use a Spatial Hash Map implemented via Godot's built-in Dictionary, mapping Vector2i keys to GridEntity references.

* For ![multi-tile][image1] structures, the entity reference is duplicated across all keys in its footprint.

## **Rationale**

1. **O(1) Lookups:** Dictionary hashing in Godot 4 is highly optimized. Conveyor belts querying their forward tile will resolve instantly.  
2. **Infinite Expansion:** Unlike a 2D Array which requires a predefined bounding box and costly reallocation on expansion, a Dictionary grows dynamically and natively supports negative coordinates.  
3. **Decoupled:** Ensures the logic layer does not depend on TileMapLayer or node graphs.

## **Consequences**

* **Memory Overhead:** Slightly higher memory footprint than a tight 2D Array due to hash bucket overhead.  
* **Future Migration:** If the factory exceeds \~500,000 tiles, we may need to migrate to an ADR outlining a "Chunked Dictionary" approach to optimize serialization and iteration, but this satisfies Phase 1 to Phase 4 requirements.

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEIAAAAaCAYAAAADiYpyAAACp0lEQVR4Xu2WWciNQRjH//bsF8hOliwX5A4RF5YoIaWIcmMrWaK4ke3OdoO44ErihvKV4kL6EGUnRSlrSknJV/Ys//955nRmxnvOed8jruZXv5ozz5zzPu+cmWcGSCQSiUSiUabRJ/Q9/UUvh+ESd+hPWPwTPRqG/zltYTm8geWgXIYEI0JG0Xewsa/pfdolGFGDc/QZ7MsTo5hYQ0/S1nHgP7IC9lLKcUYUK6P8NtAW2PsUoh29TRfBHnImDJc4BFs9eZhNO8adHqPpyLgzB/ojVsNyXBXFyiyh82FjDkexukymB2kb+pz+oMODETZRHaK+asyh55E9GZqE67R3HKhDK/oA9j295O4wXGIY7NnbYGPmheH67KRzXXst/pzNfrAXK8JiegHh5CnRm6i9v6sxlp5wbS37015MaKLWufYV+p12q4Tz0Uy7unYnWKFRUezp+pbRja5dhOW0CVbsBsImQSuiETbB8hCqE/e8mFhI+9DO9Cu9Gobro1lrjvp2wVaFlpg4RcdUwoVYD/v3btBxUawIWl39XVs17IMXGwCrC2IWwtxzo320PerrRT/Tt7AZfhiGC9GXvoStDC3fRtD2Uo0qswf2sspTlLeE2OdiWSdfTXQaTIo7yRHYDx6jx6NYXrS1tBL0+1vQQBV3TKcHvM8rYblNoAvoIC+mLaPVosJfiLuwPRyjU0Onhx64NIrloTu9hvDI3YHsal+PvagUc6HfVF6bYUW5TA/YZeus15eLKfRW3OmhvagHqggVQQX3Euw+EbOfbo07a6AJfUqHen2DYXldRLjdNCnq18mXi5n0BSrXZl1Dp/oDHONhV9uiaA/rPK+G7ixZz/NpTx/RL7AcP8L2v9DtUXVnhPusG+cr+g02VqfeY2TfYxKJRCKRSCT+mt/+zoRrGuTjMgAAAABJRU5ErkJggg==>
