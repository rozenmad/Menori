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

vec3.unit_x = new(1, 0, 0)
vec3.unit_y = new(0, 1, 0)
vec3.unit_z = new(0, 0, 1)

function vec3_mt:clone()
	return new(self.x, self.y, self.z)
end

function vec3_mt:add(other)
	self.x = self.x + other.x
	self.y = self.y + other.y
	self.z = self.z + other.z
	return self
end

function vec3_mt:sub(other)
	self.x = self.x - other.x
	self.y = self.y - other.y
	self.z = self.z - other.z
	return self
end

function vec3_mt:mul(other)
	self.x = self.x * other.x
	self.y = self.y * other.y
	self.z = self.z * other.z
	return self
end

function vec3_mt:div(other)
	self.x = self.x / other.x
	self.y = self.y / other.y
	self.z = self.z / other.z
	return self
end

function vec3_mt:length()
	return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function vec3_mt:normalize()
	local length = self:length()
	if length ~= 0 then
		self.x = self.x / length
		self.y = self.y / length
		self.z = self.z / length
	end
	return self
end

function vec3_mt:unpack()
	return self.x, self.y, self.z
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
		return a:clone():add(b)
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
		return a:clone():sub(b)
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
		return a:clone():mul(b)
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
		return a:clone():div(b)
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

function vec3.is_vec3(a)
	return type(a) == "table" and
		type(a.x) == "number" and
		type(a.y) == "number" and
		type(a.z) == "number"
end

function vec3.dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z
end

function vec3.distance(p0, p1)
	return (p0 - p1):length()
end

function vec3.fract(a)
	return new(
		a.x - math.floor(a.x),
		a.y - math.floor(a.y),
		a.z - math.floor(a.z)
	)
end

function vec3.cross(a, b)
	return new(
		a.y * b.z - a.z * b.y,
		a.z * b.x - a.x * b.z,
		a.x * b.y - a.y * b.x
	)
end

function vec3.min(a, b)
	return new(math.min(a.x, b.x), math.min(a.y, b.y), math.min(a.z, b.z))
end

function vec3.max(a, b)
	return new(math.max(a.x, b.x), math.max(a.y, b.y), math.max(a.z, b.z))
end

function vec3.abs(a)
	return new(math.abs(a.x), math.abs(a.y), math.abs(a.z))
end

function vec3.lessThan(a, b)
	return { a.x < b.x, a.y < b.y, a.z < b.z }
end

function vec3.pow(a, b)
	return new(
		math.pow(a.x, b.x),
		math.pow(a.y, b.y),
		math.pow(a.z, b.z)
	)
end

return setmetatable(vec3, { __call = function(_, x, y, z)
	return new(x, y, z)
end })