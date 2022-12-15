#ifdef USE_SKINNING
      vert_normal = vec4(transpose(inverse(skin_matrix * m_model)) * vec4(vert_normal, 0.0)).xyz;
#endif