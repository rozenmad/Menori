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
local node         = require (modules .. 'node')
local Scene        = require (modules .. 'scene')
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

local BODY_COLORS = {
    static = {0.9, 0.2, 0.2, 1},
    dynamic = {0.4, 0.9, 0.4, 1},
    sleep = {0.4, 0.4, 0.4, 1}
}

local vec3      = ml.vec3
local intersect = ml.intersect
local floor     = math.floor
local ceil      = math.ceil

function Body(self, body_type)
    self.body_type        = body_type or 'static'
    self.mass             = 1
    self.inv_mass         = (body_type == 'static') and 0 or 1
    self.restitution      = 0.5
    self.friction         = 0.3
    self.is_sleeping      = false
    self.sleep_timer      = 1
    self.use_gravity      = true
    self.in_cells         = {}
    self.link_name        = tostring(self)

    self.velocity         = vec3()
    self.force            = vec3()

    self.material:set('baseColor', (body_type == 'static') and BODY_COLORS.static or BODY_COLORS.dynamic)

    function self:update_aabb()
        self.aabb = self:get_aabb()
        self.aabb_min_x = self.aabb.min.x
        self.aabb_max_x = self.aabb.max.x
        self.aabb_min_y = self.aabb.min.y
        self.aabb_max_y = self.aabb.max.y
        self.aabb_min_z = self.aabb.min.z
        self.aabb_max_z = self.aabb.max.z
        if self.world then
            self.world:add_body_in_cells(self)
        end
    end
    self:update_aabb()

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
        local old_body = self.body_type
        self.inv_mass = (body_type == 'static') and 0 or (1 / self.mass)
        if body_type == 'dynamic' then
            self.force.y = self.world.gravity.y * self.mass
            self.material:set('baseColor', BODY_COLORS.dynamic)
        else
            self.material:set('baseColor', BODY_COLORS.static)
        end
        self.body_type = body_type
        if old_body ~= body_type then
            if old_body == 'dynamic' and body_type == 'static' then
                for index, v_body in pairs(self.world.dynamic_bodies) do
                    if v_body == self then
                        table.remove(self.world.dynamic_bodies, index)
                    end
                end
                table.insert(self.world.static_bodies, self)
            elseif old_body == 'static' and body_type == 'dynamic' then
                for index, v_body in pairs(self.world.static_bodies) do
                    if v_body == self then
                        table.remove(self.world.static_bodies, index)
                    end
                end
                table.insert(self.world.dynamic_bodies, self)
            end
        end
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

function World:init(cell_size, gravity_y, sleep)
    self.gravity         = vec3(0, gravity_y or -9.81, 0)
    self.sleep           = sleep
    self.dynamic_bodies  = {}
    self.static_bodies   = {}
    self.cells           = {}
    self.non_empty_cells = {}
    self.cell_size       = cell_size or 64
    self.node            = node('Physics World')
end

function World:remove_body_in_cells(body)
    for i = #body.in_cells, 1, -1 do
        local arr = body.in_cells[i]
        for index, v_body in pairs(arr) do
            if v_body == body then
                table.remove(arr, index)
                break
            end
        end
    end
    if body.inv_mass ~= 0 then
        self:update_cell_dynamic_flag_for_body(body, false)
    end
    body.in_cells = {}
end

function World:add_body_in_cells(body)
    self:remove_body_in_cells(body)
    local startCellX, startCellY, startCellZ,
          width, height, depth = self:aabb_to_cell_cube(
        body.aabb_min_x, body.aabb_min_y, body.aabb_min_z,
        body.aabb_max_x, body.aabb_max_y, body.aabb_max_z
    )
    local processd_cells = {}
    for z = startCellZ, startCellZ + depth - 1 do
        for y = startCellY, startCellY + height - 1 do
            for x = startCellX, startCellX + width - 1 do
                local cell = self:get_cell(x, y, z)
                if not processd_cells[cell] then
                    table.insert(cell, body)
                    table.insert(body.in_cells, cell)
                    processd_cells[cell] = true

                    if body.inv_mass ~= 0 then
                        self:update_cell_dynamic_flag_for_body(body, true)
                    end
                end
            end
        end
    end
end

function World:grid_to_cell(x, y, z)
    return floor(x / self.cell_size) + 1,
           floor(y / self.cell_size) + 1,
           floor(z / self.cell_size) + 1
end

function World:grid_to_world(cx, cy, cz)
    return (cx - 1) * self.cell_size,
           (cy - 1) * self.cell_size,
           (cz - 1) * self.cell_size
end

function World:aabb_to_cell_cube(minX, minY, minZ, maxX, maxY, maxZ)
    local startCellX, startCellY, startCellZ = self:grid_to_cell(minX, minY, minZ)
    local endCellX, endCellY, endCellZ = self:grid_to_cell(maxX, maxY, maxZ)

    endCellX = math.max(endCellX, startCellX)
    endCellY = math.max(endCellY, startCellY)
    endCellZ = math.max(endCellZ, startCellZ)

    return startCellX, startCellY, startCellZ,
           endCellX - startCellX + 1,
           endCellY - startCellY + 1,
           endCellZ - startCellZ + 1
end

function World:get_cell(x, y, z)
    local cx, cy, cz = self:grid_to_cell(x, y, z)
    self.cells[cz] = self.cells[cz] or {}
    self.cells[cz][cy] = self.cells[cz][cy] or {}

    local cell = self.cells[cz][cy][cx]
    if not cell then
        cell = {}
        self.cells[cz][cy][cx] = cell
        self.non_empty_cells[cell] = {cz, cy, cx, false}
    end

    return cell
end

function World:update_cell_dynamic_flag_for_body(body, is_dynamic)
    for i = #body.in_cells, 1, -1 do
        local cell = body.in_cells[i]

        local cell_has_dynamic = is_dynamic
        if not is_dynamic then
            for body_i = #cell, 1, -1 do
                if cell[body_i].inv_mass ~= 0 and not cell[body_i].is_sleeping then
                    cell_has_dynamic = true
                end
            end
        end
        self.non_empty_cells[cell][4] = cell_has_dynamic
    end
end

function World:add_body(body)
    if body.body_type == 'dynamic' then
        body.force.y = self.gravity.y * body.mass
        table.insert(self.dynamic_bodies, body)
    else
        table.insert(self.static_bodies, body)
    end
    self:add_body_in_cells(body)
    self.node:attach(body)
    body.world = self
end

function World:remove_body(body)
    self:remove_body_in_cells(body)
    if body.body_type == 'dynamic' then
        for index, v_body in ipairs(self.dynamic_bodies) do
            if v_body == body then
                table.remove(self.dynamic_bodies, index)
                break
            end
        end
    else
        for index, v_body in ipairs(self.static_bodies) do
            if v_body == body then
                table.remove(self.static_bodies, index)
                break
            end
        end
    end
    self.node:detach(body)
    body.world = nil
end

function World:step(dt)
    local processed_collision = {}

    for cell, position in pairs(self.non_empty_cells) do
        if position[4] then
            local l = #cell
            for i = 1, l do
                local body_a = cell[i]
                for j = i + 1, l do
                    local body_b = cell[j]

                    if body_b.inv_mass ~= 0 or body_a.inv_mass ~= 0 then
                        local key = body_a.link_name .. body_b.link_name

                        if not processed_collision[key] then
                            processed_collision[key] = true

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
                    end
                end
            end
            if l == 0 then
                if self.cells[position[1]] and self.cells[position[1]][position[2]] then
                    self.cells[position[1]][position[2]][position[3]] = nil
                end
                self.non_empty_cells[cell] = nil
            end
        end
    end

    for index, body_a in pairs(self.dynamic_bodies) do
        if self.sleep then
            local velocity = body_a.velocity.x + body_a.velocity.y + body_a.velocity.z
            if velocity < 0.01 and velocity > -0.01 then
                body_a.sleep_timer = body_a.sleep_timer - dt
                if body_a.sleep_timer < 0 then
                    body_a.is_sleeping = true
                    body_a.material:set('baseColor', BODY_COLORS.sleep)
                    self:update_cell_dynamic_flag_for_body(body_a, false)
                end
            else
                body_a.sleep_timer = 1
                if body_a.is_sleeping then
                    body_a.material:set('baseColor', BODY_COLORS.dynamic)
                    body_a.is_sleeping = false
                    self:update_cell_dynamic_flag_for_body(body_a, true)
                end
            end
        end

        if not body_a.is_sleeping then
            if body_a.use_gravity then
                body_a.force.y = body_a.force.y + self.gravity.y * body_a.mass
            end
            -- F = ma => a = F/m, v = v0 + a*dt
            body_a.velocity.x = body_a.velocity.x + body_a.force.x * body_a.inv_mass * dt
            body_a.velocity.y = body_a.velocity.y + body_a.force.y * body_a.inv_mass * dt
            body_a.velocity.z = body_a.velocity.z + body_a.force.z * body_a.inv_mass * dt

            body_a.velocity.x = body_a.velocity.x * 0.99
            body_a.velocity.y = body_a.velocity.y * 0.99
            body_a.velocity.z = body_a.velocity.z * 0.99

            local pos = body_a.position
            body_a:set_position(
                pos.x + body_a.velocity.x * dt,
                pos.y + body_a.velocity.y * dt,
                pos.z + body_a.velocity.z * dt
            )

            body_a.force.x = 0
            body_a.force.y = 0
            body_a.force.z = 0
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
    self.node:remove_children()

    for _, body in ipairs(self.dynamic_bodies) do
        body:remove()
    end

    for _, body in ipairs(self.static_bodies) do
        body:remove()
    end

    self.dynamic_bodies = {}
    self.static_bodies  = {}
end

function World:render(scene, environment)
	scene:render_nodes(self.node, environment, {
		node_sort_comp = Scene.alpha_mode_comp
	})
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