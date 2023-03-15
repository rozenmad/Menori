varying vec3 normal;
varying vec3 frag_position;

uniform vec4 baseColor;
uniform vec4 fog_color;
uniform vec3 camera_position;

uniform Image emissiveTexture;
uniform vec3 emissiveFactor;

uniform float alphaCutoff;
uniform bool opaque;
uniform Image MainTex;

void effect() {
      vec4 texcolor = Texel(MainTex, VaryingTexCoord.xy) * baseColor;
      vec3 emissive_texcolor = Texel(emissiveTexture, VaryingTexCoord.xy).xyz * emissiveFactor;
      texcolor = vec4(texcolor.rgb + emissive_texcolor, texcolor.a);
      if (texcolor.a < alphaCutoff) {
            discard;
      }
      if (opaque) {
            texcolor.a = 1.0;
      }
      love_Canvases[0] = vec4(0.0, 0.0, 0.0, 1.0);
      love_Canvases[1] = vec4((normal+1.0)*0.5, 1.0);
      love_Canvases[2] = vec4(frag_position, 1.0);
}