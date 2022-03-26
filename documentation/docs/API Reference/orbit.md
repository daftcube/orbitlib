# Orbit
`Orbit.lua` defines a class that represents an immutable two-body Keplerian orbit.

Instances of the `Orbit` class are **immutable and should not be modified under any circumstances.** To apply a change to an orbit, simply construct a new one.

The source file contains more functions than are documented on this page. These functions are either incomplete or are used in intermediate calculations in public documented functions. Note that functions that are not documented on this page are not intended to be used outside of the module or called by other scripts. However, if one is curious about these functions, there are comments in the source.

## Fields

### Parent CelestialBody Parameters

#### <code>[CelestialBody](./celestialBody.md) parentBody</code>

Represents the parent body that the orbit circles.

#### `number mu` <span class="unitSpan">:material-ruler: km^3/s^2</span>

`mu` represents the [Standard Gravitational Parameter ](https://en.wikipedia.org/wiki/Specific_mechanical_energy), a quantity equal to the mass of the parent body multiplied by the [Universal Gravitational Constant](./physicsConstants.md).

#### `string conic`

Represents the type of conic this Keplerian Orbit represents. Can be either:
- `"CIRCLE"`, when `eccentricity = 0`
- `"ELLIPSE"`, when `0 < eccentricity < 1`
- `"PARABOLA"`, when `eccentricity = 1`
- `"HYPERBOLA"`, when `eccentricity > 1`

### Energy Parameters

#### `number specificMechanicalEnergy` <span class="unitSpan">:material-ruler: </span>

Also denoted as `E`, this represents the [specific mechanical energy](https://en.wikipedia.org/wiki/Specific_mechanical_energy) of the orbit, or the energy per unit mass.

#### `number specificAngularMomentum` <span class="unitSpan">:material-ruler: (km^2)/s</span>

Also denotaed as `h`, represents the [specific angular momentum](https://en.wikipedia.org/wiki/Specific_angular_momentum) of the orbit.

### Shape Parameters

#### `number semimajorAxis` <span class="unitSpan">:material-ruler: km</span>

Also denoted as `a`, this value represents the [semimajor axis](https://en.wikipedia.org/wiki/Semi-major_and_semi-minor_axes) of the orbit, in kilometers. For elliptical and circular orbits, (<code>eccentricity < 1</code>) this value is positive. For hyperbolic orbits, this value is negative.

#### `number periapsis` <span class="unitSpan">:material-ruler: km</span>

Represents the [periapsis](https://en.wikipedia.org/wiki/Apsis), or distance between the center of the parent body and the closest point of the orbit.

#### `number apoapsis` <span class="unitSpan">:material-ruler: km</span>

Represents the [apoapsis](https://en.wikipedia.org/wiki/Apsis), distance between the center of the parent body and the furthest point of the orbit. If the orbit is parabolic or hyperbolic, then this value is equal to `math.huge`.

#### `number eccentricity`

Represents the [eccentricity](https://en.wikipedia.org/wiki/Orbital_eccentricity) of this orbit, or a dimensionless parameter that measures how the shape of the orbit deviates from being a perfect circle.

### Orientation Parameters

#### `number inclination` <span class="unitSpan">:material-ruler: rad</span>

Also denoted as `i`, represents the [inclination](https://en.wikipedia.org/wiki/Orbital_inclination) of this orbit. Inclination represents the tilt of the orbit from the equator.

#### `number longitudeOfAscendingNode` <span class="unitSpan">:material-ruler: rad</span>

Also denoted as `Ω`, represents the [longitude of the ascending node](https://en.wikipedia.org/wiki/Longitude_of_the_ascending_node) of this orbit.

#### `number argumentOfPeriapsis` <span class="unitSpan">:material-ruler: rad</span>

Also denoted as `ω`, represents the [argument of the periapsis](https://en.wikipedia.org/wiki/Argument_of_periapsis) of this orbit.

### Position over Time Parameters

#### `number period` <span class="unitSpan">:material-ruler: s</span>

The period of the orbit, or the time it takes for the object to complete a single orbit around the parent body. If the orbit is parabolic or hyperbolic, the value is equivalent to `math.huge`.

#### `number timeToEscape` <span class="unitSpan">:material-ruler: s</span>

Given its position at `t=epoch`, the time it will take for the object to escape the gravitational influence of the parent body. If the orbit is elliptical or circular, this value is equivalent to `math.huge`.

#### `number epoch` <span class="unitSpan">:material-ruler: s</span>

The time that this orbit was created.

#### `number trueAnomalyAtEpoch` <span class="unitSpan">:material-ruler: rad</span>

The angular position of the object along its orbit at the time this orbit was created. (`t=epoch`).

### Other Parameters

#### `number parameter` <span class="unitSpan">:material-ruler: km</span>

Also denoted as `p`, the [semilatus rectum](https://en.wikipedia.org/wiki/Ellipse#Semi-latus_rectum) of the orbit. This is the length of the chord through the focus that is perpendicular to the major axis.

### Universal Formulation for Prediction

#### `number alpha`

A cached intermediate value used during the Universal Prediction algorithm.

#### `number radiusEpochX` <span class="unitSpan">:material-ruler: km</span>

The x-coordinate of the vector pointing from the parent body to the position of the orbiting object at epoch in ECI coordinates. Used during the Universal Prediction algorithm.

#### `number radiusEpochY` <span class="unitSpan">:material-ruler: km</span>

The y-coordinate of the vector pointing from the parent body to the position of the orbiting object at epoch in ECI coordinates. Used during the Universal Prediction algorithm.

#### `number radiusEpochZ` <span class="unitSpan">:material-ruler: km</span>

The z-coordinate of the vector pointing from the parent body to the position of the orbiting object at epoch in ECI coordinates. Used during the Universal Prediction algorithm.

#### `number velocityEpochX` <span class="unitSpan">:material-ruler: km/s</span>

The x-coordinate of the orbiting body's velocity vector in ECI coordinates. Used during the Universal Prediction algorithm.

#### `number velocityEpochY` <span class="unitSpan">:material-ruler: km/s</span>

The y-coordinate of the orbiting body's velocity vector in ECI coordinates. Used during the Universal Prediction algorithm.

#### `number velocityEpochZ` <span class="unitSpan">:material-ruler: km/s</span>

The z-coordinate of the orbiting body's velocity vector in ECI coordinates. Used during the Universal Prediction algorithm.

#### `number velocityEpoch` <span class="unitSpan">:material-ruler: km/s</span>

The magnitude of the orbiting body's velocity vector in ECI coordinates. Used during the Universal Prediction algorithm.

#### `number velocityRadialEpoch` <span class="unitSpan">:material-ruler: km/s</span>

The magnitude of the orbiting body's velocity vector that is radial to the parent body in ECI coordinates. Used during the Universal Prediction algorithm.

### Perifocal to ECI Transformation Matrix

#### `number m11`
Represents row 1 column 1 of the Perifocal to ECI Transformation Matrix.

#### `number m12`
Represents row 1 column 2 of the Perifocal to ECI Transformation Matrix.

#### `number m13`
Represents row 1 column 3 of the Perifocal to ECI Transformation Matrix.

#### `number m21`
Represents row 2 column 1 of the Perifocal to ECI Transformation Matrix.

#### `number m22`
Represents row 2 column 2 of the Perifocal to ECI Transformation Matrix.

#### `number m23`
Represents row 2 column 3 of the Perifocal to ECI Transformation Matrix.

#### `number m31`
Represents row 3 column 1 of the Perifocal to ECI Transformation Matrix.

#### `number m32`
Represents row 3 column 2 of the Perifocal to ECI Transformation Matrix.

#### `number m33`
Represents row 3 column 3 of the Perifocal to ECI Transformation Matrix.

## Constructors

### fromKeplerianElements

```lua
function Orbit.fromKeplerianElements(
    parentBody: CelestialBody,
    eccentricity: number,
    semimajorAxis: number,
    inclination: number,
    longitudeAscendingNode: number,
    argumentPeriapsis: number,
    trueAnomalyEpoch: number,
    epoch: number,
    reuseOrbitObject: Orbit?
) → Orbit
```

Used to construct an orbit using standard Keplerian Orbital Parameters.

The `reuseOrbitObject` field is used to provide an existing Orbit object to the constructor. If nil, a new object will be constructed. If provided, instead of creating an entirely new object, it will overwrite all the values of `reuseOrbitObject` instead. This can be used to reuse tables to avoid pressuring the garbage collector.

### fromPositionVelocityECI
```lua
function Orbit.fromPositionVelocityECI(
    parentBody: CelestialBody, 
    positionX: number, 
    positionY: number, 
    positionZ: number, 
    velocityX: number, 
    velocityY: number, 
    velocityZ: number, 
    currentTime: number, 
    reuseOrbitObject: Orbit?
) → Orbit
```

Given the initial position and velocity of the orbiting body, this function solves for the Keplerian orbital parameters to construct the Orbit.

The `reuseOrbitObject` field is used to provide an existing Orbit object to the constructor. If nil, a new object will be constructed. If provided, instead of creating an entirely new object, it will overwrite all the values of `reuseOrbitObject` instead. This can be used to reuse tables to avoid pressuring the garbage collector.

## Methods

### GetPositionPerifocal(...)
```lua
function Orbit:GetPositionPerifocal(trueAnomaly: number) → number, number, number, number
```

Returns the current position and velocity at the given true anomaly relative to the Perifocal coordinate system.

`number trueAnomaly`: (:material-ruler: rad) The true anomaly of the spacecraft at the current point along its orbit.

**Returns:** `number, number, number, number` The x and y component of the position (:material-ruler: km) in perifocal coordinates, and the x and y component (:material-ruler: km/s) of the velocity in perifocal coordinates.

### GetPositionVelocityECI(...)
```lua
function Orbit:GetPositionVelocityECI(trueAnomaly: number) → number, number, number, number, number, number
```

Returns the current position and velocity at the given true anomaly relative to the ECI coordinate system.

`number trueAnomaly`: (:material-ruler: rad) The true anomaly of the spacecraft at the current point along its orbit.

**Returns:** `number, number, number, number, number, number` The x, y, and z components (:material-ruler: km) of the position in ECI coordinates, and the x, y, and z components (:material-ruler: km/s) of the velocity in ECI coordinates. 

### CalculateTrueAnomalyAtRadius(...)
```lua
function Orbit:CalculateTrueAnomalyAtRadius(radius: number) → number?
```

Calculates the true anomaly where the orbit crosses the given radius.

`number radius`: (:material-ruler: km) The radius for which to solve for its true anomaly intersection point.

**Returns:** The true anomaly (:material-ruler: rad) where the orbit crosses the given radius, or nil if the orbit never crosses the radius.

### TransformPerifocalToECI(...)

```lua
function Orbit:TransformPerifocalToECI(xValue: number, yValue: number) → number, number, number
```

Transforms the given coordinates in the perifocal coordinates system to ECI coordinates.

`number xValue`: (:material-ruler: km) The x-coodinate of the perifocal coordinate.

`number yValue`: (:material-ruler: km) The y-coodinate of the perifocal coordinate.

**Returns:** The x, y, and z coordinates (:material-ruler: km) in ECI coordinates.

### GetNormalECI()

```lua
function Orbit:GetNormalECI() → number, number, number
```

**Returns:** The normal vector of the orbital plane in ECI coordinates.

### GetTimeToEscape(...)

```lua
function Orbit:GetTimeToEscape(trueAnomaly: number) → number
```

Returns the time to escape for a hyperbolic orbit. If the orbit is an ellipse, returns infinity (because it will never escape)

`number trueAnomaly` (:material-ruler: rad): The current true anomaly of the spacecraft.

**Returns:** The time to escape (:material-ruler: s).

### GetTimeOfFlight(...)

```lua
function Orbit:GetTimeOfFlight(startTrueAnomaly: number, endTrueAnomaly: number) → number
```

Calculates the flight time from the current angle to the target angle.

`number currentAngle` (:material-ruler: rad): The starting true anomaly of the spacecraft. This can be in the range `[-inf, inf]` if elliptical.

`number targetAngle` (:material-ruler: rad): The ending true anomaly of the spacecraft. This can be in the range `[-inf, inf]` if elliptical.

**Returns:** The time (:material-ruler: s) until the spacecraft reaches the given true anomaly. Returns math.huge if the spacecraft will never reach the given target angle.

### Orbit:UniversalPrediction(...)

```lua
function Orbit:UniversalPrediction(currentTime: number, tolerance: number) → number
```

Uses the Universal Formulation of Orbital Prediction to numerically approximate the orbiting object's future position along its orbit at the given time. 

This function uses numerical analysis, so perfect accuracy is not possible; instead, the function takes a required "tolerance" that it will refine the prediction to.

`number currentTime` (:material-ruler: s): The time at which to get the orbiting body's future position. The function calculates the internal deltaTime based on this orbit's epoch.

`number tolerance` (:material-ruler: km): The desired accuracy for the prediction. Use an appropriate small value like 0.000008 km. Lower tolerances mean more accuracy, but will take longer to compute.

**Returns:** The true anomaly (:material-ruler: rad) of the orbiting body at currentTime.

### CubicBezierApproximationControlPoints(...)
```lua
function Orbit:CubicBezierApproximationControlPoints(startTrueAnomaly: number, endTrueAnomaly: number) → 
    number, number, 
    number, number, number, 
    number, number, 
    number, number, number
```
Calculates the control points for representing an arc of this orbit using a cubic bezier curve. Returns values in Perifocal coordinate system.

`number startTrueAnomaly` (:material-ruler: rad) The angular position of the start of the arc.

`number endTrueAnomaly` (:material-ruler: rad) The angular position of the end of the arc.

**Additional Argument Considerations**: This function assumes `startTrueAnomaly < endTrueAnomaly` and `|startTrueAnomaly - endTrueAnomaly| < pi`.

**Returns:** 

- `number` (:material-ruler: km): The x-coordinate of the position of the first control point in Perifocal coordinates.

- `number` (:material-ruler: km): The y-coordinate of the position of the first control point in Perifocal coordinates.

- `number` (:material-ruler: km): The x-coordinate of the direction vector of the first control point in Perifocal coordinates.

- `number` (:material-ruler: km): The y-coordinate of the direction vector of the first control point in Perifocal coordinates.

- `number` (:material-ruler: km): The Timmer distance of the first control point in Perifocal coordinates.

- `number` (:material-ruler: km): The x-coordinate of the position of the second control point in Perifocal coordinates.

- `number` (:material-ruler: km): The y-coordinate of the position of the second control point in Perifocal coordinates.

- `number` (:material-ruler: km): The x-coordinate of the direction vector of the second control point in Perifocal coordinates.

- `number` (:material-ruler: km): The y-coordinate of the direction vector of the second control point in Perifocal coordinates.

- `number` (:material-ruler: km): The Timmer distance of the second control point in Perifocal coordinates.
