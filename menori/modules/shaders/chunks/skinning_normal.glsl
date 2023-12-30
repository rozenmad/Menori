#ifdef USE_SKINNING
      vert_normal = vec4(m_transpose(m_inverse(skin_matrix * m_model)) * vec4(vert_normal, 0.0)).xyz;
#endif