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

function Body(self, body_type)
    self.body_type        = body_type or 'static'
    self.mass             = 1
    self.inv_mass         = (body_type == 'static') and 0 or 1
    self.restitution      = 0.5
    self.friction         = 0.3
    self.is_sleeping      = false
    self.use_gravity      = true

    self.velocity         = vec3()
    self.angular_velocity = vec3()
    self.force            = vec3()
    self.torque           = vec3()

    function self:set_body_type(body_type)
        self.inv_mass = (body_type == 'static') and 0 or (1 / self.mass)
        if body_type ~= self.body_type then
            if self.body_type == 'dynamic' then
                for index, body in ipairs(self.world.bodies) do
                    if body == self then
                        table.remove(self.world.bodies, index)
                        break
                    end
                end
            else
                for index, body in ipairs(self.world.static_bodies) do
                    if body == self then
                        table.remove(self.world.static_bodies, index)
                        break
                    end
                end
            end
            if body_type == 'dynamic' then
                table.insert(self.world.bodies, self)
                self.force.y = self.world.gravity.y * self.mass
            else
                table.insert(self.world.static_bodies, self)
            end
        end
        self.body_type = body_type
    end

    function self:apply_force(fx, fy, fz)
        self.force.x = self.force.x + fx
        self.force.y = self.force.y + fy
        self.force.z = self.force.z + fz
        self.is_sleeping = false
    end

    function self:set_velocity(vx, vy, vz)
        self.velocity.x = vx
        self.velocity.y = vy
        self.velocity.z = vz
        self.is_sleeping = false
    end

    function self:get_hemisphere_centers() -- получения центра полусфер капсулы
        if self.is_capsule then
            local half = self.height * 0.5
            local mat = self.world_matrix
            local p0_world = mat:multiply_vec3(vec3(0, -half, 0))
            local p1_world = mat:multiply_vec3(vec3(0, half, 0))
            return p0_world, p1_world
        end
        return self:get_world_position(), self:get_world_position()
    end

    function self:get_world_position()
        return self:get_world_position()
    end
end

local BoxModel = ModelNode:extend('BoxModel')
function BoxModel:init(w, h, d)
	BoxModel.super.init(self, Box(w, h, d))
	self.w = w
    self.h = h
    self.d = d
    self.is_box = true
    Body(self, 'static')
end

local SphereModel = ModelNode:extend('SphereModel')
function SphereModel:init(radius)
	SphereModel.super.init(self, Sphere(radius))
	self.radius = radius
    self.is_sphere = true
    Body(self, 'static')
end

local PlaneModel = ModelNode:extend('PlaneModel')
function PlaneModel:init(width, height, v_segments, h_segments)
	PlaneModel.super.init(self, Plane(width, height, v_segments, h_segments))
	self.width = width
    self.height = height
    self.v_segments = v_segments
    self.h_segments = h_segments
    self.is_plane = true
    Body(self, 'static')
end

local CapsuleModel = ModelNode:extend('CapsuleModel')
function CapsuleModel:init(radius, height)
	CapsuleModel.super.init(self, Capsule(radius, height))
	self.is_capsule = true
	self.radius = radius
	self.height = height
    Body(self, 'static')
end

local TriangleModel = ModelNode:extend('TriangleModel')
function TriangleModel:init(v1, v2, v3)
	TriangleModel.super.init(self, Triangle(v1, v2, v3))
	self.v1 = v1
    self.v2 = v2
    self.v3 = v3
    self.is_triangle = true
    Body(self, 'static')
end

local World = class('World')

function World:init(gravity_y, sleep)
    self.gravity       = vec3(0, gravity_y or -9.81, 0)
    self.sleep         = sleep
    self.bodies        = {}
    self.static_bodies = {}
    self.iterations    = 3
end

function World:add_body(body)
    if body.body_type == 'dynamic' then
        table.insert(self.bodies, body)
        body.force.y = self.gravity.y * body.mass
    else
        table.insert(self.static_bodies, body)
    end
    body.world = self
end

function World:remove_body(body)
    for i, v in ipairs(self.bodies) do
        if v == body then
            table.remove(self.bodies, i)
            body.world = nil
            break
        end
    end
end

function World:step(dt)
    for _, body in ipairs(self.bodies) do
        if not body.is_sleeping then
            if body.use_gravity then
                body.force.y = body.force.y + self.gravity.y * body.mass
            end

            -- скорость (F = ma => a = F/m, v = v0 + a*dt)
            body.velocity.x = body.velocity.x + body.force.x * body.inv_mass * dt
            body.velocity.y = body.velocity.y + body.force.y * body.inv_mass * dt
            body.velocity.z = body.velocity.z + body.force.z * body.inv_mass * dt

            -- сопротивление воздуха
            body.velocity.x = body.velocity.x * 0.99
            body.velocity.y = body.velocity.y * 0.99
            body.velocity.z = body.velocity.z * 0.99

            -- позиция
            local pos = body.position
            body:set_position(
                pos.x + body.velocity.x * dt,
                pos.y + body.velocity.y * dt,
                pos.z + body.velocity.z * dt
            )

            body.force.x = 0
            body.force.y = 0
            body.force.z = 0
        end
    end

    self:_resolve_collisions()
end

function World:_resolve_collisions()
    for i, body_a in ipairs(self.bodies) do
        for j, body_b in ipairs(self.static_bodies) do
            local collision = self:_check_collision(body_a, body_b)
            if collision then
                self:_resolve_collision(body_a, body_b, collision)
            end
        end
    end
end

function World:_resolve_collision(body_a, body_b, collision)
    if body_a.inv_mass == 0 then
        return
    end

    local nx, ny, nz = collision.normal[1], collision.normal[2], collision.normal[3]

    -- отталкивание
    local pos = body_a.position
    body_a:set_position(
        pos.x + nx * collision.depth,
        pos.y + ny * collision.depth,
        pos.z + nz * collision.depth
    )

    -- отражение скорости
    local dot_product = body_a.velocity.x * nx + body_a.velocity.y * ny + body_a.velocity.z * nz
    if dot_product < 0 then
        body_a.velocity.x = body_a.velocity.x - nx * dot_product * (1 + body_a.restitution)
        body_a.velocity.y = body_a.velocity.y - ny * dot_product * (1 + body_a.restitution)
        body_a.velocity.z = body_a.velocity.z - nz * dot_product * (1 + body_a.restitution)
    end

    -- трение
    body_a.velocity.x = body_a.velocity.x * (1 - body_a.friction)
    body_a.velocity.z = body_a.velocity.z * (1 - body_a.friction)
end

function World:_check_collision(body_a, body_b)
    local aabb_a = body_a:get_aabb()
    local aabb_b = body_b:get_aabb()

    if not intersect.aabb_aabb(aabb_a, aabb_b) then
        return nil
    end

    if body_a.is_box and body_b.is_box then
        return intersect.aabb_aabb_collision(aabb_a, aabb_b)
    end

    if body_a.is_sphere and body_b.is_sphere then
        return intersect.sphere_sphere(
            body_a:get_world_position(),
            body_a.radius,
            body_b:get_world_position(),
            body_b.radius
        )
    end

    if body_a.is_sphere and body_b.is_box then
        return intersect.sphere_aabb(
            body_a:get_world_position(),
            body_a.radius,
            aabb_b
        )
    end

    if body_a.is_sphere and body_b.is_plane then
        local sphere_pos = body_a:get_world_position()
        local plane_pos = body_b:get_world_position()

        if sphere_pos.y - body_a.radius < plane_pos.y + 0.5 then
            return {
                normal = {0, 1, 0},
                depth = (plane_pos.y + 0.1) - (sphere_pos.y - body_a.radius),
                point = {sphere_pos.x, plane_pos.y + 0.5, sphere_pos.z}
            }
        end
    end

    if body_a.is_capsule and body_b.is_plane then
        local p0, p1 = body_a:get_hemisphere_centers()
        local plane_pos = body_b:get_world_position()

        local bottom = math.min(p0.y, p1.y) - body_a.radius
        if bottom < plane_pos.y + 0.5 then
            return {
                normal = {0, 1, 0},
                depth = (plane_pos.y + 0.1) - bottom,
                point = {p0.x, plane_pos.y + 0.5, p0.z}
            }
        end
    end

    return {
        normal = {0, 1, 0},
        depth = 0.01,
        point = {
            (aabb_a.min.x + aabb_a.max.x) * 0.5,
            math.min(aabb_a.min.y, aabb_b.min.y),
            (aabb_a.min.z + aabb_a.max.z) * 0.5
        }
    }
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