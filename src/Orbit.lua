--[[
    OrbitalMechanics/Orbit.lua

    Represents a trajectory around a celestial body.

    Shout out to DarkFireDrago for help with numerical analysis!

    Copyright © 2021 Owen Bartolf

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
--]]

local OrbitalMath = require(script.Parent.OrbitalMath)
local PhysicsConstants = require(script.Parent.PhysicsConstants)
local DoubleMath2D = require(script.Parent.DoubleMath2D)

local TAU = PhysicsConstants.tau
local EPSILON = PhysicsConstants.epsilon

local StumpffS = OrbitalMath.StumpffS
local StumpffC = OrbitalMath.StumpffC
local CalculateObjectSeparation = OrbitalMath.CalculateObjectSeparation

local MAX_ITERATIONS_CHORD = 40
local TOLERANCE_CHORD = 1e-4

local CROSSES_WITHIN_DISTANCE_SAMPLES = 150
local CROSSES_WITHIN_DISTANCE_TOLERANCE = 0.0001
local CROSSES_WITHIN_DISTANCE_FUNCTION_TOLERANCE = 0.001
local CROSSES_WITHIN_MAX_ITERATIONS = 30

local HOOTS_ORBITS_NOT_ELLIPTICAL_EXCEPTION = "[Orbit] Both orbits must be elliptical to use Hoots closest approach."
-------------------------------------------------------------------------------
-- HELPER FUNCTIONS
-------------------------------------------------------------------------------

--[[
    A helper function that returns the conic section for the
    orbit based on its eccentricity.
--]]
local function GetConicTypeFromEccentricity(eccentricity: number)
    if eccentricity == 0 then
        return "CIRCLE"
    elseif eccentricity < 1 then
        return "ELLIPSE"
    elseif eccentricity == 1 then
        return "PARABOLA"
    elseif eccentricity > 1 then
        return "HYPERBOLA"
    end
end

--[[
    A helper function that represents a normalized positional derivative for one
    axis in perifocal space.

    @param velocityMagnitude (number) A value equal to mu / h
    @param eccentricity (number) The eccentricity of the orbit
    @param trueAnomaly (number) The current true anomaly.

    @returns (number) Value of expression.
--]]
local function ChordDerivativeFunctionX(
    velocityMagnitude: number,
    eccentricity: number,
    trueAnomaly: number,
    chordXNorm: number
)
    local velX = velocityMagnitude * -math.sin(trueAnomaly)
    local velY = velocityMagnitude * (eccentricity + math.cos(trueAnomaly))

    return (velX / math.sqrt( velX*velX + velY*velY )) - chordXNorm
end

--[[
    A helper function that represents a normalized positional derivative for one
    axis in perifocal space.

    @param velocityMagnitude (number) A value equal to mu / h
    @param eccentricity (number) The eccentricity of the orbit
    @param trueAnomaly (number) The current true anomaly.

    @returns (number) Value of expression.
--]]
local function ChordDerivativeFunctionY(
    velocityMagnitude: number,
    eccentricity: number,
    trueAnomaly: number,
    chordYNorm: number
)

    local velX = velocityMagnitude * -math.sin(trueAnomaly)
    local velY = velocityMagnitude * (eccentricity + math.cos(trueAnomaly))

    return (velY / math.sqrt( velX*velX + velY*velY )) - chordYNorm

end

-------------------------------------------------------------------------------
-- ORBIT CLASS
-------------------------------------------------------------------------------

local Orbit = {}
Orbit.__index = Orbit

--[[
    Standard Constructor
--]]
function Orbit.new(parentBody)
   
    local self = {

        -- Parent CelestialBody parameters:
        parentBody = parentBody,
        mu = parentBody.mu, -- In km^3/s^2

        -- ORBIT CLASSIFICATION
        conic = "CIRCLE",
        
        -- ENERGY PARAMETERS
        specificMechanicalEnergy = 0,
        specificAngularMomentum = 0,
        
        -- ELEMENTARY PARAMETERS:
        -- Shape Parameters
        semimajorAxis = 0,
        periapsis = 0,
        apoapsis = 0, -- Note: Infinity when parabolic/hyperbolic
        eccentricity = 0,

        -- Orientation Parameters
        inclination = 0,
        longitudeOfAscendingNode = 0,
        argumentOfPeriapsis = 0,

        -- Position over Time Parameters
        period = 0, -- Infinity when parabolic/hyperbolic
        timeToEscape = 0, -- Note: Infinity when circular / elliptical
        epoch = 0,
        trueAnomalyAtEpoch = 0,

        -- OTHER PARAMETERS:
        parameter = 0,

        -- UNIVERSAL PREDICTION
        alpha = 0,

        -- R0V0 (Cached for Universal Formulation)
        radiusEpochX = 0,
        radiusEpochY = 0,
        radiusEpochZ = 0,
        radiusEpoch = 0,
        velocityEpochX = 0,
        velocityEpochY = 0,
        velocityEpochZ = 0,
        velocityEpoch = 0,
        velocityRadialEpoch = 0,

        -- Perifocal to ECI Transformation Matrix
        m11 = 0,
        m12 = 0,
        m13 = 0,
        m21 = 0,
        m22 = 0,
        m23 = 0,
        m31 = 0,
        m32 = 0,
        m33 = 0

    }

    setmetatable(self, Orbit)

    return Orbit

end

--[[
    Constructs orbit from Keplerian Orbital Elements.

    @param parentBody (CelestialBody)
    @param eccentricity (number)
    @param semimajorAxis (number)
    @param inclination (number)
    @param longitudeAscendingNode (number)
    @param argumentPeriapsis (number)
    @param trueAnomalyEpoch (number)
    @param epoch (number)

    @returns (Orbit)
--]]
function Orbit.fromKeplerianElements(
    parentBody: table,
    eccentricity: number,
    semimajorAxis: number,
    inclination: number,
    longitudeAscendingNode: number,
    argumentPeriapsis: number,
    trueAnomalyEpoch: number,
    epoch: number,
    reuseOrbitObject: table?
)
    
    -- Cache mu from parent body
    local mu = parentBody.mu
    local muReciprocal = 1 / mu

    -- Calculate parameter p
    local p = semimajorAxis * (1 - eccentricity*eccentricity)

    -- Calculate specific angular momentum h
    local hSqrMagnitude = mu * p
    local h = math.sqrt(hSqrMagnitude)

    -- Calculate specific mechanical energy E
    local E = -mu/(2 * semimajorAxis)

    -- Calculate Transformation Matrix
    local m11, m12, m13, m21, m22, m23, m31, m32, m33 = 
        OrbitalMath.CalculatePerifocalToECIMatrix(inclination, longitudeAscendingNode, argumentPeriapsis)

    -- Calculate Conic-Specific parameters
    local semiminorAxis = 0
    local ap = 0
    local pe = 0
    local period = 0
    local timeToEscape = 0

    if eccentricity >= 0 and eccentricity < 1 then -- Ellipse Case
        
        semiminorAxis = math.sqrt(semimajorAxis * p)
        ap = semimajorAxis * (1 + eccentricity)
        pe = semimajorAxis * (1 - eccentricity)
        period = TAU * math.sqrt( muReciprocal*semimajorAxis*semimajorAxis*semimajorAxis ) -- Kepler's formula
        timeToEscape = math.huge
        

    elseif eccentricity > 1 then -- Hyperbola case
        
        semiminorAxis = semimajorAxis * math.sqrt(eccentricity*eccentricity - 1)
        ap = math.huge
        pe = semimajorAxis * (1 - eccentricity)
        period = math.huge

    else
        error("Not supported.")
    end
    
    -- Construct object
    if reuseOrbitObject == nil then

        -- Don't use constructor; there would be way too many arguments
            -- to make it efficient.

            reuseOrbitObject = setmetatable(
                {
                    parentBody = parentBody,
                    conic = GetConicTypeFromEccentricity(eccentricity),

                    -- ENERGY AND MOMENTUM PARAMETERS
                    specificMechanicalEnergy = E,
                    specificAngularMomentum = h,
                    
                    -- SHAPE PARAMETERS
                    eccentricity = eccentricity,
                    semimajorAxis = semimajorAxis,
                    semiminorAxis = semiminorAxis,
                    parameter = p,
                    apoapsis = ap,
                    periapsis = pe,
                    
                    -- ROTATIONAL PARAMETERS
                    inclination = inclination,
                    longitudeOfAscendingNode = longitudeAscendingNode,
                    argumentOfPeriapsis = argumentPeriapsis,

                    -- TIME PARAMETERS
                    epoch = epoch,
                    trueAnomalyAtEpoch = trueAnomalyEpoch,
                    period = period,
                    timeToEscape = timeToEscape,
                    
                    -- UNIVERSAL PREDICTION
                    alpha = 1 / semimajorAxis,

                    -- R0V0 (Cached for Universal Formulation)
                    -- TO BE CALCULATED!
                    radiusEpochX = 0,
                    radiusEpochY = 0,
                    radiusEpochZ = 0,
                    radiusEpoch = 0,
                    velocityEpochX = 0,
                    velocityEpochY = 0,
                    velocityEpochZ = 0,
                    velocityEpoch = 0,
                    velocityRadialEpoch = 0,

                    -- TRANSFORMATION MATRIX
                    m11 = m11,
                    m12 = m12,
                    m13 = m13,
                    m21 = m21,
                    m22 = m22,
                    m23 = m23,
                    m31 = m31,
                    m32 = m32,
                    m33 = m33

                },
                Orbit
            )
    else

        

        reuseOrbitObject.parentBody = parentBody
        reuseOrbitObject.conic = GetConicTypeFromEccentricity(eccentricity)
        -- ENERGY AND MOMENTUM PARAMETERS
        reuseOrbitObject.specificMechanicalEnergy = E
        reuseOrbitObject.specificAngularMomentum = h
                            
        -- SHAPE PARAMETERS
        reuseOrbitObject.eccentricity = eccentricity
        reuseOrbitObject.semimajorAxis = semimajorAxis
        reuseOrbitObject.semiminorAxis = semiminorAxis
        reuseOrbitObject.parameter = p
        reuseOrbitObject.apoapsis = ap
        reuseOrbitObject.periapsis = pe
                            
        -- ROTATIONAL PARAMETERS
        reuseOrbitObject.inclination = inclination
        reuseOrbitObject.longitudeOfAscendingNode = longitudeAscendingNode
        reuseOrbitObject.argumentOfPeriapsis = argumentPeriapsis
        -- TIME PARAMETERS
        reuseOrbitObject.epoch = epoch
        reuseOrbitObject.trueAnomalyAtEpoch = trueAnomalyEpoch
        reuseOrbitObject.period = period
        reuseOrbitObject.timeToEscape = timeToEscape
                            
        -- UNIVERSAL PREDICTION
        reuseOrbitObject.alpha = 1 / semimajorAxis
        
        -- R0V0 is to be calculated

        -- TRANSFORMATION MATRIX
        m11 = m11
        m12 = m12
        m13 = m13
        m21 = m21
        m22 = m22
        m23 = m23
        m31 = m31
        m32 = m32
        m33 = m33

    end

    -- Calculate radius and velocity at epoch, along with magnitudes.
    local rx, ry, rz, vx, vy, vz = reuseOrbitObject:GetPositionVelocityECI(trueAnomalyEpoch)
    local r = math.sqrt(rx*rx + ry*ry + rz*rz)
    local v = math.sqrt(vx*vx + vy*vy + vz*vz)
    local velocityRadialEpoch = vx*(rx/r) + vy*(ry/r) + vz*(rz/r)
    
    -- Calculate R0 and V0 values and (hyperbola time to escape if applicable)
    reuseOrbitObject.radiusEpochX = rx
    reuseOrbitObject.radiusEpochY = ry
    reuseOrbitObject.radiusEpochZ = rz
    reuseOrbitObject.radiusEpoch = r
    reuseOrbitObject.velocityEpochX = vx
    reuseOrbitObject.velocityEpochY = vy
    reuseOrbitObject.velocityEpochZ = vz
    reuseOrbitObject.velocityEpoch = v
    reuseOrbitObject.velocityRadialEpoch = velocityRadialEpoch

    return reuseOrbitObject

end
--[[
    Derives the orbital parameters using initial cartesian position and 
    velocity state vectors and constructs a new Orbit object containing the
    derived parameters.

    @param parentBody (CelestialBody) The parent body the object is orbiting.
    @param positionX (number) The x coordinate of the position in ECI coordinates, in km.
    @param positionY (number) The y coordinate of the position in ECI coordinates, in km.
    @param positionZ (number) The z coordinate of the position in ECI coordinates, in km.
    @param velocityX (number) The x coordinate of the velocity in ECI coordinates, in km/s.
    @param velocityY (number) The x coordinate of the velocity in ECI coordinates, in km/s.
    @param velocityZ (number) The x coordinate of the velocity in ECI coordinates, in km/s.
    @param currentTime (number) The time that this object was first tracked, in s.
    @param reuseOrbitObject (OPTIONAL) (Orbit) If provided, the orbital parameters
    will be placed in the given object instead of constructing a new one.

    @returns
--]]
function Orbit.fromPositionVelocityECI(parentBody: table, 
    positionX: number, 
    positionY: number, 
    positionZ: number, 
    velocityX: number, 
    velocityY: number, 
    velocityZ: number, 
    currentTime: number, 
    reuseOrbitObject: table?)

    -- Cache mu from parent body
    local mu = parentBody.mu
    local muReciprocal = 1 / mu

    -- Use a loop just in case the orbit is unresolvable using standard
    -- elementary parameters.
    local isValidOrbit = false
    while not isValidOrbit do
        
        -- Calculate magnitudes of velocity and position
        local currentRadius = OrbitalMath.Magnitude(positionX, positionY, positionZ)
        local velocitySquared = OrbitalMath.SqrMagnitude(velocityX, velocityY, velocityZ)

        -- Calculate specific angular momentum h
        local hx, hy, hz = OrbitalMath.CrossProduct(positionX, positionY, positionZ, velocityX, velocityY, velocityZ)
        local hSqrMagnitude = (hx*hx + hy*hy + hz*hz)

        -- Calculate eccentricity vector
        local dotRadiusVelocity = OrbitalMath.DotProduct(positionX, positionY, positionZ, velocityX, velocityY, velocityZ)
        local eccentricityPositionScalar = velocitySquared - mu/currentRadius
        local eccentricityX = muReciprocal * ( (eccentricityPositionScalar*positionX) - (dotRadiusVelocity*velocityX)  )
        local eccentricityY = muReciprocal * ( (eccentricityPositionScalar*positionY) - (dotRadiusVelocity*velocityY)  )
        local eccentricityZ = muReciprocal * ( (eccentricityPositionScalar*positionZ) - (dotRadiusVelocity*velocityZ)  )
        local eSqr = OrbitalMath.SqrMagnitude(eccentricityX, eccentricityY, eccentricityZ)
        local e = math.sqrt(eSqr)
        -- If a circle or parabola edge case, just give the orbit a slight bump to not make it parabolic.
        if e == 0 or e == 1 then
            velocityX = velocityX + EPSILON -- There is a 0% chance of this happening, but it could happen.
            continue             -- Don't question statistics.
        end

        -- Calculate Radial Velocity at Epoch
        local velocityRadialEpoch = velocityX*(positionX/currentRadius) + velocityY*(positionY/currentRadius) + velocityZ*(positionZ/currentRadius)

        -- Calculate inclination from h. If invalid, add epsilon to velocity and try again.
        local i = math.acos(hz / math.sqrt(hSqrMagnitude))
        -- If an equatorial orbit, just give the orbit a slight bump to make it nonequatorial.
        if i == 0 or i == math.pi then -- There is a 0% chance of this happening, but it could happen.
            velocityZ = velocityZ + EPSILON   -- Don't question statistics.
            continue
        end
        
        -- Get specific mechanical energy
        local E = 0.5*velocitySquared - (mu / currentRadius)

        -- Get ascending node vector
        local nx, ny, nz = OrbitalMath.CrossProduct(0,0,1,hx,hy,hz)
        local nMag = OrbitalMath.Magnitude(nx, ny, nz)
        
        -- Longitude of Ascending Node
        local bigOmega = math.acos(nx / nMag)
        if ny < 0 then
            bigOmega = TAU - bigOmega
        end

        -- Argument of Periapsis
        local smallOmega = math.acos( OrbitalMath.DotProduct(nx, ny, nz, eccentricityX, eccentricityY, eccentricityZ) / (e * nMag) )
        if eccentricityZ < 0 then
            smallOmega = TAU - smallOmega
        end

        -- Calculate true anomaly
        local nu = math.acos(OrbitalMath.DotProduct(eccentricityX, eccentricityY, eccentricityZ, positionX, positionY, positionZ) / (e*currentRadius))
        if dotRadiusVelocity < 0 then
            nu = TAU - nu
        end

        -- Calculate parameter p
        local p = (muReciprocal*hSqrMagnitude)    

        -- Calculate Conic-Specific parameters
        local a = 0
        local b = 0
        local ap = 0
        local pe = 0
        local period = 0
        local timeToEscape = 0
        if e < 1 then
            a = p/(1-eSqr)
            b = math.sqrt(a*p)
            ap = a * (1 + e)
            pe = a * (1 - e)
            period = TAU * math.sqrt( muReciprocal*a*a*a ) -- Kepler's formula
            timeToEscape = math.huge
        else -- Then it's a hyperbola; 0% chance of it being not an ellipse or hyperbola
            a = -p/(eSqr-1)
            b = a * math.sqrt(e*e - 1)
            ap = math.huge
            pe = a * (1 - e)
            period = math.huge
        end

        -- Calculate Transformation Matrix
        local m11, m12, m13, m21, m22, m23, m31, m32, m33 = OrbitalMath.CalculatePerifocalToECIMatrix(i, bigOmega, smallOmega)

        -- Create object if required
        if reuseOrbitObject == nil then
            -- Don't use constructor; there would be way too many arguments
            -- to make it efficient.

            reuseOrbitObject = setmetatable(
                {
                    parentBody = parentBody,
                    conic = GetConicTypeFromEccentricity(e),

                    -- ENERGY AND MOMENTUM PARAMETERS
                    specificMechanicalEnergy = E,
                    specificAngularMomentum = math.sqrt(hSqrMagnitude),
                    
                    -- SHAPE PARAMETERS
                    eccentricity = e,
                    semimajorAxis = a,
                    semiminorAxis = b,
                    parameter = p,
                    apoapsis = ap,
                    periapsis = pe,
                    
                    -- ROTATIONAL PARAMETERS
                    inclination = i,
                    longitudeOfAscendingNode = bigOmega,
                    argumentOfPeriapsis = smallOmega,

                    -- TIME PARAMETERS
                    epoch = currentTime,
                    trueAnomalyAtEpoch = nu,
                    period = period,
                    timeToEscape = timeToEscape,
                    
                    -- UNIVERSAL PREDICTION
                    alpha = 1 / a,

                    -- R0V0 (Cached for Universal Formulation)
                    radiusEpochX = positionX,
                    radiusEpochY = positionY,
                    radiusEpochZ = positionZ,
                    radiusEpoch = math.sqrt(positionX*positionX + positionY*positionY + positionZ*positionZ),
                    velocityEpochX = velocityX,
                    velocityEpochY = velocityY,
                    velocityEpochZ = velocityZ,
                    velocityEpoch = math.sqrt(velocityX*velocityX + velocityY*velocityY + velocityZ*velocityZ),
                    velocityRadialEpoch = velocityRadialEpoch,

                    -- TRANSFORMATION MATRIX
                    m11 = m11, 
                    m12 = m12, 
                    m13 = m13, 
                    m21 = m21, 
                    m22 = m22, 
                    m23 = m23, 
                    m31 = m31, 
                    m32 = m32, 
                    m33 = m33

                },
                Orbit
            )
        else
            reuseOrbitObject.parentBody = parentBody
            reuseOrbitObject.conic = GetConicTypeFromEccentricity(e)

            -- Energy and Momentum Parameters
            reuseOrbitObject.specificMechanicalEnergy = E
            reuseOrbitObject.specificAngularMomentum = math.sqrt(hSqrMagnitude)
            
            -- Shape Parameters
            reuseOrbitObject.semimajorAxis = a
            reuseOrbitObject.semiminorAxis = b
            reuseOrbitObject.parameter = p
            reuseOrbitObject.eccentricity = e
            reuseOrbitObject.parameter = p
            reuseOrbitObject.apoapsis = ap
            reuseOrbitObject.periapsis = pe
            
            -- Rotational Parameters 
            reuseOrbitObject.inclination = i
            reuseOrbitObject.longitudeOfAscendingNode = bigOmega
            reuseOrbitObject.argumentOfPeriapsis = smallOmega
            
            -- Time parameters
            reuseOrbitObject.epoch = currentTime
            reuseOrbitObject.trueAnomalyAtEpoch = nu
            reuseOrbitObject.period = period
            reuseOrbitObject.timeToEscape = timeToEscape

            -- Universal Prediction Cached Values
            reuseOrbitObject.alpha = 1 / a

            -- Saving r0 and v0 is critical for universal prediction
            reuseOrbitObject.radiusEpochX = positionX
            reuseOrbitObject.radiusEpochY = positionY
            reuseOrbitObject.radiusEpochZ = positionZ
            reuseOrbitObject.radiusEpoch = math.sqrt(positionX*positionX + positionY*positionY + positionZ*positionZ)
            reuseOrbitObject.velocityEpochX = velocityX
            reuseOrbitObject.velocityEpochY = velocityY
            reuseOrbitObject.velocityEpochZ = velocityZ
            reuseOrbitObject.velocityEpoch = math.sqrt(velocityX*velocityX + velocityY*velocityY + velocityZ*velocityZ)
            reuseOrbitObject.velocityRadialEpoch = velocityRadialEpoch

            -- Calculate transformation matrix
            reuseOrbitObject.m11 = m11
            reuseOrbitObject.m12 = m12
            reuseOrbitObject.m13 = m13
            reuseOrbitObject.m21 = m21
            reuseOrbitObject.m22 = m22
            reuseOrbitObject.m23 = m23
            reuseOrbitObject.m31 = m31
            reuseOrbitObject.m32 = m32
            reuseOrbitObject.m33 = m33

        end

        if e > 1 then
            reuseOrbitObject.timeToEscape = reuseOrbitObject:GetTimeToEscape(nu)
        end

        return reuseOrbitObject

    end

end

-------------------------------------------------------------------------------
-- POSITION FUNCTIONS
-------------------------------------------------------------------------------

--[[
    Returns the current position and velocity at the given true anomaly
    relative to the perifocal coordinate system.

    @param trueAnomaly (number) The true anomaly of the spacecraft at the
    current point along its orbit.

    @returns (number, number, number, number) The position and velocity in perifocal coordinates.
    Only returns x and y; assumes z = 0
--]]
function Orbit:GetPositionPerifocal(trueAnomaly: number)

    -- Localize values and precompute trig
    local e = self.eccentricity
    local sinTrueAnomaly = math.sin(trueAnomaly)
    local cosTrueAnomaly = math.cos(trueAnomaly)

    -- Calculate constants for position and velocity in perifocal coordinates
    local radiusMagnitude = self.parameter / (1 + e * cosTrueAnomaly)
    local velocityMagnitude = self.parentBody.mu / self.specificAngularMomentum

    return radiusMagnitude * cosTrueAnomaly, radiusMagnitude * sinTrueAnomaly,
        velocityMagnitude * -sinTrueAnomaly, velocityMagnitude * (e + cosTrueAnomaly)

end

--[[
    Returns the current position and velocity at the given true anomaly
    relative to the ECI coordinate system.

    @param trueAnomaly (number) The true anomaly of the spacecraft at the
    current point along its orbit.

    @returns (number, number, number) The IJK ECI coordinates.
--]]
function Orbit:GetPositionVelocityECI(trueAnomaly: number)

    -- Localize values and matrix values
    -- Third column matrix elements not needed because perifocal
    -- z = 0.
    local e = self.eccentricity
    local h = self.specificAngularMomentum
    local m11 = self.m11
    local m12 = self.m12
    local m21 = self.m21
    local m22 = self.m22
    local m31 = self.m31
    local m32 = self.m32

    -- Basically the same as perifocal.
    -- However, I dont want to push and pop a stack frame.
    -- Because in Lua, it apparently can cost a bit to do that.
    -- Yes, this is filthy code that only yields marginal
    -- benefit. Only someone as stupid as me would think this
    -- is a good idea.

    -- Precompute trig
    local sinTrueAnomaly = math.sin(trueAnomaly)
    local cosTrueAnomaly = math.cos(trueAnomaly)

    -- Calculate constants for position and velocity in perifocal coordinates
    local radiusMagnitude = self.parameter / (1 + e * cosTrueAnomaly)
    local velocityMagnitude = self.parentBody.mu / h

    local rx = radiusMagnitude * cosTrueAnomaly
    local ry = radiusMagnitude * sinTrueAnomaly

    local vx = velocityMagnitude * -sinTrueAnomaly
    local vy = velocityMagnitude * (e + cosTrueAnomaly)

    return rx*m11 + ry*m12,
           rx*m21 + ry*m22,
           rx*m31 + ry*m32,
           vx*m11 + vy*m12,
           vx*m21 + vy*m22,
           vx*m31 + vy*m32

end

--[[
    Calculates the true anomaly where the orbit crosses
    the given radius.

    @param radius (number) The radius for which to solve for
    its true anomaly intersection point.

    @returns (number?) The true anomaly where the orbit crosses the given
    radius, or nil if the orbit never crosses the radius.

--]]
function Orbit:CalculateTrueAnomalyAtRadius(radius: number)
    
    local intersection = math.acos( (self.parameter - radius) / (radius * self.eccentricity) )
    
    -- If intersection is NaN (IEE754 states NaN ~= NaN always...)
    if intersection ~= intersection then
        return nil -- No value.
    end
    return intersection -- If not, grab the intersection.

end

--[[
    Transforms the given coordinates in the perifocal coordinates system
    to ECI coordinates.

    @param xValue (number)
    @param yValue (number)

    @returns (number, number, number) The coordinates in ECI space.
--]]
function Orbit:TransformPerifocalToECI(xValue: number, yValue: number)

    return xValue * self.m11 + yValue * self.m12,
           xValue * self.m21 + yValue * self.m22,
           xValue * self.m31 + yValue * self.m32
end

-------------------------------------------------------------------------------
-- GEOMETRY
-------------------------------------------------------------------------------

--[[
    Returns the normal vector of the orbital plane.
--]]
function Orbit:GetNormalECI()
    return self.m13, self.m23, self.m33
end

-------------------------------------------------------------------------------
-- TIME OF FLIGHT AND PREDICTION FUNCTIONS
-------------------------------------------------------------------------------

--[[
    Returns the time to escape for a hyperbolic orbit.
    If the orbit is an ellipse, returns infinity (because it will never escape)

    @param trueAnomaly (number) The current true anomaly of the spacecraft

    @returns (number) The time to escape.
--]]
function Orbit:GetTimeToEscape(trueAnomaly: number)
    if self.conic == "ELLIPSE" or self.parentBody.sphereOfInfluence == math.huge then
        return math.huge
    else
        
        -- Cache current 
        local rEscape = self.parentBody.sphereOfInfluence
        local e = self.eccentricity
        local p = self.parameter

        -- Calculate front term
        local a = self.semimajorAxis
        local frontTerm = math.sqrt( (-a*a*a) / self.parentBody.mu )

        -- Eccentric anomaly derivations
        local trueAnomalyOfEscape = math.acos((p-rEscape) / (rEscape*e))
        local eccentricAnomalyOfEscape = OrbitalMath.EccentricHyperbolicFromTrue(trueAnomalyOfEscape, e)
        local currentEccentricAnomaly = OrbitalMath.EccentricHyperbolicFromTrue(trueAnomaly, e)

        -- Actual calculation
        return frontTerm * ((e*math.sinh(eccentricAnomalyOfEscape) - eccentricAnomalyOfEscape) - (e*math.sinh(currentEccentricAnomaly) - currentEccentricAnomaly) )

    end
end

--[[
    Calculates the flight time from the current angle to the target angle.

    @param currentAngle (number) The starting true anomaly of the spacecraft.
    This can be in the range [-inf, inf] if elliptical.
    @param targetAngle (number) The ending true anomaly of the spacecraft.
    This can be in the range [-inf, inf] if elliptical.

    @returns (number) The time, in seconds, until the spacecraft reaches the given
    true anomaly. Returns math.huge if the spacecraft will never reach the given
    target angle.
--]]
function Orbit:GetTimeOfFlight(startTrueAnomaly: number, endTrueAnomaly: number)
    
    -- Gurantee start true anomaly is less than end true anomaly because
    -- the math only works if that is so.
    -- if startTrueAnomaly > endTrueAnomaly then
    --     local temp = startTrueAnomaly
    --     startTrueAnomaly = endTrueAnomaly
    --     endTrueAnomaly = temp
    -- end
    
    -- Cache values
    local e = self.eccentricity
    
    -- Elliptic vs Hyperbolic Case
    if self.conic == "ELLIPSE" then

        -- Calculate front term
        local a = self.semimajorAxis
        local frontTerm = math.sqrt( (a*a*a) / self.parentBody.mu )

        local startEccentricAnomaly = OrbitalMath.EccentricFromTrue(startTrueAnomaly, e)
        local endEccentricAnomaly = OrbitalMath.EccentricFromTrue(endTrueAnomaly, e)

        local startMean = OrbitalMath.MeanFromEccentric(startEccentricAnomaly, e)
        local endMean = OrbitalMath.MeanFromEccentric(endEccentricAnomaly, e)

        -- If we pass through periapsis between revolutions, be sure to position end AFTER start.
        if startMean > endMean then
            endMean = endMean + TAU
        end

        return frontTerm * (endMean - startMean)

    else -- Use hyperbolic
       
        -- Calculate front term
        local a = self.semimajorAxis
        local frontTerm = math.sqrt( (-a*a*a) / self.parentBody.mu )

        local startHyperbolicEccentricAnomaly = OrbitalMath.EccentricHyperbolicFromTrue(startTrueAnomaly, e)
        local endHyperbolicEccentricAnomaly = OrbitalMath.EccentricHyperbolicFromTrue(endTrueAnomaly, e)

        return frontTerm * ((e*math.sinh(endHyperbolicEccentricAnomaly) - endHyperbolicEccentricAnomaly) - (e*math.sinh(startHyperbolicEccentricAnomaly) - startHyperbolicEccentricAnomaly) )

    end

end

--[[
    Uses the Universal Formulation to calculate a future position of the spacecraft
    along an orbit.

    @param currenTime (number) The time, in seconds. This function calculates the internal deltaTime
    based on this orbit's epoch.
    @param tolerance (number) The desired accuracy for the prediction. Use a value like 0.000008 km.

    @returns (number) The true anomaly of the spacecraft at currentTime.
--]]
function Orbit:UniversalPrediction(currentTime: number, tolerance: number)
    
    -- Cache important values and functions
    local mu = self.parentBody.mu
    local alpha = self.alpha
    local conicType = self.conic
    local e = self.eccentricity

    -- Derive other important values
    local sqrtMu = math.sqrt(mu)
    local r0 = self.radiusEpoch
    local r0vr0 = r0 * self.velocityRadialEpoch
    local deltaTime = currentTime - self.epoch

    -- NEWTONS METHOD TO FIND UNIVERSAL VARIABLE X
    local currentX = sqrtMu * math.abs(alpha) * deltaTime -- x0 first guess
    local currentZ = alpha * currentX*currentX -- z = ax^2
    --local iterations = 0

    while true do
        
        --iterations = iterations + 1

        local fX_i = ((r0vr0 / sqrtMu) * currentX * currentX * StumpffC(currentZ)) + ((1 - alpha*r0)*currentX*currentX*currentX*StumpffS(currentZ)) + (r0*currentX) - (sqrtMu*deltaTime)
        local fXPrime_i = ((r0vr0 / sqrtMu) * currentX * (1 - currentZ*StumpffS(currentZ))) + ((1 - alpha*r0) * currentX * currentX * StumpffC(currentZ)) + r0

        local ratio_i = fX_i / fXPrime_i
        if math.abs(ratio_i) > tolerance then
            currentX = currentX - ratio_i
            currentZ = alpha * currentX*currentX -- z = ax^2
        else
            break
        end

    end

    -- Universal X found? Now calculate the new true anomaly
    if conicType == "ELLIPSE" then
        local eccentricAnomalyAtEpoch = OrbitalMath.EccentricFromTrue(self.trueAnomalyAtEpoch, e)
        local eccentricAnomalyAtTime = (currentX / math.sqrt(self.semimajorAxis)) + eccentricAnomalyAtEpoch
        return OrbitalMath.TrueFromEccentric(eccentricAnomalyAtTime, e)
    else
        local hyperbolicEccentricAnomalyAtEpoch = OrbitalMath.EccentricHyperbolicFromTrue(self.trueAnomalyAtEpoch, e)
        local hyperbolicEccentricAnomalyAtTime = (currentX / math.sqrt(-self.semimajorAxis)) + hyperbolicEccentricAnomalyAtEpoch
        return OrbitalMath.TrueFromEccentricHyperbolic(hyperbolicEccentricAnomalyAtTime, e)
    end

    error("Conic unsupported.")

end

-------------------------------------------------------------------------------
-- SOI CHANGE CALCULATION
-------------------------------------------------------------------------------

--[[
    For the time interval [startTime, endTime], calculates the first time this 
    orbit crosses within the given distance of otherOrbit. Returns nil if the
    orbits do not get within the given distance.

    @param otherOrbit (Orbit) The orbit to check against.
    @param distance (number)  The minimum distance separation to evaluate.
    @param startTime (number) The start time (after epoch)
    @param endTime (number) The end time (after epoch)

    @returns (number) The time the two orbits first get within the distance.

    @remarks This algorithm is fairly slow. For elliptical orbit pairs, consider
    implementing Hoots et al. 1984 at some point.
--]]
function Orbit:CrossesWithinDistance(otherOrbit: table, distance: number, startTime: number, endTime: number)

    -- Using sqr object separation, so let's square our distance
    --distance = distance*distance

    -- Walk the graph with MVT
    local sampleIncrement = (endTime - startTime) / CROSSES_WITHIN_DISTANCE_SAMPLES 
    local previousSample = 
        CalculateObjectSeparation(self, otherOrbit, startTime + sampleIncrement, CROSSES_WITHIN_DISTANCE_FUNCTION_TOLERANCE) - distance
    
    local startInterval = nil -- We are searching for a start and end interval to run secant method over.
    local endInterval = nil

    for i = startTime + sampleIncrement + sampleIncrement, endTime, sampleIncrement do

        -- If we find a root, exit immediately and run numeric algorithm
        local currentSample = 
            CalculateObjectSeparation(self, otherOrbit, i, CROSSES_WITHIN_DISTANCE_FUNCTION_TOLERANCE) - distance

        if math.sign(currentSample) ~= math.sign(previousSample) then
            
            startInterval = i - sampleIncrement
            endInterval = i

            break

        end

        previousSample = currentSample

    end

    -- If we came home empty-handed, exit
    if startInterval == nil then
        return nil
    end

    -- SECANT FOR ROOT
    local intermediateValue = nil

    for i = 1, CROSSES_WITHIN_MAX_ITERATIONS do
        
        local sqrDistStartInterval = 
            CalculateObjectSeparation(self, otherOrbit, startInterval, CROSSES_WITHIN_DISTANCE_FUNCTION_TOLERANCE) - distance
        local sqrDistEndInterval = 
            CalculateObjectSeparation(self, otherOrbit, endInterval, CROSSES_WITHIN_DISTANCE_FUNCTION_TOLERANCE) - distance

        intermediateValue = (startInterval*sqrDistEndInterval - endInterval*sqrDistStartInterval) / (sqrDistEndInterval - sqrDistStartInterval)

        -- Check if we can accept value as answer.
        if math.abs(startInterval - endInterval) <  CROSSES_WITHIN_DISTANCE_TOLERANCE then
            break
        end

        -- If not, adjust interval
        startInterval = endInterval
        endInterval = intermediateValue

    end

    return intermediateValue

end

-------------------------------------------------------------------------------
-- RENDERING
-------------------------------------------------------------------------------

--[[
    Given a start and end true anomaly, calculates the true anomaly of the
    tangent line along the conic that is parallel to the chord.

    @param startTrueAnomaly (number) The start of the arc
    @param endTrueAnomaly (number) The end of the arc

    @returns (number) the true anomaly of the tangent line along the
    conic that is parallel to the chord.

    @remarks
    Assumptions - startTrueAnomaly < endTrueAnomaly and
    |startTrueAnomaly - endTrueAnomaly| < pi.
--]]
function Orbit:ChordTangentAnomaly(startTrueAnomaly: number, endTrueAnomaly: number)

    -- Localize values
    local e = self.eccentricity
    local a = self.semimajorAxis
    local p = self.parameter

    -- Calculate chord vector
    local startPosX, startPosY = self:GetPositionPerifocal(startTrueAnomaly)
    local endPosX, endPosY = self:GetPositionPerifocal(endTrueAnomaly)

    local chordVectorX = endPosX - startPosX
    local chordVectorY = endPosY - startPosY
    
    -- Calculate whether positive or negative function should be used
    local _, midpointY = self:GetPositionPerifocal((startTrueAnomaly + endTrueAnomaly) / 2)
    local shouldUsePositiveFunction = midpointY > 0

    -- CASE: ELLIPSE
    -- Use closed-form solutions to derivatives to easily calculate
    -- the tangent point.
    if e < 1 then

        -- Edge case: chordVectorX == 0 means the chord is vertical and derivative is
        -- undefined. There is only one answer in this case.
        if chordVectorX == 0 then
            -- Get true anomaly of semiminor axis
            local semiMinorAxisTrueAnom = self:CalculateTrueAnomalyAtRadius(math.sqrt(p*a))
            -- Select quadrant based on start range
            local startTrueAnomalyNorm = startTrueAnomaly % TAU
            if startTrueAnomalyNorm > semiMinorAxisTrueAnom and startTrueAnomaly < TAU then
                return math.pi
            else
                return 0
            end
        end

        -- Calculate derivative and solve
        -- Yes, this code could be cleaned up, but it runs fine and im lazy
        local chordDerivative = chordVectorY / chordVectorX
        local xPos = 0
        local yPos = 0

        local a2 = a*a
        local b = math.sqrt(p*a)
        local b2 = b*b
        local c = math.sqrt(a2-b2)
        local a4 = a2*a2
        local a6 = a4*a2
        local d2 = chordDerivative*chordDerivative
        local d4 = d2*d2
        local cxSum = 0

        if shouldUsePositiveFunction then
            
            if chordDerivative > 0 then
                xPos = (-a2*c*d2 - math.sqrt(a6*d4 + a4*b2*d2) + b2*(-c)) / (a2*d2 + b2)
            else
                xPos = (-a2*c*d2 + math.sqrt(a6*d4 + a4*b2*d2) + b2*(-c)) / (a2*d2 + b2)
            end

            cxSum = c + xPos
            yPos = math.sqrt(b2*(1 - ((cxSum*cxSum)/a2) ))
        else
            if chordDerivative > 0 then
                xPos = (-a2*c*d2 + math.sqrt(a6*d4 + a4*b2*d2) + b2*(-c)) / (a2*d2 + b2)
            else
                xPos = (-a2*c*d2 - math.sqrt(a6*d4 + a4*b2*d2) + b2*(-c)) / (a2*d2 + b2)
            end

            cxSum = c + xPos
            yPos = -math.sqrt(b2*(1 - ((cxSum*cxSum)/a2) ))
        end
        
        return math.atan2(yPos, xPos)

    else -- CASE: HYPERBOLA - Use Illinois Regula Falsi Method
        
        -- Cache normalized curves and constants
        local velocityMagnitude = self.parentBody.mu / self.specificAngularMomentum

        -- Select best root-finding function
        local f = nil
        local chordNorm = 0
        if math.abs(chordVectorX) < math.abs(chordVectorY) then
            f = ChordDerivativeFunctionX
            chordNorm = chordVectorX / math.sqrt(chordVectorX*chordVectorX + chordVectorY*chordVectorY)
        else
            f = ChordDerivativeFunctionY
            chordNorm = chordVectorY / math.sqrt(chordVectorX*chordVectorX + chordVectorY*chordVectorY)
        end

        local c = 0
        local fc = 0
        local side = 0

        local fStartTrueAnomaly = f(velocityMagnitude, e, startTrueAnomaly, chordNorm)
        local fEndTrueAnomaly = f(velocityMagnitude, e, endTrueAnomaly, chordNorm)

        for i = 1, MAX_ITERATIONS_CHORD do

            c = (fStartTrueAnomaly * endTrueAnomaly - fEndTrueAnomaly * startTrueAnomaly) / (fStartTrueAnomaly - fEndTrueAnomaly)

            -- Break if accurate enough
            if math.abs(endTrueAnomaly - startTrueAnomaly) < TOLERANCE_CHORD * math.abs(endTrueAnomaly + startTrueAnomaly) then
                break
            end

            fc = f(velocityMagnitude, e, c, chordNorm)

            if fc * fEndTrueAnomaly > 0 then -- CASE: Same sign
                endTrueAnomaly = c
                fEndTrueAnomaly = fc
                if side == -1 then
                    fStartTrueAnomaly = fStartTrueAnomaly * 0.5
                end
                side = -1
            elseif fStartTrueAnomaly * fc > 0 then -- CASE: Different Sign
                startTrueAnomaly = c
                fStartTrueAnomaly = fc
                if side == 1 then
                    fEndTrueAnomaly = fEndTrueAnomaly * 0.5
                end
                side = 1
            else
                break
            end

        end

        return c

    end
end

--[[
    Calculates the control points for representing an arc of this orbit
    using a cubic bezier curve. Returns values in Perifocal coordinate
    system.

    @param startTrueAnomaly (number) The start of the arc
    @param endTrueAnomaly (number) The end of the arc

    @remarks
    Assumptions - startTrueAnomaly < endTrueAnomaly and
    |startTrueAnomaly - endTrueAnomaly| < pi.
--]]
function Orbit:CubicBezierApproximationControlPoints(startTrueAnomaly: number, endTrueAnomaly: number)

    -- Calculate start and end points
    local startPosX, startPosY, startDirX, startDirY = self:GetPositionPerifocal(startTrueAnomaly)
    local endPosX, endPosY, endDirX, endDirY = self:GetPositionPerifocal(endTrueAnomaly)

    -- Calculate chord tangent position and direction
    local chordTangentTrueAnomaly = self:ChordTangentAnomaly(startTrueAnomaly, endTrueAnomaly)
    local chordPosX, chordPosY, chordDirX, chordDirY = self:GetPositionPerifocal(chordTangentTrueAnomaly)

    -- Calculate Timmer control points
    local rx, ry = DoubleMath2D.LineIntersection(
        startPosX, startPosY, startDirX, startDirY,
        chordPosX, chordPosY, chordDirX, chordDirY
    )
    local sx, sy = DoubleMath2D.LineIntersection(
        endPosX, endPosY, endDirX, endDirY,
        chordPosX, chordPosY, chordDirX, chordDirY
    )

    -- Calculate Timmer control point distances
    local startPosToRX = rx - startPosX
    local startPosToRY = ry - startPosY
    local startTimmerDistance = (4/3) * math.sqrt(startPosToRX*startPosToRX + startPosToRY*startPosToRY)
    local sToEndPosX = endPosX - sx
    local sToEndPosY = endPosY - sy
    local endTimmerDistance = (4/3) * math.sqrt(sToEndPosX*sToEndPosX + sToEndPosY*sToEndPosY)

    -- Resolve control points
    return startPosX, startPosY, startDirX, startDirY, startTimmerDistance, 
           endPosX, endPosY, endDirX, endDirY, endTimmerDistance
    
end

-------------------------------------------------------------------------------

return Orbit