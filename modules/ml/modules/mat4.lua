--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
	this module based on Cirno's Perfect Math Library - mat4
--]]

local modules = (...):gsub('%.[^%.]+$', '') .. "."
local vec3 = require(modules .. "vec3")

local ffi = require 'ffi'

local mat4 = {}
local mat4_mt = {}
mat4_mt.__index = mat4_mt

mat4.bytesize = ffi.sizeof('float[16]')

local temp_array = ffi.new('float[16]')
local temp_a4 = {0, 0, 0, 0}

local function dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z
end

local function identity(e)
	e[ 0], e[ 1], e[ 2], e[ 3] = 1, 0, 0, 0
	e[ 4], e[ 5], e[ 6], e[ 7] = 0, 1, 0, 0
	e[ 8], e[ 9], e[10], e[11] = 0, 0, 1, 0
	e[12], e[13], e[14], e[15] = 0, 0, 0, 1
end

local function copy(dest, source)
	for i = 0, 15 do
		dest[i] = source[i]
	end
end

local function new(m)
	local data = love.data.newByteData(mat4.bytesize)
	local t = setmetatable({
		data = data,
		e = ffi.cast('float*', data:getFFIPointer()),
		_changed = true,
	}, mat4_mt)

	if type(m) == 'table' then
		if #m == 16 then
			for i = 0, 15 do
				t.e[i] = tonumber(m[i + 1])
			end
		else
			copy(t.e, m.e)
		end
	else
		identity(t.e)
	end
	return t
end

local tmat4 = {}
local function multiply(a, b)
	tmat4[0]  = a[0] * b[0]  + a[4] * b[1]  + a[8]  * b[2]  + a[12] * b[3]
	tmat4[1]  = a[1] * b[0]  + a[5] * b[1]  + a[9]  * b[2]  + a[13] * b[3]
	tmat4[2]  = a[2] * b[0]  + a[6] * b[1]  + a[10] * b[2]  + a[14] * b[3]
	tmat4[3]  = a[3] * b[0]  + a[7] * b[1]  + a[11] * b[2]  + a[15] * b[3]
	tmat4[4]  = a[0] * b[4]  + a[4] * b[5]  + a[8]  * b[6]  + a[12] * b[7]
	tmat4[5]  = a[1] * b[4]  + a[5] * b[5]  + a[9]  * b[6]  + a[13] * b[7]
	tmat4[6]  = a[2] * b[4]  + a[6] * b[5]  + a[10] * b[6]  + a[14] * b[7]
	tmat4[7]  = a[3] * b[4]  + a[7] * b[5]  + a[11] * b[6]  + a[15] * b[7]
	tmat4[8]  = a[0] * b[8]  + a[4] * b[9]  + a[8]  * b[10] + a[12] * b[11]
	tmat4[9]  = a[1] * b[8]  + a[5] * b[9]  + a[9]  * b[10] + a[13] * b[11]
	tmat4[10] = a[2] * b[8]  + a[6] * b[9]  + a[10] * b[10] + a[14] * b[11]
	tmat4[11] = a[3] * b[8]  + a[7] * b[9]  + a[11] * b[10] + a[15] * b[11]
	tmat4[12] = a[0] * b[12] + a[4] * b[13] + a[8]  * b[14] + a[12] * b[15]
	tmat4[13] = a[1] * b[12] + a[5] * b[13] + a[9]  * b[14] + a[13] * b[15]
	tmat4[14] = a[2] * b[12] + a[6] * b[13] + a[10] * b[14] + a[14] * b[15]
	tmat4[15] = a[3] * b[12] + a[7] * b[13] + a[11] * b[14] + a[15] * b[15]

	for i = 0, 15 do
		a[i] = tmat4[i]
	end

	return a
end

local function rotate(e, angle, ax, ay, az, length)
	local c = math.cos(angle)
	local s = math.sin(angle)

	local invc = 1.0 - c

	local x = (ax / length) * invc
	local y = (ay / length) * invc
	local z = (az / length) * invc

	e[0]  = c + x * ax;
	e[1]  = x * ay + s * az;
	e[2]  = x * az - s * ay;

	e[4]  = y * ax - s * az;
	e[5]  = c + y * ay;
	e[6]  = y * az + s * ax;

	e[8]  = z * ax + s * ay;
	e[9]  = z * ay - s * ax;
	e[10] = c + z * az;
end

local temp_transform = love.math.newTransform()
function mat4_mt:to_temp_transform_object()
	local e = self.e
	temp_transform:setMatrix('column',
		e[ 0], e[ 1], e[ 2], e[ 3],
		e[ 4], e[ 5], e[ 6], e[ 7],
		e[ 8], e[ 9], e[10], e[11],
		e[12], e[13], e[14], e[15]
	)
	return temp_transform
end

function mat4_mt:to_temp_table()
	local t = {}
	local e = self.e
	t[ 1] = e[0]
	t[ 2] = e[4]
	t[ 3] = e[8]
	t[ 4] = e[12]
	t[ 5] = e[1]
	t[ 6] = e[5]
	t[ 7] = e[9]
	t[ 8] = e[13]
	t[ 9] = e[2]
	t[10] = e[6]
	t[11] = e[10]
	t[12] = e[14]
	t[13] = e[3]
	t[14] = e[7]
	t[15] = e[11]
	t[16] = e[15]
	return t
end

function mat4_mt:clone()
	return new(self)
end

function mat4_mt:copy(other)
	copy(self.e, other.e)
	return self
end

function mat4_mt:identity()
	self._changed = true
	identity(self.e)
	return self
end

function mat4_mt:multiply(other)
	self._changed = true
	multiply(self.e, other.e)
	return self
end

function mat4_mt:inverse()
	self._changed = true
	local e = self.e
	tmat4[0]  = e[5] * e[10] * e[15] - e[5] * e[11] * e[14] - e[9] * e[6] * e[15] + e[9] * e[7] * e[14] + e[13] * e[6] * e[11] - e[13] * e[7] * e[10]
	tmat4[4]  =-e[4] * e[10] * e[15] + e[4] * e[11] * e[14] + e[8] * e[6] * e[15] - e[8] * e[7] * e[14] - e[12] * e[6] * e[11] + e[12] * e[7] * e[10]
	tmat4[8]  = e[4] * e[9]  * e[15] - e[4] * e[11] * e[13] - e[8] * e[5] * e[15] + e[8] * e[7] * e[13] + e[12] * e[5] * e[11] - e[12] * e[7] * e[9]
	tmat4[12] =-e[4] * e[9]  * e[14] + e[4] * e[10] * e[13] + e[8] * e[5] * e[14] - e[8] * e[6] * e[13] - e[12] * e[5] * e[10] + e[12] * e[6] * e[9]
	tmat4[1]  =-e[1] * e[10] * e[15] + e[1] * e[11] * e[14] + e[9] * e[2] * e[15] - e[9] * e[3] * e[14] - e[13] * e[2] * e[11] + e[13] * e[3] * e[10]
	tmat4[5]  = e[0] * e[10] * e[15] - e[0] * e[11] * e[14] - e[8] * e[2] * e[15] + e[8] * e[3] * e[14] + e[12] * e[2] * e[11] - e[12] * e[3] * e[10]
	tmat4[9]  =-e[0] * e[9]  * e[15] + e[0] * e[11] * e[13] + e[8] * e[1] * e[15] - e[8] * e[3] * e[13] - e[12] * e[1] * e[11] + e[12] * e[3] * e[9]
	tmat4[13] = e[0] * e[9]  * e[14] - e[0] * e[10] * e[13] - e[8] * e[1] * e[14] + e[8] * e[2] * e[13] + e[12] * e[1] * e[10] - e[12] * e[2] * e[9]
	tmat4[2]  = e[1] * e[6]  * e[15] - e[1] * e[7]  * e[14] - e[5] * e[2] * e[15] + e[5] * e[3] * e[14] + e[13] * e[2] * e[7]  - e[13] * e[3] * e[6]
	tmat4[6]  =-e[0] * e[6]  * e[15] + e[0] * e[7]  * e[14] + e[4] * e[2] * e[15] - e[4] * e[3] * e[14] - e[12] * e[2] * e[7]  + e[12] * e[3] * e[6]
	tmat4[10] = e[0] * e[5]  * e[15] - e[0] * e[7]  * e[13] - e[4] * e[1] * e[15] + e[4] * e[3] * e[13] + e[12] * e[1] * e[7]  - e[12] * e[3] * e[5]
	tmat4[14] =-e[0] * e[5]  * e[14] + e[0] * e[6]  * e[13] + e[4] * e[1] * e[14] - e[4] * e[2] * e[13] - e[12] * e[1] * e[6]  + e[12] * e[2] * e[5]
	tmat4[3]  =-e[1] * e[6]  * e[11] + e[1] * e[7]  * e[10] + e[5] * e[2] * e[11] - e[5] * e[3] * e[10] - e[9]  * e[2] * e[7]  + e[9]  * e[3] * e[6]
	tmat4[7]  = e[0] * e[6]  * e[11] - e[0] * e[7]  * e[10] - e[4] * e[2] * e[11] + e[4] * e[3] * e[10] + e[8]  * e[2] * e[7]  - e[8]  * e[3] * e[6]
	tmat4[11] =-e[0] * e[5]  * e[11] + e[0] * e[7]  * e[9]  + e[4] * e[1] * e[11] - e[4] * e[3] * e[9]  - e[8]  * e[1] * e[7]  + e[8]  * e[3] * e[5]
	tmat4[15] = e[0] * e[5]  * e[10] - e[0] * e[6]  * e[9]  - e[4] * e[1] * e[10] + e[4] * e[2] * e[9]  + e[8]  * e[1] * e[6]  - e[8]  * e[2] * e[5]

	local det = e[0] * tmat4[0] + e[1] * tmat4[4] + e[2] * tmat4[8] + e[3] * tmat4[12]
	copy(e, tmat4)

	if det ~= 0.0 then
		local invdet = 1.0 / det
		for i = 0, 15 do
			e[i] = e[i] * invdet
		end
	end
	return self
end

function mat4_mt:transpose()
	self._changed = true
	local e = self.e
	temp_array[0]  = e[0]
	temp_array[1]  = e[4]
	temp_array[2]  = e[8]
	temp_array[3]  = e[12]
	temp_array[4]  = e[1]
	temp_array[5]  = e[5]
	temp_array[6]  = e[9]
	temp_array[7]  = e[13]
	temp_array[8]  = e[2]
	temp_array[9]  = e[6]
	temp_array[10] = e[10]
	temp_array[11] = e[14]
	temp_array[12] = e[3]
	temp_array[13] = e[7]
	temp_array[14] = e[11]
	temp_array[15] = e[15]
	copy(e, temp_array)
	return self
end

function mat4_mt:set_position_and_rotation(position, angle, axis)
	self._changed = true
	if type(angle) == "table" or type(angle) == "cdata" then
		angle, axis = angle:to_angle_axis()
	end
	local length = axis:len()
	local e = self.e

	if length ~= 0 then
		rotate(e, angle, axis.x, axis.y, axis.z, length)

		e[3], e[7], e[11] = 0, 0, 0
	else
		e[0], e[1], e[ 2] = 0, 0, 0
		e[4], e[5], e[ 6] = 0, 0, 0
		e[8], e[9], e[10] = 0, 0, 0
	end

	e[12] = position.x
	e[13] = position.y
	e[14] = position.z
	e[15] = 1
end

function mat4_mt:scale(x, y, z)
	self._changed = true
	if type(x) == 'table' or type(x) == 'cdata' then
		x, y, z = x.x, x.y, x.z
	end
	identity(temp_array)
	temp_array[0]  = x
	temp_array[5]  = y
	temp_array[10] = z
	multiply(self.e, temp_array)
	return self
end

function mat4_mt:translate(x, y, z)
	self._changed = true
	if type(x) == 'table' or type(x) == 'cdata' then
		x, y, z = x.x, x.y, x.z
	end
	identity(temp_array)
	temp_array[12] = x
	temp_array[13] = y
	temp_array[14] = z
	multiply(self.e, temp_array)
	return self
end

function mat4_mt:shear(yx, xy, zx, zy, xz, yz)
	self._changed = true
	identity(temp_array)
	temp_array[1] = yx or 0
	temp_array[2] = zx or 0
	temp_array[4] = xy or 0
	temp_array[6] = zy or 0
	temp_array[8] = xz or 0
	temp_array[9] = yz or 0

	multiply(self.e, temp_array)
	return self
end

function mat4_mt:rotate(angle, axis)
	self._changed = true
	if type(angle) == "table" or type(angle) == "cdata" then
		angle, axis = angle:to_angle_axis()
	end
	local length = axis:length()

	if length ~= 0 then
		identity(temp_array)
		rotate(temp_array, angle, axis.x, axis.y, axis.z, length)
		multiply(self.e, temp_array)
	end
	return self
end

function mat4_mt:reflect(position, normal)
	self._changed = true
	local nx, ny, nz = normal:unpack()
	local d = -position:dot(normal)
	temp_array[0]  = 1 - 2 * nx ^ 2
	temp_array[1]  = 2 * nx * ny
	temp_array[2]  =-2 * nx * nz
	temp_array[3]  = 0
	temp_array[4]  =-2 * nx * ny
	temp_array[5]  = 1 - 2 * ny ^ 2
	temp_array[6]  =-2 * ny * nz
	temp_array[7]  = 0
	temp_array[8]  =-2 * nx * nz
	temp_array[9]  =-2 * ny * nz
	temp_array[10] = 1 - 2 * nz ^ 2
	temp_array[11] = 0
	temp_array[12] =-2 * nx * d
	temp_array[13] =-2 * ny * d
	temp_array[14] =-2 * nz * d
	temp_array[15] = 1

	multiply(self.e, temp_array)
	return self
end

local function look_at_LH(self, eye, center, up)
	self._changed = true
	local f = (center - eye):normalize()
	local s = vec3.cross(up, f):normalize()
	local u = vec3.cross(f, s)

	temp_array[0]  = s.x
	temp_array[1]  = u.x
	temp_array[2]  = f.x
	temp_array[3]  = 0
	temp_array[4]  = s.y
	temp_array[5]  = u.y
	temp_array[6]  = f.y
	temp_array[7]  = 0
	temp_array[8]  = s.z
	temp_array[9]  = u.z
	temp_array[10] = f.z
	temp_array[11] = 0
	temp_array[12] = -dot(s, eye);
	temp_array[13] = -dot(u, eye);
	temp_array[14] = -dot(f, eye);
	temp_array[15] = 1

	multiply(self.e, temp_array)
	return self
end

local function look_at_RH(self, eye, center, up)
	self._changed = true
	local f = (center - eye):normalize()
	local s = vec3.cross(f, up):normalize()
	local u = vec3.cross(s, f)

	temp_array[0]  = s.x
	temp_array[1]  = u.x
	temp_array[2]  =-f.x
	temp_array[3]  = 0
	temp_array[4]  = s.y
	temp_array[5]  = u.y
	temp_array[6]  =-f.y
	temp_array[7]  = 0
	temp_array[8]  = s.z
	temp_array[9]  = u.z
	temp_array[10] =-f.z
	temp_array[11] = 0
	temp_array[12] = -dot(s, eye);
	temp_array[13] = -dot(u, eye);
	temp_array[14] =  dot(f, eye);
	temp_array[15] = 1

	multiply(self.e, temp_array)
	return self
end

local function look_at_np(self, eye, look_at, up)
	self._changed = true
	local z_axis = (eye - look_at):normalize()
	local x_axis = vec3.cross(up, z_axis):normalize()
	local y_axis = vec3.cross(z_axis, x_axis)

	temp_array[0]  = x_axis.x
	temp_array[1]  = y_axis.x
	temp_array[2]  = z_axis.x
	temp_array[3]  = 0
	temp_array[4]  = x_axis.y
	temp_array[5]  = y_axis.y
	temp_array[6]  = z_axis.y
	temp_array[7]  = 0
	temp_array[8]  = x_axis.z
	temp_array[9]  = y_axis.z
	temp_array[10] = z_axis.z
	temp_array[11] = 0
	temp_array[12] = 0
	temp_array[13] = 0
	temp_array[14] = 0
	temp_array[15] = 1

	multiply(self.e, temp_array)
	return self
end

function mat4_mt:multiply_vec4(v, out)
	out = out or v
	local e = self.e
	temp_a4[1] = v.x * e[0] + v.y * e[4] + v.z * e[8]  + v.w * e[12]
	temp_a4[2] = v.x * e[1] + v.y * e[5] + v.z * e[9]  + v.w * e[13]
	temp_a4[3] = v.x * e[2] + v.y * e[6] + v.z * e[10] + v.w * e[14]
	temp_a4[4] = v.x * e[3] + v.y * e[7] + v.z * e[11] + v.w * e[15]
	out.x = temp_a4[1]
	out.y = temp_a4[2]
	out.z = temp_a4[3]
	out.w = temp_a4[4]
	return out
end

function mat4_mt:multiply_vec3(v, out)
	out = out or v
	local e = self.e
	temp_a4[1] = v.x * e[0] + v.y * e[4] + v.z * e[8]  + e[12]
	temp_a4[2] = v.x * e[1] + v.y * e[5] + v.z * e[9]  + e[13]
	temp_a4[3] = v.x * e[2] + v.y * e[6] + v.z * e[10] + e[14]
	out.x = temp_a4[1]
	out.y = temp_a4[2]
	out.z = temp_a4[3]
	return out
end

-- https://github.com/g-truc/glm/blob/23e0701c0483283440d4d1bcd17eb7070fa8eb75/glm/ext/matrix_clip_space.inl#L249
local function perspective_RH_NO(self, fovy, aspect, near, far)
	self._changed = true
	assert(aspect ~= 0, 'aspect == 0')
	assert(near ~= far, 'near == far')

	local e = self.e
	identity(e)

	local tanhf = math.tan(math.rad(fovy) / 2)

	e[0]  = 1 / (tanhf * aspect)
	e[5]  = 1 / tanhf
	e[10] =-(far + near) / (far - near)
	e[11] =-1
	e[14] =-(2 * far * near) / (far - near)
	e[15] = 0

	return self
end

-- https://github.com/g-truc/glm/blob/23e0701c0483283440d4d1bcd17eb7070fa8eb75/glm/ext/matrix_clip_space.inl#L281
local function perspective_LH_NO(self, fovy, aspect, near, far)
	self._changed = true
	assert(aspect ~= 0, 'aspect == 0')
	assert(near ~= far, 'near == far')

	local e = self.e
	identity(e)

	local tanhf = math.tan(math.rad(fovy) / 2)

	e[0]  = 1 / (tanhf * aspect)
	e[5]  = 1 / tanhf
	e[10] = (far + near) / (far - near)
	e[11] = 1
	e[14] =-(2 * far * near) / (far - near)
	e[15] = 0

	return self
end

-- https://github.com/g-truc/glm/blob/23e0701c0483283440d4d1bcd17eb7070fa8eb75/glm/ext/matrix_clip_space.inl#L29
local function ortho_LH_NO(self, left, right, bottom, top, zNear, zFar)
	self._changed = true
	local e = self.e
	identity(e)
	e[0]  = 2 / (right - left)
	e[5]  = 2 / (top - bottom)
	e[10] = 2 / (zFar - zNear)
	e[12] = -(right + left) / (right - left)
	e[13] = -(top + bottom) / (top - bottom)
	e[14] = -(zFar + zNear) / (zFar - zNear)
	return self
end

-- https://github.com/g-truc/glm/blob/23e0701c0483283440d4d1bcd17eb7070fa8eb75/glm/ext/matrix_clip_space.inl#L55
local function ortho_RH_NO(self, left, right, bottom, top, zNear, zFar)
	self._changed = true
	local e = self.e
	identity(e)
	e[0]  =  2 / (right - left)
	e[5]  =  2 / (top - bottom)
	e[10] = -2 / (zFar - zNear)
	e[12] = -(right + left) / (right - left)
	e[13] = -(top + bottom) / (top - bottom)
	e[14] = -(zFar + zNear) / (zFar - zNear)
	return self
end

mat4_mt.look_at				= look_at_LH
mat4_mt.look_at_LH			= look_at_LH
mat4_mt.look_at_RH			= look_at_RH
mat4_mt.look_at_np			= look_at_np

mat4_mt.ortho				= ortho_LH_NO
mat4_mt.ortho_LH_NO 		= ortho_LH_NO
mat4_mt.ortho_RH_NO 		= ortho_RH_NO

mat4_mt.perspective			= perspective_LH_NO
mat4_mt.perspective_LH_NO	= perspective_LH_NO
mat4_mt.perspective_RH_NO	= perspective_RH_NO

function mat4_mt:is_changed()
	return self._changed == true
end

-- metamethods --
function mat4_mt.__index(t, k)
	if type(k) == 'number' then
		return t.e[k]
	else
		return rawget(mat4_mt, k)
	end
end

function mat4_mt.__newindex(t, k, v)
	if type(k) == "number" then
		t.e[k] = v
	else
		rawset(t, k, v)
	end
end

function mat4_mt.__mul(a, b)
	assert(mat4.is_mat4(a))
	assert(mat4.is_mat4(b))
	return a:clone():multiply(b)
end

function mat4_mt.__tostring(a)
	local str = "[\n"
	for i = 0, 3 do
		str = str .. '\t'
		for j = 0, 3 do
			str = str .. string.format("%+0.3f", a.e[i+j*4])
			str = str .. ", "
		end
		str = str .. '\n'
	end
	str = str .. "],"
	return str
end

-- mat4 common --

function mat4.is_mat4(a)
	if type(a) ~= "table" then
		return false
	end

	for i = 0, 15 do
		if type(a[i]) ~= "number" then
			return false
		end
	end

	return true
end

function mat4.unproject(win, viewproj, viewport)
	local x = (2 * (win.x - viewport[1])) / viewport[3] - 1
	local y = (2 * (win.y - viewport[2])) / viewport[4] - 1
	local z = win.z * 2 - 1
	local ray = {x = x, y = y, z = z, w = 1}
	viewproj:clone():inverse():multiply_vec4(ray)
	local v = {x = ray.x, y = ray.y, z = ray.z}
	v.x = v.x / ray.w
	v.y = v.y / ray.w
	v.z = v.z / ray.w
	return v
end

return setmetatable(mat4, { __call = function(_, m)
	return new(m)
end })