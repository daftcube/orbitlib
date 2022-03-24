--[[
    OrbitalMechanics/OrbitalMath.lua

    Orbital Mechanics unfolds over truly astronomical scales. Such scales
    cannot be accurately represented with 32-bit floating point numbers,
    so we define our own vector functions that use tuples of 64-bit raw
    Lua numbers.

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

local module = {}

local PhysicsConstants = require(script.Parent.PhysicsConstants)
local TAU = PhysicsConstants.tau

local e_const = 2.71828182846
local MAX_ITERATIONS_MEAN = 100

-------------------------------------------------------------------------------
-- 64 BIT VECTOR MATHEMATICS
-------------------------------------------------------------------------------

--[[
    Calculates the cross product of vectors a and b.

    @param a1 (number) The x coordinate of vector a.
    @param a2 (number) The y coordinate of vector a.
    @param a3 (number) The z coordinate of vector a.
    @param b1 (number) The x coordinate of vector b.
    @param b2 (number) The y coordinate of vector b.
    @param b3 (number) The z coordinate of vector b.

    @returns (number, number, number) The cross product between a and b.
--]]
function module.CrossProduct(a1: number, a2: number, a3: number, b1: number, b2: number, b3: number)
    return a2*b3 - a3*b2, a3*b1 - a1*b3, a1*b2 - a2*b1
end

--[[
    Calculates the magnitude of vector a.

    @param a1 (number) The x coordinate of vector a.
    @param a2 (number) The y coordinate of vector a.
    @param a3 (number) The z coordinate of vector a.

    @returns (number) The magnitude of vector a.
--]]
function module.Magnitude(a1: number, a2: number, a3: number)
    return math.sqrt(a1*a1 + a2*a2 + a3*a3)
end

--[[
    Calculates the squared magnitude of vector a without
    making a square root operation.

    @param a1 (number) The x coordinate of vector a.
    @param a2 (number) The y coordinate of vector a.
    @param a3 (number) The z coordinate of vector a.

    @returns (number) The squared magnitude of vector a.
--]]
function module.SqrMagnitude(a1: number, a2: number, a3: number)
    return a1*a1 + a2*a2 + a3*a3
end

--[[
    Calculates the dot product of vectors a and b.

    @param a1 (number) The x coordinate of vector a.
    @param a2 (number) The y coordinate of vector a.
    @param a3 (number) The z coordinate of vector a.
    @param b1 (number) The x coordinate of vector b.
    @param b2 (number) The y coordinate of vector b.
    @param b3 (number) The z coordinate of vector b.

    @returns (number) The dot product between a and b.
--]]
function module.DotProduct(a1: number, a2: number, a3: number, b1: number, b2: number, b3: number)
    return a1*b1 + a2*b2 + a3*b3
end

--[[
    Calculates the scalar product of scalar s and vector a.

    @param s (number) A scalar.
    @param a1 (number) The x coordinate of vector a.
    @param a2 (number) The y coordinate of vector a.
    @param a3 (number) The z coordinate of vector a.

    @returns (number, number, number) The cross product between a and b.
--]]
function module.VectorScalarMultiplication(s: number, a1: number, a2: number, a3: number)
    return s*a1, s*a2, s*a3
end

-------------------------------------------------------------------------------
-- HYPERBOLIC TRIGONOMETRIC FUNCTIONS
-------------------------------------------------------------------------------

--[[
    Calculates the hyperbolic tangent of x.

    @param x (number) The argument.

    @returns (number) The hyperbolic tangent of x.
]]
function module.Tanh(x: number)
    local eX = math.pow(e_const, x)
    local eMinusX = math.pow(e_const, -x)
    
    return (eX-eMinusX) / (eX + eMinusX)
end

--[[
    Calculates the inverse hyperbolic sine of x.

    @param x (number) The argument.

    @returns (number) The inverse hyperbolic sine of x.
]]
function module.Asinh(x: number)
    return math.log(x + math.sqrt(x*x + 1))
end

--[[
    Calculates the inverse hyperbolic cosine of x.

    @param x (number) The argument.

    @returns (number) The inverse hyperbolic cosine of x.
]]
function module.Acosh(x: number)
    return math.log(x + math.sqrt(x*x - 1))
end

--[[
    Calculates the inverse hyperbolic tangent of x.

    @param x (number) The argument.

    @returns (number) The inverse hyperbolic tangent of x.
]]
function module.Atanh(x: number)
    return 0.5 * math.log( (1+x) / (1-x) )
end

-------------------------------------------------------------------------------
-- ANOMALY CONVERSIONS FOR ELLIPTICAL ORBITS
-------------------------------------------------------------------------------

--[[
    Calculates Mean Anomaly from Eccentric Anomaly using a series derivation.
    THIS IS NOT ACCURATE. Consider using the Universal Formulation instead.

    @param M (number) The mean anomaly.
    @param e (eccentricity) The eccentricity of the orbit.

    @returns (number) The mean anomaly from the eccentric anomaly.

    @remarks
    This does not have high accuracy when e is close to 1; use the universal
    prediction instead.
--]]
function module.EccentricFromMean(M: number, e: number)

    local e2 = e*e
    local e3 = e2*e
    local e4 = e3*e
    local e5 = e4*e
    local e6 = e5*e    

    return ( (1/48)*e6 + 0.5*e2 - (1/6)*e4 )*math.sin(2*M) + 
           ((1/3)*e4 - (4/15)*e6)*math.sin(4*M) + 
           ((125/384)*e5)*math.sin(5*M) +
           ( (-1/8)*e3 + (1/192)*e5 + e)*math.sin(M) + 
           (27/80)*math.sin(6*M)*e6 + 
           ( (3/8)*e3 - (27/128)*e5 )*math.sin(3*M) +
           M

end

--[[
    Calculates the eccentric anomaly from the true anomaly.

    @param V (number) The True Anomaly.
    @param e (number) The eccentricity of the orbit.

    @returns (number) The Eccentric Anomaly from the True Anomaly
--]]
function module.EccentricFromTrue(V: number, e: number)
    return math.atan2(math.sqrt(1 - e*e) * math.sin(V), e + math.cos(V)) % TAU
end

--[[
    Calculates the mean anomaly from the eccentric anomaly.

    @param E (number) The Eccentric Anomaly.
    @param e (number) The eccentricity of the orbit.

    @returns (number) The Mean Anomaly from the Eccentric Anomaly

--]]
function module.MeanFromEccentric(E: number, e: number)
    return E - e*math.sin(E)
end

--[[
    Calculates the true anomaly from the eccentric anomaly.

    @param E (number) The Eccentric Anomaly.
    @param e (number) The eccentricity of the orbit.

    @returns (number) The true anomaly from the eccentric anomaly.
--]]
function module.TrueFromEccentric(E: number, e: number)
    return 2 * math.atan2( math.sqrt(1 + e) * math.sin( E / 2), math.sqrt(1 - e) * math.cos(E / 2) )
end

-------------------------------------------------------------------------------
-- ANOMALY CONVERSIONS FOR HYPERBOLIC ORBITS
-------------------------------------------------------------------------------

-- Cache hyperbolic trig functions
local tanh = module.Tanh
local atanh = module.Atanh

--[[
    Calculates Eccentric Anomaly from Hyperbolic Mean Anomaly using a series solution.

    @param M (number) The hyperbolic mean anomaly.
    @param e (eccentricity) The eccentricity of the orbit.

    @returns (number) The mean anomaly from the eccentric anomaly.

    @remarks I don't think this currently works. Just use the universal
    prediction method anyway.
    
--]]
function module.EccentricFromMeanHyperbolic(M: number, e: number)

    local e2 = e*e
    local e3 = e2*e
    local e4 = e3*e
    local e5 = e4*e
    local e6 = e5*e    

    return -1*(( (1/48)*e6 + 0.5*e2 - (1/6)*e4 )*math.sinh(2*M) + 
           ((1/3)*e4 - (4/15)*e6)*math.sinh(4*M) + 
           ((125/384)*e5)*math.sinh(5*M) +
           ( (-1/8)*e3 + (1/192)*e5 + e)*math.sinh(M) + 
           (27/80)*math.sinh(6*M)*e6 + 
           ( (3/8)*e3 - (27/128)*e5 )*math.sinh(3*M) +
           M)

end

--[[
    Calculates the hyperbolic mean anomaly from the eccentric anomaly.

    @param E (number) The Hyperbolic Mean Anomaly.
    @param e (number) The eccentricity of the orbit.

    @returns (number) The Hyperbolic Mean Anomaly from the Eccentric Anomaly
--]]
function module.MeanHyperbolicFromEccentric(E: number, e: number)
    return e*math.sinh(E) - E
end

--[[
    Calculates the hyperbolic eccentric anomaly from the true anomaly.

    @param V (number) The True Anomaly.
    @param e (number) The eccentricity of the orbit.

    @returns (number) The Hyperbolic Eccentric Anomaly from the True Anomaly
--]]
function module.EccentricHyperbolicFromTrue(V: number, e: number)
    return 2 * atanh( math.sqrt( (e - 1) / (e + 1) ) * math.tan(0.5 * V) )
end

--[[
    Calculates the true anomaly from the hyperbolic eccentric anomaly.

    @param V (number) The Hyperbolic Eccentric Anomaly.
    @param e (number) The eccentricity of the orbit.

    @returns (number) The Hyperbolic Eccentric Anomaly from the True Anomaly
--]]
function module.TrueFromEccentricHyperbolic(E: number, e: number)
    return 2 * math.atan( math.sqrt( (e + 1) / (e - 1) ) * math.tanh(0.5 * E) )
end

-------------------------------------------------------------------------------
-- PERIFOCAL->ECI MATRIX
-------------------------------------------------------------------------------

--[[
    From the three rotational orbital parameters, calculates the 3x3 matrix.

    @param i (number) The inclination, in radians
    @param O (number) The longitude of the ascending node, in radians
    @param o (number) The argument of the periapsis, in radians

    @returns (number, number, number, number, number, 
    number, number, number, number) The values of the 3x3 matrix.
--]]
function module.CalculatePerifocalToECIMatrix(i: number, O: number, o: number)
    
    local sinI = math.sin(i)
    local cosI = math.cos(i)
    local sinOmega = math.sin(O)
    local cosOmega = math.cos(O)
    local sinSmolOmega = math.sin(o)
    local cosSmolOmega = math.cos(o)

    return cosOmega*cosSmolOmega - sinOmega*sinSmolOmega*cosI, -cosOmega*sinSmolOmega - sinOmega*cosI*cosSmolOmega,  sinOmega*sinI,
           sinOmega*cosSmolOmega + cosOmega*cosI*sinSmolOmega, -sinOmega*sinSmolOmega + cosOmega*cosI*cosSmolOmega, -cosOmega*sinI,
           sinI*sinSmolOmega                                 , sinI*cosSmolOmega                                  , cosI
end

-------------------------------------------------------------------------------
-- UNIVERSAL PREDICTION FORMULATION
-------------------------------------------------------------------------------

-- TODO: Consider making optimized function given that
-- probability of parabolic orbit is 0.

--[[
    Calculates the Stumpff function S.

    @param z (number) The argument, usually alpha*x^2

    @returns (number) The value of S for the given z. 
--]]
function module.StumpffS(z: number)
    if z > 0 then -- Ellipse
        local sqrtZ = math.sqrt(z)
        return (sqrtZ - math.sin(sqrtZ)) / (sqrtZ * sqrtZ * sqrtZ)
    elseif z < 0 then -- Hyperbola
        local sqrtZ = math.sqrt(-z)
        return (math.sinh(sqrtZ) - sqrtZ) / (sqrtZ * sqrtZ * sqrtZ)
    else -- Parabola
        return 1/6
    end
end

--[[
    Calculates the Stumpff function C.

    @param z (number) The argument, usually alpha*x^2

    @returns (number) The value of C for the given z. 
--]]
function module.StumpffC(z: number)
    if z > 0 then -- Ellipse
        return (1 - math.cos(math.sqrt(z))) / z
    elseif z < 0 then -- Hyperbola 
        z = -z
        return (math.cosh(math.sqrt(z)) - 1) / z
    else -- Parabola
        return 0.5
    end
end

-------------------------------------------------------------------------------
-- DISTANCE FORMULAS
-------------------------------------------------------------------------------

--[[
    Calculates the squared separation between two objects on orbits.

    @param orbitA (Orbit) The first orbit.
    @param orbitB (Orbit) The other orbit.
    @param time (number) The time since epoch.
    @param tolerance (number) A epsilon value for the 
    accuracy of numeric approximations of orbital position.

    @returns (number) The squared separation between
--]]
function module.CalculateObjectSeparation(orbitA: table, orbitB: table, time: number, tolerance: number)

    local aTrueAnom = orbitA:UniversalPrediction(time, tolerance)
    local bTrueAnom = orbitB:UniversalPrediction(time, tolerance)
    local ax, ay, az = orbitA:GetPositionVelocityECI(aTrueAnom)
    local bx, by, bz = orbitB:GetPositionVelocityECI(bTrueAnom)

    local dx = ax - bx
    local dy = ay - by
    local dz = az - bz

    return math.sqrt(dx*dx + dy*dy + dz*dz)

end

-------------------------------------------------------------------------------

return module