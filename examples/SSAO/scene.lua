-- Screen space ambient occlusion Menori Example
--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2023
-------------------------------------------------------------------------------
]]

local menori = require ('menori')

local ml = menori.ml
local vec3 = ml.vec3
local quat = ml.quat
local ml_utils = ml.utils

local function generate_hemisphere_kernels(size)
	local samples = {}
	for i = 1, size do
		local v = vec3(
			love.math.random()*2.0 - 1.0,
			love.math.random()*2.0 - 1.0,
			love.math.random()
		)
		v = v:normalize()
		v = v * love.math.random()
		local scale = (i) / size
		scale = ml.utils.lerp(0.1, 1.0, scale*scale)
		v = v * scale
		local x, y, z = v:unpack()
		table.insert(samples, {x, y, z})
	end
	return samples
end

local function generate_ssao_noise_texture()
	local image_data = love.image.newImageData(4, 4)
	image_data:mapPixel(function(x, y, r, g, b, a)
		r = love.math.random()
		g = love.math.random()
		b = 0.0
		a = 1
		return r, g, b, a
	end)
	local image = love.graphics.newImage(image_data)
	image:setFilter('nearest', 'nearest')
	image:setWrap('repeat', 'repeat')
	return image
end

local function init_ssao_shader()
	local bias = 0.04
	local noise_t = generate_ssao_noise_texture()
	local ssao_shader = love.graphics.newShader('examples/SSAO/ssao.glsl')
	local samples = generate_hemisphere_kernels(64)

	ssao_shader:send('kernel_size', 64)
	ssao_shader:send('samples', unpack(samples))
	ssao_shader:send('noise_texture', noise_t)
	ssao_shader:send('bias', bias)
	return ssao_shader
end

local scene = menori.Scene:extend('SSAO_scene')

function scene:init()
	scene.super.init(self)

	local _, _, w, h = menori.app:get_viewport()
	self.ssao_c      = love.graphics.newCanvas(w, h)
	self.ssao_blur_c = love.graphics.newCanvas(w, h)
	self.albedo_c    = love.graphics.newCanvas(w, h)
	self.normal_c    = love.graphics.newCanvas(w, h, { format = 'rgba16f' })
	self.depth24_c   = love.graphics.newCanvas(w, h, { readable = true, format = 'depth24' })

	self.view_scale = 4
	self.x_angle = -60
	self.y_angle = -30

	self.render_state = {
		self.albedo_c, self.normal_c, -- in deferred shader love_Canvases[0] - albedo; love_Canvases[1] - normal;
		depthstencil = self.depth24_c,
		node_sort_comp = menori.Scene.alpha_mode_comp,
		clear = true,
	}

	self.ssao_radius = 0.85
	self.ssao_shader = init_ssao_shader()
	self.apply_ssao_shader = love.graphics.newShader('examples/SSAO/apply_ssao.glsl')
	self.ssao_blur_shader = love.graphics.newShader('examples/SSAO/ssao_blur.glsl')

	self.camera = menori.PerspectiveCamera(60, w/h, 0.1, 1024)
	self.environment = menori.Environment(self.camera)

	self.root_node = menori.Node()

	local gltf = menori.glTFLoader.load('examples/assets/choco_bunny.glb')
	local scenes = menori.NodeTreeBuilder.create(gltf, function (scene, builder)
		scene:traverse(function (node)
			if node.mesh then
				-- use deferred shader
				if node.skeleton_node then
					node.material.shader = menori.ShaderUtils.shaders['deferred_mesh_skinning']
				else
					node.material.shader = menori.ShaderUtils.shaders['deferred_mesh']
				end
			end
		end)
	end)

	self.root_node:attach(scenes[1])

	self.temp_projection_m = self.camera.m_projection:clone()
	self.temp_inv_projection_m = self.camera.m_inv_projection:clone()
	-- flip Y when draw in canvas
	self.temp_inv_projection_m[6] = -self.temp_inv_projection_m[6]
	self.temp_projection_m[6] = -self.temp_projection_m[6]
end

local tips = {
	{ text = "SSAO enable (press Z): ", key = 'z', boolean = true },
	{ text = "SSAO range check (press X): ", key = 'x', boolean = true },
	{ text = "Apply SSAO blur (press C): ", key = 'c', boolean = true },
	{ text = "Only draw SSAO (press V): ", key = 'v', boolean = false },
}

function scene:render()
	love.graphics.clear(0.3, 0.25, 0.2)

	--draw scene in canvases [albedo_c, normal_c], depthstencil = depth24_c
	self:render_nodes(self.root_node, self.environment, self.render_state)

	if tips[1].boolean then
		-- calculate ssao
		love.graphics.setCanvas(self.ssao_c)
		love.graphics.clear()
		love.graphics.setShader(self.ssao_shader)

		self.ssao_shader:send('range_check_enable', tips[2].boolean)
		self.ssao_shader:send('inv_projection', 'column', self.temp_inv_projection_m.data)
		self.ssao_shader:send('projection', 'column', self.temp_projection_m.data)
		self.ssao_shader:send('normal_c', self.normal_c)
		self.ssao_shader:send('depth24_c', self.depth24_c)
		self.ssao_shader:send('radius', self.ssao_radius)

		local _, _, w, h = menori.app:get_viewport()
		love.graphics.rectangle('fill', 0, 0, w, h)
		love.graphics.setShader()
		love.graphics.setCanvas()

		local result_ssao_canvas = self.ssao_c
		if tips[3].boolean then
			-- apply blur to ssao, store result in ssao_blur canvas
			love.graphics.setCanvas(self.ssao_blur_c)
			love.graphics.setShader(self.ssao_blur_shader)
			self.ssao_blur_shader:send('ssao_c', self.ssao_c)

			love.graphics.rectangle('fill', 0, 0, w, h)

			love.graphics.setShader()
			love.graphics.setCanvas()

			result_ssao_canvas = self.ssao_blur_c
		end

		if tips[4].boolean then
			-- draw only ssao canvas
			love.graphics.draw(result_ssao_canvas)
		else
			-- apply blurred ssao to albedo
			-- draw result on the screen
			love.graphics.setShader(self.apply_ssao_shader)
			self.apply_ssao_shader:send('ssao_c', result_ssao_canvas)
			love.graphics.draw(self.albedo_c)
			love.graphics.setShader()
		end
	else
		love.graphics.draw(self.albedo_c)
	end

	-- draw tips on the screen
	love.graphics.setColor(1, 0.5, 0, 1)
	local y = 45
	for _, v in ipairs(tips) do
		love.graphics.print(v.text .. (v.boolean and "On" or "Off"), 10, y)
		y = y + 15
	end
	love.graphics.print("SSAO radius (hold Q or E): " .. self.ssao_radius, 10, y)
	love.graphics.print("Hold mouse right button to move camera.", 10, y+30)
	love.graphics.print("Use mousewheel for zoom.", 10, y+45)
	love.graphics.setColor(1, 1, 1, 1)
end

function scene:keyreleased(key)
	for _, v in ipairs(tips) do
		if key == v.key then
			v.boolean = not v.boolean
		end
	end
end

-- camera control
function scene:mousemoved(x, y, dx, dy)
	if love.mouse.isDown(2) then
		self.y_angle = self.y_angle - dy * 0.2
		self.x_angle = self.x_angle - dx * 0.2
		self.y_angle = ml_utils.clamp(self.y_angle, -45, 45)
	end
end

function scene:wheelmoved(x, y)
	self.view_scale = self.view_scale - y * 0.2
end

function scene:update(dt)
	self:update_nodes(self.root_node, self.environment)

	if love.keyboard.isDown('q') then
		self.ssao_radius = self.ssao_radius + 0.001
	end
	if love.keyboard.isDown('e') and self.ssao_radius > 0.001 then
		self.ssao_radius = self.ssao_radius - 0.001
	end

	-- rotate the camera
	local q = quat.from_euler_angles(0, math.rad(self.x_angle), math.rad(self.y_angle)) * vec3.unit_z * self.view_scale
	local v = vec3(0, 0, 0)
	self.camera.center = v
	self.camera.eye = q + v
	self.camera:update_view_matrix()
end

return scene