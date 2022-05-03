local bound3 = {}
local bound3_mt = {}
bound3_mt.__index = bound3_mt

local modules = (...):gsub('%.[^%.]+$', '') .. "."
local vec3    = require(modules .. "vec3")

local function new(min, max)
      return setmetatable({
            min = min and min:clone() or vec3(0),
            max = max and max:clone() or vec3(0),
      }, bound3_mt)
end

function bound3.with_size(min, size)
      return new(min, min + size)
end

function bound3_mt:scale(v)
      self.min:scale(v)
      self.max:scale(v)
end

function bound3_mt:move(x, y, z)
      self.min:set(self.min.x + x, self.min.y + y, self.min.z + z)
      self.max:set(self.max.x + x, self.max.y + y, self.max.z + z)
end

-- contain by XZ axis
function bound3_mt:contain(b)
      local a = self
      local ax1 = a.min.x
      local ax2 = a.min.x + a.max.x
      local ay1 = a.min.z
      local ay2 = a.min.z + a.max.z

      local bx1 = b.min.x
      local bx2 = b.min.x + b.max.x
      local by1 = b.min.z
      local by2 = b.min.z + b.max.z

      if ay1 <= by1 and ay2 >= by2 and ax1 <= bx1 and ax2 >= bx2 then
            return true
       end
end

function bound3_mt:center()
      return (self.min + self.max) / 2
end

function bound3_mt:size()
      return self.max - self.min
end

function bound3_mt:clone()
      return new(self.min, self.max)
end

function bound3_mt.__tostring(self)
      return ("%s, %s"):format(tostring(self.min), tostring(self.max))
end

return setmetatable(bound3, { __call = function(_, min, max)
	return new(min, max)
end })