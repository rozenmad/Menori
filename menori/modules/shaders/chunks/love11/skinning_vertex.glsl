#ifdef USE_SKINNING
      mat4 skin_matrix = mat4(0.0);
      skin_matrix += VertexWeights.x * joints_matrices[int(VertexJoints.x*float(0xFFFF))];
      skin_matrix += VertexWeights.y * joints_matrices[int(VertexJoints.y*float(0xFFFF))];
      skin_matrix += VertexWeights.z * joints_matrices[int(VertexJoints.z*float(0xFFFF))];
      skin_matrix += VertexWeights.w * joints_matrices[int(VertexJoints.w*float(0xFFFF))];

      vert_position = skin_matrix * vert_position;
#endif