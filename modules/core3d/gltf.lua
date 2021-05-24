--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

local json = require 'libs.json'
local ImageLoader = require 'menori.modules.imageloader'

local gl_component_offset = {
	[5120] = 1,
	[5121] = 1,
	[5122] = 2,
	[5123] = 2,
	[5125] = 4,
	[5126] = 4,
}

local function unpack_type(component_type)
	if component_type == 5120 then return 'b'  end
	if component_type == 5121 then return 'B'  end
	if component_type == 5122 then return 'h'  end
	if component_type == 5123 then return 'H'  end
	if component_type == 5125 then return 'I4' end
	if component_type == 5126 then return 'f'  end
end

local buffers, images, materials, meshes
local data

local function float_round(num, decimals)
 	local power = 10 ^ (decimals or 0)
  	return (math.floor(num * power + 0.5) / power)
end

local function get_buffer_content(v, additional_value)
	additional_value = additional_value or 0

	local accessor = data.accessors[v + 1]
	local buffer_view = data.bufferViews[accessor.bufferView + 1]

	local buffer = buffers[buffer_view.buffer + 1]

	local offset = buffer_view.byteOffset
	local values = {}
	local component_offset = gl_component_offset[accessor.componentType]
	local utype = unpack_type(accessor.componentType)
	for i = offset, offset + buffer_view.byteLength - 1, component_offset do
		values[#values + 1] = love.data.unpack(utype, buffer, i + 1) + additional_value
	end
	return values
end

local attribute_list = {
	'POSITION',
	'NORMAL',
	'TEXCOORD_0',
	'TEXCOORD_1',
}

local default = {0, 0, 0}

local function load_mesh(mesh)
	local primitives = {}
	for j, primitive in ipairs(mesh.primitives) do
		local indices = get_buffer_content(primitive.indices, 1)

		local vt = {}
		local tc_index = 1
		local pdata = {}

		for i, v in ipairs(attribute_list) do
			if primitive.attributes[v] then
				pdata[v] = get_buffer_content(primitive.attributes[v])
			end
		end

		local p   = pdata['POSITION']   or default
		local n   = pdata['NORMAL']     or default
		local tc0 = pdata['TEXCOORD_0'] or default

		for i = 1, #p, 3 do
			local x = float_round(p[i+0], 2)
			local y = float_round(p[i+1], 2)
			local z = float_round(p[i+2], 2)
			local t = tc0[tc_index+0]
			local s = tc0[tc_index+1]
			vt[#vt + 1] = {x, y, z, t, s, n[i], n[i+1], n[i+2]}
			tc_index = tc_index + 2
		end

		local material
		if primitive.material then
			material = materials[primitive.material + 1]
		else
			material = {}
		end
		primitives[j] = {
			vertices = vt, indices = indices, material = material
		}
	end
	return primitives
end

local function read_scene_nodes(nodes)
	local node_list = {}
	for i, v in ipairs(nodes) do
		local t = v.translation or {0, 0, 0}
		local s = v.scale or {1, 1, 1}
		local r = v.rotation or {0, 0, 0, 0}

		 -- get mesh index or 0
		local mesh_index = v.mesh or -1
		local node = {
			primitives = meshes[mesh_index+1],
			extras = v.extras,
			translation = t,
			scale = s,
			rotation = r,
		}
		node_list[v.name] = node
	end
	return node_list
end

local function get_image_by_index(index)
	return images[data.textures[index + 1].source + 1]
end

local function load(path, filename)
	data = json.decode(love.filesystem.read(path .. filename .. '.gltf'))

	buffers = {}
	for i, v in ipairs(data.buffers) do
		buffers[i] = love.filesystem.read(path .. v.uri)
	end

	images  = {}
	if data.images then
		for i, v in ipairs(data.images) do
			local image_filename = path .. v.uri
			local image
			if ImageLoader.has(filename) then
				image = ImageLoader.find(image_filename)
			else
				image = ImageLoader.load(image_filename, false)
			end
			images[i] = {
				data = image, filename = image_filename
			}
		end
	end

	materials = {}
	for i, v in ipairs(data.materials or {}) do
		local material = {}
		local baseColorTexture = v.pbrMetallicRoughness and v.pbrMetallicRoughness.baseColorTexture
		if baseColorTexture then
			local image = get_image_by_index(v.pbrMetallicRoughness.baseColorTexture.index)
			material.image_data = image.data
			material.image_name = image.name
		end
		if v.emissiveTexture then
			local image = get_image_by_index(v.emissiveTexture.index)
			material.image_data = image.data
			material.image_name = image.name
		end
		if v.extensions then
			if v.extensions.KHR_materials_pbrSpecularGlossiness then
				local diffuse_t = v.extensions.KHR_materials_pbrSpecularGlossiness.diffuseTexture
				local image = get_image_by_index(diffuse_t.index)
				material.image_data = image.data
				material.image_name = image.name
			end
		end
		materials[i] = material
	end

	meshes = {}
	for i, v in ipairs(data.meshes) do
		meshes[i] = load_mesh(v)
	end

	return read_scene_nodes(data.nodes)
end

return {
	load = load
}