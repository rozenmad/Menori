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

function vec4_mt:clone()
    	return new(self.x, self.y, self.z, self.w)
end

function vec4_mt:add(other)
	self.x = self.x + other.x
	self.y = self.y + other.y
	self.z = self.z + other.z
	self.w = self.w + other.w
	return self
end

function vec4_mt:sub(other)
	self.x = self.x - other.x
	self.y = self.y - other.y
	self.z = self.z - other.z
	self.w = self.w - other.w
	return self
end

function vec4_mt:mul(other)
	self.x = self.x * other.x
	self.y = self.y * other.y
	self.z = self.z * other.z
	self.w = self.w * other.w
	return self
end

function vec4_mt:div(other)
	self.x = self.x / other.x
	self.y = self.y / other.y
	self.z = self.z / other.z
	self.w = self.w / other.w
	return self
end

function vec4_mt:length()
    	return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w)
end

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
		return a:clone():add(b)
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
		return a:clone():sub(b)
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
		return a:clone():mul(b)
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
		return a:clone():div(b)
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

function vec4.is_vec4(a)
	return type(a) == "table" and
		type(a.x) == "number" and
		type(a.y) == "number" and
		type(a.z) == "number" and
		type(a.w) == "number"
end

function vec4.dot(a, b)
    	return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
end

function vec4.fract(a)
	return new(
		a.x - math.floor(a.x),
		a.y - math.floor(a.y),
		a.z - math.floor(a.z),
		a.w - math.floor(a.w)
	)
end

function vec4.min(a, b)
	return new(math.min(a.x, b.x), math.min(a.y, b.y), math.min(a.z, b.z), math.min(a.w, b.w))
end

function vec4.max(a, b)
	return new(math.max(a.x, b.x), math.max(a.y, b.y), math.max(a.z, b.z), math.max(a.w, b.w))
end

function vec4.abs(a)
	return new(math.abs(a.x), math.abs(a.y), math.abs(a.z), math.abs(a.w))
end

function vec4.lessThan(a, b)
	return { a.x < b.x, a.y < b.y, a.z < b.z, a.w < b.w }
end

function vec4.pow(a, b)
	return new(
		math.pow(a.x, b.x),
		math.pow(a.y, b.y),
		math.pow(a.z, b.z),
		math.pow(a.w, b.w)
	)
end

return setmetatable(vec4, { __call = function(_, x, y, z, w)
	return new(x, y, z, w)
end })