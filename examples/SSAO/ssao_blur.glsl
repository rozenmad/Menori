uniform sampler2D ssao_c;

vec4 effect(vec4 color, Image t, vec2 texture_coords, vec2 screen_coords) {
      vec2 uv = love_PixelCoord / love_ScreenSize.xy;
      vec2 texelSize = 1.0 / love_ScreenSize.xy;
      float result = 0.0;
      for( int x = -2; x < 2; ++x ) {
            for( int y = -2; y < 2; ++y ) {
                  vec2 offset = vec2(float(x), float(y)) * texelSize;
                  result += Texel(ssao_c, uv + offset).r;
            }
      }
      result = result / (4.0 * 4.0);
      return vec4(result, result, result, 1.0);
}  