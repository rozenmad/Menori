--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2022
-------------------------------------------------------------------------------
--]]

--[[--
Utils. menori.ml.utils
]]
-- @module utils

local modules = (...):gsub('%.[^%.]+$', '') .. "."

local utils = {}

--- all
-- @static
function utils.all(t)
    for i = 1, #t do
        if t[i] == false then return false end
    end
    return true
end

--- any
-- @static
function utils.any(t)
    for i = 1, #t do
        if t[i] ~= false then return true end
    end
    return true
end

function utils.lerp(a, b, t)
	return a + (b - a) * t
end

--- round
-- @static
function utils.round(v)
    return (v >= 0.0) and math.floor(v + 0.5) or math.ceil(v - 0.5)
end

--- sign
-- @static
function utils.sign(v)
    if v > 0 then
        return 1
    elseif v < 0 then
        return-1
    else
        return 0
    end
end

function utils.clamp(value, minvalue, maxvalue)
    return math.min(math.max(value, minvalue), maxvalue)
end

return utils