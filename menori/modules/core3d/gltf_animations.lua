--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2023
-------------------------------------------------------------------------------
]]

--[[--
A class that provides functionality for gltf animations.
]]
-- @classmod glTFAnimation

local modules = (...):match('(.*%menori.modules.)')

local class = require (modules .. 'libs.class')
local utils = require (modules .. 'libs.utils')
local ml    = require (modules .. 'ml')
local Node  = require (modules .. 'node')

local vec3  = ml.vec3
local quat  = ml.quat

local glTFAnimation = class('glTFAnimations')

----
-- The public constructor.
-- @tparam table animations Animations loaded with the glTFLoader
function glTFAnimation:init(animations)
	self.animations = animations
	self.accumulator = 0
	self.animation = self.animations[1]
end

local function get_sampler_data(accumulator, sampler, target)
	local min = sampler.time_array[1]
	local max = sampler.time_array[#sampler.time_array]
	accumulator = (accumulator % (max - min)) + min

	local frame1_index = utils.binsearch(sampler.time_array, accumulator)
	local frame2_index = math.min(#sampler.time_array, frame1_index + 1)

	local frame1 = sampler.data_array[frame1_index]
	local frame2 = sampler.data_array[frame2_index]

	if sampler.interpolation == 'STEP' or frame1_index == frame2_index then
		if target == 'rotation' then
			return quat(frame1)
		elseif target == 'weights' then

		else
			return vec3(frame1)
		end
	end

	local time1 = sampler.time_array[frame1_index]
	local time2 = sampler.time_array[frame2_index]

	local s = ((accumulator) - time1) / (time2 - time1)

	if sampler.interpolation == 'LINEAR' then
		if target == 'rotation' then
			return quat.slerp(quat(frame1), quat(frame2), s)
		elseif target == 'weights' then

		else
			return vec3.lerp(vec3(frame1), vec3(frame2), s)
		end
	end

	return frame1
end

local target_path = {
      rotation = Node.set_rotation,
      translation = Node.set_position,
      scale = Node.set_scale,
      weights = function ()
	end
}

----
-- Set the action by name.
-- @tparam string name Action name
function glTFAnimation:set_action_by_name(name)
	for i, v in ipairs(self.animations) do
		if v.name == name then
			self.animation = v
			break
		end
	end
end

----
-- Set the action by index.
-- @tparam number i Action index
function glTFAnimation:set_action(i)
	self.animation = self.animations[i]
end

----
-- Get the total number of actions.
-- @treturn number
function glTFAnimation:get_action_count()
	return #self.animations
end

----
-- Update animations.
-- @tparam number dt
function glTFAnimation:update(dt)
	if self.animation then
		for _, channel in ipairs(self.animation.channels) do
			local node = channel.target_node
			local data = get_sampler_data(self.accumulator, channel.sampler, channel.target_path)
			target_path[channel.target_path](node, data)
		end
	end
	self.accumulator = self.accumulator + dt
end

return glTFAnimation