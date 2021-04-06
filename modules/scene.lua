--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

--- Base class of Scenes.
--- Inherit this class for your scenes.
-- @module Scene
local class 		= require('menori.modules.libs.class')

local lovg = love.graphics
local temp_environment

local temp_renderstate = { clear = true }

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
	self.render_time = 0
end

function scene:current_render_time()
	return self.render_time
end

--- Recursively calls render on all nodes.
function scene:render_nodes(node, environment, renderstates, filter)
	renderstates = renderstates or temp_renderstate
	self.render_time = love.timer.getTime()
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
	if parent_node.local_matrix:is_changed() or transform_flag then
		parent_node:update_local_transform()
		transform_flag = true
	end
	if parent_node.render and parent_node.render_flag then
		table.insert(self.list_drawable_nodes, parent_node)
	end
	local i = 1
	local childs = parent_node._childs
	while i <= #childs do
		local node = childs[i]
		self:_recursive_render_nodes(node, transform_flag)
		i = i + 1
	end
end

--- Recursively calls update on all nodes.
function scene:update_nodes(node, environment)
	temp_environment = environment
	self:_recursive_update_nodes(node)
end

function scene:_recursive_update_nodes(parent_node)
	if parent_node.update_flag then
		if parent_node.update then
			parent_node:update(self, temp_environment)
		end

		local i = 1
		local childs = parent_node._childs
		while i <= #childs do
			local node = childs[i]
			if node.detach_flag then
				table.remove(childs, i)
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