varying vec3 normal;
varying vec4 frag_position;

uniform mat4 m_model;
uniform mat4 m_view;
uniform mat4 m_projection;

#menori_include <morph_base.glsl>

#menori_include <transpose.glsl>
#menori_include <inverse.glsl>
#menori_include <skinning_vertex_base.glsl>

vec4 position(mat4 transform_projection, vec4 vertex_position) {
	#menori_include <normal_base.glsl>
	vec4 vert_position = vertex_position;
	
	#menori_include <morph.glsl>

	vert_position = vec4((m_model * vert_position).xyz, 1.0);

	#menori_include <skinning_vertex.glsl>
	#menori_include <normal.glsl>

	normal = vert_normal;

	frag_position = m_view * vert_position;
	return m_projection * frag_position;
}