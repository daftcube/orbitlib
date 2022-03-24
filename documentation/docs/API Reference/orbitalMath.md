# OrbitalMath

Orbital Mechanics unfolds over truly astronomical scales. Such scales cannot be accurately represented with 32-bit floating point numbers, so we define our own vector functions that use tuples of 64-bit raw Lua numbers.

The source file contains more functions than are documented on this page. These functions are either incomplete or are used in intermediate calculations in public documented functions. Note that functions that are not documented on this page are not intended to be used outside of the module or called by other scripts. However, if one is curious about these functions, there are comments in the source.

## Functions

### CrossProduct(...)

```lua
function module.CrossProduct(a1: number, a2: number, a3: number, b1: number, b2: number, b3: number) → number, number, number
```

Calculates the cross product of vectors a and b.

`number a1`: The x coordinate of vector a.

`number a2`: The y coordinate of vector a.

`number a3`: The z coordinate of vector a.

`number b1`: The x coordinate of vector b.

`number b2`: The y coordinate of vector b.

`number b3`: The z coordinate of vector b.

**Returns** The x, y, and z component of the cross product of the two vectors.

### Magnitude(...)

```lua
function module.Magnitude(a1: number, a2: number, a3: number) → number
```

Calculates the magnitude of vector a.

`number a1`: The x coordinate of vector a.

`number a2`: The y coordinate of vector a.

`number a3`: The z coordinate of vector a.

**Returns**: The magnitude of vector a.

### SqrMagnitude(...)

```lua
function module.SqrMagnitude(a1: number, a2: number, a3: number) → number
```

Calculates the squared magnitude of vector a without making a square root operation.

`number a1`: The x coordinate of vector a.

`number a2`: The y coordinate of vector a.

`number a3`: The z coordinate of vector a.

**Returns**: The squared magnitude of vector a.

### DotProduct(...)

```lua
function module.CrossProduct(a1: number, a2: number, a3: number, b1: number, b2: number, b3: number) → number, number, number
```

Calculates the dot product of vectors a and b.

`number a1`: The x coordinate of vector a.

`number a2`: The y coordinate of vector a.

`number a3`: The z coordinate of vector a.

`number b1`: The x coordinate of vector b.

`number b2`: The y coordinate of vector b.

`number b3`: The z coordinate of vector b.

**Returns** The dot product between a and b.

### Tanh(...)

```lua
function module.Tanh(x: number) → number
```

Calculates the hyperbolic tangent of x.

`number x`: The argument.

**Returns:** The hyperbolic tangent of x.

### Asinh(...)

```lua
function module.Asinh(x: number) → number
```

Calculates the inverse hyperbolic sine of x.

`number x`: The argument.

**Returns:** The inverse hyperbolic sine of x.

### Acosh(...)

```lua
function module.Acosh(x: number) → number
```

Calculates the inverse hyperbolic cosine of x.

`number x`: The argument.

**Returns:** The inverse hyperbolic cosine of x.

### Atanh(...)

```lua
function module.Atanh(x: number) → number
```

Calculates the inverse hyperbolic tangent of x.

`number x`: The argument.

**Returns:** The inverse hyperbolic tangent of x.

### EccentricFromMean(...)

```lua
function module.EccentricFromMean(M: number, e: number) → number
```

Calculates Mean Anomaly from Eccentric Anomaly using a series derivation. **THIS IS NOT ACCURATE WHEN E IS CLOSE TO 1.** Consider using the Universal Formulation instead.

`number M`: The mean anomaly.

`number e`: The eccentricity of the orbit.

**Returns:** The mean anomaly from the eccentric anomaly.

### EccentricFromTrue(...)

```lua
function module.EccentricFromTrue(V: number, e: number) → number
```

Calculates the eccentric anomaly from the true anomaly.

`number V`: The True Anomaly.

`number e`: The eccentricity of the orbit.

**Returns:** The Eccentric Anomaly from the True Anomaly.

### MeanFromEccentric(...)

```lua
function module.MeanFromEccentric(E: number, e: number) → number
```

Calculates the mean anomaly from the eccentric anomaly.

`number E`: The Eccentric Anomaly.

`number e`: The eccentricity of the orbit.

**Returns:** The Mean Anomaly from the Eccentric Anomaly.

### TrueFromEccentric(...)

```lua
function module.TrueFromEccentric(E: number, e: number) → number
```

Calculates the true anomaly from the eccentric anomaly.

`number E`: The Eccentric Anomaly.

`number e`: The eccentricity of the orbit.

**Returns:** The true anomaly from the eccentric anomaly.

### EccentricFromMeanHyperbolic(...)

```lua
function module.EccentricFromMeanHyperbolic(M: number, e: number) → number
```

Calculates Eccentric Anomaly from Hyperbolic Mean Anomaly using a series solution.

**Remarks**: I don't think this currently works. Just use the universal prediction method anyway.

`number E`: The hyperbolic mean anomaly.

`number e`: The eccentricity of the orbit.

**Returns:** The Eccentric Anomaly from Hyperbolic Mean Anomaly

### MeanHyperbolicFromEccentric(...)

```lua
function module.MeanHyperbolicFromEccentric(E: number, e: number) → number
```

Calculates the hyperbolic mean anomaly from the eccentric anomaly.

`number E`: The hyperbolic mean anomaly.

`number e`: The eccentricity of the orbit.

**Returns:** The Hyperbolic Mean Anomaly from the Eccentric Anomaly

### EccentricHyperbolicFromTrue(...)

```lua
function module.EccentricHyperbolicFromTrue(V: number, e: number) → number
```

Calculates the hyperbolic mean anomaly from the eccentric anomaly.

`number V`: The Hyperbolic Eccentric Anomaly.

`number e`: The eccentricity of the orbit.

**Returns:** The Hyperbolic Eccentric Anomaly from the True Anomaly.

### TrueFromEccentricHyperbolic(...)

```lua
function module.TrueFromEccentricHyperbolic(E: number, e: number) → number
```

Calculates the true anomaly from the hyperbolic eccentric anomaly.

`number V`: The Hyperbolic Eccentric Anomaly.

`number e`: The eccentricity of the orbit.

**Returns:** The Hyperbolic Eccentric Anomaly from the True Anomaly

### CalculatePerifocalToECIMatrix(...)

```lua
function module.CalculatePerifocalToECIMatrix(i: number, O: number, o: number) → 
    number, number, number,
    number, number, number,
    number, number, number
```

From the three rotational orbital parameters, calculates the 3x3 matrix.

`number i`: The inclination, in radians.

`number O`: The longitude of the ascending node, in radians.

`number o`: The argument of the periapsis, in radians.

**Returns:** The values of the 3x3 matrix.

### StumpffS(...)

```lua
function module.StumpffS(z: number) → number
```

Calculates the Stumpff function S.

`number z`: The argument, usually alpha*x^2

**Returns:** The value of S for the given z. 

### StumpffC(...)

```lua
function module.StumpffC(z: number) → number
```

Calculates the Stumpff function C.

`number z`: The argument, usually alpha*x^2

**Returns:** The value of C for the given z.
