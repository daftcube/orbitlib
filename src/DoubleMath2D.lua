--[[
    DoubleMath2D.lua

    Contains a kitchen sink of 2D math functions.

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

--[[
    Calculates the vertex of a line-line intersection.

    @param lineAPosX (number)
    @param lineAPosY (number)
    @param lineAVectorX (number)
    @param lineAVectorY (number)
    @param lineBPosX (number)
    @param lineBPosY (number)
    @param lineBVectorX (number)
    @param lineBVectorY (number)

    @returns (number, number) The X and Y coordinate of the intersection
        between the two given lines. Will be NaN if parallel or coinciding.
    
    @attribution Shout out to our math consultant DarkFireDrago for coming
    up with this algorithm.

--]]
function module.LineIntersection(
    lineAPosX: number,
    lineAPosY: number,
    lineAVectorX: number,
    lineAVectorY: number,
    lineBPosX: number,
    lineBPosY: number,
    lineBVectorX: number,
    lineBVectorY: number
)

    local b1 = lineBPosX - lineAPosX
    local b2 = lineBPosY - lineAPosY

    local t1 = -((-b2*lineBVectorX + b1*lineBVectorY)/(lineAVectorY*lineBVectorX - lineAVectorX*lineBVectorY))

    return lineAPosX + t1*lineAVectorX, lineAPosY + t1*lineAVectorY

end

return module