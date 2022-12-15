varying vec3 normal;
varying vec3 frag_position;

uniform mat4 m_model;
uniform mat4 m_view;
uniform mat4 m_projection;

attribute vec3 VertexNormal;
attribute vec4 VertexJoints;
attribute vec4 VertexWeights;

#include <skinning_vertex_base.glsl>

vec4 position(mat4 transform_projection, vec4 vertex_position) {
      vec3 vert_normal = normalize(VertexNormal);
      vec4 vert_position = vec4((m_model * vertex_position).xyz, 1.0);

      #include <skinning_vertex.glsl>
      #include <skinning_normal.glsl>
      
      #ifndef USE_SKINNING
            vert_normal = vec4(transpose(inverse(m_model)) * vec4(vert_normal, 0.0)).xyz;
      #endif
      normal = normalize(vert_normal.xyz);

      frag_position = vert_position.xyz;
      return m_projection * m_view * vert_position;
}
