local menori = require 'menori'

local scene_iterator = 1
local example_list = {
	{ title = "minimal", path = "examples.minimal.scene" },
	{ title = "basic_lighting", path = "examples.basic_lighting.scene" },
	{ title = "SSAO", path = "examples.SSAO.scene" },
}
for _, v in ipairs(example_list) do
	local Scene = require(v.path)
	menori.app:add_scene(v.title, Scene())
end
menori.app:set_scene('minimal')

function love.draw()
	menori.app:render()

	local font = love.graphics.getFont()
	local w, h = love.graphics.getDimensions()

	love.graphics.setColor(1, 0.5, 0, 1)
	love.graphics.print(love.timer.getFPS(), 10, 10)
	love.graphics.setColor(1, 1, 1, 1)
	local prev_str = "Prev scene (press A)"
	local next_str = "Next scene (press D)"
	love.graphics.print("Example: " .. example_list[scene_iterator].title, 10, 25)
	love.graphics.print(prev_str, 10, h-30)
	love.graphics.print(next_str, w - font:getWidth(next_str) - 10, h-30)
end

function love.update(dt)
	menori.app:update(dt)

	if love.keyboard.isDown('escape') then
		love.event.quit()
	end
	love.mouse.setRelativeMode(love.mouse.isDown(2))
end

local function set_scene()
	menori.app:set_scene(example_list[scene_iterator].title)
end

function love.wheelmoved(...)
	menori.app:handle_event('wheelmoved', ...)
end
function love.keyreleased(key, ...)
	if key == 'a' then
		scene_iterator = scene_iterator - 1
		if scene_iterator < 1 then scene_iterator = #example_list end
		set_scene()
	end
	if key == 'd' then
		scene_iterator = scene_iterator + 1
		if scene_iterator > #example_list then scene_iterator = 1 end
		set_scene()
	end
	menori.app:handle_event('keyreleased', key, ...)
end
function love.keypressed(...)
	menori.app:handle_event('keypressed', ...)
end
function love.mousemoved(...)
	menori.app:handle_event('mousemoved', ...)
end