--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

local modules = (...):match('(.*%menori.modules.)')

local class = require (modules .. 'libs.class')

local animation_list = class('animation_list')
local animation = class('animation')

function animation:constructor(name, sprite)
	self.name = name

	self.loops = 0
	self.loop_count = 0
	self.index = 1

	self.sprite = sprite

	self.frame_duration = 0
	self.accumulator = 0
	self.next_animation = nil
end

function animation:set(duration, loops)
	duration = duration or 0
	self.frame_duration = duration / self.sprite:get_frame_count()
	self.loops = loops or 0
end

function animation:reset()
	self.loop_count = self.loops
	self.accumulator = self.frame_duration
	self.index = 1
end

function animation_list:constructor(list)
	self.list = {}
	for k, v in pairs(list) do
		self.list[k] = animation(k, v:clone())
	end
	self.stop = false
	self.curr = nil
	self.next = nil
	self.name_lock = ''
end

function animation_list:update(dt)
	if self.curr and not self.stop then
		self.curr.accumulator = self.curr.accumulator - dt
		if self.curr.accumulator <= 0 then
			self.curr.index = self.curr.index + 1
			if self.next then
				self.curr = self.next
				self.next = nil
				self.curr:reset()
			else
				if self.curr.index > self.curr.sprite:get_frame_count() then
					self.curr.index = 1
					self.curr.loop_count = self.curr.loop_count - 1
				end
				if self.curr.loop_count == 0 then
					if self.curr.next_animation then
						self.curr = self.curr.next_animation
						self.curr:reset()
					else
						self.stop = true
					end
				end

				self.curr.accumulator = self.curr.frame_duration
			end
            self.curr.sprite:set_frame_index(self.curr.index)
        end
	end
end

function animation_list:set_chain(name, chain_list)
	local chain_next
	chain_next = function(chain_list, index)
		local object = chain_list[index]
		if not object then return nil end
		local a = self.list[object[1]]
		a:set(object[2], object[3])
		a:reset()
		a.next_animation = chain_next(chain_list, index + 1)
		return a
	end
	self.list[name] = chain_next(chain_list, 1)
end

function animation_list:get_animation(name)
	return self.list[name]
end

function animation_list:set_current(name, await)
	if self.name_lock == name then
		return
	end

	local next_a = self.list[name]
	next_a:reset()

	if self.stop or not await then
		self.curr = next_a
		self.next = nil
		self.curr.sprite:set_frame_index(self.curr.index)
		self.stop = false
	else
		self.next = next_a
	end
	self.name_lock = name
end

function animation_list:get_current()
	return self.curr
end

function animation_list:draw(...)
	if self.curr then
		self.curr.sprite:draw(...)
	end
end

return animation_list