varying vec3 normal;
varying vec4 frag_position;

uniform mat4 m_model;
uniform mat4 m_view;
uniform mat4 m_projection;

attribute vec3 VertexNormal;
attribute vec4 VertexJoints;
attribute vec4 VertexWeights;

#menori_include <transpose.glsl>
#menori_include <inverse.glsl>
#menori_include <skinning_vertex_base.glsl>

vec4 position(mat4 transform_projection, vec4 vertex_position) {
      vec3 vert_normal = VertexNormal;
      vec4 vert_position = vec4((m_model * vertex_position).xyz, 1.0);

      #menori_include <skinning_vertex.glsl>
      #menori_include <normal.glsl>

      normal = vert_normal;

      frag_position = m_view * vert_position;
      return m_projection * frag_position;
}