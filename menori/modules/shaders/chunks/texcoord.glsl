#ifdef USE_TEXCOORD
      VaryingTexCoord.xy = VertexTexCoord.xy;
#else
      VaryingTexCoord.xy = vec2(0.0);
#endif