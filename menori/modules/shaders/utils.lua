local modules = (...):match('(.*%menori.modules.shaders.)')
local menori_modules = (...):match('(.*%menori.modules.)')

local ffi = require (menori_modules .. 'libs.ffi')

local features = love.graphics.getSupported()

local data_format = {
      ["float"]       = "float",
      ["floatvec2"]   = "vec2",
      ["floatvec3"]   = "vec3",
      ["floatvec4"]   = "vec4",
      ["floatmat2x2"] = "mat2",
      ["floatmat3x3"] = "mat3",
      ["floatmat4x4"] = "mat4",
      ["int32"]       = "int",
      ["int32vec2"]   = "ivec2",
      ["int32vec3"]   = "ivec3",
      ["int32vec4"]   = "ivec4",
      ["uint32"]      = "uint",
      ["uint32vec2"]  = "uvec2",
      ["uint32vec3"]  = "uvec3",
      ["uint32vec4"]  = "uvec4",
      ["snorm8vec4"]  = "vec4",
      ["unorm8vec4"]  = "vec4",
      ["int8vec4"]    = "ivec4",
      ["uint8vec4"]   = "uvec4",
      ["snorm16vec2"] = "vec2",
      ["snorm16vec4"] = "vec4",
      ["unorm16vec2"] = "vec2",
      ["unorm16vec4"] = "vec4",
      ["int16vec2"]   = "ivec2",
      ["int16vec4"]   = "ivec4",
      ["uint16"]      = "uint",
      ["uint16vec2"]  = "uvec2",
      ["uint16vec4"]  = "uvec4",
      ["bool"]        = "bool",
      ["boolvec2"]    = "bvec2",
      ["boolvec3"]    = "bvec3",
      ["boolvec4"]    = "bvec4",
}

local function readfile(path, name)
      path = path:gsub('%.', '/')
      return love.filesystem.read(path .. name .. '.glsl')
end

local chunks = {}
local function add_shader_chunk(path, name)
      chunks[name .. '.glsl'] = readfile(path, name)
end

local shaders_path = love._version_major > 11 and '.love12.' or ''
local md5_hash

if love._version_major > 11 then
      md5_hash = function (s)
            return love.data.hash('string', 'md5', s)
      end
else
      md5_hash = function (s)
            return love.data.hash('md5', s)
      end
end

add_shader_chunk(modules .. 'chunks.', 'billboard_base')
add_shader_chunk(modules .. 'chunks.', 'billboard')
add_shader_chunk(modules .. 'chunks.', 'color')
add_shader_chunk(modules .. 'chunks.', 'inverse')
add_shader_chunk(modules .. 'chunks.', 'normal')
add_shader_chunk(modules .. 'chunks.', 'skinning_vertex_base')
add_shader_chunk(modules .. 'chunks.', 'skinning_vertex')
add_shader_chunk(modules .. 'chunks.', 'texcoord')
add_shader_chunk(modules .. 'chunks.', 'transpose')

local function include_chunks(code)
      local lines = {}
      for line in string.gmatch(code .. "\n", "(.-)\n") do
            local temp = line:gsub("^[ \t]*#menori_include <(.-)>", function (name)
                  assert(chunks[name] ~= nil, name)
                  return chunks[name]
            end)
            table.insert(lines, temp)
      end
      return table.concat(lines, '\n')
end

local function preprocess_shader(code, opt)
      if opt then
            local additional = ''
            if opt.definitions then
                  local t = {}
                  for _, v in ipairs(opt.definitions) do
                        table.insert(t, string.format('#define %s\n', v))
                  end
                  if #t > 0 then
                        local s = table.concat(t) .. '\n'
                        additional = s .. additional
                  end
            end

            if opt.attributes then
                  local s = table.concat(opt.attributes, '\n') .. '\n'
                  additional = s .. additional
            end

            code = additional .. code
      end

      if features['glsl3'] then
            code = '#pragma language glsl3\n' .. code
      end

      return include_chunks(code)
end

local cache = {
      default_mesh_vert  = readfile(modules .. shaders_path, 'default_mesh_vert'),
      default_mesh_frag  = readfile(modules .. shaders_path, 'default_mesh_frag'),
      deferred_mesh_frag = readfile(modules .. shaders_path, 'deferred_mesh_frag'),
}

local shader_defines = {
      VertexColor    = "USE_COLOR",
      VertexJoints   = "USE_SKINNING",
      VertexTexCoord = "USE_TEXCOORD",
}

local shader_program_cache = {}

local function create_shader(material)
      local opt = {
            definitions = {}, attributes = {},
      }

      if love._version_major > 11 then
            for _, element in ipairs(material.attributes) do
                  local define = shader_defines[element.name]
                  if define then
                        table.insert(opt.definitions, define)
                  end

                  table.insert(opt.attributes,
                        string.format("layout (location = %d) in %s %s;",
                              element.location,
                              data_format[element.format],
                              element.name
                        ))
            end
      else
            for _, element in ipairs(material.attributes) do
                  local define = shader_defines[element[1]]
                  if define then
                        table.insert(opt.definitions, define)
                  end
            end
      end

      local vertcode = material.shader_vertcode
      local fragcode = material.shader_fragcode

      material.shader_vertcode = vertcode
      material.shader_fragcode = fragcode

      vertcode = preprocess_shader(vertcode, opt)
      opt.attributes = nil
      fragcode = preprocess_shader(fragcode, opt)

      local cache_key = md5_hash(vertcode .. fragcode)

      local shader = shader_program_cache[cache_key]
      if not shader then
            shader = love.graphics.newShader(fragcode, vertcode)
            shader_program_cache[cache_key] = shader
      end
      return shader
end

return {
      cache = cache,
      add_shader_chunk = add_shader_chunk,
      preprocess_shader = preprocess_shader,
      create_shader = create_shader,
}