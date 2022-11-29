return [[
#pragma language glsl3

varying vec3 normal;
varying vec3 frag_position;

uniform mat4 m_model;
uniform mat4 m_view;
uniform mat4 m_projection;
uniform bool use_joints;
uniform mat4 joints_matrices[150];

attribute vec3 VertexNormal;
attribute vec4 VertexJoints;
attribute vec4 VertexWeights;   

vec4 position(mat4 transform_projection, vec4 vertex_position) {
      vec3 object_normal = normalize(VertexNormal);
      vec4 world_position = vec4((m_model * vertex_position).xyz, 1.0);
      if (use_joints) {
            mat4 skin_matrix = mat4(0.0);
            skin_matrix += VertexWeights.x * joints_matrices[int(VertexJoints.x*0xFFFF)];
            skin_matrix += VertexWeights.y * joints_matrices[int(VertexJoints.y*0xFFFF)];
            skin_matrix += VertexWeights.z * joints_matrices[int(VertexJoints.z*0xFFFF)];
            skin_matrix += VertexWeights.w * joints_matrices[int(VertexJoints.w*0xFFFF)];

            world_position = skin_matrix * world_position;
            object_normal = vec4(transpose(inverse(skin_matrix * m_model)) * vec4(object_normal, 0.0)).xyz;
      } else {
            object_normal = vec4(transpose(inverse(m_model)) * vec4(object_normal, 0.0)).xyz;
      }
      normal = object_normal.xyz;
      
      frag_position = world_position.xyz;
      return m_projection * m_view * world_position;
}
]]