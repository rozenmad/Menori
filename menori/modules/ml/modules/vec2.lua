local vec2 = {}
local vec2_mt = {}
vec2_mt.__index = vec2_mt

local function new(x, y)
	x = x or 0
	return setmetatable({
		x = x or x,
		y = y or x,
	}, vec2_mt)
end

vec2.unit_x = new(1, 0)
vec2.unit_y = new(0, 1)

function vec2_mt:clone()
	return new(self.x, self.y)
end

function vec2_mt:add(other)
	self.x = self.x + other.x
	self.y = self.y + other.y
	return self
end

function vec2_mt:sub(other)
	self.x = self.x - other.x
	self.y = self.y - other.y
	return self
end

function vec2_mt:mul(other)
	self.x = self.x * other.x
	self.y = self.y * other.y
	return self
end

function vec2_mt:div(other)
	self.x = self.x / other.x
	self.y = self.y / other.y
	return self
end

function vec2_mt:scale(scalar)
	self.x = self.x * scalar
	self.y = self.y * scalar
	return self
end

function vec2_mt:length()
	return math.sqrt(self.x * self.x + self.y * self.y)
end

function vec2_mt:normalize()
	local length = self:length()
	if length ~= 0 then
		self.x = self.x / length
		self.y = self.y / length
	end
	return self
end

function vec2_mt:unpack()
	return self.x, self.y
end

-- vec2 operator overloading --

function vec2_mt.__unm(a)
	return new(-a.x, -a.y)
end

function vec2_mt.__eq(a, b)
	if not vec2.is_vec2(a) or not vec2.is_vec2(b) then
		return false
	end
	return a.x == b.x and a.y == b.y
end

function vec2_mt.__add(a, b)
	local is_a_vec2 = vec2.is_vec2(a)
	local is_b_vec2 = vec2.is_vec2(b)
	if is_a_vec2 and is_b_vec2 then
		return a:clone():add(b)
	end

	if is_a_vec2 then
		return new(a.x + b, a.y + b)
	else
		return new(a + b.x, a + b.y)
	end
end

function vec2_mt.__sub(a, b)
	local is_a_vec2 = vec2.is_vec2(a)
	local is_b_vec2 = vec2.is_vec2(b)
	if is_a_vec2 and is_b_vec2 then
		return a:clone():sub(b)
	end

	if is_a_vec2 then
		return new(a.x - b, a.y - b)
	else
		return new(a - b.x, a - b.y)
	end
end

function vec2_mt.__mul(a, b)
	local is_a_vec2 = vec2.is_vec2(a)
	local is_b_vec2 = vec2.is_vec2(b)
	if is_a_vec2 and is_b_vec2 then
		return a:clone():mul(b)
	end

	if is_a_vec2 then
		return new(a.x * b, a.y * b)
	else
		return new(a * b.x, a * b.y)
	end
end

function vec2_mt.__div(a, b)
	local is_a_vec2 = vec2.is_vec2(a)
	local is_b_vec2 = vec2.is_vec2(b)
	if is_a_vec2 and is_b_vec2 then
		return a:clone():div(b)
	end

	if is_a_vec2 then
		return new(a.x / b, a.y / b)
	else
		return new(a / b.x, a / b.y)
	end
end

function vec2_mt.__tostring(a)
	return string.format("(%+0.3f,%+0.3f)", a.x, a.y)
end

-- vec2 common --

function vec2.is_vec2(a)
	return type(a) == "table" and
		type(a.x) == "number" and
		type(a.y) == "number"
end

function vec2.dot(a, b)
	return a.x * b.x + a.y * b.y
end

function vec2.distance(p0, p1)
	return (p0 - p1):length()
end

function vec2.fract(a)
	return new(
		a.x - math.floor(a.x),
		a.y - math.floor(a.y)
	)
end

function vec2.min(a, b)
	return new(math.min(a.x, b.x), math.min(a.y, b.y))
end

function vec2.max(a, b)
	return new(math.max(a.x, b.x), math.max(a.y, b.y))
end

function vec2.abs(a)
	return new(math.abs(a.x), math.abs(a.y))
end

function vec2.lessThan(a, b)
	return { a.x < b.x, a.y < b.y }
end
function vec2.lessThanEqual(a, b)
	return { a.x <= b.x, a.y <= b.y }
end

function vec2.greaterThan(a, b)
	return { a.x > b.x, a.y > b.y }
end
function vec2.greaterThanEqual(a, b)
	return { a.x >= b.x, a.y >= b.y }
end

function vec2.pow(a, b)
	return new(
		math.pow(a.x, b.x),
		math.pow(a.y, b.y)
	)
end

return setmetatable(vec2, { __call = function(_, x, y)
	if type(x) == 'table' then
		local xx, yy = x.x or x[1], x.y or x[2]
		return new(xx, yy)
	end
	return new(x, y)
end })