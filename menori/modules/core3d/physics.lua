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

local thread = love.thread

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
    end

    function self:set_velocity(vx, vy, vz)
        self.velocity.x = vx
        self.velocity.y = vy
        self.velocity.z = vz
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

    function self:update_capsule_points()
        local half = self.height * 0.5
        local mat = self.world_matrix
        self.p0 = mat:multiply_vec3(vec3(0, -half, 0))
        self.p1 = mat:multiply_vec3(vec3(0, half, 0))
    end

    local _set_position = self.set_position
    function self:set_position(x, y, z)
        _set_position(self, x, y, z)
        self:update_capsule_points()
    end
    self:set_position(0, 0, 0)

    -- local _set_rotation = self.set_rotation
    -- function self:set_rotation(q)
    --     _set_rotation(self, q)
    --     self:update_capsule_points()
    -- end

    local _set_scale = self.set_scale
    function self:set_scale(sx, sy, sz)
        _set_scale(self, sx, sy, sz)
        self:update_capsule_points()
    end

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
    local body_table = body.body_type == 'dynamic' and self.bodies or self.static_bodies
    for index, v_body in ipairs(body_table) do
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
    for i, body_a in ipairs(self.bodies) do
        for j, body_b in ipairs(self.static_bodies) do
            local collision = self:_check_collision(body_a, body_b)
            if collision then
                self:_resolve_collision(body_a, body_b, collision)
            end
        end

        if self.sleep then
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

function World:_resolve_collision(body_a, body_b, collision)
    if body_a.inv_mass == 0 then
        return
    end

    local nx, ny, nz = collision.normal[1], collision.normal[2], collision.normal[3]

    local pos = body_a.position
    body_a:set_position(
        pos.x + nx * collision.depth,
        pos.y + ny * collision.depth,
        pos.z + nz * collision.depth
    )

    local dot_product = body_a.velocity.x * nx + body_a.velocity.y * ny + body_a.velocity.z * nz
    if dot_product < 0 then
        body_a.velocity.x = body_a.velocity.x - nx * dot_product * (1 + body_a.restitution)
        body_a.velocity.y = body_a.velocity.y - ny * dot_product * (1 + body_a.restitution)
        body_a.velocity.z = body_a.velocity.z - nz * dot_product * (1 + body_a.restitution)
    end

    body_a.velocity.x = body_a.velocity.x * (1 - body_a.friction)
    body_a.velocity.z = body_a.velocity.z * (1 - body_a.friction)
end

--[[
box - box
box - capsule
box - plane?
box - sphere
box - triangle

capsule - box
capsule - capsule
capsule - plane?
capsule - sphere
capsule - triangle

plane - box
plane? - capsule
plane - plane
plane - sphere
plane - triangle

sphere - box
sphere - capsule
sphere - plane?
sphere - sphere
sphere - triangle

triangle - box
triangle - capsule
triangle - plane
triangle - sphere
triangle - triangle
]]
function World:_check_collision(body_a, body_b)
    local aabb_a = body_a:get_aabb()
    local aabb_b = body_b:get_aabb()

    if not intersect.aabb_aabb(aabb_a, aabb_b) then
        return nil
    end

    if (body_a.is_box or body_a.is_plane or body_a.is_triangle) and (body_b.is_box or body_b.is_plane or body_b.is_triangle) then
        return intersect.aabb_aabb_collision(aabb_a, aabb_b)
    end

    if (body_a.is_box or body_b.is_plane) and body_b.is_capsule then
        body_b:update_capsule_points()
        return intersect.capsule_aabb(body_b.p0, body_b.p1, body_b.radius, aabb_a)
    end

    if (body_a.is_box or body_a.is_plane or body_a.is_triangle) and body_b.is_sphere then
        return intersect.sphere_aabb(
            body_b.position,
            body_b.radius,
            aabb_a
        )
    end

    if body_a.is_capsule and (body_b.is_box or body_b.is_plane) then
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
        return nil
    end

    if body_a.is_capsule and body_b.is_capsule then
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
        return nil
    end

    if body_a.is_capsule and body_b.is_triangle then
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
        return nil
    end

    if body_a.is_capsule and body_b.is_sphere then
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
        return nil
    end

    if body_a.is_triangle and body_b.is_capsule then
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
        return nil
    end

    if body_a.is_sphere and body_b.is_capsule then
        body_b:update_capsule_points()

        return intersect.capsule_sphere(body_b.p0, body_b.p1, body_b.radius, body_a.position, body_a.radius)
    end

    if body_a.is_sphere and body_b.is_sphere then
        return intersect.sphere_sphere(
            body_a:get_world_position(),
            body_a.radius,
            body_b:get_world_position(),
            body_b.radius
        )
    end

    if body_a.is_sphere and (body_b.is_box or body_b.is_plane or body_a.is_triangle) then
        return intersect.sphere_aabb(
            body_a.position,
            body_a.radius,
            aabb_b
        )
    end

    return intersect.aabb_aabb_collision(aabb_a, aabb_b)
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