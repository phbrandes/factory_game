# **ADR-017: Visual Chunking for Rendering Optimization**

## **Status**

Accepted

## **Context**

Phase 7 requires performance optimization. A late-game factory may have 100,000+ entities. While the purely data-driven simulation handles this comfortably at 10 TPS, rendering and lerping 100,000 Sprite2D nodes at 60 FPS will cause severe GPU and CPU bottlenecking.

## **Decision**

We will implement a VisualChunkManager within the rendering layer.

1. **Grid to Chunk Math:** The visual world is divided into ![][image1] tile chunks. Grid coordinate (x, y) maps to chunk coordinate (floor(x/16), floor(y/16)).  
2. **Chunk Nodes:** Each chunk is a Node2D (VisualChunk). Visual representations of entities (like BeltVisualizer) are parented to their respective chunk rather than a single global renderer root.  
3. **Frustum Culling:** The camera will inform the VisualChunkManager of its viewport bounds. Chunks outside these bounds will have their process\_mode set to PROCESS\_MODE\_DISABLED and visible set to false.

## **Rationale**

* Setting process\_mode to disabled completely halts the \_process(delta) loop for all children of that chunk, immediately reclaiming CPU cycles from off-screen animations.  
* Preserves Architecture Law 1: The simulation layer remains a flat O(1) dictionary and is completely unaware of chunks, cameras, or culling.

## **Consequences**

* Multi-tile buildings (e.g., a ![][image2] reactor) that straddle a chunk boundary must be assigned to the chunk containing their origin point, meaning chunk culling bounds must have a slight overdraw (padding) to prevent large buildings from popping out of existence at the edge of the screen.

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEIAAAAZCAYAAACFHfjcAAAB90lEQVR4Xu2XyytFURSHl0fexMhEyMBEGUqmHokYSPInMFOKiYQSIwMDxYwYSCh5JnlkJpQJeQyVKAyQZ/zW3ee65y7OvefIPqP91Te4v71bZ3XPPuueS2QwGAzeyZOBjQTYDY/gPpyEyWE7/OXfe02BZXABLoq1IIlwGc7BNJgOD2CnfZMPaOu1FV7DJfhOzsV74A1MtT7XwE84EdzgA771+ky/F8+AT3BMZMOwxJb5idZenYo3kfpGW+SCSxpkIKgideS9oKvXAE7FhyhUfBpuwUNYbdsTiQHYL0MLbnwWxsmFKOjqNYBT8SlSxY9htpU1wldYGtwUhRHYJ7J6uAqTRO4Gnb06Fuc7xsUHbVksvIU7tiwSMXCcQpO7Em6Smup/QWevgeI8kSWjpIo3i/wMfpAaRm7g4z9DanDtwszwZU9o7ZWLr8gQ9JIqXifyEyvPFXkkKuAjbJcLHtHaKxfnZ1bCzXMRHmx2zuEbuZ/4/PO1B3PgPP28a17Q2isXX5MhqdfVe9glsgdSb3huKCb1qstfAsNvf/yM88D8C9p6jYcvcFsuWPBRvqTQ0eogdcGC7x3OFJI6Cfki57uzDstFHg0tvdbCC3hH6kixV6SOUpZtH9MGT0ldZAMWhS87wnfeqQn+H8DPupsh5kevBoPBYDAYovMF3dynE2vCEcYAAAAASUVORK5CYII=>

[image2]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAC4AAAAZCAYAAABOxhwiAAABrklEQVR4Xu2VPShFYRjH/4QoFMlg8jmIUMggJSWDhZLYrEryNbEpk8WgSEoZjJIsFCb5GAwWFtlk8JV8LIr/23NO95y3e9/znjvcO9zzq1+d8zz3vf3ve8/zHiAiIjMpoo+0Xm+kmAM6rhdNLNM/2qg3Ukg/JMOE3khEHf1BeoPn0luEDL5Ht5He4LN0CyGC99E1Ogf74M20Ri96KKY9etFAOT2jHbAMngNZUIZwwavoJa3WG6SQHtMuvWFgg/bSNlgGn6TTznWY4IoGek0rPbUCegQZMlta6K5zbRW8lJ5DhkIRNriiFRK+guZBjrJh3yeCUT+01rm2Cr4K/84kE1zRSa8gAz7mbwUyBDmGXQKDq79Z7Y6XZIOrOTmhd7RE65nIpxeQQXYJDD5DX+iTx0/Iomd6E/uokWy6Q6doNz2FvIFtaKfv8Gd4hWT4cO7dR8iIenTC7HgW3aQLnpo6Wg8hQ5oM6tEx7ng81iGLmvRGAlbool4kg3QfsaEPwwgkgzrtAhmlD/QXsugNctqYGKBLetGD+s55vWhAvQ/u6Rckw7dzH+89EREREZHp/ANyHmBEsK2gCwAAAABJRU5ErkJggg==>