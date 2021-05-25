--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

local json = require 'libs.json'
local ImageLoader = require 'menori.modules.imageloader'
local ffi = require 'ffi'

local gl_component_size = {
	[5120] = 1,
	[5121] = 1,
	[5122] = 2,
	[5123] = 2,
	[5125] = 4,
	[5126] = 4,
}

local gl_type = {
	['SCALAR'] = 1,
	['VEC2'] = 2,
	['VEC3'] = 3,
	['VEC4'] = 4,
	['MAT2'] = 4,
	['MAT3'] = 9,
	['MAT4'] = 16,
}

local function unpack_type(component_type)
	if component_type == 5120 then
		return 'b'
	elseif component_type == 5121 then
		return 'B'
	elseif component_type == 5122 then
		return 'h'
	elseif component_type == 5123 then
		return 'H'
	elseif component_type == 5125 then
		return 'I4'
	elseif component_type == 5126 then
		return 'f'
	end
end

local buffers, images, materials, meshes
local data

local function get_buffer(accessor_index)
	local accessor = data.accessors[accessor_index + 1]
	local buffer_view = data.bufferViews[accessor.bufferView + 1]

	local data = buffers[buffer_view.buffer + 1]

	local offset = buffer_view.byteOffset or 0
	local length = buffer_view.byteLength

	local component_size = gl_component_size[accessor.componentType]
	local component_type = unpack_type(accessor.componentType)

	local type_elements_count = gl_type[accessor.type]
	return {
		data = data,
		offset = offset + (accessor.byteOffset or 0),
		length = length,

		stride = buffer_view.byteStride or (component_size * type_elements_count),
		component_size = component_size,
		component_type = component_type,

		type_elements_count = type_elements_count,
		count = accessor.count,
	}
end

local function get_indices_content(v)
	local buffer = get_buffer(v)
	local element_size = buffer.component_size * buffer.type_elements_count

	local temp_data = love.data.newByteData(buffer.count * element_size)
	local temp_data_pointer = ffi.cast('char*', temp_data:getFFIPointer())

	local data = ffi.cast('char*', buffer.data:getFFIPointer()) + buffer.offset

	for i = 0, buffer.count - 1 do
		ffi.copy(temp_data_pointer + i * element_size, data + i * buffer.stride, element_size)
	end

	return temp_data, element_size
end

local attribute_list = {
	'POSITION',
	'NORMAL',
	'TEXCOORD_0',
}

local function attrib_exist(attribute)
	for i, v in ipairs(attribute_list) do
		if v == attribute then
			return true
		end
	end
end

local function load_mesh(mesh)
	local primitives = {}
	for j, primitive in ipairs(mesh.primitives) do
		local indices, indices_type_size
		if primitive.indices then
			indices, indices_type_size = get_indices_content(primitive.indices)
		end

		local length = 0
		local components_stride = 0
		local attribute_buffers = {}
		local count = 0
		local mesh_format = {}

		for k, v in pairs(primitive.attributes) do
			if attrib_exist(k) then
				local buffer = get_buffer(v)
				attribute_buffers[k] = buffer

				count = buffer.count

				local element_size = buffer.component_size * buffer.type_elements_count
				length = length + buffer.count * element_size
				components_stride = components_stride + element_size
			end
		end

		local start_offset = 0
		local temp_data = love.data.newByteData(length)
		local temp_data_pointer = ffi.cast('char*', temp_data:getFFIPointer())

		for i, v in pairs(attribute_list) do
			local buffer = attribute_buffers[v]
			if buffer then
				local element_size = buffer.component_size * buffer.type_elements_count
				for i = 0, buffer.count - 1 do
					local p1 = buffer.offset + i * buffer.stride
					local data = ffi.cast('char*', buffer.data:getFFIPointer()) + p1

					local p2 = start_offset + i * components_stride

					ffi.copy(temp_data_pointer + p2, data, element_size)
				end
				start_offset = start_offset + element_size
			end
		end

		local material
		if primitive.material then
			material = materials[primitive.material + 1]
		else
			material = {}
		end
		primitives[j] = {
			vertices = temp_data,
			indices = indices,
			indices_type_size = indices_type_size,
			material = material,
			count = count
		}
	end
	return primitives
end

local nodes_mt = {}
nodes_mt.__index = nodes_mt
function nodes_mt.find_by_name(nodes, name)
	for i, v in ipairs(nodes) do
		if v.name == name then
			return v
		end
	end
end

local function read_scene_nodes(nodes)
	setmetatable(nodes, nodes_mt)
	for i, v in ipairs(nodes) do
		 -- get mesh index or 0
		local mesh_index = v.mesh or -1
		v.primitives = meshes[mesh_index + 1]
	end
	return nodes
end

local function get_image_by_index(index)
	return images[data.textures[index + 1].source + 1]
end

local function load(path, filename)
	data = json.decode(love.filesystem.read(path .. filename .. '.gltf'))

	buffers = {}
	for i, v in ipairs(data.buffers) do
		buffers[i] = love.filesystem.read('data', path .. v.uri)
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