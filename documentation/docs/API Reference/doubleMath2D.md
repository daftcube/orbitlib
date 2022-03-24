# DoubleMath2D

Contains some 2D math functions.

## LineIntersection(...)

```lua
function module.LineIntersection(
    lineAPosX: number,
    lineAPosY: number,
    lineAVectorX: number,
    lineAVectorY: number,
    lineBPosX: number,
    lineBPosY: number,
    lineBVectorX: number,
    lineBVectorY: number
) → number, number
```

`number lineAPosX`: The x-coordinate of the first line's vertex.

`number lineAPosY`: The y-coordinate of the first line's vertex.

`number lineAVectorX`: The x-coordinate of the first line's direction vector.

`number lineAVectorY`: The y-coordinate of the first line's direction vector.

`number lineBPosX`: The x-coordinate of the second line's vertex.

`number lineBPosY`: The y-coordinate of the second line's vertex.

`number lineBVectorX`: The x-coordinate of the second line's direction vector.

`number lineBVectorY`: The y-coordinate of the second line's direction vector.

**Returns:** The x and y coordinate of the intersection between the two given lines. Will be `NaN` if the given lines are parallel or coinciding (on top of one another).