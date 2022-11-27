return [[
      varying vec4 pos;
      #ifdef VERTEX
            uniform mat4 m_model;
            uniform mat4 m_view;
            uniform mat4 m_projection;
            uniform bool use_joints;
            uniform mat4 joints_matrices[150];
            
            attribute vec4 VertexJoints;
            attribute vec4 VertexWeights;
            vec4 position(mat4 transform_projection, vec4 vertex_position) {
                  pos = vertex_position * m_model;
                  vec4 worldPosition = vec4(pos.xyz, 1.0);
                  if (use_joints) {
                        mat4 skinMat =
                              VertexWeights.x * joints_matrices[int(VertexJoints.x*0xFFFF)] +
                              VertexWeights.y * joints_matrices[int(VertexJoints.y*0xFFFF)] +
                              VertexWeights.z * joints_matrices[int(VertexJoints.z*0xFFFF)] +
                              VertexWeights.w * joints_matrices[int(VertexJoints.w*0xFFFF)];
                        worldPosition = skinMat * worldPosition;
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