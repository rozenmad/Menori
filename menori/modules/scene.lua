--[[
-------------------------------------------------------------------------------
      Menori
      @author rozenmad
      2022
-------------------------------------------------------------------------------
]]

--[[--
Base class of scenes.
It contains methods for recursively drawing and updating nodes.
You need to inherit from the Scene class to create your own scene object.
]]
--- @classmod Scene

local modules = (...):match('(.*%menori.modules.)')
local class = require (modules .. 'libs.class')

local lovg = love.graphics
local temp_environment

local temp_renderstates = { clear = false }

local function layer_comp(a, b)
      return a.layer < b.layer
end

local priorities = {OPAQUE = 0, MASK = 1, BLEND = 2}
local function alpha_mode_comp(a, b)
      return priorities[a.material.alpha_mode] < priorities[b.material.alpha_mode]
end

local function default_filter(node, scene, environment)
      node:render(scene, environment)
end

local scene = class('Scene')

scene.alpha_mode_comp = alpha_mode_comp
scene.layer_comp = layer_comp

--- The public constructor.
function scene:init()
      self.list_drawable_nodes = {}
end

--- Recursive node render function.
-- @tparam menori.Node node
-- @tparam menori.Environment environment
-- @tparam[opt] table renderstates
-- @tparam[opt] function filter The callback function.
-- @usage renderstates = { canvas, ..., clear = true, colors = {color, ...} }
-- @usage function default_filter(node, scene, environment) node:render(scene, environment) end
function scene:render_nodes(node, environment, renderstates, filter)
      assert(node, "in function 'scene:render_nodes' node does not exist.")

      lovg.push('all')

      environment._shader_object_cache = nil
      renderstates = renderstates or temp_renderstates
      filter = filter or default_filter
      self:_recursive_render_nodes(node, false)
      table.sort(self.list_drawable_nodes, renderstates.node_sort_comp or layer_comp)

      local camera = environment.camera
      if camera._camera_2d_mode then
            camera:_apply_transform()
      end

      local canvases = #renderstates > 0

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

      for _, v in ipairs(self.list_drawable_nodes) do
            filter(v, self, environment)
      end
      lovg.pop()

      local count = #self.list_drawable_nodes
      self.list_drawable_nodes = {}

      return count
end

function scene:_recursive_render_nodes(node, transform_flag)
      if not node.render_flag then
            return
      end
      if node._transform_flag or transform_flag then
            node:update_transform()
            transform_flag = true
      end

      if node.render then
            table.insert(self.list_drawable_nodes, node)
      end

      for _, v in ipairs(node.children) do
            self:_recursive_render_nodes(v, transform_flag)
      end
end

--- Recursive node update function.
-- @tparam Node node
-- @tparam Environment environment
function scene:update_nodes(node, environment)
      assert(node, "in function 'scene:update_nodes' node does not exist.")
      temp_environment = environment
      self:_recursive_update_nodes(node)
end

function scene:_recursive_update_nodes(node)
      if not node.update_flag then
            return
      end

      if node.update then
            node:update(self, temp_environment)
      end

      local i = 1
      local children = node.children
      while i <= #children do
            local child = children[i]
            if child.detach_flag then
                  table.remove(children, i)
            else
                  self:_recursive_update_nodes(child)
                  i = i + 1
            end
      end
end

function scene:render()
      
end

function scene:update()
      
end

return scene