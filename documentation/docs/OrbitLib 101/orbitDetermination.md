# Orbital Determination

How can we calculate the shape of an orbit given a spacecraft's initial position and velocity? This is the **Orbit Determination** problem.

## OrbitLib Determination

Using the [`Orbit.fromPositionVelocityECI(...)`](http://127.0.0.1:8000/API%20Reference/orbit/#frompositionvelocityeci) constructor, we can calculate an orbit from initial position and velocity.

```lua title="Hello OrbitLib! Script" linenums="1"
local earth = CelestialBody.new("Earth", 5.972e24, 6378.1)
local determinedOrbit = Orbit.fromPositionVelocityECI(earth, 6800, 0, 0, 0, 6.2, 6.2, 0)
print(determinedOrbit)
```

## Implementing "Maneuver Nodes"

A common staple of orbital mechanics games is to allow the player to place "maneuver nodes." These nodes represent points along the orbit where the spacecraft will burn to adjust its velocity and, in turn, trajectory.

The easiest way to implement impulse maneuver nodes is probably the following:

1. Use [`Orbit:GetPositionVelocityECI(...)`](http://127.0.0.1:8000/API%20Reference/orbit/#getpositionvelocityeci) to get the position and velocity at the true anomaly of the maneuver node.

2. Add the end velocity from the maneuver to the result from step 1.

3. Use [`Orbit.fromPositionVelocityECI(...)`](http://127.0.0.1:8000/API%20Reference/orbit/#frompositionvelocityeci) to calculate the new orbit using the position from step 1 and the new velocity from step 2.