# Design Notes

This page explains some of the more controversial design decisions made during the development of OrbitLib that might not make sense at first glance.

## Coordinate Systems

OrbitLib was built to be as close to common aerospace conventions as possible. In astrodynamics, the coordinate system used has a different set of reference unit vectors. The differences are outlined in the figure below.

![Coordinates](./assets/orbitLibCoordinates.png)

Luckily, these differences in coordinate systems can be easily corrected using a simple matrix change-of-coordinates like so:

```lua title="Conversion Examples"
-- Convert from Roblox coordinates to OrbitLib coordinates.
function RobloxToOrbitLib(x: number, y: number, z: number)
    return x, -z, y
end

-- Convert from OrbitLib coordinates to Roblox Coordinates.
function OrbitLibToRoblox(i: number, j: number, k: number)
    return i, k, -j
end
```

## Why No Vectors?

A keen observer might spot that OrbitLib prefers to return vectors as pairs of standard Lua `number` types instead of returning a single `Vector3`. Why do this? Using Roblox vectors is standard convention, after all. It's cleaner to return a single value, and its faster to operate on two `Vector3`s when compared to conducting the same operations on six `number` types.

The answer is **floating point precision.** 

Roblox `Vector3` values store their components as 32-bit floating point numbers. A standard 32-bit floating point number have up to seven significant figures of reliable accuracy. If our base unit is the meter, this means that the furthest from the origin (0,0,0) that one can travel in any direction while maintaining millimeter (0.001) accuracy is about 10000 meters. For perspective, the radius of the Earth is about 6700 kilometers, or 6700000 meters. **This is not nearly enough accuracy to represent astronomical distances.**

You might have even observed the consequences of 32-bit precision in-game. In some Roblox games, one might spot that their character and other geometry begins to shake when moving far from the center of the map. See the figure below (source: [Babytrvp on Devforum](https://devforum.roblox.com/t/floating-point-error-demonstration/800923)).

![Floating Point Error Video](./assets/tvrpFloatError.gif)

This occurs because the positional data gets large, but precision remains fixed. If one travels 100,000 units from the origin, there is only 1 significant figure of accuracy left to represent the decimal part of the position. This is what causes the shaking in the figure.

On the other hand, standard Lua `number` values are stored as 64-bit floating point numbers. 64-bit floating point numbers have up to sixteen significant figures of reliable accuracy. This means that the furthest we can travel from the origin in any direction while maintaining millimeter precision is about 10,000,000,000,000 (10^13) meters, or 1,000,000,000 kilometers. This is enough precision to fit the entire solar system without any extra work; the furthest Pluto is from the Sun is just 7*10^12 meters. Hence, OrbitLib uses standard Lua types to maintain a high degree of accuracy while keeping the library as simple as possible to use.

Why does Roblox use 32-bit floating point numbers in their vectors? It comes down to speed: 32-bit numbers have faster mathematical operations than 64-bit floating point numbers. As a typical Roblox developer is not going to make a map larger than a few thousand studs in extents, it makes sense to use less accurate but faster decimal numbers.


## Bring Your Own Renderer (BYOR)

OrbitLib was intended to be a highly portable physics and mathematics library. Additionally, different projects have different visual styles and needs. In order to maintain portability between projects, OrbitLib does not ship with functions for rendering orbits.

If an OrbitLib user wants a visual representation of their orbits, they must build it their own rendering functions. Don't fret though; there is an example of how to render OrbitLib components in the [OrbitLib 101 section](./OrbitLib 101/buildingBasicRenderer.md). To make something more robust, we suggest two approaches:

### Simple: Keep Everything Small

If one does not care about having millimeter rendering precision, the easiest way to avoid floating point precision issues is to keep the scale down. This is the approach most examples in on this site use.

The drawbacks of this method is that only a scale model of the solar system can be visually rendered. This means spacecraft will be, at most, dots in the world.

### Advanced: Floating Origin

Games like Kerbal Space Program are able to represent interstellar distances with sub-millimeter precision by using clever reference frame tricks. The idea about rendering precision is that the camera can move only 10,000 units from the center of the world before floating point issues occur. So, as the game progresses, when the player moves further than a set distance from the origin, the game shifts the player's position back to the origin while moving all other objects to maintain their relative distance from the player. In other words, the origin of the world "floats" with the player.

For more reading, see this [paper](https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.471.7201&rep=rep1&type=pdf) by Chris Thorne.

Using this method, it is possible to move an effectively unlimited distance from the world's 'origin.' The drawback, however, is that this is very difficult to implement, especially in Roblox. It will take a talented developer to make this possible.

Daftcube's Note: if you are even considering this, try to do it in a different engine. It's so much easier when you have a much greater degree of low-level control. I attempted to do this in Roblox, but got frusturated with it. Using Three.js, I was able to implement a floating origin system in a few days. You can see it in action in the [WebGL Demo](./demo.md).