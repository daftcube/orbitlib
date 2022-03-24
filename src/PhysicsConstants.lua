--[[
    OrbitalMechanics/PhysicsConstants.lua

    Contains useful physical constants.

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

local module = {
    -- Universal Gravitational Constant, in units km^3 kg^-1 s^-2
    G = 6.67408 * 10^-20,

    -- Tau, defined as 2pi radianss
    tau = 6.28318530718,

    -- Epsilon, a tiny floating difference
    epsilon = 1e-6,

    -- One Gee = Acceleration due to Gravity on Earth ASL
    gee = 0.00980665 -- km/(s^2)
}

return module