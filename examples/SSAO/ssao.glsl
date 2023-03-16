// http://john-chapman-graphics.blogspot.com/2013/01/ssao-tutorial.html
#define power 2.0

uniform sampler2D normal_c;
uniform sampler2D depth24_c;
uniform sampler2D noise_texture;

uniform int kernel_size;
uniform vec3 samples[64];
uniform float radius;
uniform float bias;
uniform bool range_check_enable;

uniform mat4 projection;
uniform mat4 inv_projection;

// reconstruct the view space positions of pixels from the depth buffer
vec3 get_position(vec2 uv) {
    float z = Texel(depth24_c, uv).r * 2.0 - 1.0;
    vec4 clipSpacePosition = vec4(uv * 2.0 - 1.0, z, 1.0);
    vec4 viewSpacePosition = inv_projection * clipSpacePosition;
    viewSpacePosition /= viewSpacePosition.w;
    vec4 position = viewSpacePosition;
    return position.xyz;
}

void effect()
{
    vec2 noiseScale = love_ScreenSize.xy / 4.0;
    vec2 uv = love_PixelCoord / love_ScreenSize.xy;
    float occlusion = 0.0;

    vec3 frag_position = get_position(uv);
    vec3 normal = normalize(Texel(normal_c, uv).rgb);
    vec3 random_vec = normalize(Texel(noise_texture, uv * noiseScale).xyz * 2.0 - 1.0);
    // create TBN change-of-basis matrix: from tangent-space to view-space
    vec3 tangent = normalize(random_vec - normal * dot(random_vec, normal));
    vec3 bitangent = cross(normal, tangent);
    mat3 TBN = mat3(tangent, bitangent, normal);

    for (int i = 0; i < kernel_size; ++i) {
        vec3 sample_position = TBN * samples[i]; // from tangent to view-space
        sample_position = frag_position + sample_position * radius; 
        
        // project sample position
        vec4 offset = vec4(sample_position, 1.0);
        offset = projection * offset; // from view to clip-space
        offset.xyz /= offset.w; // perspective divide
        offset.xyz = offset.xyz * 0.5 + 0.5; // transform to range 0.0 - 1.0
        
        float sample_depth = get_position(offset.xy).z;
        
        if (range_check_enable) {
            float range_check = smoothstep(0.0, 1.0, radius / abs(frag_position.z - sample_depth));
            occlusion += (sample_depth >= sample_position.z + bias ? 1.0 : 0.0) * range_check;
        } else {
            occlusion += (sample_depth >= sample_position.z + bias ? 1.0 : 0.0);
        }
    }
    occlusion = (occlusion / float(kernel_size));
    occlusion = pow(1.0 - occlusion, power);
    
    love_Canvases[0] = vec4(occlusion, occlusion, occlusion, 1.0);
}