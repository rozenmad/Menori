--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2022
-------------------------------------------------------------------------------
--]]

--[[--
Vector3.
menori.ml.vec3
]]
-- @classmod vec3
-- @alias vec3_mt

local modules = (...):gsub('%.[^%.]+$', '') .. "."
local utils = require(modules .. "utils")

local vec3 = {}
local vec3_mt = {}
vec3_mt.__index = vec3_mt

local function new(x, y, z)
	x = x or 0
	return setmetatable({
		x = x or x,
		y = y or x,
		z = z or x,
	}, vec3_mt)
end

vec3.zero   = new()
vec3.unit_x = new(1, 0, 0)
vec3.unit_y = new(0, 1, 0)
vec3.unit_z = new(0, 0, 1)

--- clone
function vec3_mt:clone()
	return new(self.x, self.y, self.z)
end

--- set
function vec3_mt:set(x, y, z)
	if type(x) == 'table' then
		x, y, z = x.x or x[1], x.y or x[2], x.z or x[3]
	end
	self.x = x
	self.y = y
	self.z = z
	return self
end

--- add
function vec3_mt:add(a, b)
	self.x = a.x + b.x
	self.y = a.y + b.y
	self.z = a.z + b.z
	return self
end

--- sub
function vec3_mt:sub(a, b)
	self.x = a.x - b.x
	self.y = a.y - b.y
	self.z = a.z - b.z
	return self
end

--- add_scalar
function vec3_mt:add_scalar(scalar)
	self.x = self.x + scalar
	self.y = self.y + scalar
	self.z = self.z + scalar
	return self
end

--- add_scalar
function vec3_mt:sub_scalar(scalar)
	self.x = self.x - scalar
	self.y = self.y - scalar
	self.z = self.z - scalar
	return self
end

--- mul
function vec3_mt:mul(a, b)
	self.x = a.x * b.x
	self.y = a.y * b.y
	self.z = a.z * b.z
	return self
end

--- div
function vec3_mt:div(a, b)
	self.x = a.x / b.x
	self.y = a.y / b.y
	self.z = a.z / b.z
	return self
end

--- scale
function vec3_mt:scale(scalar)
	self.x = self.x * scalar
	self.y = self.y * scalar
	self.z = self.z * scalar
	return self
end

--- length
function vec3_mt:length()
	return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

--- length2
function vec3_mt:length2()
	return self.x * self.x + self.y * self.y + self.z * self.z
end

--- normalize
function vec3_mt:normalize()
	local length = self:length()
	if length ~= 0 then
		self.x = self.x / length
		self.y = self.y / length
		self.z = self.z / length
	end
	return self
end

--- round
function vec3_mt:round()
	self.x = utils.round(self.x)
	self.y = utils.round(self.y)
	self.z = utils.round(self.z)
end

--- unpack
function vec3_mt:unpack()
	return self.x, self.y, self.z
end

--- set from matrix position
function vec3_mt:set_from_matrix_position(m)
	self.x = m.e[13]
	self.y = m.e[14]
	self.z = m.e[15]
end

-- vec3 operator overloading --

function vec3_mt.__unm(a)
	return new(-a.x, -a.y, -a.z)
end

function vec3_mt.__eq(a, b)
	if not vec3.is_vec3(a) or not vec3.is_vec3(b) then
		return false
	end
	return a.x == b.x and a.y == b.y and a.z == b.z
end

function vec3_mt.__add(a, b)
	local is_a_vec3 = vec3.is_vec3(a)
	local is_b_vec3 = vec3.is_vec3(b)
	if is_a_vec3 and is_b_vec3 then
		return vec3():add(a, b)
	end

	if is_a_vec3 then
		return new(a.x + b, a.y + b, a.z + b)
	else
		return new(a + b.x, a + b.y, a + b.z)
	end
end

function vec3_mt.__sub(a, b)
	local is_a_vec3 = vec3.is_vec3(a)
	local is_b_vec3 = vec3.is_vec3(b)
	if is_a_vec3 and is_b_vec3 then
		return vec3():sub(a, b)
	end

	if is_a_vec3 then
		return new(a.x - b, a.y - b, a.z - b)
	else
		return new(a - b.x, a - b.y, a - b.z)
	end
end

function vec3_mt.__mul(a, b)
	local is_a_vec3 = vec3.is_vec3(a)
	local is_b_vec3 = vec3.is_vec3(b)
	if is_a_vec3 and is_b_vec3 then
		return vec3():mul(a, b)
	end

	if is_a_vec3 then
		return new(a.x * b, a.y * b, a.z * b)
	else
		return new(a * b.x, a * b.y, a * b.z)
	end
end

function vec3_mt.__div(a, b)
	local is_a_vec3 = vec3.is_vec3(a)
	local is_b_vec3 = vec3.is_vec3(b)
	if is_a_vec3 and is_b_vec3 then
		return vec3():div(a, b)
	end

	if is_a_vec3 then
		return new(a.x / b, a.y / b, a.z / b)
	else
		return new(a / b.x, a / b.y, a / b.z)
	end
end

function vec3_mt.__tostring(a)
	return string.format("(%+0.3f,%+0.3f,%+0.3f)", a.x, a.y, a.z)
end

-- vec3 --

vec3._mt = vec3_mt

--- is vec3
-- @static
function vec3.is_vec3(a)
	return type(a) == "table" and
		type(a.x) == "number" and
		type(a.y) == "number" and
		type(a.z) == "number" and
		type(a.w) == "nil"
end

--- dot
-- @static
function vec3.dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z
end

--- distance
-- @static
function vec3.distance(p0, p1)
	return (p0 - p1):length()
end

--- fract
-- @static
function vec3.fract(a)
	return new(
		a.x - math.floor(a.x),
		a.y - math.floor(a.y),
		a.z - math.floor(a.z)
	)
end

--- cross
-- @static
function vec3.cross(a, b)
	return new(
		a.y * b.z - a.z * b.y,
		a.z * b.x - a.x * b.z,
		a.x * b.y - a.y * b.x
	)
end

--- lerp
-- @static
function vec3.lerp(a, b, s)
	return a + (b - a) * s
end

--- min
-- @static
function vec3.min(a, b)
	return new(math.min(a.x, b.x), math.min(a.y, b.y), math.min(a.z, b.z))
end

--- max
function vec3.max(a, b)
	return new(math.max(a.x, b.x), math.max(a.y, b.y), math.max(a.z, b.z))
end

--- abs
-- @static
function vec3.abs(a)
	return new(math.abs(a.x), math.abs(a.y), math.abs(a.z))
end

--- equal
-- @static
function vec3.equal(a, b)
	return { a.x == b.x, a.y == b.y, a.z == b.z }
end

--- notEqual
-- @static
function vec3.notEqual(a, b)
	return { a.x ~= b.x, a.y ~= b.y, a.z ~= b.z  }
end

--- lessThan
-- @static
function vec3.lessThan(a, b)
	return { a.x < b.x, a.y < b.y, a.z < b.z }
end

--- lessThanEqual
-- @static
function vec3.lessThanEqual(a, b)
	return { a.x <= b.x, a.y <= b.y, a.z <= b.z }
end

--- greaterThan
-- @static
function vec3.greaterThan(a, b)
	return { a.x > b.x, a.y > b.y, a.z > b.z }
end

--- greaterThanEqual
-- @static
function vec3.greaterThanEqual(a, b)
	return { a.x >= b.x, a.y >= b.y, a.z >= b.z }
end

--- pow
-- @static
function vec3.pow(a, b)
	return new(
		math.pow(a.x, b.x),
		math.pow(a.y, b.y),
		math.pow(a.z, b.z)
	)
end

return setmetatable(vec3, { __call = function(_, x, y, z)
	if type(x) == 'table' then
		local xx, yy, zz = x.x or x[1], x.y or x[2], x.z or x[3]
		return new(xx, yy, zz)
	end
	return new(x, y, z)
end })