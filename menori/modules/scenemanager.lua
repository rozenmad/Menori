--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2025
-------------------------------------------------------------------------------
]]

--[[--
Singleton object.
The main class for managing scenes.
]]
-- @classmod SceneManager

local modules = (...):match('(.*%menori.modules.)')
local class = require (modules .. 'libs.class')

local scenemanager = class('SceneManager')

local scenes = {}
local accumulator = 0
local focused = true

local scene_stack = {}

scenemanager.max_frames_per_draw = 6
scenemanager.tick_period = 1.0 / 60.0

function scenemanager.add_scene(scene_object, name)
	name = name or scene_object.name
	scenes[name] = scene_object
end

function scenemanager.push(name)
	local scene = scenes[name]

	local prev_scene = scenemanager.current()
	if prev_scene and prev_scene.on_leave and not scene.transparent_flag then
		prev_scene:on_leave()
	end

	assert(scene, string.format('Scene named "%s" does not exist', name))
	table.insert(scene_stack, scene)
	if scene and scene.on_enter then
		scene:on_enter()
	end
	return scene
end

function scenemanager.pop()
	local scene = table.remove(scene_stack, #scene_stack)
	if scene and scene.on_leave then
		scene:on_leave()
	end
	local prev_scene = scenemanager.current()
	if prev_scene and prev_scene.on_enter and not scene.transparent_flag then
		prev_scene:on_enter()
	end
	return prev_scene
end

function scenemanager.remove(scene)
	for i = #scene_stack, 1, -1 do
		if scene_stack[i] == scene then
			table.remove(scene_stack, i)
		end
	end
end

function scenemanager.current()
	return scene_stack[#scene_stack]
end

function scenemanager.get_scene(name)
	return scenes[name]
end

local function render_scene(index)
	local scene = scene_stack[index]
	if scene then
		if scene.transparent_flag then
			render_scene(index - 1)
		end
		if scene.render then
			scene:render()
		end
	end
end

function scenemanager.render()
	render_scene(#scene_stack)
end

function scenemanager.update(dt)
	if not focused then
		return
	end

	accumulator = accumulator + dt

	local target_dt = scenemanager.tick_period

	local steps = math.floor(accumulator / target_dt)

	if steps > scenemanager.max_frames_per_draw then
		accumulator = 0
		steps = scenemanager.max_frames_per_draw
	elseif steps > 0 then
		accumulator = accumulator - steps * target_dt
	end

	--local interpolation_dt = accumulator / target_dt

	local current_scene = scene_stack[#scene_stack]
	if current_scene then
		if current_scene.update then
			while steps > 0 do
				current_scene:update(target_dt)
				steps = steps - 1
			end
		end
	end
end

function scenemanager.focus(f)
	focused = f
end

--- Handling any LOVE event. Redirects an event call to an overridden function in the active scene.
-- @tparam string eventname
function scenemanager.handle_event(eventname, ...)
	local current_scene = scene_stack[#scene_stack]
	if current_scene then
		local event = current_scene[eventname]
		if event then
			event(current_scene, ...)
		end
	end
end

return scenemanager