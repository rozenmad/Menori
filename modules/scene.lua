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

--- Recursively calls render on all nodes.
function scene:render_nodes(node, environment, renderstates, filter)
	renderstates = renderstates or {}
	filter = filter or default_filter
	self:_recursive_render_nodes(node, false)
	table.sort(self.list_drawable_nodes, node_sort)

	lovg.push()
	temp_environment = environment
	local camera = temp_environment.camera

	if camera.mode == '2d' then
		camera:_push_transform()
	end

	if renderstates then
		local prev_canvas = love.graphics.getCanvas()
		lovg.setCanvas(renderstates)
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
		love.graphics.setCanvas(prev_canvas)
	else
		for _, n in ipairs(self.list_drawable_nodes) do
			filter(n, self, temp_environment)
		end
	end

	lovg.pop()

	local count = #self.list_drawable_nodes
	self.list_drawable_nodes = {}

	return count
end

function scene:_recursive_render_nodes(parent_node, transform_flag)
	if parent_node.local_matrix:is_changed() or transform_flag then
		parent_node:update_local_transform()
		transform_flag = true
	end
	local i = 1
	local childs = parent_node._childs
	while i <= #childs do
		local node = childs[i]
		if node.detach_flag then
			table.remove(childs, i)
		else
			if node.render and node.render_flag then self.list_drawable_nodes[#self.list_drawable_nodes + 1] = node end
			self:_recursive_render_nodes(node, transform_flag)
			i = i + 1
		end
	end
end

--- Recursively calls update on all nodes.
function scene:update_nodes(node, environment)
	temp_environment = environment
	self:_recursive_update_nodes(node, true)
end

function scene:_recursive_update_nodes(parent_node, update_flag)
	for _, node in ipairs(parent_node._childs) do
		if not node.update_flag then update_flag = false end

		if node.update and update_flag then
			node:update(self, temp_environment)
		end
		self:_recursive_update_nodes(node, update_flag)
	end
end

function scene:render()
	
end

function scene:update()
	
end

return scene