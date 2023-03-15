uniform sampler2D ssao_c;

vec4 effect(vec4 color, Image t, vec2 texture_coords, vec2 screen_coords) {
      vec4 texcolor = Texel(t, texture_coords) * color;
      float ssao_value = Texel(ssao_c, texture_coords).r;
      if( texcolor.a <= 0.0 ) {
            discard;
      }
      return vec4(texcolor.xyz * ssao_value, 1.0);
}