--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

local modules = (...):match('(.*%menori.modules.)')

local class = require (modules .. 'libs.class')

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

function script:init(coroutine_fn, opt)
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