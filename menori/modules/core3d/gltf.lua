--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

--[[--
Module for import/export the *gltf format.
]]
-- @module menori.glTFLoader

local modules = (...):match('(.*%menori.modules.)')

local json = require 'libs.rxijson.json'

local ffi
if type(jit) == 'table' and jit.status() then
	ffi = require 'ffi'
end

local buffers, images, materials
local data

local type_constants = {
	['SCALAR'] = 1,
	['VEC2'] = 2,
	['VEC3'] = 3,
	['VEC4'] = 4,
	['MAT2'] = 4,
	['MAT3'] = 9,
	['MAT4'] = 16,
}

local component_type_constants = {
	[5120] = 1,
	[5121] = 1,
	[5122] = 2,
	[5123] = 2,
	[5125] = 4,
	[5126] = 4,
}

local datatypes = {
	'byte',
	'unorm16',
	'',
	'float',
}

local function get_component_type_value(typename)
	if typename == 'byte' then
		return 5120
	elseif typename == 'unorm16' then
		return 5123
	elseif typename == 'float' then
		return 5126
	end
end

local attribute_aliases = {
	['POSITION'] = 'VertexPosition',
	['TEXCOORD'] = 'VertexTexCoord',
	['JOINTS']   = 'VertexJoints',
	['NORMAL']   = 'VertexNormal',
	['COLOR']    = 'VertexColor',
	['WEIGHTS']  = 'VertexWeights',
	['TANGENT']  = 'VertexTangent',
}

local function get_key_from_value(t, value)
	for k, v in pairs(t) do
		if v == value then
			return k
		end
	end
end

local function get_primitive_modes_constants(mode)
	if mode == 0 then
		return 'points'
	elseif mode == 1 then
	elseif mode == 2 then
	elseif mode == 3 then
	elseif mode == 5 then
		return 'strip'
	elseif mode == 6 then
		return 'fan'
	end
	return 'triangles'
end

local function unpack_type(component_type)
	if
	component_type == 5120 then
		return 'b'
	elseif
	component_type == 5121 then
		return 'B'
	elseif
	component_type == 5122 then
		return 'h'
	elseif
	component_type == 5123 then
		return 'H'
	elseif
	component_type == 5125 then
		return 'I4'
	elseif
	component_type == 5126 then
		return 'f'
	end
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

local function get_buffer(accessor_index)
	local accessor = data.accessors[accessor_index + 1]
	local buffer_view = data.bufferViews[accessor.bufferView + 1]

	local data = buffers[buffer_view.buffer + 1]

	local offset = buffer_view.byteOffset or 0
	local length = buffer_view.byteLength

	local component_size = component_type_constants[accessor.componentType]
	local component_type = unpack_type(accessor.componentType)

	local type_elements_count = type_constants[accessor.type]
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

	local temp_data
	if ffi then
		temp_data = love.data.newByteData(buffer.count * element_size)
		local temp_data_pointer = ffi.cast('char*', temp_data:getFFIPointer())
		local data = ffi.cast('char*', buffer.data:getFFIPointer()) + buffer.offset

		for i = 0, buffer.count - 1 do
			ffi.copy(temp_data_pointer + i * element_size, data + i * buffer.stride, element_size)
		end
	else
		temp_data = {}
		local data_string = buffer.data:getString()

		for i = 0, buffer.count - 1 do
			local pos =  buffer.offset + i * element_size + 1
			local v = love.data.unpack(buffer.component_type, data_string, pos) + 1
			table.insert(temp_data, v)
		end
	end
	return temp_data, element_size
end

local function get_vertices_content(attribute_buffers, components_stride, length)
	local start_offset = 0
	local temp_data

	if ffi then
		temp_data = love.data.newByteData(length)
		local temp_data_pointer = ffi.cast('char*', temp_data:getFFIPointer())

		for _, buffer in ipairs(attribute_buffers) do
			local element_size = buffer.component_size * buffer.type_elements_count
			for i = 0, buffer.count - 1 do
				local p1 = buffer.offset + i * buffer.stride
				local data = ffi.cast('char*', buffer.data:getFFIPointer()) + p1

				local p2 = start_offset + i * components_stride

				ffi.copy(temp_data_pointer + p2, data, element_size)
			end
			start_offset = start_offset + element_size
		end
	else
		temp_data = {}
		for _, buffer in ipairs(attribute_buffers) do
			local data_string = buffer.data:getString()
			for i = 0, buffer.count - 1 do
				local vertex = temp_data[i + 1] or {}
				temp_data[i + 1] = vertex

				local pos = buffer.offset + i * buffer.stride
				for k = 0, buffer.type_elements_count - 1 do
					local element_pos = pos + k * buffer.component_size + 1
					local attr = love.data.unpack(buffer.component_type, data_string, element_pos)
					vertex[start_offset + k + 1] = attr
				end
			end
			start_offset = start_offset + buffer.type_elements_count
		end
	end

	return temp_data
end

local function init_mesh(mesh)
	local primitives = {}
	for j, primitive in ipairs(mesh.primitives) do
		local indices, indices_tsize
		if primitive.indices then
			indices, indices_tsize = get_indices_content(primitive.indices)
		end

		local length = 0
		local components_stride = 0
		local attribute_buffers = {}
		local count = 0
		local vertexformat = {}

		for k, v in pairs(primitive.attributes) do
			local attribute, value = k:match('(%w+)(.*)')
			local attribute_name
			if value == '_0' then
				attribute_name = attribute_aliases[attribute]
			elseif attribute_aliases[attribute] then
				attribute_name = attribute_aliases[attribute] .. value
			else
				attribute_name = k
			end

			local buffer = get_buffer(v)
			attribute_buffers[#attribute_buffers+1] = buffer

			count = buffer.count

			local element_size = buffer.component_size * buffer.type_elements_count
			length = length + buffer.count * element_size
			components_stride = components_stride + element_size

			table.insert(vertexformat, {
				attribute_name, datatypes[buffer.component_size], buffer.type_elements_count
			})
		end

		local vertices = get_vertices_content(attribute_buffers, components_stride, length)

		local material
		if primitive.material then
			material = materials[primitive.material + 1]
		else
			material = {}
		end
		primitives[j] = {
			mode = get_primitive_modes_constants(primitive.mode),
			vertexformat = vertexformat,
			vertices = vertices,
			indices = indices,
			indices_tsize = indices_tsize,
			material = material,
			count = count
		}
	end
	return primitives
end

local function texture(textures, t)
	if t then
		local texture = textures[t.index + 1]
		local ret = {
			texture = texture,
			source  = texture.image.source,
		}
		for k, v in pairs(t) do
			if k ~= 'index' then
				ret[k] = v
			end
		end
		return ret
	end
end

local function create_material(textures, material)
	local uniforms = {}

	local baseTexture
	local metallicRoughnessTexture
	local normalTexture
	local occlusionTexture
	local emissiveTexture

	local pbr = material.pbrMetallicRoughness
	if pbr then
		local _pbrBaseColorTexture = pbr.baseColorTexture
		local _pbrMetallicRoughnessTexture = pbr.metallicRoughnessTexture

		baseTexture = texture(textures, _pbrBaseColorTexture)
		metallicRoughnessTexture = texture(textures, _pbrMetallicRoughnessTexture)

		if baseTexture then
			uniforms.baseTexture = baseTexture.source
			uniforms.baseTextureCoord = baseTexture.tcoord
		end
		if metallicRoughnessTexture then
			uniforms.metallicRoughnessTexture = metallicRoughnessTexture.source
			uniforms.metallicRoughnessTextureCoord = metallicRoughnessTexture.tcoord
		end

		uniforms.metalness = pbr.metallicFactor
		uniforms.roughness = pbr.roughnessFactor

		uniforms.baseColor = pbr.baseColorFactor or {1, 1, 1, 1}
	end

	if material.normalTexture then
		local normalTexture = texture(textures, material.normalTexture)
		uniforms.normalTexture = normalTexture.source
		uniforms.normalTextureCoord = normalTexture.tcoord
		uniforms.normalTextureScale = normalTexture.scale
	end

	if material.occlusionTexture then
		local occlusionTexture = texture(textures, material.occlusionTexture)
		uniforms.occlusionTexture = occlusionTexture.source
		uniforms.occlusionTextureCoord = occlusionTexture.tcoord
		uniforms.occlusionTextureStrength = occlusionTexture.strength
	end

	if material.emissiveTexture then
		local emissiveTexture = texture(textures, material.emissiveTexture)
		uniforms.emissiveTexture = emissiveTexture.source
		uniforms.occlusionTextureCoord = emissiveTexture.tcoord
	end
	uniforms.emissiveColor = material.emissiveFactor

	return {
		baseTexture = baseTexture,
		metallicRoughnessTexture = metallicRoughnessTexture,
		normalTexture = normalTexture,
		occlusionTexture = occlusionTexture,
		emissiveTexture = emissiveTexture,

		uniforms = uniforms,
	}
end

local function parse_mag_filter(value)
	if
	value == 9728 then
		return 'nearest'
	elseif
	value == 9729 then
		return 'linear'
	end
end

local function parse_min_filter(value)
	if
	value == 9728 then
		return 'nearest'
	elseif
	value == 9729 then
		return 'linear'
	end
end

local function parse_wrap(value)
	if
	value == 33071 then
		return 'clamp'
	elseif
	value == 33648 then
		return 'mirroredrepeat'
	elseif
	value == 10497 then
		return 'repeat'
	end
end

--- Load model by filename
-- @function load
-- @tparam string filename The filepath to the gltf file (must be separated (.gltf+.bin+textures) or.gltf+textures)
-- @tparam function io_read Callback to read the file (Optional) = love.filesystem.read
-- @treturn table
local function load(filename, io_read)
	local path, name = filename:match("(.*/)(.+)%.gltf$")
	io_read = io_read or love.filesystem.read

	local filepath = path .. name .. '.gltf'
	--assert(love.filesystem.getInfo(filepath), 'in function <glTFLoader.load> file "' .. filepath .. '" not found.')

	local gltf_filedata = io_read(filepath)
	data = json.decode(gltf_filedata)

	buffers = {}
	for i, v in ipairs(data.buffers) do
		local data = v.uri:match('^data:application/octet%-stream;base64,(.+)')
		if data then
			buffers[i] = love.data.decode('data', 'base64', data)
		else
			buffers[i] = love.data.newByteData(io_read(path .. v.uri))
		end
	end

	images = {}
	if data.images then
		for i, v in ipairs(data.images) do
			local image_filename = path .. v.uri
			local image_filedata = love.filesystem.newFileData(io_read(image_filename), image_filename)
			local imageData = love.image.newImageData(image_filedata)
			local image = love.graphics.newImage(imageData)
			imageData:release()
			images[i] = {
				source = image, name = v.uri, path = path, filedata = image_filedata
			}
		end
	end

	local samplers = {}
	if data.samplers then
		for _, v in ipairs(data.samplers) do
			table.insert(samplers, {
				magFilter = parse_mag_filter(v.magFilter),
				minFilter = parse_min_filter(v.minFilter),
				wrapS = parse_wrap(v.wrapS),
				wrapT = parse_wrap(v.wrapT),
			})
		end
	end

	local textures = {}
	if data.textures then
		for _, v in ipairs(data.textures) do
			table.insert(textures, {
				image = images[v.source + 1], sampler = samplers[v.sampler]
			})
		end
	end

	materials = {}
	if data.materials then
		for i, v in ipairs(data.materials) do
			materials[i] = create_material(textures, v)
		end
	end

	local meshes = {}
	for i, v in ipairs(data.meshes) do
		meshes[i] = init_mesh(v)
	end

	return {
		asset = data.asset,
		nodes = data.nodes,
		scene = data.scene,

		meshes = meshes,
		scenes = data.scenes,
		images = images,
	}
end

return {
	load = load,
}