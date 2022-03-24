
--[[
    OrbitalMechanics/CelestialBody.lua

    Represents a CelestialBody with a high mass.

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

local G = require(script.Parent.PhysicsConstants).G

local UNIVERSAL_PREDICTION_TOLERANCE = 0.00001

local CelestialBody = {}
CelestialBody.__index = CelestialBody

--[[
    Constructor

    @param mass (number) The mass of the body in kg.
    @param radius (number) The radius of the body in km.
--]]
function CelestialBody.new(name: string, mass: number, radius: number)
    local self = {
        -- IMMUTABLE INFORMATION
        -- Identity
        name = name,

        -- Physical Properties and Constants
        mass = mass, -- in kg
        mu = mass * G, -- in km^3/s^2
        radius = radius, -- in km

        -- Orbital Information
        sphereOfInfluence = math.huge, -- SoI of body. If no parent, it's infinity.
        parentBody = nil,  -- If nil, center of solar system.
                           -- if not nil, this body orbits the parent.
        orbit = nil,       -- Orbital information if parent defined.
        childBodies = {},   -- Collection of child bodies, if present.

    }

    setmetatable(self, CelestialBody)

    return self

end


--[[
    Sets this celestial body's parent as another celestial body.

    @param otherCelestialBody (CelestialBody) The new parent body.
    Set to nil if this celestial should be the center of the universe.
    @param orbit (Orbit) The orbit that defines motion about the 
    parent body. Set to nil if this celestial should be the center 
    of the universe.

    @remarks The CelestialBody graph must be a tree.
--]]
function CelestialBody:SetParent(otherCelestialBody, orbit)

    -- Remove from previous parent, if required
    if self.parentBody ~= nil then
        self.parentBody.childBodies[self] = nil -- Remove from set.
    end

    -- Set values
    self.parentBody = otherCelestialBody
    self.orbit = orbit

    -- Calculate new SoI
    if otherCelestialBody ~= nil and self.orbit ~= nil then

        -- Validate orbit is valid for this object
        assert(self.orbit.parentBody == self.parentBody, "Orbit's parentBody must match CelestialBody's parentBody")

        -- Calculate SoI
        self.sphereOfInfluence = self.orbit.semimajorAxis * math.pow((self.mass / self.parentBody.mass), .4)

        -- Add to parent celestial's set of child celestials
        otherCelestialBody.childBodies[self] = true

    else
        self.sphereOfInfluence = math.huge
    end
end


return CelestialBody