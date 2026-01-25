--[[
-------------------------------------------------------------------------------
	Menori
	@author Max-Dil
	2025
-------------------------------------------------------------------------------
]]

local obj = {}

local modules = (...):match('(.*%menori.modules.)')

local ModelNode = require (modules .. 'core3d.model_node')
local Node = require (modules .. 'node')
local Mesh = require (modules .. 'core3d.mesh')
local Material = require (modules .. 'core3d.material')

local mtllib_cache = {}

local function split(str, sep)
    local result = {}
    for match in str:gmatch(string.format('([^%s]+)', sep or '%s')) do
        table.insert(result, match)
    end
    return result
end

local function parse_mtllib(path, base_dir)
    local full_path = base_dir .. path
    if mtllib_cache[full_path] then return mtllib_cache[full_path] end

    local materials = {}
    local current_mtl = nil

    for line in love.filesystem.lines(full_path) do
        local v = split(line, ' ')
        if v[1] == 'newmtl' then
            current_mtl = {name = v[2]}
            materials[v[2]] = current_mtl
        elseif current_mtl then
            if v[1] == 'Kd' then
                current_mtl.baseColor = {tonumber(v[2]), tonumber(v[3]), tonumber(v[4]), 1.0}
            elseif v[1] == 'map_Kd' then
                current_mtl.main_texture = love.graphics.newImage(base_dir .. v[2])
            elseif v[1] == 'd' or v[1] == 'Tr' then
                current_mtl.alpha = tonumber(v[2])
                if current_mtl.alpha and current_mtl.alpha < 1.0 then
                    current_mtl.alpha_mode = 'BLEND'
                end
            elseif v[1] == 'illum' then
                current_mtl.illum = tonumber(v[2])
            end
        end
    end

    mtllib_cache[full_path] = materials
    return materials
end

function obj.load(path)
    local base_dir = path:match('(.*[/\\])') or ''

    local vertices, normals, texcoords = {}, {}, {}
    local groups = {}
    local materials = {}
    local current_group = {name = 'default', material = nil, faces = {}}
    local current_material = nil

    for line in love.filesystem.lines(path) do
        local v = split(line, ' ')

        if v[1] == 'v' then
            vertices[#vertices + 1] = {tonumber(v[2]), tonumber(v[3]), tonumber(v[4])}
        elseif v[1] == 'vn' then
            normals[#normals + 1] = {tonumber(v[2]), tonumber(v[3]), tonumber(v[4])}
        elseif v[1] == 'vt' then
            texcoords[#texcoords + 1] = {tonumber(v[2]), 1.0 - tonumber(v[3])}

        elseif v[1] == 'f' then
            local face = {}
            for i = 2, #v do
                local indices = split(v[i], '/')
                local vertex = {
                    v = tonumber(indices[1]),
                    vt = indices[2] ~= '' and tonumber(indices[2]) or nil,
                    vn = indices[3] ~= '' and tonumber(indices[3]) or nil
                }
                face[#face + 1] = vertex
            end
            current_group.faces[#current_group.faces + 1] = face
        elseif v[1] == 'g' or v[1] == 'o' then
            if #current_group.faces > 0 then
                groups[#groups + 1] = current_group
            end
            current_group = {
                name = v[2] or 'unnamed',
                material = current_material,
                faces = {}
            }
        elseif v[1] == 'usemtl' then
            current_material = v[2]
            if #current_group.faces > 0 then
                groups[#groups + 1] = current_group
                current_group = {
                    name = current_group.name,
                    material = current_material,
                    faces = {}
                }
            else
                current_group.material = current_material
            end
        elseif v[1] == 'mtllib' then
            local mtl_materials = parse_mtllib(v[2], base_dir)
            for k, v in pairs(mtl_materials) do
                materials[k] = v
            end
        end
    end

    if #current_group.faces > 0 then
        groups[#groups + 1] = current_group
    end

    local root_node = Node('OBJ group')
    root_node.name = 'root'

    for _, group in ipairs(groups) do
        local mesh_vertices, mesh_indices = {}, {}
        local index_map = {}
        local index_counter = 1

        for _, face in ipairs(group.faces) do
            local face_indices = {}

            for _, vertex in ipairs(face) do
                local key = string.format('%d/%d/%d',
                    vertex.v or 0,
                    vertex.vt or 0,
                    vertex.vn or 0
                )

                if not index_map[key] then
                    local pos = vertices[vertex.v] or {0, 0, 0}
                    local uv = vertex.vt and texcoords[vertex.vt] or {0, 0}
                    local normal = vertex.vn and normals[vertex.vn] or {0, 0, 0}

                    mesh_vertices[#mesh_vertices + 1] = {
                        pos[1], pos[2], pos[3],
                        uv[1], uv[2],
                        normal[1], normal[2], normal[3]
                    }

                    index_map[key] = index_counter
                    index_counter = index_counter + 1
                end

                face_indices[#face_indices + 1] = index_map[key]
            end

            if #face_indices == 4 then
                mesh_indices[#mesh_indices + 1] = face_indices[1]
                mesh_indices[#mesh_indices + 1] = face_indices[2]
                mesh_indices[#mesh_indices + 1] = face_indices[3]
                mesh_indices[#mesh_indices + 1] = face_indices[1]
                mesh_indices[#mesh_indices + 1] = face_indices[3]
                mesh_indices[#mesh_indices + 1] = face_indices[4]
            else
                for _, idx in ipairs(face_indices) do
                    mesh_indices[#mesh_indices + 1] = idx
                end
            end
        end

        if #mesh_vertices > 0 then
            local mesh = Mesh({
                vertices = mesh_vertices,
                indices = mesh_indices,
                vertexformat = Mesh.default_vertexformat,
                mode = 'triangles'
            })

            local material_props = group.material and materials[group.material]
            local material = Material.default:clone()
            material.name = group.material or 'default'

            if material_props then
                if material_props.baseColor then
                    material:set('baseColor', material_props.baseColor)
                end
                if material_props.main_texture then
                    material.main_texture = material_props.main_texture
                end
                if material_props.alpha_mode then
                    material.alpha_mode = material_props.alpha_mode
                end
            end

            local group_node = ModelNode(mesh, material)
            group_node.name = group.name
            root_node:attach(group_node)
        end
    end

    return root_node
end

return obj