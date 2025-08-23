#ifdef USE_SKINNING
	uniform sampler2D joints_texture;

	mat4 getBoneMatrix(const in float i) {
		int size = textureSize(joints_texture, 0).x;
		int j = int(i*float(0xFFFF)) * 4;
		int x = j % size;
		int y = j / size;
		vec4 v1 = texelFetch( joints_texture, ivec2( x,     y ), 0 );
		vec4 v2 = texelFetch( joints_texture, ivec2( x + 1, y ), 0 );
		vec4 v3 = texelFetch( joints_texture, ivec2( x + 2, y ), 0 );
		vec4 v4 = texelFetch( joints_texture, ivec2( x + 3, y ), 0 );
		return mat4( v1, v2, v3, v4 );

	}
#endif