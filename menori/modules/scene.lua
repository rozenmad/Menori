--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

--[[--
Base class of scenes.
It contains methods for recursively drawing and updating all nodes of the scene.
You need to inherit from the Scene class to create your own scene object.
]]
-- @module menori.Scene

local modules = (...):match('(.*%menori.modules.)')

local class = require (modules .. 'libs.class')

local lovg = love.graphics
local temp_environment

local temp_renderstate = { clear = false }

local function node_sort(a, b)
	return a.layer < b.layer
end

local function default_filter(node, scene, environment)
	node:render(scene, environment)
end

local scene = class('Scene')

--- Constructor
function scene:constructor()
	self.list_drawable_nodes = {}
end

--- Recursively call render function for every node.
-- @tparam Node node
-- @tparam Environment environment
-- @tparam table renderstates (Optional)
-- @tparam function filter (Optional)
function scene:render_nodes(node, environment, renderstates, filter)
	assert(node, "in function 'scene:update_nodes' node does not exist.")
	environment._shader_cache_object = nil
	renderstates = renderstates or temp_renderstate
	filter = filter or default_filter
	self:_recursive_render_nodes(node, false)
	table.sort(self.list_drawable_nodes, node_sort)

	lovg.push()
	temp_environment = environment
	local camera = temp_environment.camera

	if camera._camera_2d_mode then
		camera:_apply_transform()
	end

	local canvases = #renderstates > 0

	local prev_canvas = love.graphics.getCanvas()
	if canvases then
		lovg.setCanvas(renderstates)
	end

	if renderstates.clear then
		if renderstates.colors then
			lovg.clear(unpack(renderstates.colors))
		else
			lovg.clear()
		end
	end

	for _, n in ipairs(self.list_drawable_nodes) do
		filter(n, self, temp_environment)
	end

	if canvases then
		love.graphics.setCanvas(prev_canvas)
	end

	lovg.pop()
	love.graphics.setShader()

	local count = #self.list_drawable_nodes
	self.list_drawable_nodes = {}

	return count
end

function scene:_recursive_render_nodes(parent_node, transform_flag)
	if parent_node._transform_flag or transform_flag then
		parent_node:update_transform()
		transform_flag = true
	end
	if parent_node.render and parent_node.render_flag then
		table.insert(self.list_drawable_nodes, parent_node)
	end
	local i = 1
	local children = parent_node.children
	while i <= #children do
		local node = children[i]
		self:_recursive_render_nodes(node, transform_flag)
		i = i + 1
	end
end

--- Recursively call update function for every node.
-- @tparam Node node
-- @tparam Environment environment
function scene:update_nodes(node, environment)
	assert(node, "in function 'scene:update_nodes' node does not exist.")
	temp_environment = environment
	self:_recursive_update_nodes(node)
end

function scene:_recursive_update_nodes(parent_node)
	if parent_node.update_flag then
		if parent_node.update then
			parent_node:update(self, temp_environment)
		end

		local i = 1
		local children = parent_node.children
		while i <= #children do
			local node = children[i]
			if node.detach_flag then
				table.remove(children, i)
			else
				self:_recursive_update_nodes(node)
				i = i + 1
			end
		end
	end
end

function scene:render()
	
end

function scene:update()
	
end

return scene