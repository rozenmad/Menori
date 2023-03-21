uniform vec4 baseColor;
uniform vec4 fog_color;
uniform vec3 camera_position;

uniform Image emissiveTexture;
uniform vec3 emissiveFactor;

uniform float alphaCutoff;
uniform bool opaque;

vec4 effect(vec4 color, Image t, vec2 texture_coords, vec2 screen_coords) {
      vec4 texcolor = Texel(t, texture_coords) * baseColor;
      vec3 emissive_texcolor = Texel(emissiveTexture, texture_coords).xyz * emissiveFactor;
      texcolor = vec4(texcolor.rgb + emissive_texcolor, texcolor.a);
      if (texcolor.a < alphaCutoff) {
            discard;
      }
      if (opaque) {
            texcolor.a = 1.0;
      }
      return texcolor * color;
}