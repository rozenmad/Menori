--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]
--[[
local script = {}
script.__index = script

function script:stop()
	self.pause = true
	coroutine.yield()
end

function script:play()
	self.pause = false
end

local global = {}
global.__index = global

function global.init()
	return setmetatable(
		{list = {}}, global
	)
end

function global.wait(f, value)
	if not value then value = true end
	while f() ~= value do
		coroutine.yield()
	end
end

local love_time = love.timer.getTime
function global.wait_time(t)
	local last_time = love_time()
	while t > 0 do
		local new_time = love_time()
		t = t - (new_time - last_time)
		last_time = new_time
		coroutine.yield()
	end
end

function global:wrap(f)
	self.list[#self.list + 1] = setmetatable(
		{handle = coroutine.create(f), pause = false}, script
	)
end

function global:loop()
	for i = #self.list, 1, -1 do
		local thread = self.list[i]
		if not thread.pause then
			local handle = thread.handle
			assert(coroutine.resume(handle, thread))
			if coroutine.status(handle) == 'dead' then
				table.remove(self.list, i)
			end
		end
	end
end]]
local class = require 'menori.modules.libs.class'

local script = class('script')

local function wait(object, tvalue)
	while true do
		local all = true
		for k, v in pairs(tvalue) do
			if object[k] ~= v then
				all = false
			end
		end
		if all then
			break
		end
		coroutine.yield()
	end
end

function script:constructor(coroutine_fn, opt)
	self.opt = opt or { loop = false }
	self.handle = coroutine.create(function()
		repeat
			coroutine_fn(wait)
		until not self.opt.loop
	end)
	self.complete = false
end

function script:update()
	local handle = self.handle
	if coroutine.status(handle) ~= 'dead' then
		assert(coroutine.resume(handle))
	else
		self.complete = true
	end
end

return script