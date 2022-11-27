--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2022
-------------------------------------------------------------------------------
--]]

--[[--
Vector4.
menori.ml.vec4
]]
-- @classmod vec4
-- @alias vec4_mt

local modules = (...):gsub('%.[^%.]+$', '') .. "."
local utils = require(modules .. "utils")

local vec4 = {}
local vec4_mt = {}
vec4_mt.__index = vec4_mt

local function new(x, y, z, w)
	x = x or 0
	return setmetatable({
		x = x or x,
		y = y or x,
		z = z or x,
		w = w or x,
	}, vec4_mt)
end

vec4.unit_x = new(1, 0, 0, 0)
vec4.unit_y = new(0, 1, 0, 0)
vec4.unit_z = new(0, 0, 1, 0)
vec4.unit_w = new(0, 0, 0, 1)

--- clone
function vec4_mt:clone()
    	return new(self.x, self.y, self.z, self.w)
end

--- set
function vec4_mt:set(x, y, z, w)
	if type(x) == 'table' then
		x, y, z, w = x.x or x[1], x.y or x[2], x.z or x[3], x.w or x[4]
	end
	self.x = x
	self.y = y
	self.z = z
	self.w = w
	return self
end

--- add
function vec4_mt:add(a, b)
	self.x = a.x + b.x
	self.y = a.y + b.y
	self.z = a.z + b.z
	self.w = a.w + b.w
	return self
end

--- sub
function vec4_mt:sub(a, b)
	self.x = a.x - b.x
	self.y = a.y - b.y
	self.z = a.z - b.z
	self.w = a.w - b.w
	return self
end

--- mul
function vec4_mt:mul(a, b)
	self.x = a.x * b.x
	self.y = a.y * b.y
	self.z = a.z * b.z
	self.w = a.w * b.w
	return self
end

--- div
function vec4_mt:div(a, b)
	self.x = a.x / b.x
	self.y = a.y / b.y
	self.z = a.z / b.z
	self.w = a.w / b.w
	return self
end

--- scale
function vec4_mt:scale(scalar)
	self.x = self.x * scalar
	self.y = self.y * scalar
	self.z = self.z * scalar
	self.w = self.w * scalar
	return self
end

--- length
function vec4_mt:length()
    	return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w)
end

--- normalize
function vec4_mt:normalize()
	local length = self:length()
	if length ~= 0 then
		self.x = self.x / length
		self.y = self.y / length
		self.z = self.z / length
		self.w = self.w / length
	end
	return self
end

--- round
function vec4_mt:round()
	self.x = utils.round(self.x)
	self.y = utils.round(self.y)
	self.z = utils.round(self.z)
	self.w = utils.round(self.w)
end

--- unpack
function vec4_mt:unpack()
	return self.x, self.y, self.z, self.w
end

-- vec3 operator overloading --

function vec4_mt.__unm(a)
	return new(-a.x, -a.y, -a.z, -a.w)
end

function vec4_mt.__eq(a, b)
	if not vec4.is_vec4(a) or not vec4.is_vec4(b) then
		return false
	end
	return a.x == b.x and a.y == b.y and a.z == b.z and a.w == b.w
end

function vec4_mt.__add(a, b)
	local is_a_vec4 = vec4.is_vec4(a)
	local is_b_vec4 = vec4.is_vec4(b)
	if is_a_vec4 and is_b_vec4 then
		return vec4():add(a, b)
	end

	if is_a_vec4 then
		return new(a.x + b, a.y + b, a.z + b, a.w + b)
	else
		return new(a + b.x, a + b.y, a + b.z, a + b.w)
	end
end

function vec4_mt.__sub(a, b)
	local is_a_vec4 = vec4.is_vec4(a)
	local is_b_vec4 = vec4.is_vec4(b)
	if is_a_vec4 and is_b_vec4 then
		return vec4():sub(a, b)
	end

	if is_a_vec4 then
		return new(a.x - b, a.y - b, a.z - b, a.w - b)
	else
		return new(a - b.x, a - b.y, a - b.z, a - b.w)
	end
end

function vec4_mt.__mul(a, b)
	local is_a_vec4 = vec4.is_vec4(a)
	local is_b_vec4 = vec4.is_vec4(b)
	if is_a_vec4 and is_b_vec4 then
		return vec4():mul(a, b)
	end

	if is_a_vec4 then
		return new(a.x * b, a.y * b, a.z * b, a.w * b)
	else
		return new(a * b.x, a * b.y, a * b.z, a * b.w)
	end
end

function vec4_mt.__div(a, b)
	local is_a_vec4 = vec4.is_vec4(a)
	local is_b_vec4 = vec4.is_vec4(b)
	if is_a_vec4 and is_b_vec4 then
		return vec4():div(a, b)
	end

	if is_a_vec4 then
		return new(a.x / b, a.y / b, a.z / b, a.w / b)
	else
		return new(a / b.x, a / b.y, a / b.z, a / b.w)
	end
end

function vec4_mt.__tostring(a)
	return string.format("(%+0.3f,%+0.3f,%+0.3f,%+0.3f)", a.x, a.y, a.z, a.w)
end

-- vec3 --

--- is vec4
-- @static
function vec4.is_vec4(a)
	return type(a) == "table" and
		type(a.x) == "number" and
		type(a.y) == "number" and
		type(a.z) == "number" and
		type(a.w) == "number"
end

--- dot
-- @static
function vec4.dot(a, b)
    	return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
end

--- fract
-- @static
function vec4.fract(a)
	return new(
		a.x - math.floor(a.x),
		a.y - math.floor(a.y),
		a.z - math.floor(a.z),
		a.w - math.floor(a.w)
	)
end

--- lerp
-- @static
function vec4.lerp(a, b, s)
	return a + (b - a) * s
end

--- min
-- @static
function vec4.min(a, b)
	return new(math.min(a.x, b.x), math.min(a.y, b.y), math.min(a.z, b.z), math.min(a.w, b.w))
end

--- max
-- @static
function vec4.max(a, b)
	return new(math.max(a.x, b.x), math.max(a.y, b.y), math.max(a.z, b.z), math.max(a.w, b.w))
end

--- abs
-- @static
function vec4.abs(a)
	return new(math.abs(a.x), math.abs(a.y), math.abs(a.z), math.abs(a.w))
end

--- equal
-- @static
function vec4.equal(a, b)
	return { a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w }
end

--- notEqual
-- @static
function vec4.notEqual(a, b)
	return { a.x ~= b.x, a.y ~= b.y, a.z ~= b.z, a.w ~= b.w }
end

--- lessThan
-- @static
function vec4.lessThan(a, b)
	return { a.x < b.x, a.y < b.y, a.z < b.z, a.w < b.w }
end

--- lessThanEqual
-- @static
function vec4.lessThanEqual(a, b)
	return { a.x <= b.x, a.y <= b.y, a.z <= b.z, a.w <= b.w  }
end

--- greaterThan
-- @static
function vec4.greaterThan(a, b)
	return { a.x > b.x, a.y > b.y, a.z > b.z, a.w > b.w  }
end

--- greaterThanEqual
-- @static
function vec4.greaterThanEqual(a, b)
	return { a.x >= b.x, a.y >= b.y, a.z >= b.z, a.w >= b.w  }
end

--- pow
-- @static
function vec4.pow(a, b)
	return new(
		math.pow(a.x, b.x),
		math.pow(a.y, b.y),
		math.pow(a.z, b.z),
		math.pow(a.w, b.w)
	)
end

return setmetatable(vec4, { __call = function(_, x, y, z, w)
	if type(x) == 'table' then
		local xx, yy, zz, ww = x.x or x[1], x.y or x[2], x.z or x[3], x.w or x[4]
		return new(xx, yy, zz, ww)
	end
	return new(x, y, z, w)
end })