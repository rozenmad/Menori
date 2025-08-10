--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2025
-------------------------------------------------------------------------------
	this module based on CPML - Cirno's Perfect Math Library
	-- @author Colby Klein
	-- @author Landon Manning
	-- @copyright 2016
	-- @license MIT/X11
	https://github.com/excessive/cpml/blob/master/modules/mat4.lua
--]]

--[[--
Matrix4.
menori.ml.mat4
]]
-- @classmod mat4
-- @alias mat4_mt

local menori_modules = (...):match('(.*%menori.modules.)')
local modules = (...):gsub('%.[^%.]+$', '') .. "."
local vec3 = require (modules .. "vec3")
local vec4 = require (modules .. "vec4")
local ffi  = require (menori_modules .. 'libs.ffi')

local bytesize
if ffi then
	bytesize = ffi.sizeof('float[16]')
end

local mat4 = {}
local mat4_mt = {}
mat4_mt.__index = mat4_mt

local temp_a4 = {0, 0, 0, 0}

local function identity(e)
	e[ 1], e[ 2], e[ 3], e[ 4] = 1, 0, 0, 0
	e[ 5], e[ 6], e[ 7], e[ 8] = 0, 1, 0, 0
	e[ 9], e[10], e[11], e[12] = 0, 0, 1, 0
	e[13], e[14], e[15], e[16] = 0, 0, 0, 1
end

local function is_identity(m, size)
	local m = m or m.e
	local s = math.sqrt(size or #m)
	for i = 0, s - 1 do
		for j = 0, s - 1 do
			local element = m[(i + j * s) + 1]
			if (element ~= 0 and i ~= j) or (element ~= 1 and i == j) then
				return false
			end
		end
	end
	return true
end

local function copy(dst, src)
	dst[1]  = src[1]
	dst[2]  = src[2]
	dst[3]  = src[3]
	dst[4]  = src[4]
	dst[5]  = src[5]
	dst[6]  = src[6]
	dst[7]  = src[7]
	dst[8]  = src[8]
	dst[9]  = src[9]
	dst[10] = src[10]
	dst[11] = src[11]
	dst[12] = src[12]
	dst[13] = src[13]
	dst[14] = src[14]
	dst[15] = src[15]
	dst[16] = src[16]
end

local function new(m)
	local data, e
	if ffi then
		data = love.data.newByteData(bytesize)
		e = ffi.cast('float*', data:getFFIPointer()) - 1
	else
		data = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
		e = data
	end
	local t = setmetatable({ data = data, e = e, changed = true }, mat4_mt)

	if type(m) == 'table' then
		if #m == 16 then
			for i = 1, 16 do
				t.e[i] = tonumber(m[i])
			end
		else
			copy(t.e, m.e)
		end
	else
		identity(t.e)
	end
	return t
end

local temp_array = {}

local function multiply(a, b, result)
	result = result or a

	local a01, a02, a03, a04 = a[1 ], a[2 ], a[3 ], a[4 ]
	local a05, a06, a07, a08 = a[5 ], a[6 ], a[7 ], a[8 ]
	local a09, a10, a11, a12 = a[9 ], a[10], a[11], a[12]
	local a13, a14, a15, a16 = a[13], a[14], a[15], a[16]

	local b01, b02, b03, b04 = b[1 ], b[2 ], b[3 ], b[4 ]
	local b05, b06, b07, b08 = b[5 ], b[6 ], b[7 ], b[8 ]
	local b09, b10, b11, b12 = b[9 ], b[10], b[11], b[12]
	local b13, b14, b15, b16 = b[13], b[14], b[15], b[16]

	result[1]  = a01 * b01 + a05 * b02 + a09 * b03 + a13 * b04
	result[2]  = a02 * b01 + a06 * b02 + a10 * b03 + a14 * b04
	result[3]  = a03 * b01 + a07 * b02 + a11 * b03 + a15 * b04
	result[4]  = a04 * b01 + a08 * b02 + a12 * b03 + a16 * b04
	result[5]  = a01 * b05 + a05 * b06 + a09 * b07 + a13 * b08
	result[6]  = a02 * b05 + a06 * b06 + a10 * b07 + a14 * b08
	result[7]  = a03 * b05 + a07 * b06 + a11 * b07 + a15 * b08
	result[8]  = a04 * b05 + a08 * b06 + a12 * b07 + a16 * b08
	result[9]  = a01 * b09 + a05 * b10 + a09 * b11 + a13 * b12
	result[10] = a02 * b09 + a06 * b10 + a10 * b11 + a14 * b12
	result[11] = a03 * b09 + a07 * b10 + a11 * b11 + a15 * b12
	result[12] = a04 * b09 + a08 * b10 + a12 * b11 + a16 * b12
	result[13] = a01 * b13 + a05 * b14 + a09 * b15 + a13 * b16
	result[14] = a02 * b13 + a06 * b14 + a10 * b15 + a14 * b16
	result[15] = a03 * b13 + a07 * b14 + a11 * b15 + a15 * b16
	result[16] = a04 * b13 + a08 * b14 + a12 * b15 + a16 * b16
    	return result
end

local function rotate(e, angle, ax, ay, az, length)
	local c = math.cos(angle)
	local s = math.sin(angle)

	local invc = 1.0 - c

	local x = (ax / length) * invc
	local y = (ay / length) * invc
	local z = (az / length) * invc

	e[1]  = c + x * ax
	e[2]  = x * ay + s * az
	e[3]  = x * az - s * ay

	e[5]  = y * ax - s * az
	e[6]  = c + y * ay
	e[7]  = y * az + s * ax

	e[9]  = z * ax + s * ay
	e[10] = z * ay - s * ax
	e[11] = c + z * az
end

local temp_transform = love.math.newTransform()

--- to temp transform object
function mat4_mt:to_temp_transform_object()
	local e = self.e
	temp_transform:setMatrix('column',
		e[ 1], e[ 2], e[ 3], e[ 4],
		e[ 5], e[ 6], e[ 7], e[ 8],
		e[ 9], e[10], e[11], e[12],
		e[13], e[14], e[15], e[16]
	)
	return temp_transform
end

--- to table
function mat4_mt:to_table()
	local t = {}
	local e = self.e
	t[1]  = e[1]
	t[2]  = e[2]
	t[3]  = e[3]
	t[4]  = e[4]
	t[5]  = e[5]
	t[6]  = e[6]
	t[7]  = e[7]
	t[8]  = e[8]
	t[9]  = e[9]
	t[10] = e[10]
	t[11] = e[11]
	t[12] = e[12]
	t[13] = e[13]
	t[14] = e[14]
	t[15] = e[15]
	t[16] = e[16]
	return t
end

--- clone
function mat4_mt:clone()
	return new(self)
end

--- copy
function mat4_mt:copy(other)
	copy(self.e, other.e)
	return self
end

--- identity
function mat4_mt:identity()
	identity(self.e)
	return self
end

--- is identity
function mat4_mt:is_identity()
	return is_identity(self.e, 16)
end

--- multiply
function mat4_mt:multiply(other)
	multiply(self.e, other.e)
	return self
end

--- determinant
function mat4_mt:determinant()
	local e = self.e

	local n11, n12, n13, n14 = e[1], e[5], e[ 9], e[13]
	local n21, n22, n23, n24 = e[2], e[6], e[10], e[14]
	local n31, n32, n33, n34 = e[3], e[7], e[11], e[15]
	local n41, n42, n43, n44 = e[4], e[8], e[12], e[16]

	return (n41 * ( n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 * n34)
		+ n42 * ( n11 * n23 * n34 - n11 * n24 * n33 + n14 * n21 * n33 - n13 * n21 * n34 + n13 * n24 * n31 - n14 * n23 * n31)
		+ n43 * ( n11 * n24 * n32 - n11 * n22 * n34 - n14 * n21 * n32 + n12 * n21 * n34 + n14 * n22 * n31 - n12 * n24 * n31)
		+ n44 * (-n13 * n22 * n31 - n11 * n23 * n32 + n11 * n22 * n33 + n13 * n21 * n32 - n12 * n21 * n33 + n12 * n23 * n31)
	)
end

--- inverse
function mat4_mt:inverse()
	local e = self.e

	local e01, e02, e03, e04 = e[1 ], e[2 ], e[3 ], e[4 ]
	local e05, e06, e07, e08 = e[5 ], e[6 ], e[7 ], e[8 ]
	local e09, e10, e11, e12 = e[9 ], e[10], e[11], e[12]
	local e13, e14, e15, e16 = e[13], e[14], e[15], e[16]

	temp_array[1]  = e06 * e11 * e16 - e06 * e12 * e15 - e10 * e07 * e16 + e10 * e08 * e15 + e14 * e07 * e12 - e14 * e08 * e11
	temp_array[5]  =-e05 * e11 * e16 + e05 * e12 * e15 + e09 * e07 * e16 - e09 * e08 * e15 - e13 * e07 * e12 + e13 * e08 * e11
	temp_array[9]  = e05 * e10 * e16 - e05 * e12 * e14 - e09 * e06 * e16 + e09 * e08 * e14 + e13 * e06 * e12 - e13 * e08 * e10
	temp_array[13] =-e05 * e10 * e15 + e05 * e11 * e14 + e09 * e06 * e15 - e09 * e07 * e14 - e13 * e06 * e11 + e13 * e07 * e10
	temp_array[2]  =-e02 * e11 * e16 + e02 * e12 * e15 + e10 * e03 * e16 - e10 * e04 * e15 - e14 * e03 * e12 + e14 * e04 * e11
	temp_array[6]  = e01 * e11 * e16 - e01 * e12 * e15 - e09 * e03 * e16 + e09 * e04 * e15 + e13 * e03 * e12 - e13 * e04 * e11
	temp_array[10] =-e01 * e10 * e16 + e01 * e12 * e14 + e09 * e02 * e16 - e09 * e04 * e14 - e13 * e02 * e12 + e13 * e04 * e10
	temp_array[14] = e01 * e10 * e15 - e01 * e11 * e14 - e09 * e02 * e15 + e09 * e03 * e14 + e13 * e02 * e11 - e13 * e03 * e10
	temp_array[3]  = e02 * e07 * e16 - e02 * e08 * e15 - e06 * e03 * e16 + e06 * e04 * e15 + e14 * e03 * e08 - e14 * e04 * e07
	temp_array[7]  =-e01 * e07 * e16 + e01 * e08 * e15 + e05 * e03 * e16 - e05 * e04 * e15 - e13 * e03 * e08 + e13 * e04 * e07
	temp_array[11] = e01 * e06 * e16 - e01 * e08 * e14 - e05 * e02 * e16 + e05 * e04 * e14 + e13 * e02 * e08 - e13 * e04 * e06
	temp_array[15] =-e01 * e06 * e15 + e01 * e07 * e14 + e05 * e02 * e15 - e05 * e03 * e14 - e13 * e02 * e07 + e13 * e03 * e06
	temp_array[4]  =-e02 * e07 * e12 + e02 * e08 * e11 + e06 * e03 * e12 - e06 * e04 * e11 - e10 * e03 * e08 + e10 * e04 * e07
	temp_array[8]  = e01 * e07 * e12 - e01 * e08 * e11 - e05 * e03 * e12 + e05 * e04 * e11 + e09 * e03 * e08 - e09 * e04 * e07
	temp_array[12] =-e01 * e06 * e12 + e01 * e08 * e10 + e05 * e02 * e12 - e05 * e04 * e10 - e09 * e02 * e08 + e09 * e04 * e06
	temp_array[16] = e01 * e06 * e11 - e01 * e07 * e10 - e05 * e02 * e11 + e05 * e03 * e10 + e09 * e02 * e07 - e09 * e03 * e06

	local det = e01 * temp_array[1] + e02 * temp_array[5] + e03 * temp_array[9] + e04 * temp_array[13]

	if det == 0.0 then return self end

	local invdet = 1.0 / det
	for i = 1, 16 do
		e[i] = temp_array[i] * invdet
	end
	return self
end

--- transpose
function mat4_mt:transpose()
	local e = self.e
	temp_array[1]  = e[1]
	temp_array[2]  = e[5]
	temp_array[3]  = e[9]
	temp_array[4]  = e[13]
	temp_array[5]  = e[2]
	temp_array[6]  = e[6]
	temp_array[7]  = e[10]
	temp_array[8]  = e[14]
	temp_array[9]  = e[3]
	temp_array[10] = e[7]
	temp_array[11] = e[11]
	temp_array[12] = e[15]
	temp_array[13] = e[4]
	temp_array[14] = e[8]
	temp_array[15] = e[12]
	temp_array[16] = e[16]
	copy(e, temp_array)
	return self
end

--- compose
function mat4_mt:compose(position, rotation, scale)
	local e = self.e

	local x, y, z, w = rotation.x, rotation.y, rotation.z, rotation.w
	local x2, y2, z2 = x + x, y + y, z + z

	local xx, xy, xz = x * x2, x * y2, x * z2
	local yy, yz, zz = y * y2, y * z2, z * z2
	local wx, wy, wz = w * x2, w * y2, w * z2

	local sx, sy, sz = scale.x, scale.y, scale.z

	e[1]  = (1 - (yy + zz)) * sx
	e[2]  = (xy + wz) * sx
	e[3]  = (xz - wy) * sx
	e[4]  = 0
	e[5]  = (xy - wz) * sy
	e[6]  = (1 - (xx + zz)) * sy
	e[7]  = (yz + wx) * sy
	e[8]  = 0
	e[9]  = (xz + wy) * sz
	e[10] = (yz - wx) * sz
	e[11] = (1 - (xx + yy)) * sz
	e[12] = 0
	e[13] = position.x
	e[14] = position.y
	e[15] = position.z
	e[16] = 1
	return self
end

local tvec3 = vec3()

--- decompose
function mat4_mt:decompose(position, rotation, scale)
	local e = self.e
	if position then
		position:set_from_matrix_position(self)
	end
	if rotation or scale then
		local sx = tvec3:set(e[1], e[ 2], e[ 3]):length()
		local sy = tvec3:set(e[5], e[ 6], e[ 7]):length()
		local sz = tvec3:set(e[9], e[10], e[11]):length()

		if self:determinant() < 0 then sx = -sx end

		if scale then
			scale.x = sx
			scale.y = sy
			scale.z = sz
		end
		if rotation then
			copy(temp_array, e)

			local invSX = 1 / sx
			local invSY = 1 / sy
			local invSZ = 1 / sz

			temp_array[ 1] = temp_array[ 1] * invSX
			temp_array[ 2] = temp_array[ 2] * invSX
			temp_array[ 3] = temp_array[ 3] * invSX

			temp_array[ 5] = temp_array[ 5] * invSY
			temp_array[ 6] = temp_array[ 6] * invSY
			temp_array[ 7] = temp_array[ 7] * invSY

			temp_array[ 9] = temp_array[ 9] * invSZ
			temp_array[10] = temp_array[10] * invSZ
			temp_array[11] = temp_array[11] * invSZ

			rotation:set_from_matrix_rotation(temp_array)
		end
	end
end

--- set position and rotation
function mat4_mt:set_position_and_rotation(position, angle, axis)
	if type(angle) == "table" then
		angle, axis = angle:to_angle_axis()
	end
	local length = axis:length()

	if length ~= 0 then
		rotate(temp_array, angle, axis.x, axis.y, axis.z, length)

		temp_array[4], temp_array[8],  temp_array[12] = 0, 0, 0
	else
		temp_array[1], temp_array[2],  temp_array[3]  = 0, 0, 0
		temp_array[5], temp_array[6],  temp_array[7]  = 0, 0, 0
		temp_array[9], temp_array[10], temp_array[11] = 0, 0, 0
	end

	temp_array[13] = position.x
	temp_array[14] = position.y
	temp_array[15] = position.z
	temp_array[16] = 1

	multiply(self.e, temp_array)
	return self
end

--- scale
function mat4_mt:scale(x, y, z)
	if type(x) == 'table' then
		x, y, z = x.x, x.y, x.z
	end
	identity(temp_array)
	temp_array[1]  = x
	temp_array[6]  = y
	temp_array[11] = z
	multiply(self.e, temp_array)
	return self
end

--- translate
function mat4_mt:translate(x, y, z)
	if type(x) == 'table' then
		x, y, z = x.x, x.y, x.z
	end
	identity(temp_array)
	temp_array[13] = x
	temp_array[14] = y
	temp_array[15] = z
	multiply(self.e, temp_array)
	return self
end

--- shear
function mat4_mt:shear(yx, xy, zx, zy, xz, yz)
	identity(temp_array)
	temp_array[2] = yx or 0
	temp_array[3] = zx or 0
	temp_array[5] = xy or 0
	temp_array[7] = zy or 0
	temp_array[9] = xz or 0
	temp_array[10] = yz or 0

	multiply(self.e, temp_array)
	return self
end

--- rotate
function mat4_mt:rotate(angle, axis)
	if type(angle) == "table" then
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

--- reflect
function mat4_mt:reflect(position, normal)
	local nx, ny, nz = normal:unpack()
	local d = vec3.dot(-position, normal)
	temp_array[1]  = 1 - 2 * nx ^ 2
	temp_array[2]  = 2 * nx * ny
	temp_array[3]  =-2 * nx * nz
	temp_array[4]  = 0
	temp_array[5]  =-2 * nx * ny
	temp_array[6]  = 1 - 2 * ny ^ 2
	temp_array[7]  =-2 * ny * nz
	temp_array[8]  = 0
	temp_array[9]  =-2 * nx * nz
	temp_array[10] =-2 * ny * nz
	temp_array[11] = 1 - 2 * nz ^ 2
	temp_array[12] = 0
	temp_array[13] =-2 * nx * d
	temp_array[14] =-2 * ny * d
	temp_array[15] =-2 * nz * d
	temp_array[16] = 1

	multiply(self.e, temp_array)
	return self
end

local function look_at_LH(self, eye, center, up)
	local f = (center - eye):normalize()
	local s = vec3.cross(up, f):normalize()
	local u = vec3.cross(f, s)

	temp_array[1]  = s.x
	temp_array[2]  = u.x
	temp_array[3]  = f.x
	temp_array[4]  = 0
	temp_array[5]  = s.y
	temp_array[6]  = u.y
	temp_array[7]  = f.y
	temp_array[8]  = 0
	temp_array[9]  = s.z
	temp_array[10] = u.z
	temp_array[11] = f.z
	temp_array[12] = 0
	temp_array[13] = -vec3.dot(s, eye)
	temp_array[14] = -vec3.dot(u, eye)
	temp_array[15] = -vec3.dot(f, eye)
	temp_array[16] = 1

	multiply(self.e, temp_array)
	return self
end

local function look_at_RH(self, eye, center, up)
	local f = (center - eye):normalize()
	local s = vec3.cross(f, up):normalize()
	local u = vec3.cross(s, f)

	temp_array[1]  = s.x
	temp_array[2]  = u.x
	temp_array[3]  =-f.x
	temp_array[4]  = 0
	temp_array[5]  = s.y
	temp_array[6]  = u.y
	temp_array[7]  =-f.y
	temp_array[8]  = 0
	temp_array[9]  = s.z
	temp_array[10] = u.z
	temp_array[11] =-f.z
	temp_array[12] = 0
	temp_array[13] = -vec3.dot(s, eye)
	temp_array[14] = -vec3.dot(u, eye)
	temp_array[15] =  vec3.dot(f, eye)
	temp_array[16] = 1

	multiply(self.e, temp_array)
	return self
end

local function look_at_np(self, eye, look_at, up)
	local z_axis = (eye - look_at):normalize()
	local x_axis = vec3.cross(up, z_axis):normalize()
	local y_axis = vec3.cross(z_axis, x_axis)

	temp_array[1]  = x_axis.x
	temp_array[2]  = y_axis.x
	temp_array[3]  = z_axis.x
	temp_array[4]  = 0
	temp_array[5]  = x_axis.y
	temp_array[6]  = y_axis.y
	temp_array[7]  = z_axis.y
	temp_array[8]  = 0
	temp_array[9]  = x_axis.z
	temp_array[10] = y_axis.z
	temp_array[11] = z_axis.z
	temp_array[12] = 0
	temp_array[13] = 0
	temp_array[14] = 0
	temp_array[15] = 0
	temp_array[16] = 1

	multiply(self.e, temp_array)
	return self
end

--- multiply vec4
function mat4_mt:multiply_vec4(v, out)
	out = out or vec4()
	local e = self.e
	temp_a4[1] = v.x * e[1] + v.y * e[5] + v.z * e[9]  + v.w * e[13]
	temp_a4[2] = v.x * e[2] + v.y * e[6] + v.z * e[10] + v.w * e[14]
	temp_a4[3] = v.x * e[3] + v.y * e[7] + v.z * e[11] + v.w * e[15]
	temp_a4[4] = v.x * e[4] + v.y * e[8] + v.z * e[12] + v.w * e[16]
	out.x = temp_a4[1]
	out.y = temp_a4[2]
	out.z = temp_a4[3]
	out.w = temp_a4[4]
	return out
end

--- multiply vec3
function mat4_mt:multiply_vec3(v, out)
	out = out or vec3()
	local e = self.e
	temp_a4[1] = v.x * e[1] + v.y * e[5] + v.z * e[9]  + e[13]
	temp_a4[2] = v.x * e[2] + v.y * e[6] + v.z * e[10] + e[14]
	temp_a4[3] = v.x * e[3] + v.y * e[7] + v.z * e[11] + e[15]
	out.x = temp_a4[1]
	out.y = temp_a4[2]
	out.z = temp_a4[3]
	return out
end

--- multiply vec3 array
function mat4_mt:multiply_vec3_array(v, out)
	out = out or {}
	local e = self.e
	temp_a4[1] = v[1] * e[1] + v[2] * e[5] + v[3] * e[9]  + e[13]
	temp_a4[2] = v[1] * e[2] + v[2] * e[6] + v[3] * e[10] + e[14]
	temp_a4[3] = v[1] * e[3] + v[2] * e[7] + v[3] * e[11] + e[15]
	out[1] = temp_a4[1]
	out[2] = temp_a4[2]
	out[3] = temp_a4[3]
	return out
end

--- multiply vec4 array
function mat4_mt:multiply_vec4_array(v, out)
	out = out or {}
	local e = self.e
	temp_a4[1] = v[1] * e[1] + v[2] * e[5] + v[3] * e[9]  + v[4] * e[13]
	temp_a4[2] = v[1] * e[2] + v[2] * e[6] + v[3] * e[10] + v[4] * e[14]
	temp_a4[3] = v[1] * e[3] + v[2] * e[7] + v[3] * e[11] + v[4] * e[15]
	temp_a4[4] = v[1] * e[4] + v[2] * e[8] + v[3] * e[12] + v[4] * e[16]
	out[1] = temp_a4[1]
	out[2] = temp_a4[2]
	out[3] = temp_a4[3]
	out[4] = temp_a4[4]
	return out
end

-- https://github.com/g-truc/glm/blob/23e0701c0483283440d4d1bcd17eb7070fa8eb75/glm/ext/matrix_clip_space.inl#L249
local function perspective_RH_NO(self, fovy, aspect, near, far)
	assert(aspect ~= 0, 'aspect == 0')
	assert(near ~= far, 'near == far')

	local e = self.e
	identity(e)

	local tanhf = math.tan(math.rad(fovy) / 2)

	e[1]  = 1 / (tanhf * aspect)
	e[6]  = 1 / tanhf
	e[11] =-(far + near) / (far - near)
	e[12] =-1
	e[15] =-(2 * far * near) / (far - near)
	e[16] = 0

	return self
end

-- https://github.com/g-truc/glm/blob/23e0701c0483283440d4d1bcd17eb7070fa8eb75/glm/ext/matrix_clip_space.inl#L281
local function perspective_LH_NO(self, fovy, aspect, near, far)
	assert(aspect ~= 0, 'aspect == 0')
	assert(near ~= far, 'near == far')

	local e = self.e
	identity(e)

	local tanhf = math.tan(math.rad(fovy) / 2)

	e[1]  = 1 / (tanhf * aspect)
	e[6]  = 1 / tanhf
	e[11] = (far + near) / (far - near)
	e[12] = 1
	e[15] =-(2 * far * near) / (far - near)
	e[16] = 0

	return self
end

-- https://github.com/g-truc/glm/blob/23e0701c0483283440d4d1bcd17eb7070fa8eb75/glm/ext/matrix_clip_space.inl#L29
local function ortho_LH_NO(self, left, right, bottom, top, zNear, zFar)
	local e = self.e
	identity(e)
	e[1]  = 2 / (right - left)
	e[6]  = 2 / (top - bottom)
	e[11] = 2 / (zFar - zNear)
	e[13] = -(right + left) / (right - left)
	e[14] = -(top + bottom) / (top - bottom)
	e[15] = -(zFar + zNear) / (zFar - zNear)
	return self
end

-- https://github.com/g-truc/glm/blob/23e0701c0483283440d4d1bcd17eb7070fa8eb75/glm/ext/matrix_clip_space.inl#L55
local function ortho_RH_NO(self, left, right, bottom, top, zNear, zFar)
	local e = self.e
	identity(e)
	e[1]  =  2 / (right - left)
	e[6]  =  2 / (top - bottom)
	e[11] = -2 / (zFar - zNear)
	e[13] = -(right + left) / (right - left)
	e[14] = -(top + bottom) / (top - bottom)
	e[15] = -(zFar + zNear) / (zFar - zNear)
	return self
end

mat4_mt.look_at    = look_at_LH
mat4_mt.look_at_LH = look_at_LH
mat4_mt.look_at_RH = look_at_RH
mat4_mt.look_at_np = look_at_np

mat4_mt.ortho       = ortho_LH_NO
mat4_mt.ortho_LH_NO = ortho_LH_NO
mat4_mt.ortho_RH_NO = ortho_RH_NO

mat4_mt.perspective       = perspective_LH_NO
mat4_mt.perspective_LH_NO = perspective_LH_NO
mat4_mt.perspective_RH_NO = perspective_RH_NO

--- unpack
function mat4_mt:unpack()
	local e = self.e
	return e[ 1], e[ 2], e[ 3], e[ 4],
		 e[ 5], e[ 6], e[ 7], e[ 8],
		 e[ 9], e[10], e[11], e[12],
		 e[13], e[14], e[15], e[16]
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
			str = str .. string.format("%+0.3f", a.e[i+j*4+1])
			str = str .. ", "
		end
		str = str .. '\n'
	end
	str = str .. "],"
	return str
end

-- mat4 common --

mat4.identity    = identity
mat4.multiply    = multiply
mat4.copy        = copy
mat4.is_identity = is_identity

--- is mat4
-- @static
function mat4.is_mat4(a)
	if type(a) ~= "table" then
		return false
	end
	for i = 1, 16 do
		if type(a[i]) ~= "number" then
			return false
		end
	end
	return true
end

--- unproject
-- @static
function mat4.unproject(win, model, proj, viewport)
	local pos = vec4(win.x, win.y, win.z, 1)
	pos.x = ((pos.x - viewport[1]) / viewport[3])
	pos.y = ((pos.y - viewport[2]) / viewport[4])
	pos.x = pos.x * 2 - 1
	pos.y = pos.y *-2 + 1
	pos.z = pos.z * 2 - 1
	pos.w = pos.w * 2 - 1

	local m = (proj * model):inverse()
	m:multiply_vec4(pos, pos)
	return vec3(pos.x / pos.w, pos.y / pos.w, pos.z / pos.w)
end

return setmetatable(mat4, { __call = function(_, m)
	return new(m)
end })