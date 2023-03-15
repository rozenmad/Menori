#ifdef USE_SKINNING
      mat3 skinnig_normal_matrix = transpose(inverse(mat3(m_view * skin_matrix * m_model)));
      vert_normal = skinnig_normal_matrix * vert_normal;
#else
      mat3 normal_matrix = transpose(inverse(mat3(m_view * m_model)));
      vert_normal = normal_matrix * vert_normal;
#endif