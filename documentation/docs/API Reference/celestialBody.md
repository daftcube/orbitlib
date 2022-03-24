# CelestialBody

CelestialBody defines a class that represents a body with sufficient mass to be orbited.

The source file contains more functions than are documented on this page. These functions are either incomplete or are used in intermediate calculations in public documented functions. Note that functions that are not documented on this page are not intended to be used outside of the module or called by other scripts. However, if one is curious about these functions, there are comments in the source.

## Fields

### `string name`
The human-readable name of the planet.

### `number mass` <span class="unitSpan">:material-ruler: kg</span>

The mass of the celestial body.

### `number mu` <span class="unitSpan">:material-ruler: km^3/s^2</span>

`mu` represents the [Standard Gravitational Parameter ](https://en.wikipedia.org/wiki/Specific_mechanical_energy), a quantity equal to the mass of the parent body multiplied by the [Universal Gravitational Constant](./physicsConstants.md).

### `number radius` <span class="unitSpan">:material-ruler: km</span>

The radius of the celestial body.

### `number sphereOfInfluence` <span class="unitSpan">:material-ruler: km</span>

The radius of the gravitational [sphere of influence](https://en.wikipedia.org/wiki/Sphere_of_influence_(astrodynamics)) of the Celestial Body. In Patched Conics, the sphere of influence is used to denote the distance from the parent body where the gravitational influence from that body is considered negligible and can be ignored.

If this CelestialBody has no parent, the sphere of influence is set to `math.huge`.

_Do not change this value manually. Instead, call SetParent(...)_

### <code>[CelestialBody](./celestialBody.md) parentBody</code>

The CelestialBody this CelestialBody orbits. By default, is nil.

_Do not change this value manually. Instead, call SetParent(...)_

### <code>[Orbit](./orbit.md) orbit</code>

If this CelestialBody has a parent, this field defines the orbit this CelestialBody follows around its parent. If this CelestialBody does not have a parent, this field is nil.

_Do not change this value manually. Instead, call SetParent(...)_

### <code>[CelestialBody[]](./celestialBody.md) childBodies</code>

Contains all the CelestialBodies that orbit this CelestialBody.

_Do not change this value manually. Instead, call SetParent(...)_

## Constructors

### CelestialBody.new(...)

```lua
function CelestialBody.new(name: string, mass: number, radius: number) → CelestialBody
```

`string name`: The human-readable name of the planet.

`number mass` <span class="unitSpan">(:material-ruler: kg)</span>: The mass of the celestial body.

`number radius` <span class="unitSpan">(:material-ruler: km)</span>: The radius of the celestial body.

## Methods

### CelestialBody:SetParent(...)

```lua
function CelestialBody:SetParent(otherCelestialBody: CelestialBody, orbit: Orbit)
```

Sets this celestial body's parent as another celestial body.

<code>[CelestialBody](./celestialBody.md) otherCelestialBody</code>: The new parent body for this CelestialBody.

<code>[Orbit](./orbit.md) otherCelestialBody</code>: The orbit that defines motion about the parent body. Set to nil if this celestial's parent is nil and thus it should be the center of the universe.

**Remarks:** The CelestialBody graph must be a tree.