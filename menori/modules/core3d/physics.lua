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
local ModelNode    = require (modules .. 'core3d.model_node')

local Box      = require(modules .. 'core3d.shapes.box')
local Sphere   = require(modules .. 'core3d.shapes.sphere')
local Triangle = require(modules .. 'core3d.shapes.triangle')
local Plane    = require(modules .. 'core3d.shapes.plane')
local Capsule  = require(modules .. 'core3d.shapes.capsule')

local SHAPE = {
    BOX = 1,
    CAPSULE = 2,
    PLANE = 3,
    SPHERE = 4,
    TRIANGLE = 5
}

local vec3      = ml.vec3
local intersect = ml.intersect

function Body(self, body_type)
    self.body_type        = body_type or 'static'
    self.mass             = 1
    self.inv_mass         = (body_type == 'static') and 0 or 1
    self.restitution      = 0.5
    self.friction         = 0.3
    self.is_sleeping      = false
    self.sleep_timer      = 1
    self.use_gravity      = true

    self.velocity         = vec3()
    self.force            = vec3()

    function self:update_aabb()
        self.aabb = self:get_aabb()
    end

    local _set_position = self.set_position
    function self:set_position(x, y, z)
        _set_position(self, x, y, z)
        self:update_aabb()
    end

    local _set_rotation = self.set_rotation
    function self:set_rotation(q)
        _set_rotation(self, q)
        self:update_aabb()
    end

    local _set_scale = self.set_scale
    function self:set_scale(sx, sy, sz)
        _set_scale(self, sx, sy, sz)
        self:update_aabb()
    end

    function self:set_body_type(body_type)
        self.inv_mass = (body_type == 'static') and 0 or (1 / self.mass)
        if body_type ~= self.body_type then
            for index, body in ipairs(self.world.bodies) do
                if body == self then
                    table.remove(self.world.bodies, index)
                    break
                end
            end
            if body_type == 'dynamic' then
                self.force.y = self.world.gravity.y * self.mass
            end
            table.insert(self.world.bodies, self)
        end
        self.body_type = body_type
    end

    function self:set_friction(friction)
        self.friction = friction
    end

    function self:set_mass(mass)
        self.mass = mass
    end

    function self:set_inverse_mass(inverse_mass)
        self.inv_mass = inverse_mass
    end

    function self:set_restitution(restitution)
        self.restitution = restitution
    end

    function self:set_awake(awake)
        self.is_sleeping = awake
        if not awake then
            self.sleep_timer = 1
        end
    end

    function self:apply_force(fx, fy, fz)
        self.force.x = self.force.x + fx
        self.force.y = self.force.y + fy
        self.force.z = self.force.z + fz
    end

    function self:set_velocity(vx, vy, vz)
        self.velocity.x = vx
        self.velocity.y = vy
        self.velocity.z = vz
    end

    function self:remove()
        if self.parent then
            self.parent:detach(self)
        end
        self:remove_children()
        if self.world then
            self.world:remove_body(self)
        end
    end

    function self:resolve_collision(collision)
        if self.inv_mass == 0 then
            return
        end

        local nx, ny, nz = collision.normal[1], collision.normal[2], collision.normal[3]

        local pos = self.position
        self:set_position(
            pos.x + nx * collision.depth,
            pos.y + ny * collision.depth,
            pos.z + nz * collision.depth
        )

        local dot_product = self.velocity.x * nx + self.velocity.y * ny + self.velocity.z * nz
        if dot_product < 0 then
            self.velocity.x = self.velocity.x - nx * dot_product * (1 + self.restitution)
            self.velocity.y = self.velocity.y - ny * dot_product * (1 + self.restitution)
            self.velocity.z = self.velocity.z - nz * dot_product * (1 + self.restitution)
        end

        self.velocity.x = self.velocity.x * (1 - self.friction)
        self.velocity.z = self.velocity.z * (1 - self.friction)
    end
end

local BoxModel = ModelNode:extend('BoxModel')
function BoxModel:init(w, h, d)
	BoxModel.super.init(self, Box(w, h, d))
	self.w = w
    self.h = h
    self.d = d
    self.is_box = true
    self.shape_id = SHAPE.BOX
    Body(self, 'static')
end

local CapsuleModel = ModelNode:extend('CapsuleModel')
function CapsuleModel:init(radius, height)
	CapsuleModel.super.init(self, Capsule(radius, height))
	self.is_capsule = true
	self.radius = radius
	self.height = height
    self.shape_id = SHAPE.CAPSULE

    function self:update_capsule_points()
        local half = self.height * 0.5
        local mat = self.world_matrix
        self.p0 = mat:multiply_vec3(vec3(0, -half, 0))
        self.p1 = mat:multiply_vec3(vec3(0, half, 0))
    end

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
    self.shape_id = SHAPE.PLANE
    Body(self, 'static')
end

local SphereModel = ModelNode:extend('SphereModel')
function SphereModel:init(radius)
	SphereModel.super.init(self, Sphere(radius))
	self.radius = radius
    self.is_sphere = true
    self.shape_id = SHAPE.SPHERE
    Body(self, 'static')
end

local TriangleModel = ModelNode:extend('TriangleModel')
function TriangleModel:init(v1, v2, v3)
	TriangleModel.super.init(self, Triangle(v1, v2, v3))
	self.v1 = v1
    self.v2 = v2
    self.v3 = v3
    self.is_triangle = true
    self.shape_id = SHAPE.TRIANGLE
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
        body.force.y = self.gravity.y * body.mass
    end
    table.insert(self.bodies, body)
    body.world = self
end

function World:remove_body(body)
    for index, v_body in ipairs(self.bodies) do
        if v_body == body then
            table.remove(self.bodies, index)
            break
        end
    end
    body.world = nil
end

function World:step(dt)
    for _, body in ipairs(self.bodies) do
        if not body.is_sleeping then
            if body.use_gravity then
                body.force.y = body.force.y + self.gravity.y * body.mass
            end

            -- F = ma => a = F/m, v = v0 + a*dt
            body.velocity.x = body.velocity.x + body.force.x * body.inv_mass * dt
            body.velocity.y = body.velocity.y + body.force.y * body.inv_mass * dt
            body.velocity.z = body.velocity.z + body.force.z * body.inv_mass * dt

            body.velocity.x = body.velocity.x * 0.99
            body.velocity.y = body.velocity.y * 0.99
            body.velocity.z = body.velocity.z * 0.99

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

    self:_resolve_collisions(dt)
end

function World:_resolve_collisions(dt)
    table.sort(self.bodies, function (a, b)
        return a.aabb.min.x < b.aabb.min.x
    end)

    local l = #self.bodies

    for i = 1, l do
        local body_a = self.bodies[i]
        for i2 = i + 1, l do
            local body_b = self.bodies[i2]

            if body_a.aabb.min.x > body_b.aabb.max.x then
                break
            end

            local collision = self:_check_collision(body_a, body_b)
            if collision then
                body_a:resolve_collision(collision)
                if body_b.inv_mass ~= 0 then
                    collision.normal[1] = -collision.normal[1]
                    collision.normal[2] = -collision.normal[2]
                    collision.normal[3] = -collision.normal[3]
                    body_b:resolve_collision(collision)
                end
            end
        end

        if self.sleep and body_a.body_type == 'dynamic' then
            local velocity = body_a.velocity.x + body_a.velocity.y + body_a.velocity.z
            if velocity < 0.01 and velocity > -0.01 then
                body_a.sleep_timer = body_a.sleep_timer - dt
                if body_a.sleep_timer < 0 then
                    body_a.is_sleeping = true
                end
            else
                body_a.sleep_timer = 1
                body_a.is_sleeping = false
            end
        end
    end
end

local collison_handlers = {
    [SHAPE.BOX] = {
        [SHAPE.BOX] = function (aabb_a, aabb_b, body_a, body_b)
            return intersect.aabb_aabb_collision(aabb_a, aabb_b)
        end,
        [SHAPE.CAPSULE] = function (aabb_a, aabb_b, body_a, body_b)
            body_b:update_capsule_points()
            return intersect.capsule_aabb(body_b.p0, body_b.p1, body_b.radius, aabb_a)
        end,
        [SHAPE.PLANE] = function (aabb_a, aabb_b, body_a, body_b)
            return intersect.aabb_aabb_collision(aabb_a, aabb_b)
        end,
        [SHAPE.SPHERE] = function (aabb_a, aabb_b, body_a, body_b)
            return intersect.sphere_aabb(body_b.position, body_b.radius, aabb_a)
        end,
        [SHAPE.TRIANGLE] = function (aabb_a, aabb_b, body_a, body_b)
            return intersect.aabb_aabb_collision(aabb_a, aabb_b)
        end
    },
    [SHAPE.CAPSULE] = {
        [SHAPE.BOX] = function (aabb_a, aabb_b, body_a, body_b)
            body_a:update_capsule_points()
            local hit = intersect.capsule_aabb(body_a.p0, body_a.p1, body_a.radius, aabb_b)
            if hit then
                local hit_point = vec3(hit.point[1], hit.point[2], hit.point[3])
                local capsule_center = (body_a.p0 + body_a.p1) * 0.5
                local to_capsule = (capsule_center - hit_point):normalize()
                local normal = vec3(hit.normal[1], hit.normal[2], hit.normal[3])
                if vec3.dot(normal, to_capsule) < 0 then
                    normal = -normal
                end
                return {
                    normal = {normal.x, normal.y, normal.z},
                    depth = hit.depth,
                    point = {hit_point.x, hit_point.y, hit_point.z}
                }
            end
        end,
        [SHAPE.CAPSULE] = function (aabb_a, aabb_b, body_a, body_b)
            body_a:update_capsule_points()
            body_b:update_capsule_points()
            local hit = intersect.capsule_capsule(body_a.p0, body_a.p1, body_a.radius, body_b.p0, body_b.p1, body_b.radius)
            if hit then
                local hit_point = vec3(hit.point[1], hit.point[2], hit.point[3])
                local capsule_center = (body_a.p0 + body_a.p1) * 0.5
                local to_capsule = (capsule_center - hit_point):normalize()
                local normal = vec3(hit.normal[1], hit.normal[2], hit.normal[3])
                if vec3.dot(normal, to_capsule) < 0 then
                    normal = -normal
                end
                return {
                    normal = {normal.x, normal.y, normal.z},
                    depth = hit.depth,
                    point = {hit_point.x, hit_point.y, hit_point.z}
                }
            end
        end,
        [SHAPE.PLANE] = function (aabb_a, aabb_b, body_a, body_b)
            body_a:update_capsule_points()
            local hit = intersect.capsule_aabb(body_a.p0, body_a.p1, body_a.radius, aabb_b)
            if hit then
                local hit_point = vec3(hit.point[1], hit.point[2], hit.point[3])
                local capsule_center = (body_a.p0 + body_a.p1) * 0.5
                local to_capsule = (capsule_center - hit_point):normalize()
                local normal = vec3(hit.normal[1], hit.normal[2], hit.normal[3])
                if vec3.dot(normal, to_capsule) < 0 then
                    normal = -normal
                end
                return {
                    normal = {normal.x, normal.y, normal.z},
                    depth = hit.depth,
                    point = {hit_point.x, hit_point.y, hit_point.z}
                }
            end
        end,
        [SHAPE.SPHERE] = function (aabb_a, aabb_b, body_a, body_b)
            body_a:update_capsule_points()
            local hit = intersect.capsule_sphere(body_a.p0, body_a.p1, body_a.radius, body_b.position, body_b.radius)
            if hit then
                local hit_point = vec3(hit.point[1], hit.point[2], hit.point[3])
                local capsule_center = (body_a.p0 + body_a.p1) * 0.5
                local to_capsule = (capsule_center - hit_point):normalize()
                local normal = vec3(hit.normal[1], hit.normal[2], hit.normal[3])
                if vec3.dot(normal, to_capsule) < 0 then
                    normal = -normal
                end
                return {
                    normal = {normal.x, normal.y, normal.z},
                    depth = hit.depth,
                    point = {hit_point.x, hit_point.y, hit_point.z}
                }
            end
        end,
        [SHAPE.TRIANGLE] = function (aabb_a, aabb_b, body_a, body_b)
            body_a:update_capsule_points()
            local mat_b = body_b.world_matrix
            local world_v1 = mat_b:multiply_vec3(vec3(body_b.v1[1], body_b.v1[2], body_b.v1[3]))
            local world_v2 = mat_b:multiply_vec3(vec3(body_b.v2[1], body_b.v2[2], body_b.v2[3]))
            local world_v3 = mat_b:multiply_vec3(vec3(body_b.v3[1], body_b.v3[2], body_b.v3[3]))
            local triangle_vertices = {
                {world_v1.x, world_v1.y, world_v1.z},
                {world_v2.x, world_v2.y, world_v2.z},
                {world_v3.x, world_v3.y, world_v3.z}
            }
            local hit = intersect.capsule_triangle(body_a.p0, body_a.p1, body_a.radius, triangle_vertices)
            if hit then
                local hit_point = vec3(hit.point[1], hit.point[2], hit.point[3])
                local capsule_center = (body_a.p0 + body_a.p1) * 0.5
                local to_capsule = (capsule_center - hit_point):normalize()
                local normal = vec3(hit.normal[1], hit.normal[2], hit.normal[3])
                if vec3.dot(normal, to_capsule) < 0 then
                    normal = -normal
                end
                return {
                    normal = {normal.x, normal.y, normal.z},
                    depth = hit.depth,
                    point = {hit_point.x, hit_point.y, hit_point.z}
                }
            end
        end
    },
    [SHAPE.PLANE] = {
        [SHAPE.BOX] = function (aabb_a, aabb_b, body_a, body_b)
            return intersect.aabb_aabb_collision(aabb_a, aabb_b)
        end,
        [SHAPE.CAPSULE] = function (aabb_a, aabb_b, body_a, body_b)
            body_b:update_capsule_points()
            return intersect.capsule_aabb(body_b.p0, body_b.p1, body_b.radius, aabb_a)
        end,
        [SHAPE.PLANE] = function (aabb_a, aabb_b, body_a, body_b)
            return intersect.aabb_aabb_collision(aabb_a, aabb_b)
        end,
        [SHAPE.SPHERE] = function (aabb_a, aabb_b, body_a, body_b)
            return intersect.sphere_aabb(body_b.position, body_b.radius, aabb_a)
        end,
        [SHAPE.TRIANGLE] = function (aabb_a, aabb_b, body_a, body_b)
            return intersect.aabb_aabb_collision(aabb_a, aabb_b)
        end
    },
    [SHAPE.SPHERE] = {
        [SHAPE.BOX] = function (aabb_a, aabb_b, body_a, body_b)
            return intersect.sphere_aabb( body_a.position, body_a.radius, aabb_b)
        end,
        [SHAPE.CAPSULE] = function (aabb_a, aabb_b, body_a, body_b)
            body_b:update_capsule_points()
            return intersect.capsule_sphere(body_b.p0, body_b.p1, body_b.radius, body_a.position, body_a.radius)
        end,
        [SHAPE.PLANE] = function (aabb_a, aabb_b, body_a, body_b)
            return intersect.sphere_aabb( body_a.position, body_a.radius, aabb_b)
        end,
        [SHAPE.SPHERE] = function (aabb_a, aabb_b, body_a, body_b)
            return intersect.sphere_aabb( body_b.position, body_b.radius, aabb_a)
        end,
        [SHAPE.TRIANGLE] = function (aabb_a, aabb_b, body_a, body_b)
            return intersect.sphere_aabb( body_a.position, body_a.radius, aabb_b)
        end
    },
    [SHAPE.TRIANGLE] = {
        [SHAPE.BOX] = function (aabb_a, aabb_b, body_a, body_b)
            return intersect.sphere_aabb( body_a.position, body_a.radius, aabb_b)
        end,
        [SHAPE.CAPSULE] = function (aabb_a, aabb_b, body_a, body_b)
            body_b:update_capsule_points()
            local mat_a = body_a.world_matrix
            local world_v1 = mat_a:multiply_vec3(vec3(body_a.v1[1], body_a.v1[2], body_a.v1[3]))
            local world_v2 = mat_a:multiply_vec3(vec3(body_a.v2[1], body_a.v2[2], body_a.v2[3]))
            local world_v3 = mat_a:multiply_vec3(vec3(body_a.v3[1], body_a.v3[2], body_a.v3[3]))
            local triangle_vertices = {
                {world_v1.x, world_v1.y, world_v1.z},
                {world_v2.x, world_v2.y, world_v2.z},
                {world_v3.x, world_v3.y, world_v3.z}
            }
            local hit = intersect.capsule_triangle(body_b.p0, body_b.p1, body_b.radius, triangle_vertices)
            if hit then
                local hit_point = vec3(hit.point[1], hit.point[2], hit.point[3])
                local capsule_center = (body_b.p0 + body_b.p1) * 0.5
                local to_capsule = (capsule_center - hit_point):normalize()
                local normal = vec3(hit.normal[1], hit.normal[2], hit.normal[3])
                if vec3.dot(normal, to_capsule) > 0 then
                    normal = -normal
                end
                return {
                    normal = {normal.x, normal.y, normal.z},
                    depth = hit.depth,
                    point = {hit_point.x, hit_point.y, hit_point.z},
                }
            end
        end,
        [SHAPE.PLANE] = function (aabb_a, aabb_b, body_a, body_b)
            return intersect.aabb_aabb_collision(aabb_a, aabb_b)
        end,
        [SHAPE.SPHERE] = function (aabb_a, aabb_b, body_a, body_b)
            return intersect.sphere_aabb( body_b.position, body_b.radius, aabb_a)
        end,
        [SHAPE.TRIANGLE] = function (aabb_a, aabb_b, body_a, body_b)
            return intersect.aabb_aabb_collision(aabb_a, aabb_b)
        end
    }
}

function World:_check_collision(body_a, body_b)
    local aabb_a = body_a.aabb
    local aabb_b = body_b.aabb

    if not intersect.aabb_aabb(aabb_a, aabb_b) then
        return nil
    end

    if collison_handlers[body_a.shape_id] then
        local handler = collison_handlers[body_a.shape_id][body_b.shape_id]
        if handler then
            return handler(aabb_a, aabb_b, body_a, body_b)
        end
    end

    return intersect.aabb_aabb_collision(aabb_a, aabb_b)
end

function World:remove()
    for _, body in ipairs(self.bodies) do
        body:remove()
    end

    self.bodies = {}
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