varying vec3 normal;
varying vec4 frag_position;

#include <billboard_base.glsl>

uniform mat4 m_view;
uniform mat4 m_projection;
uniform mat4 m_model;

attribute vec3 VertexNormal;
attribute vec3 instance_position;

vec4 position(mat4 transform_projection, vec4 vertex_position) {
      vec3 vert_normal = VertexNormal;
      vec4 vert_position = vec4((m_model * vertex_position).xyz, 1.0);

      #include <billboard.glsl>
      #include <normal.glsl>

      vert_position += vec4(instance_position.xyz, 0.0);

      normal = vert_normal;
      frag_position = m_view * m_model * vert_position;
      return m_projection * frag_position;
}