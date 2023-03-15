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
      vec3 vert_normal = VertexNormal;
      vec4 vert_position = vec4((m_model * vertex_position + vertex_position * 0.01).xyz, 1.0);

      #include <skinning_vertex.glsl>
      #include <normal.glsl>

      normal = vert_normal;

      frag_position = vert_position.xyz;
      return m_projection * m_view * vert_position;
}