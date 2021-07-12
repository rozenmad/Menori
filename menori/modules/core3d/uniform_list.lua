--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

--[[--
Description.
]]
-- @module menori.UniformList

local modules = (...):match('(.*%menori.modules.)')
local class = require (modules .. 'libs.class')

local UniformList = class('UniformList')

--- init.
function UniformList:init()
	self.list = {}
end

--- Set one or more values to a uniform variable into list.
-- @tparam string name
-- @param ... See shader:send(name, ...)
function UniformList:set(name, ...)
	self.list[name] = {...}
end

--- Set one or more color values to uniform variable into list.
-- @tparam string name
-- @param ... See shader:sendColor(name, ...)
function UniformList:set_color(name, ...)
	self.list[name] = {
		type = 'color', object = {...}
	}
end

--- Set ml matrix object to uniform variable into list.
-- @tparam string name
-- @param object ml.mat4
function UniformList:set_matrix(name, object)
	self.list[name] = {
		type = 'matrix', object = object,
	}
end

--- Set ml vector object to uniform variable into list.
-- @tparam string name
-- @param object ml.vec
function UniformList:set_vector(name, object)
	self.list[name] = {
		type = 'vector', object = object,
	}
end

--- Remove uniform variable from list.
-- @tparam string name
-- @param object ml.vec
function UniformList:remove(name)
	self.list[name].used = nil
end

--- Sends all uniform values from the list to the shader.
function UniformList:send_to(shader, concat_str)
	concat_str = concat_str or ''
	for k, v in pairs(self.list) do
		local name = concat_str .. k
		if shader:hasUniform(name) then
			if v.type then
				if v.type == 'matrix' then
					shader:send(name, v.object.data)
				elseif v.type == 'vector' then
					shader:send(name, {v.object:unpack()})
				elseif v.type == 'color' then
					shader:sendColor(name, unpack(v.object))
				end
			else
				shader:send(name, unpack(v))
			end
		end
	end
end

return UniformList