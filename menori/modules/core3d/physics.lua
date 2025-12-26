--[[
-------------------------------------------------------------------------------
	Menori
	@author Max-Dil
	2025
-------------------------------------------------------------------------------
]]

local modules = (...):match('(.*%menori.modules.)')

local class        = require (modules .. 'libs.class')
local ml           = require (modules .. 'ml')
local vertexformat = require (modules .. 'core3d.shapes.vertexformat')
local ModelNode    = require (modules .. 'core3d.model_node')

local Box      = require(modules .. 'core3d.shapes.box')
local Sphere   = require(modules .. 'core3d.shapes.sphere')
local Triangle = require(modules .. 'core3d.shapes.triangle')
local Plane    = require(modules .. 'core3d.shapes.plane')
local Capsule  = require(modules .. 'core3d.shapes.capsule')

local vec3      = ml.vec3
local mat4      = ml.mat4
local bound3    = ml.bound3
local intersect = ml.intersect
local bvh       = ml.bvh
local quat      = ml.quat

local BoxModel = ModelNode:extend('BoxModel')
function BoxModel:init(x, y, z, w, h, d)
	BoxModel.super.init(self, Box(w, h, d))

	self:set_position(x, y, z)
	self.is_box = true
end

local SphereModel = ModelNode:extend('SphereModel')
function SphereModel:init(x, y, z, radius)
	SphereModel.super.init(self, Sphere(radius))
	self:set_position(x, y, z)
	self.is_sphere = true
	self.radius = radius
end

local TriangleModel = ModelNode:extend('TriangeModel')
function TriangleModel:init(x, y, z, v1, v2, v3)
	TriangleModel.super.init(self, Triangle(v1, v2, v3))
	self:set_position(x, y, z)
	self.is_capsule = true
    self.v1 = v1
    self.v2 = v2
    self.v3 = v3
end

local PlaneModel = ModelNode:extend('PlaneModel')
function PlaneModel:init(x, y, z, width, height, v_segments, h_segments)
	PlaneModel.super.init(self, Plane(width, height, v_segments, h_segments))
	self:set_position(x, y, z)
	self.is_capsule = true
    self.width = width
    self.height = height
    self.v_segments = v_segments
    h_segments = h_segments
end

local CapsuleModel = ModelNode:extend('CapsuleModel')
function CapsuleModel:init(x, y, z, radius, height)
	CapsuleModel.super.init(self, Capsule(radius, height))
	self:set_position(x, y, z)
	self.is_capsule = true
	self.radius = radius
	self.height = height
end


local Shape = class('Shape')

function Shape:init(model)
    self.model = model
end

local Body = class('Body')

function Body:init(world, x, y, z, body_type)
    self.world            = world
    self.x                = x
    self.y                = y

    self.body_type        = body_type or "dynamic"
    self.mass             = body_type == "static" and 0 or 1
    self.inverse_mass     = body_type == "static" and 0 or 1
    self.restitution      = 0.5
    self.friction         = 0.3

    self.shapes           = {}
    self.matrix           = mat4()
    self.aabb             = bound3()

    self.position         = vec3(x or 0, y or 0, z or 0)
    self.rotation         = quat()
    self.velocity         = vec3()
    self.angular_velocity = vec3()
    self.force            = vec3()
    self.torque           = vec3()

    world:add_body(self)
end

function Body:add_shape(shape)
    table.insert(self.shapes, shape)
end

local World = class('World')

function World:init(gravity_x, gravity_y, gravity_z, sleep)
    self.gravity                  = vec3(gravity_x or 0, gravity_y or -9.81, gravity_z or 0)
    self.sleep                    = sleep

    self.static_bvh               = nil
    self.dynamic_bvh_nodes        = {}

    self._static_bodies           = {}
    self._dynamic_bodies          = {}
    self._broadphase_pairs        = {}

    self._need_static_bvh_rebuild = false
end

function World:add_body(body)
    if body.body_type == 'static' then
        table.insert(self._static_bodies, body)
        self._need_static_bvh_rebuild = true
    else
        table.insert(self._dynamic_bodies, body)
    end
end

function World:_rebuild_static_bvh()
    if not self._need_static_bvh_rebuild then return end

    local static_nodes = {}

    for i_b = #self._static_bodies, 1, -1 do
        local body = self._static_bodies[i_b]

        if body.shapes[1] then
            local aabb = bound3()

            for i_s = #body.shapes, 1, -1 do
                local shape = body.shapes[i_s]

                local shape_aabb = shape:get_aabb()

                local transformed_min = body.matrix:multiply_vec3(shape_aabb.min)
                local transformed_max = body.matrix:multiply_vec3(shape_aabb.max)

                aabb.min = vec3.min(aabb.min, transformed_min)
                aabb.max = vec3.max(aabb.max, transformed_max)
            end

            table.insert(static_nodes, {
                aabb = aabb,
                body = body,
                index = i_b
            })
        end
    end

    if static_nodes[1] then
        print(#static_nodes)
    else
        self.static_bvh = nil
    end

    self._need_static_bvh_rebuild = false
end

function World:step(dt)
    
end

local Physics = class('Physics')

function Physics:init()
    self.box      = BoxModel
    self.capsule  = CapsuleModel
    self.plane    = PlaneModel
    self.sphere   = SphereModel
    self.triangle = TriangleModel

    self.world    = World
    self.body     = Body
end

return Physics