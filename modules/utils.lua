--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

local cpml = require 'libs.cpml'
local vec3 = cpml.vec3
local bound3 = cpml.bound3

local function get_bound3(vt, matrix)
	local min = vec3(vt[1][1], vt[1][2], vt[1][3])
	local max = vec3(vt[1][1], vt[1][2], vt[1][3])

	for i = 1, #vt do
		local x = vt[i][1]
		local y = vt[i][2]
		local z = vt[i][3]
		if x > max.x then max.x = x elseif x < min.x then min.x = x end
		if y > max.y then max.y = y elseif y < min.y then min.y = y end
		if z > max.z then max.z = z elseif z < min.z then min.z = z end
	end

	local b = bound3(matrix:multiply_vec3(min), matrix:multiply_vec3(max))
	if b.min.x > b.max.x then b.min.x, b.max.x = b.max.x, b.min.x end
	if b.min.y > b.max.y then b.min.y, b.max.y = b.max.y, b.min.y end
	if b.min.z > b.max.z then b.min.z, b.max.z = b.max.z, b.min.z end
	return b
end

--[[love.audio.replay = function(audio)
	if audio:isPlaying() then audio:stop() end
	audio:play()
end]]

return {
	get_bound3 				= get_bound3,
}