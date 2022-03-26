# Quickstart

Welcome to OrbitLib! This quickstart aims to provide everything needed to start using OrbitLib at a basic level.

## Features

OrbitLib is a library that brings Keplerian orbital mechanics to Roblox.

Its features include:

- Basic Orbital Properties
- Orbital Derivation from Position and Velocity
- Orbital Prediction over Time
- Utilities for Rendering

## Installation

Let's open Roblox Studio and create an empty project on a baseplate.

Next, follow the instructions on the [Installation Page](./installation.md) and return here once done. For the sake of the quickstart guide, let's **install OrbitLib into ReplicatedStorage**. Once done, your ReplicatedStorage should look something like this:

![OrbitLib Installed](./assets/orbitlibInstalled.png)

## Units

Before we continue to writing code, let's talk about units.

In physics, units are very important. We can get _very different_ answers to problems if we use even a different scale of the same unit (kilometers vs meters). Thus, it is important to keep track of what units are being used at all times.

The OrbitLib documentation helps you keep track of what units functions expect and return using the ruler (:material-ruler:) icon. If you see this icon in the documentation, that means the function/field/variable/whatever uses those types of units. 

## Hello OrbitLib!

Now that OrbitLib is installed, let's take it for a test drive. Let's write some code that creates Earth and a satellite orbiting it.

Create a new script in `ServerScriptService` and name it `HelloOrbitLib`.

On the first lines, let's import the CelestialBody class and Orbit class from their respective module scripts:

```lua title="Importing the Modules"
-- Import modules from OrbitLib
local CelestialBody = require(game.ReplicatedStorage.OrbitLib.CelestialBody)
local Orbit = require(game.ReplicatedStorage.OrbitLib.Orbit)
```

Now, let's create Earth using [`CelestialBody.new(...)`](./API Reference/celestialBody.md#constructors). The constructor expects a `string` name as the first argument, the mass of the planet (:material-ruler: kg), and the radius of the planet (:material-ruler: km).

```lua title="Importing the Modules"
-- Create Earth, a CelestialBody with a mass of 5.972*10^24 kg 
-- and a radius of 6378.1 kilometers
local earth = CelestialBody.new("Earth", 5.972e24, 6378.1)
```

Great, we now have a properly configured CelestialBody. Let's make an orbit around it. 

[Keplerian elements](https://en.wikipedia.org/wiki/Orbital_elements) are a common way to describe the shape of orbits. Using the [`Orbit.fromKeplerianElements(...)`](./API Reference/orbit.md#fromkeplerianelements) constructor, we can create an orbit using common Keplerian elements.

Let's make an orbit around the equator of the planet at an altitude of about 1700 kilometers above the surface. The orbital parameters for such an orbit would be as follows:

| Orbital Parameter                   | Value                       |
|-------------------------------------|-----------------------------|
| Semimajor Axis (a)                  | 8000 (:material-ruler: km)  |
| Eccentricity (e)                    | 0                           |
| Inclination (i)                     | 0 (:material-ruler: rad)    |
| Longitude of the Ascending Node (Ω) | 0 (:material-ruler: rad)    |
| Argument of the Periapsis (ω)       | 0 (:material-ruler: rad)    |
| True Anomaly (v)                    | 0 (:material-ruler: rad)    |

Let's construct this orbit and then print out the result.

```lua title="From Keplerian Elements"
-- Create a circular orbit about 1700 kilometers above the surface.
local orbitTest = Orbit.fromKeplerianElements(
	earth, 0, 8000, 0, 0, 0, 0, 0
)
print(orbitTest)
```

Now that we have an orbit, let's do something with it. How about we calculate the position of the periapsis and the velocity of the spacecraft at periapsis? We can do this by using the [`Orbit:GetPositionVelocityECI(...)`](./API Reference/orbit.md#fromkeplerianelements) function using 0 radians as our true anomaly.

```lua title="GetPositionVelocityECI"
-- Get the position and velocity at the periapsis (true anomaly = 0 radians)
local eciPosX, eciPosY, eciPosZ, eciVelX, eciVelY, eciVelZ = orbit:GetPositionVelocityECI(0)

-- Pythagorean theorem to calculate the magnitude of the velocity.
local velMagnitude = math.sqrt(eciVelX*eciVelX + eciVelY*eciVelY + eciVelZ*eciVelZ)
print("Position at Periapsis: "..eciPosX.." km,"..eciPosY.." km,"..eciPosZ.." km. Velocity: "..velMagnitude.." km/s")
```

Putting that all together, we get:

```lua title="Hello OrbitLib! Script" linenums="1"

print("Hello OrbitLib!")

-- Import modules from OrbitLib
local CelestialBody = require(game.ReplicatedStorage.OrbitLib.CelestialBody)
local Orbit = require(game.ReplicatedStorage.OrbitLib.Orbit)

-- Create Earth, a CelestialBody with a mass of 5.972*10^24 kg 
-- and a radius of 6378.1 kilometers
local earth = CelestialBody.new("Earth", 5.972e24, 6378.1)

-- Create a circular orbit about 1700 kilometers above the surface.
local orbitTest = Orbit.fromKeplerianElements(
	earth, 0, 6548.1, 0, 0, 0, 0, 0
)

print(orbitTest)

-- Get the position and velocity at the periapsis (true anomaly = 0 radians)
local eciPosX, eciPosY, eciPosZ, eciVelX, eciVelY, eciVelZ = orbit:GetPositionVelocityECI(0)

-- Pythagorean theorem to calculate the magnitude of the velocity.
local velMagnitude = math.sqrt(eciVelX*eciVelX + eciVelY*eciVelY + eciVelZ*eciVelZ)
print("Position at Periapsis: "..eciPosX.." km,"..eciPosY.." km,"..eciPosZ.." km. Velocity: "..velMagnitude.." km/s")

```

When we run this code, we should see the following output into the console.

```lua title="Hello OrbitLib! Script Output" linenums="1"
Position at Periapsis: 6548.1 km,0 km,0 km. Velocity: 7.80185639124535 km/s
{
    ["alpha"] = 0.0001975739654546026,
    ["apoapsis"] = 6800.000000000001,
    ["argumentOfPeriapsis"] = 3.141592653589793,
    ["conic"] = "ELLIPSE",
    ["eccentricity"] = 0.3435029650912981,
    ["epoch"] = 0,
    ["inclination"] = 0.03224688243525252,
    ["longitudeOfAscendingNode"] = 0,
    ["m11"] = -1,
    ["m12"] = -1.224646799147353e-16,
    ["m13"] = 0,
    ["m21"] = 1.224010122837544e-16,
    ["m22"] = -0.9994801143396996,
    ["m23"] = -0.03224129401095665,
    ["m31"] = 3.948419751088679e-18,
    ["m32"] = -0.03224129401095665,
    ["m33"] = 0.9994801143396996,
    ["parameter"] = 4464.179837379173,
    ["parentBody"] =  ▶ {...},
    ["periapsis"] = 3322.791205805645,
    ["period"] = 3583.683853558884,
    ["radiusEpoch"] = 6800,
    ["radiusEpochX"] = 6800,
    ["radiusEpochY"] = 0,
    ["radiusEpochZ"] = 0,
    ["semimajorAxis"] = 5061.395602902823,
    ["semiminorAxis"] = 4753.417738793676,
    ["specificAngularMomentum"] = 42181.92978041663,
    ["specificMechanicalEnergy"] = -39.37412611764706,
    ["timeToEscape"] = inf,
    ["trueAnomalyAtEpoch"] = 3.141592653589793,
    ["velocityEpoch"] = 6.203224967708329,
    ["velocityEpochX"] = 0,
    ["velocityEpochY"] = 6.2,
    ["velocityEpochZ"] = 0.2,
    ["velocityRadialEpoch"] = 0
}
```

We have successfully used OrbitLib to create our first orbit! As you can see, there is a lot going on in a single orbit object, but that is mainly because orbital mechanics is fairly complex.

Of course, nothing visual is going on here. That is because OrbitLib is principally a mathematics and physics package. However, with just a little effort, we can write some code to let us visually see what is going on with these orbits. We'll talk about how to do that in the [Basic Rendering](./OrbitLib 101/buildingBasicRenderer.md) Article.