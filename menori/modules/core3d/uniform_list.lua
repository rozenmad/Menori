--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2022
-------------------------------------------------------------------------------
]]

--[[--
A class that stores a list of Uniform variables and implements their sending to the shader.
]]
--- @classmod UniformList

local modules = (...):match('(.*%menori.modules.)')
local class = require (modules .. 'libs.class')

local UniformList = class('UniformList')

local uniform_types = {
	[1] = 'any', [2] = 'color', [3] = 'matrix', [4] = 'vector',
}

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

--- The public constructor.
function UniformList:init()
	self.list = {}
end

--- Set one or more any type values into uniform list.
-- @tparam string name
-- @param ... See shader:send(name, ...)
function UniformList:set(name, ...)
	local uniform = locate_uniform(self.list, name, false, 1)
	uniform.value = {...}
end

--- Set one or more color values into uniform list.
-- @tparam string name
-- @param ... See shader:sendColor(name, ...)
function UniformList:set_color(name, ...)
	local uniform = locate_uniform(self.list, name, false, 2)
	uniform.value = {...}
end

--- Set matrix object into uniform list.
-- @tparam string name
-- @tparam ml.mat4 object Matrix of the menori.ml
function UniformList:set_matrix(name, object)
	local uniform = locate_uniform(self.list, name, false, 3)
	uniform.value = object
end

--- Set vector object into uniform list.
-- @tparam string name
-- @tparam ml.vec object Vector of the menori.ml.
function UniformList:set_vector(name, object)
	local uniform = locate_uniform(self.list, name, false, 4)
	uniform.value = object
end

--- Get Uniform variable from list.
-- @tparam string name
-- @treturn table {[constant]=boolean,[type]=number,[value]=table}
function UniformList:get(name)
	return self.list[name]
end

--- Remove Uniform variable from list.
-- @tparam string name
function UniformList:remove(name)
	self.list[name] = nil
end

--- Send all Uniform values from the list to the Shader.
-- @param shader [LOVE Shader](https://love2d.org/wiki/Shader)
-- @param[opt=''] concat_str A string to be added before each Uniform name.
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
				shader:send(name, v.value.data)
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