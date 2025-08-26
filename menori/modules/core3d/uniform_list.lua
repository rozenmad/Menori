--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2025
-------------------------------------------------------------------------------
]]

--[[--
A class that stores a list of Uniform variables and implements their sending to the shader.
]]
-- @classmod UniformList

local modules = (...):match('(.*%menori.modules.)')
local class = require (modules .. 'libs.class')

local UniformList = class('UniformList')

local uniform_types = {
	[1] = 'any', [2] = 'color', [3] = 'matrix', [4] = 'vector',
}

local _temp = {}

local function locate_uniform(list, name, constant, type)
	local uniform = list[name]
	if uniform == nil then
		uniform = { type = type, constant = constant }
		list[name] = uniform
	elseif constant then
		error(string.format('set_uniform: attempt to assign a new value to a constant - "%s" type - "type"', name, uniform_types[type]))
	end
	return uniform
end

----
-- The public constructor.
function UniformList:init()
	self.list = {}
end

----
-- Set one or more any type values into uniform list.
-- @tparam string name
-- @param ... See shader:send(name, ...)
function UniformList:set(name, ...)
	local uniform = locate_uniform(self.list, name, false, 1)
	uniform.value = {...}
end

----
-- Set one or more color values into uniform list.
-- @tparam string name
-- @param ... See shader:sendColor(name, ...)
function UniformList:set_color(name, ...)
	local uniform = locate_uniform(self.list, name, false, 2)
	uniform.value = {...}
end

----
-- Set matrix object into uniform list.
-- @tparam string name
-- @tparam mat4 object Matrix of the menori.ml
function UniformList:set_matrix(name, object)
	local uniform = locate_uniform(self.list, name, false, 3)
	uniform.value = object
end

----
-- Set vector object into uniform list.
-- @tparam string name
-- @tparam vec2|vec3|vec4 object Vector of the menori.ml.
function UniformList:set_vector(name, object)
	local uniform = locate_uniform(self.list, name, false, 4)
	uniform.value = object
end

----
-- Get Uniform variable from list.
-- @tparam string name
-- @treturn table {[constant]=boolean,[type]=number,[value]=table}
function UniformList:get(name)
	return self.list[name]
end

---
-- Remove Uniform variable from list.
-- @tparam string name
function UniformList:remove(name)
	self.list[name] = nil
end

----
-- Send all Uniform values from the list to the Shader.
-- @param shader [LOVE Shader](https://love2d.org/wiki/Shader)
-- @param[opt=''] prefix_s A string to be added before each Uniform name.
function UniformList:send_to(shader, prefix_s)
	for k, v in pairs(self.list) do
		local name = prefix_s and (prefix_s .. k) or k
		if shader:hasUniform(name) then
			local type = v.type
			if
			type == 1 then
				shader:send(name, unpack(v.value))
			elseif
			type == 2 then
				shader:sendColor(name, unpack(v.value))
			elseif
			type == 3 then
				shader:send(name, v.value.data)
			elseif
			type == 4 then
				_temp[1] = v.value.x or v.value[1]
				_temp[2] = v.value.y or v.value[2]
				_temp[3] = v.value.z or v.value[3]
				_temp[4] = v.value.w or v.value[4]
				shader:send(name, _temp)
			end
		end
	end
end

return UniformList