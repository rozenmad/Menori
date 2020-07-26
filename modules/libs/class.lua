--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

local new_class

local function new(self, ...)
	local t = setmetatable({}, self)
	if self.constructor then self.constructor(t, ...) end
	return t
end

local function extend(self, name)
	assert(type(self) == 'table', 'use ":" syntax before the extend.')
	return new_class(name, self)
end


local function implement(self, ...)
	for _, class in pairs({...}) do
	  	for k, v in pairs(class) do
			if self[k] == nil and type(v) == "function" then
		  		self[k] = v
			end
	  	end
	end
end

new_class = function(name, base_class)
	local t = {
		new 		= new,
		extend 		= extend,
		implement 	= implement,
		super 		= base_class,
		class_name 	= name or 'unnamed class'
	}
	t.__index = t
	t.__tostring = function(self)
		return string.format('%p instance of: "%s"', self, self.class_name)
	end

	return setmetatable(t, {__index = base_class, __call = new})
end

return new_class