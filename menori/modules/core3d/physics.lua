local modules = (...):match('(.*%menori.modules.)')

local class = require (modules .. 'libs.class')
local module = require (modules .. 'libs.bullet3d')
local bullet3 = module.bindings

jit.opt.start("maxtrace=8000", "maxmcode=16384", "maxrecord=16000")

local vec3 = function (x, y, z)
    return bullet3.btVector3(x or 0, y or 0, z or 0)
end

local quat = function (x, y, z, w)
    return bullet3.btQuaternion(x or 0, y or 0, z or 0, w or 1)
end

local transform = function(pos, rot)
    local t = bullet3.btTransform()
    t:setIdentity()
    if pos then t:setOrigin(pos) end
    if rot then t:setRotation(rot) end
    return t
end

-------------- World Class methods --------------------
local World = class('World')

function World:init(gravity)
    if type(gravity) == 'table' then
        gravity = vec3(gravity[1], gravity[2], gravity[3])
    end
    self.gravity = gravity or vec3(0, -9.81, 0)

    self.collisionConfiguration = bullet3.btDefaultCollisionConfiguration()
    self.dispatcher = bullet3.btCollisionDispatcher(self.collisionConfiguration)
    self.broadphase = bullet3.btDbvtBroadphase()
    self.solver = bullet3.btSequentialImpulseConstraintSolver()

    self.world = bullet3.btDiscreteDynamicsWorld(
        self.dispatcher, self.broadphase, self.solver, self.collisionConfiguration
    )
    self.world:setGravity(self.gravity)

    self.bodies = {}
    self.shapes = {}
    self.joints = {}
end

function World:update(dt, maxSubSteps, fixedTimeStep)
    dt = dt or (1/60)
    maxSubSteps = maxSubSteps or 10
    fixedTimeStep = fixedTimeStep or (1/60)

    self.world:stepSimulation(dt, maxSubSteps, fixedTimeStep)
end

function World:addBody(body)
    table.insert(self.bodies, body)
    self.world:addRigidBody(body.body)
    return body
end

function World:removeBody(body)
    for i, b in ipairs(self.bodies) do
        if b == body then
            table.remove(self.bodies, i)
            self.world:removeRigidBody(body.body)
            break
        end
    end
end

function World:addJoint(joint)
    table.insert(self.joints, joint)
    self.world:addConstraint(joint.constraint, true)
    return joint
end

function World:removeJoint(joint)
    for i, j in ipairs(self.joints) do
        if j == joint then
            table.remove(self.joints, i)
            self.world:removeConstraint(joint.constraint)
            break
        end
    end
end


function World:rayCast(from, to)
    local fromVec = type(from) == "table" and vec3(from[1], from[2], from[3]) or from
    local toVec = type(to) == "table" and vec3(to[1], to[2], to[3]) or to

    local callback = bullet3.ClosestRayResultCallback(fromVec, toVec)

    bullet3.btCollisionWorld.rayTest(self.world, fromVec, toVec, callback)

    if callback:hasHit() then
        return {
            hit = true,
            position = {
                callback.m_hitPointWorld:x(),
                callback.m_hitPointWorld:y(),
                callback.m_hitPointWorld:z()
            },
            normal = {
                callback.m_hitNormalWorld:x(),
                callback.m_hitNormalWorld:y(),
                callback.m_hitNormalWorld:z()
            },
            fraction = callback.m_closestHitFraction,
            body = callback.m_collisionObject
        }
    end

    return {hit = false}
end

function World:setGravity(x, y, z)
    if type(x) == "table" then
        self.gravity = vec3(x[1], x[2], x[3])
    else
        self.gravity = vec3(x, y, z)
    end
    self.world:setGravity(self.gravity)
end

function World:destroy()
    for i = #self.joints, 1, -1 do
        self:removeJoint(self.joints[i])
    end

    for i = #self.bodies, 1, -1 do
        self:removeBody(self.bodies[i])
    end
end


-------------- Shape Class methods --------------------
local Shape = class('Shape')

--[[Shape('box', x, y, z)
Shape('sphere', radius)
Shape('capsule', radius, height)
Shape('cylinder', x, y, z)
Shape('cone', radius, height)
Shape('plane', normal, constant)]]
function Shape:init(type, ...)
    self.type = type
    self.args = {...}

    if type == "box" then
        local size = vec3(...)
        self.shape = bullet3.btBoxShape(size)
    elseif type == "sphere" then
        local radius = ...
        self.shape = bullet3.btSphereShape(radius)
    elseif type == "capsule" then
        local radius, height = ...
        self.shape = bullet3.btCapsuleShape(radius, height)
    elseif type == "cylinder" then
        local size = vec3(...)
        self.shape = bullet3.btCylinderShape(size)
    elseif type == "cone" then
        local radius, height = ...
        self.shape = bullet3.btConeShape(radius, height)
    elseif type == "plane" then
        local normal, constant = ...
        self.shape = bullet3.btStaticPlaneShape(normal, constant)
    else
        error("unknown shape type: " .. tostring(type))
    end
end

function Shape:setMargin(margin)
    self.shape:setMargin(margin)
end

function Shape:getMargin()
    return self.shape:getMargin()
end

function Shape:calculateLocalInertia(mass)
    local inertia = vec3(0, 0, 0)
    if mass > 0 then
        self.shape:calculateLocalInertia(mass, inertia)
    end
    return inertia
end

-------------- Body Class methods --------------------
local Body = class('Body')

function Body:init(world, shape, mass, position, rotation)
    self.world = world
    self.shape = shape
    self.mass = mass or 0

    local pos = position and vec3(position[1], position[2], position[3]) or vec3(0, 0, 0)
    local rot = rotation and quat(rotation[1], rotation[2], rotation[3], rotation[4]) or quat(0, 0, 0, 1)

    local startTransform = transform(pos, rot)
    local localInertia = shape:calculateLocalInertia(mass)

    self.motionState = bullet3.btDefaultMotionState(startTransform)

    local rbInfo = bullet3.btRigidBodyConstructionInfo(
        mass, self.motionState, shape.shape, localInertia
    )

    self.body = bullet3.btRigidBody(rbInfo)

    if mass > 0 then
        self.body:setDamping(0.1, 0.1)
        self.body:setSleepingThresholds(0.8, 1.0)
    end

    if world then
        world:addBody(self)
    end
end

function Body:setPosition(x, y, z)
    local transform = self.body:getWorldTransform()
    if type(x) == "table" then
        transform:setOrigin(vec3(x[1], x[2], x[3]))
    else
        transform:setOrigin(vec3(x, y, z))
    end
    self.body:setWorldTransform(transform)
    self.body:activate()
end

function Body:getPosition()
    local transform = self.body:getWorldTransform()
    local origin = transform:getOrigin()
    return origin:x(), origin:y(), origin:z()
end

function Body:setRotation(x, y, z, w)
    local transform = self.body:getWorldTransform()
    if type(x) == "table" then
        transform:setRotation(quat(x[1], x[2], x[3], x[4]))
    else
        transform:setRotation(quat(x, y, z, w))
    end
    self.body:setWorldTransform(transform)
    self.body:activate()
end

function Body:getRotation()
    local transform = self.body:getWorldTransform()
    local rotation = transform:getRotation()
    return rotation:x(), rotation:y(), rotation:z(), rotation:w()
end

function Body:setLinearVelocity(x, y, z)
    if type(x) == "table" then
        self.body:setLinearVelocity(vec3(x[1], x[2], x[3]))
    else
        self.body:setLinearVelocity(vec3(x, y, z))
    end
    self.body:activate()
end

function Body:getLinearVelocity()
    local velocity = self.body:getLinearVelocity()
    return velocity:x(), velocity:y(), velocity:z()
end

function Body:setAngularVelocity(x, y, z)
    if type(x) == "table" then
        self.body:setAngularVelocity(vec3(x[1], x[2], x[3]))
    else
        self.body:setAngularVelocity(vec3(x, y, z))
    end
    self.body:activate()
end

function Body:getAngularVelocity()
    local velocity = self.body:getAngularVelocity()
    return velocity:x(), velocity:y(), velocity:z()
end

function Body:applyForce(force, position)
    local f = type(force) == "table" and vec3(force[1], force[2], force[3]) or force
    local p = position and (type(position) == "table" and vec3(position[1], position[2], position[3]) or position) or nil

    if p then
        self.body:applyForce(f, p)
    else
        self.body:applyCentralForce(f)
    end
    self.body:activate()
end

function Body:applyImpulse(impulse, position)
    local i = type(impulse) == "table" and vec3(impulse[1], impulse[2], impulse[3]) or impulse
    local p = position and (type(position) == "table" and vec3(position[1], position[2], position[3]) or position) or nil

    if p then
        self.body:applyImpulse(i, p)
    else
        self.body:applyCentralImpulse(i)
    end
    self.body:activate()
end

function Body:applyTorque(torque)
    local t = type(torque) == "table" and vec3(torque[1], torque[2], torque[3]) or torque
    self.body:applyTorque(t)
    self.body:activate()
end

function Body:setMass(mass)
    self.mass = mass
    local localInertia = self.shape:calculateLocalInertia(mass)
    self.body:setMassProps(mass, localInertia)
end

function Body:setFriction(friction)
    self.body:setFriction(friction)
end

function Body:setRestitution(restitution)
    self.body:setRestitution(restitution)
end

function Body:setDamping(linear, angular)
    self.body:setDamping(linear or 0, angular or 0)
end

function Body:setAngularFactor(x, y, z)
    if type(x) == "table" then
        self.body:setAngularFactor(vec3(x[1], x[2], x[3]))
    else
        self.body:setAngularFactor(vec3(x, y, z))
    end
end

function Body:activate()
    self.body:activate()
end

function Body:destroy()
    if self.world then
        self.world:removeBody(self)
    end
end

-------------- Joint Class methods --------------------
local Joint = class('Joint')

function Joint:init(type, bodyA, bodyB, ...)
    self.type = type
    self.bodyA = bodyA
    self.bodyB = bodyB

    if type == "point" then
        local pivotA, pivotB = ...
        local pa = type(pivotA) == "table" and vec3(pivotA[1], pivotA[2], pivotA[3]) or pivotA
        local pb = type(pivotB) == "table" and vec3(pivotB[1], pivotB[2], pivotB[3]) or pivotB

        if not pb then
            self.constraint = bullet3.btPoint2PointConstraint(bodyA.body, pa)
        else
            self.constraint = bullet3.btPoint2PointConstraint(bodyA.body, bodyB.body, pa, pb)
        end
    elseif type == "hinge" then
        local pivotA, axisA, pivotB, axisB = ...
        local pa = type(pivotA) == "table" and vec3(pivotA[1], pivotA[2], pivotA[3]) or pivotA
        local aa = type(axisA) == "table" and vec3(axisA[1], axisA[2], axisA[3]) or axisA
        local pb = type(pivotB) == "table" and vec3(pivotB[1], pivotB[2], pivotB[3]) or pivotB
        local ab = type(axisB) == "table" and vec3(axisB[1], axisB[2], axisB[3]) or axisB

        if not pb or not ab then
            self.constraint = bullet3.btHingeConstraint(bodyA.body, pa, aa, true)
        else
            self.constraint = bullet3.btHingeConstraint(bodyA.body, bodyB.body, pa, pb, aa, ab, true)
        end

    elseif type == "fixed" then
        local frameA, frameB = ...
        local fa = type(frameA) == "table" and transform(
            vec3(frameA[1], frameA[2], frameA[3]),
            quat(frameA[4], frameA[5], frameA[6], frameA[7])
        ) or frameA

        local fb = type(frameB) == "table" and transform(
            vec3(frameB[1], frameB[2], frameB[3]),
            quat(frameB[4], frameB[5], frameB[6], frameB[7])
        ) or frameB

        self.constraint = bullet3.btFixedConstraint(bodyA.body, bodyB.body, fa, fb)

    elseif type == "slider" then
        local frameA, frameB, useLinearReferenceFrameA = ...
        local fa = type(frameA) == "table" and transform(
            vec3(frameA[1], frameA[2], frameA[3]),
            quat(frameA[4], frameA[5], frameA[6], frameA[7])
        ) or frameA

        local fb = type(frameB) == "table" and transform(
            vec3(frameB[1], frameB[2], frameB[3]),
            quat(frameB[4], frameB[5], frameB[6], frameB[7])
        ) or frameB

        self.constraint = bullet3.btSliderConstraint(bodyA.body, bodyB.body, fa, fb, useLinearReferenceFrameA or true)
    else
        error("unknown joint type: " .. tostring(type))
    end

    if bodyA.world and bodyA.world == bodyB.world then
        bodyA.world:addJoint(self)
    end
end

function Joint:setBreakingImpulseThreshold(threshold)
    self.constraint:setBreakingImpulseThreshold(threshold)
end

function Joint:enableFeedback(enable)
    self.constraint:enableFeedback(enable)
end

function Joint:setParam(param, value, axis)
    self.constraint:setParam(param, value, axis or -1)
end

function Joint:getParam(param, axis)
    return self.constraint:getParam(param, axis or -1)
end

function Joint:destroy()
    if self.bodyA and self.bodyA.world then
        self.bodyA.world:removeJoint(self)
    end
end

function Joint:setLimits(low, high, softness, bias, relaxation)
    if self.type == "hinge" and self.constraint then
        self.constraint:setLimit(low, high, softness or 0.9, bias or 0.3, relaxation or 1.0)
    end
end

function Joint:enableMotor(enable)
    if self.type == "hinge" and self.constraint then
        self.constraint:enableMotor(enable)
    end
end

function Joint:setMotorTarget(target, dt)
    if self.type == "hinge" and self.constraint then
        self.constraint:setMotorTarget(target, dt or (1/60))
    end
end

function Joint:setMaxMotorImpulse(maxImpulse)
    if self.type == "hinge" and self.constraint then
        self.constraint:setMaxMotorImpulse(maxImpulse)
    end
end

-------------- Main module --------------------
local Physics = class('physics')

function Physics:init()
end

function Physics.newWorld(gravity)
    return World(gravity)
end

function Physics.newShape(type, ...)
    return Shape(type, ...)
end

function Physics.newBody(world, shape, mass, position, rotation)
    return Body(world, shape, mass, position, rotation)
end

function Physics.newJoint(type, bodyA, bodyB, ...)
    return Joint(type, bodyA, bodyB, ...)
end

function Physics.vec3(x, y, z)
    return vec3(x, y, z)
end

function Physics.quat(x, y, z, w)
    return quat(x, y, z, w)
end

function Physics.transform(position, rotation)
    return transform(
        position and vec3(position[1], position[2], position[3]),
        rotation and quat(rotation[1], rotation[2], rotation[3], rotation[4])
    )
end

Physics.World = World
Physics.Shape = Shape
Physics.Body = Body
Physics.Joint = Joint

return Physics