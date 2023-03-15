#pragma language glsl3
varying vec3 normal;
varying vec4 frag_position;
uniform vec3 view_position;

uniform mat4 m_inv_view;

uniform vec4 baseColor;

struct PointLight {
      vec3 position;
      vec3 ambient;
      vec3 diffuse;
      vec3 specular;
      
      float constant;
      float linear;
      float quadratic;
};

const int MAX_POINT_LIGHTS = 6;
uniform PointLight point_lights[MAX_POINT_LIGHTS];
uniform int point_lights_count;

vec3 calculate_point_light(in PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir) {
      vec3 light_direction = normalize(light.position - fragPos);
      float diff = max(dot(normal, light_direction), 0.0);

      vec3 reflect_direction = reflect(-light_direction, normal);
      float spec = pow(max(dot(viewDir, reflect_direction), 0.0), 96.0);

      float dist = length(light.position - fragPos);
      float attenuation = 1.0 / (light.constant + light.linear * dist + light.quadratic * 
            (dist * dist));
      
      return (light.ambient + light.diffuse * diff + light.specular * spec) * attenuation;
} 

vec4 effect(vec4 color, Image t, vec2 texture_coords, vec2 screen_coords) {
      vec3 frag_p = (m_inv_view * frag_position).xyz;
      vec3 view_direction = normalize(view_position - frag_p.xyz);

      vec3 result = vec3(0.0);
      for(int i = 0; i < point_lights_count; i++) {
            if( point_lights[i].constant != 0.0 ) {
                  result += calculate_point_light(point_lights[i], normal, frag_p, view_direction);
            }
      }

      vec4 texcolor = Texel(t, texture_coords);
      if( texcolor.a <= 0.0 ) discard;
      return texcolor * color * vec4(result, 1.0) * baseColor;
}