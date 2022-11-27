return [[
#pragma language glsl3
varying vec4 pos;
#ifdef VERTEX
      uniform mat4 m_model;
      uniform mat4 m_view;
      uniform mat4 m_projection;

      uniform bool use_joints;
      uniform samplerBuffer joints_matrices_buffer;

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
            pos = vertex_position * m_model;
            vec4 worldPosition = vec4(pos.xyz, 1.0);
            if (use_joints) {
                  vec4 skinned = vec4( 0.0 );
                  skinned += getBoneMatrix(VertexJoints.x) * worldPosition * VertexWeights.x;
                  skinned += getBoneMatrix(VertexJoints.y) * worldPosition * VertexWeights.y;
                  skinned += getBoneMatrix(VertexJoints.z) * worldPosition * VertexWeights.z;
                  skinned += getBoneMatrix(VertexJoints.w) * worldPosition * VertexWeights.w;
                  worldPosition = skinned;
            }
            return worldPosition * m_view * m_projection;
      }
#endif
#ifdef PIXEL
      uniform vec4 baseColor;
      uniform vec4 fog_color;
      uniform vec3 camera_position;
      uniform Image emissiveTexture;
      
      vec4 effect(vec4 color, Image t, vec2 texture_coords, vec2 screen_coords)
      {
            vec4 texcolor = Texel(t, texture_coords);
            vec4 emissive_texcolor = Texel(emissiveTexture, texture_coords);
            if( texcolor.a <= 0.0f ) discard;
            return texcolor * baseColor;
      }
#endif
]]