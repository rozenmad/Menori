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

local uniform_types = {
	'any', 'color', 'vector', 'matrix',
}

local function locate_uniform(list, name, constant, type)
	local uniform = list[name]
	if uniform == nil then
		uniform = { type = type, constant = constant, delete = false }
		list[name] = uniform
	elseif constant then
		error(string.format('set_uniform: attempt to assign a new value to a constant - "%s" type - "type"', name, type))
	end
	return uniform
end

--- init.
function UniformList:init()
	self.list = {}
end

--- Set one or more values to a uniform variable into list.
-- @tparam string name
-- @param ... See shader:send(name, ...)
function UniformList:set(name, ...)
	local uniform = locate_uniform(self.list, name, false, 1)
	uniform.value = {...}
end

--- Set one or more color values to uniform variable into list.
-- @tparam string name
-- @param ... See shader:sendColor(name, ...)
function UniformList:set_color(name, ...)
	local uniform = locate_uniform(self.list, name, false, 2)
	uniform.value = {...}
end

--- Set menori.ml.matrix object to uniform variable into list.
-- @tparam string name
-- @param object ml.mat4
function UniformList:set_matrix(name, object)
	local uniform = locate_uniform(self.list, name, false, 3)
	uniform.value = object
end

--- Set menori.ml.vector object to uniform variable into list.
-- @tparam string name
-- @param object ml.vec
function UniformList:set_vector(name, object)
	local uniform = locate_uniform(self.list, name, false, 4)
	uniform.value = object
end

--- Remove uniform variable from list.
-- @tparam string name
-- @param object ml.vec
function UniformList:remove(name)
	self.list[name] = nil
end

--- Sends all uniform values from the list to the shader.
function UniformList:send_to(shader, concat_str)
	concat_str = concat_str or ''
	for k, v in pairs(self.list) do
		local name = concat_str .. k
		if shader:hasUniform(name) then
			if
			v.type == 1 then
				shader:send(name, unpack(v.value))
			elseif
			v.type == 2 then
				shader:sendColor(name, unpack(v.value))
			elseif
			v.type == 3 then
				shader:send(name, v.value)
			elseif
			v.type == 4 then
				shader:send(name, {v.value:unpack()})
			--[[elseif
			v.type == 5 then
				local t = {}
				for i = 1, #v.value do
					table.insert(t, {v.value[i]:unpack()})
				end
				shader:send(name, unpack(t))]]
			end
		end
	end
end

return UniformList