varying vec3 normal;
varying vec4 frag_position;

out vec4 VaryingTexCoord;
out vec4 VaryingColor;

uniform mat4 m_model;
uniform mat4 m_view;
uniform mat4 m_projection;

#menori_include <morph_base.glsl>

#menori_include <transpose.glsl>
#menori_include <inverse.glsl>
#menori_include <skinning_vertex_base.glsl>

void vertexmain() {
	#menori_include <normal_base.glsl>
	vec4 vert_position = vec4(VertexPosition.xyz, 1.0);
	
	#menori_include <morph.glsl>

	vert_position = m_model * vert_position;

	#menori_include <texcoord.glsl>
	#menori_include <color.glsl>
	#menori_include <skinning_vertex.glsl>
	#menori_include <normal.glsl>

	normal = vert_normal;

	frag_position = m_view * vert_position;
	gl_Position = m_projection * frag_position;
}