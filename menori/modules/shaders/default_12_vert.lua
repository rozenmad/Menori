return [[
#pragma language glsl3

varying vec3 normal;
varying vec3 frag_position;

uniform mat4 m_model;
uniform mat4 m_view;
uniform mat4 m_projection;

uniform bool use_joints;
uniform samplerBuffer joints_matrices_buffer;

attribute vec3 VertexNormal;
attribute vec4 VertexJoints;
attribute vec4 VertexWeights;

mat4 getBoneMatrix(float i) {
      vec4 v1 = texelFetch(joints_matrices_buffer, int(i*0xFFFF)*4+0);
      vec4 v2 = texelFetch(joints_matrices_buffer, int(i*0xFFFF)*4+1);
      vec4 v3 = texelFetch(joints_matrices_buffer, int(i*0xFFFF)*4+2);
      vec4 v4 = texelFetch(joints_matrices_buffer, int(i*0xFFFF)*4+3);
      mat4 bone = mat4( v1, v2, v3, v4 );
      return bone;
}

vec4 position(mat4 transform_projection, vec4 vertex_position) {
      vec3 object_normal = normalize(VertexNormal);
      vec4 world_position = vec4((m_model * vertex_position).xyz, 1.0);
      if (use_joints) {
            mat4 skin_matrix = mat4(0.0);
            skin_matrix += VertexWeights.x * getBoneMatrix(VertexJoints.x);
            skin_matrix += VertexWeights.y * getBoneMatrix(VertexJoints.y);
            skin_matrix += VertexWeights.z * getBoneMatrix(VertexJoints.z);
            skin_matrix += VertexWeights.w * getBoneMatrix(VertexJoints.w);

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