#ifdef USE_SKINNING
      mat4 skin_matrix = mat4(0.0);
      skin_matrix += VertexWeights.x * getBoneMatrix(VertexJoints.x);
      skin_matrix += VertexWeights.y * getBoneMatrix(VertexJoints.y);
      skin_matrix += VertexWeights.z * getBoneMatrix(VertexJoints.z);
      skin_matrix += VertexWeights.w * getBoneMatrix(VertexJoints.w);

      vert_position = skin_matrix * vert_position;
#endif