local modules = (...):match('(.*%menori.modules.shaders.)')
modules = modules:gsub('%.', '/')

local chunks = {}
local function add_shader_chunk(path, name)
      chunks[name] = love.filesystem.read(path .. name)
end

if love._version_major > 11 then
      add_shader_chunk(modules .. 'chunks/', 'skinning_vertex_base.glsl')
      add_shader_chunk(modules .. 'chunks/', 'skinning_vertex.glsl')
else
      add_shader_chunk(modules .. 'chunks/love11/', 'skinning_vertex_base.glsl')
      add_shader_chunk(modules .. 'chunks/love11/', 'skinning_vertex.glsl')
end

add_shader_chunk(modules .. 'chunks/', 'skinning_normal.glsl')

local cache = {}

local function include_chunks(code)
	return code:gsub("#include <(.-)>", function (name)
		assert(chunks[name] ~= nil, name)
		return chunks[name]
	end)
end

local function load_shader_code(name, path, vert, frag, opt)
      local codevert = love.filesystem.read(path .. vert)
      local codefrag = love.filesystem.read(path .. frag)
      if opt and opt.defines then
            for k, v in pairs(opt.defines) do
                  codevert = string.format('#define %s\n', v) .. codevert
                  codefrag = string.format('#define %s\n', v) .. codefrag
            end
      end
      codevert = '#pragma language glsl3\n' .. codevert
      codefrag = '#pragma language glsl3\n' .. codefrag

      cache[name .. '_vert'] = include_chunks(codevert)
      cache[name .. '_frag'] = include_chunks(codefrag)
end

load_shader_code('default_mesh', modules, 'default_mesh_vert.glsl', 'default_mesh_frag.glsl')
load_shader_code('default_mesh_skinning', modules, 'default_mesh_vert.glsl', 'default_mesh_frag.glsl', { defines = {"USE_SKINNING"} })

load_shader_code('deferred_mesh', modules, 'default_mesh_vert.glsl', 'deferred_mesh_frag.glsl')
load_shader_code('deferred_mesh_skinning', modules, 'default_mesh_vert.glsl', 'deferred_mesh_frag.glsl', { defines = {"USE_SKINNING"} })

local shaders = {
      default_mesh = love.graphics.newShader(cache['default_mesh_vert'], cache['default_mesh_frag']),
      default_mesh_skinning = love.graphics.newShader(cache['default_mesh_skinning_vert'], cache['default_mesh_skinning_frag']),
      deferred_mesh = love.graphics.newShader(cache['deferred_mesh_vert'], cache['deferred_mesh_frag']),
      deferred_mesh_skinning = love.graphics.newShader(cache['deferred_mesh_skinning_vert'], cache['deferred_mesh_skinning_frag']),
}

return {
      cache = cache,
      add_shader_chunk = add_shader_chunk,
      load_shader_code = load_shader_code,
      shaders = shaders,
}