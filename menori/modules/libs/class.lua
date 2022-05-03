--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

local function implement(self, ...)
	for _, class in pairs({...}) do
		for k, v in pairs(class) do
			if self[k] == nil and type(v) == "function" then
				self[k] = v
			end
		end
	end
end

local new_class
new_class = function(class_name, base_class)
	local __mt = {
		__tostring = function(self)
			return string.format('%p instance of "%s"', self, self.class_name)
		end,
	}
	local class = {
            super = base_class,
            class_name = class_name,
            extend = function (self, _class_name)
                  return new_class(_class_name, self)
            end,
      }

	if base_class then
		for k, metamethod in pairs(base_class) do
			if k:find("__") == 1 and type(metamethod) == "function" then
				__mt[k] = metamethod
			end
		end
	end
	__mt.__index = class
      return setmetatable(class, {
		__index = base_class,
		__call = function (self, ...)
			local t = setmetatable({}, __mt)
			if self.init then self.init(t, ...) end
			return t
		end,
	})
end

return new_class