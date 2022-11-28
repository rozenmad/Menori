return [[
#pragma language glsl3

uniform vec4 baseColor;
uniform vec4 fog_color;
uniform vec3 camera_position;
uniform Image emissiveTexture;

vec4 effect(vec4 color, Image t, vec2 texture_coords, vec2 screen_coords)
{
      vec4 texcolor = Texel(t, texture_coords);
      vec4 emissive_texcolor = Texel(emissiveTexture, texture_coords);
      if( texcolor.a <= 0.0f ) discard;
      return texcolor * baseColor;
}
]]