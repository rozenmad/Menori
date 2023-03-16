#ifdef USE_SKINNING
      uniform samplerBuffer joints_matrices_buffer;

      mat4 getBoneMatrix(float i) {
            vec4 v1 = texelFetch(joints_matrices_buffer, int(i*float(0xFFFF))*4+0);
            vec4 v2 = texelFetch(joints_matrices_buffer, int(i*float(0xFFFF))*4+1);
            vec4 v3 = texelFetch(joints_matrices_buffer, int(i*float(0xFFFF))*4+2);
            vec4 v4 = texelFetch(joints_matrices_buffer, int(i*float(0xFFFF))*4+3);
            mat4 bone = mat4( v1, v2, v3, v4 );
            return bone;
      }
#endif