#ifdef VERTEX
uniform mat4 m_model;
uniform mat4 m_view;
uniform mat4 m_projection;

attribute vec3 VertexNormal;

varying vec3 normal;
varying vec3 frag_position;

// love2d use row major matrices by default, we have column major and need transpose it.
// 11.3 love has bug with matrix layout in shader:send().
vec4 position(mat4 transform_projection, vec4 vertex_position) {
      normal = normalize(VertexNormal);
      vec4 position = vertex_position * m_model;
      frag_position = position.xyz;
      return position * m_view * m_projection;
}
#endif

#ifdef PIXEL
varying vec3 normal;
varying vec3 frag_position;
uniform vec3 view_position;

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
      
      return (light.ambient + light.diffuse * diff + light.specular * spec) * 
            attenuation;
} 

vec4 effect(vec4 color, Image t, vec2 texture_coords, vec2 screen_coords) {
      vec3 view_direction = normalize(view_position - frag_position);

      vec3 result = vec3(0.0);
      for(int i = 0; i < MAX_POINT_LIGHTS; i++) {
            if( point_lights[i].constant != 0.0 ) {
                  result += calculate_point_light(point_lights[i], normal, frag_position, view_direction);
            }
      }

      vec4 texcolor = Texel(t, texture_coords);
      if( texcolor.a <= 0.0 ) discard;
      return texcolor * color * vec4(result, 1.0);
}
#endif