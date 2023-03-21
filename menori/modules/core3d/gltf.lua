--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2023
-------------------------------------------------------------------------------
]]

--[[--
Module for load the *gltf format.
Separated GLTF (.gltf+.bin+textures) or (.gltf+textures) is supported now.
]]
-- @module glTFLoader

local json = require 'libs.rxijson.json'

local ffi
if type(jit) == 'table' or jit.status() then
	ffi = require 'ffi'
end

local function getFFIPointer(data)
	if data.getFFIPointer then return data:getFFIPointer() else return data:getPointer() end
end

local glTFLoader = {}
local buffers, data

local type_constants = {
	['SCALAR'] = 1,
	['VEC2'] = 2,
	['VEC3'] = 3,
	['VEC4'] = 4,
	['MAT2'] = 4,
	['MAT3'] = 9,
	['MAT4'] = 16,
}

local ffi_indices_types = {
	[5121] = 'unsigned char*',
	[5123] = 'unsigned short*',
	[5125] = 'unsigned int*',
}

local component_type_constants = {
	[5120] = 1,
	[5121] = 1,
	[5122] = 2,
	[5123] = 2,
	[5125] = 4,
	[5126] = 4,
}

local component_types = {
	[5120] = 'int8',
	[5121] = 'uint8',
	[5122] = 'int16',
	[5123] = 'unorm16',
	[5125] = 'uint32',
	[5126] = 'float',
}

local add_vertex_format
if love._version_major > 11 then
	local types = {
		['SCALAR'] = '',
		['VEC2'] = 'vec2',
		['VEC3'] = 'vec3',
		['VEC4'] = 'vec4',
		['MAT2'] = 'mat2x2',
		['MAT3'] = 'mat3x3',
		['MAT4'] = 'mat4x4',
	}
	function add_vertex_format(vertexformat, attribute_name, buffer)
		local format = component_types[buffer.component_type] .. types[buffer.type]
		table.insert(vertexformat, {
			name = attribute_name, format = format
		})
	end
else
	local types = {
		'byte',
		'unorm16',
		'',
		'float',
	}

	function add_vertex_format(vertexformat, attribute_name, buffer)
		table.insert(vertexformat, {
			attribute_name, types[buffer.component_size], buffer.type_elements_count
		})
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

local function get_unpack_type(component_type)
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
	local type_elements_count = type_constants[accessor.type]
	return {
		data = data,
		offset = offset + (accessor.byteOffset or 0),
		length = length,

		stride = buffer_view.byteStride or (component_size * type_elements_count),
		component_size = component_size,
		component_type = accessor.componentType,
		type = accessor.type,

		type_elements_count = type_elements_count,
		count = accessor.count,

		min = accessor.min,
		max = accessor.max,
	}
end

local function get_indices_content(v)
	local buffer = get_buffer(v)
	local element_size = buffer.component_size * buffer.type_elements_count

	local min = buffer.min and buffer.min[1] or 0
	local max = buffer.max and buffer.max[1] or 0

	local uint8 = element_size < 2

	local temp_data
	if ffi and not uint8 then
		temp_data = love.data.newByteData(buffer.count * element_size)
		local temp_data_pointer = ffi.cast('char*', getFFIPointer(temp_data))
		local data = ffi.cast('char*', getFFIPointer(buffer.data)) + buffer.offset

		for i = 0, buffer.count - 1 do
			ffi.copy(temp_data_pointer + i * element_size, data + i * buffer.stride, element_size)
			local value = ffi.cast(ffi_indices_types[buffer.component_type], temp_data_pointer + i * element_size)[0]
			if value > max then max = value end
			if value < min then min = value end
		end

		for i = 0, buffer.count - 1 do
			local ptr = ffi.cast(ffi_indices_types[buffer.component_type], temp_data_pointer + i * element_size)
			ptr[0] = ptr[0] - min
		end
	else
		temp_data = {}
		local data_string = buffer.data:getString()
		local unpack_type = get_unpack_type(buffer.component_type)

		for i = 0, buffer.count - 1 do
			local pos = buffer.offset + i * element_size + 1
			local value = love.data.unpack(unpack_type, data_string, pos)
			temp_data[i + 1] = value + 1
			if value > max then max = value end
			if value < min then min = value end
		end

		for i = 0, buffer.count - 1 do
			temp_data[i+1] = temp_data[i+1] - min
		end
	end
	return temp_data, element_size, min, max
end

local function get_vertices_content(attribute_buffers, components_stride, length, min, max)
	local start_offset = 0
	local temp_data

	if ffi then
		temp_data = love.data.newByteData(length)
		local temp_data_pointer = ffi.cast('char*', getFFIPointer(temp_data))

		for _, buffer in ipairs(attribute_buffers) do
			local element_size = buffer.component_size * buffer.type_elements_count
			for i = min, max do
				local p1 = buffer.offset + i * buffer.stride
				local data = ffi.cast('char*', getFFIPointer(buffer.data)) + p1

				local p2 = start_offset + (i - min) * components_stride

				ffi.copy(temp_data_pointer + p2, data, element_size)
			end
			start_offset = start_offset + element_size
		end
	else
		temp_data = {}
		for _, buffer in ipairs(attribute_buffers) do
			local unpack_type = get_unpack_type(buffer.component_type)
			local data_string = buffer.data:getString()
			for i = min, max do
				local vertex = temp_data[(i - min) + 1] or {}
				temp_data[(i - min) + 1] = vertex

				local pos = buffer.offset + i * buffer.stride
				for k = 0, buffer.type_elements_count - 1 do
					local element_pos = pos + k * buffer.component_size + 1
					local attr = love.data.unpack(unpack_type, data_string, element_pos)
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
		local indices, indices_tsize, min, max
		if primitive.indices then
			indices, indices_tsize, min, max = get_indices_content(primitive.indices)
		else
			min = 0
			max = 0
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

			if max == 0 then max = buffer.count end
			if ffi then
				count = (max - min) + 1
			else
				count = (max - min)
			end

			local element_size = buffer.component_size * buffer.type_elements_count
			length = length + count * element_size
			components_stride = components_stride + element_size

			add_vertex_format(vertexformat, attribute_name, buffer)
		end

		local vertices = get_vertices_content(attribute_buffers, components_stride, length, min, max)

		primitives[j] = {
			mode = get_primitive_modes_constants(primitive.mode),
			vertexformat = vertexformat,
			vertices = vertices,
			indices = indices,
			indices_tsize = indices_tsize,
			material_index = primitive.material,
			count = count,
		}
	end
	return {
		primitives = primitives,
		name = mesh.name,
	}
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

	local main_texture
	local pbr = material.pbrMetallicRoughness
	uniforms.baseColor = (pbr and pbr.baseColorFactor) or {1, 1, 1, 1}
	if pbr then
		local _pbrBaseColorTexture = pbr.baseColorTexture
		local _pbrMetallicRoughnessTexture = pbr.metallicRoughnessTexture

		main_texture = texture(textures, _pbrBaseColorTexture)
		local metallicRoughnessTexture = texture(textures, _pbrMetallicRoughnessTexture)

		if main_texture then
			uniforms.mainTexCoord = main_texture.tcoord
		end
		if metallicRoughnessTexture then
			uniforms.metallicRoughnessTexture = metallicRoughnessTexture.source
			uniforms.metallicRoughnessTextureCoord = metallicRoughnessTexture.tcoord
		end

		uniforms.metalness = pbr.metallicFactor
		uniforms.roughness = pbr.roughnessFactor
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
	uniforms.emissiveFactor = material.emissiveFactor or {0, 0, 0}
	uniforms.opaque = material.alphaMode == 'OPAQUE' or not material.alphaMode
	if material.alphaMode == 'MASK' then
		uniforms.alphaCutoff = material.alphaCutoff or 0.5
	else
		uniforms.alphaCutoff = 0.0
	end

	return {
		name = material.name,
		main_texture = main_texture,
		uniforms = uniforms,
		double_sided = material.doubleSided,
		alpha_mode = material.alphaMode or 'OPAQUE',
	}
end

local function parse_filter(value)
	if
	value == 9728 then
		return 'nearest'
	elseif
	value == 9729 then
		return 'linear'
	else
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
	else
		return 'clamp'
	end
end

local function get_data_array(buffer)
	local array = {}
	if ffi then
		for i = 0, buffer.count - 1 do
			local data_offset = ffi.cast('char*', getFFIPointer(buffer.data)) + buffer.offset + i * buffer.stride
			local ptr = ffi.cast('float*', data_offset)
			if buffer.type_elements_count > 1 then
				local vector = {}
				for j = 1, buffer.type_elements_count do
					local value = ptr[j-1]
					table.insert(vector, value)
				end
				table.insert(array, vector)
			else
				table.insert(array, ptr[0])
			end
		end
	end
	return array
end

local function read_animation(animation)
	local samplers = {}
	for i, v in ipairs(animation.samplers) do
		local time_buffer = get_buffer(v.input)
		local data_buffer = get_buffer(v.output)

		table.insert(samplers, {
			time_array = get_data_array(time_buffer),
			data_array = get_data_array(data_buffer),
			interpolation = v.interpolation,
		})
	end

	local channels = {}
	for i, v in ipairs(animation.channels) do
		table.insert(channels, {
			sampler = samplers[v.sampler + 1],
			target_node = v.target.node,
			target_path = v.target.path,
		})
	end

	return channels
end

local function load_image(io_read, path, images, texture)
	local source = texture.source + 1
	local MSFT_texture_dds = texture.extensions and texture.extensions.MSFT_texture_dds
	if MSFT_texture_dds then
		source = MSFT_texture_dds.source + 1
	end

	local image = images[source]
	local image_raw_data
	if image.uri then
		local base64data = image.uri:match('^data:image/.*;base64,(.+)')
		if base64data then
			image_raw_data = love.data.decode('data', 'base64', base64data)
		else
			local image_filename = path .. image.uri
			image_raw_data = love.filesystem.newFileData(io_read(image_filename), image_filename)
		end
	else
		local buffer_view = data.bufferViews[image.bufferView + 1]

		local data = buffers[buffer_view.buffer + 1]

		local offset = buffer_view.byteOffset or 0
		local length = buffer_view.byteLength

		image_raw_data = love.data.newDataView(data, offset, length)
	end

	local image_data
	if not MSFT_texture_dds then
		image_data = love.image.newImageData(image_raw_data)
	else
		image_data = love.image.newCompressedData(image_raw_data)
	end

	local image_source = love.graphics.newImage(image_data)
	image_data:release()
	return {
		source = image_source
	}
end

local function unpack_data(format, data, iterator)
	local pos = iterator.position
	iterator.position	= iterator.position + love.data.getPackedSize(format)
	return love.data.unpack(format, data, pos + 1)
end

local function glb_parser(glb_data)
	local iterator = {
		position = 0
	}
	local magic, version = unpack_data('<I4I4', glb_data, iterator)
	assert(magic == 0x46546C67, 'GLB: wrong magic!')
	assert(version == 0x2, 'Supported only GLTF 2.0!')

	local length = unpack_data('<I4', glb_data, iterator)

	local json_data
	local buffers = {}
	local bufferi = 1

	while iterator.position < length do
		local chunk_length, chunk_type = unpack_data('<I4I4', glb_data, iterator)
		local start_position = iterator.position
		if
		chunk_type == 0x4E4F534A then
			local data_view = love.data.newDataView(glb_data, iterator.position, chunk_length)
			json_data = json.decode(data_view:getString())
		elseif
		chunk_type == 0x004E4942 then
			local data_view = love.data.newDataView(glb_data, iterator.position, chunk_length)
			buffers[bufferi] = data_view
			bufferi = bufferi + 1
		end

		iterator.position = start_position + chunk_length
	end

	return json_data, buffers
end

--- Load gltf model by filename.
-- @function load
-- @tparam string filename The filepath to the gltf file (GLTF must be separated (.gltf+.bin+textures) or (.gltf+textures)
-- @tparam[opt=love.filesystem.read] function io_read Callback to read the file.
-- @treturn table
function glTFLoader.load(filename)
	local path = filename:match(".+/")
	local name, extension = filename:match("([^/]+)%.(.+)$")
	local io_read = love.filesystem.read
	assert(love.filesystem.getInfo(filename), 'in function <glTFLoader.load> file "' .. filename .. '" not found.')

	if extension == 'gltf' then
		local filedata = io_read(filename)
		data = json.decode(filedata)
		buffers = {}
		for i, v in ipairs(data.buffers) do
			local base64data = v.uri:match('^data:application/.*;base64,(.+)')
			if base64data then
				buffers[i] = love.data.decode('data', 'base64', base64data)
			else
				buffers[i] = love.data.newByteData(io_read(path .. v.uri))
			end
		end
	elseif extension == 'glb' then
		local filedata = io_read('data', filename)
		data, buffers = glb_parser(filedata)
	end

	local samplers = {}
	if data.samplers then
		for _, v in ipairs(data.samplers) do
			table.insert(samplers, {
				magFilter = parse_filter(v.magFilter),
				minFilter = parse_filter(v.minFilter),
				wrapS = parse_wrap(v.wrapS),
				wrapT = parse_wrap(v.wrapT),
			})
		end
	end

	local images = {}
	local textures = {}
	if data.textures then
		for _, texture in ipairs(data.textures) do
			local sampler = samplers[texture.sampler + 1]
			local image = images[texture.source + 1]

			if not image then
				image = load_image(io_read, path, data.images, texture)
				images[texture.source + 1] = image
			end

			table.insert(textures, {
				image = image, sampler = sampler
			})

			if sampler then
				image.source:setFilter(sampler.magFilter, sampler.minFilter)
				image.source:setWrap(sampler.wrapS, sampler.wrapT)
			end
		end
	end

	local skins = {}
	if data.skins then
		for _, v in ipairs(data.skins) do
			local buffer = get_buffer(v.inverseBindMatrices)
			table.insert(skins, {
				inverse_bind_matrices = get_data_array(buffer),
				joints = v.joints,
				skeleton = v.skeleton,
			})
		end
	end

	local materials = {}
	if data.materials then
		for i, v in ipairs(data.materials) do
			materials[i] = create_material(textures, v)
		end
	end

	local meshes = {}
	for i, v in ipairs(data.meshes) do
		meshes[i] = init_mesh(v)
	end

	local animations = {}
	if data.animations then
		for i, animation in ipairs(data.animations) do
			animations[i] = {
				channels = read_animation(animation),
				name = animation.name
			}
		end
	end

	return {
		asset = data.asset,
		nodes = data.nodes,
		scene = data.scene,
		materials = materials,
		meshes = meshes,
		scenes = data.scenes,
		images = images,
		animations = animations,
		skins = skins,
	}
end

return glTFLoader