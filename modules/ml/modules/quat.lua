local modules = (...):gsub('%.[^%.]+$', '') .. "."
local vec3 = require(modules .. "vec3")
local vec4 = require(modules .. "vec4")

local sin = math.sin
local cos = math.cos

local quat = {}

function quat.from_angle_axis(angle, axis, a3, a4)
	if axis and a3 and a4 then
		local x, y, z = axis, a3, a4
		local s = sin(angle * 0.5)
		local c = cos(angle * 0.5)
		return vec4(x * s, y * s, z * s, c)
	else
		return quat.from_angle_axis(angle, axis.x, axis.y, axis.z)
	end
end

return quat