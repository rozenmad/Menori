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

--- all true
-- @static
function utils.all_true(t)
    for i = 1, #t do
        if t[i] == false then return false end
    end
    return true
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

return utils