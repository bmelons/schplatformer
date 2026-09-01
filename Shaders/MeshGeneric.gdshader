shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, vertex_lighting;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_nearest_mipmap, repeat_enable;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0, 0.001) = 0.5;

uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D texture_roughness : hint_roughness_r, filter_nearest_mipmap, repeat_enable;

uniform float metallic : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform sampler2D texture_metallic : hint_default_white, filter_nearest_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);

uniform float specular : hint_range(0.0, 1.0, 0.01) = 0.5;

uniform float uv1_blend_sharpness : hint_range(0.0, 150.0, 0.001) = 1.0;
uniform vec3 uv1_scale = vec3(1.0);
uniform vec3 uv1_offset = vec3(0.0);

varying vec3 uv1_triplanar_pos;
varying vec3 uv1_power_normal;

void vertex() {
    uv1_power_normal = pow(abs(NORMAL), vec3(uv1_blend_sharpness));
    uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
    uv1_triplanar_pos = (VERTEX * uv1_scale + uv1_offset) * vec3(1.0, -1.0, 1.0);
}

vec4 texture_three_point(sampler2D tex, vec2 uv) { // not my algorithm
    vec2 tex_size = vec2(textureSize(tex, 0));
    
    // Capture continuous derivatives to eliminate mipmap sampling seams
    vec2 dx = dFdx(uv);
    vec2 dy = dFdy(uv);

    vec2 p = uv * tex_size - 0.5;
    vec2 f = fract(p);
    vec2 base = floor(p);

    // Diagonal split for 3-point interpolation
    vec2 offset = f - step(1.0, f.x + f.y);

    // Compute exact UV coordinates for the 3 samples
    vec2 uv0 = (base + 0.5 + step(1.0, f.x + f.y)) / tex_size;
    vec2 uv1 = (base + 0.5 + vec2(step(1.0, f.x + f.y) - sign(offset.x), step(1.0, f.x + f.y))) / tex_size;
    vec2 uv2 = (base + 0.5 + vec2(step(1.0, f.x + f.y), step(1.0, f.x + f.y) - sign(offset.y))) / tex_size;

    vec4 c0 = textureGrad(tex, uv - offset / tex_size, dx, dy);
    vec2 c1off = vec2(offset.x - sign(offset.x), offset.y);
    vec4 c1 = textureGrad(tex, uv - c1off / tex_size, dx, dy);
    vec2 c2off = vec2(offset.x, offset.y - sign(offset.y));
    vec4 c2 = textureGrad(tex, uv - c2off / tex_size, dx, dy);

    return c0 + abs(offset.x) * (c1 - c0) + abs(offset.y) * (c2 - c0);
}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
    vec4 samp = vec4(0.0);
    samp += texture_three_point(p_sampler, p_triplanar_pos.xy) * p_weights.z;
    samp += texture_three_point(p_sampler, p_triplanar_pos.xz) * p_weights.y;
    samp += texture_three_point(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
    return samp;
}

void fragment() {
    vec4 albedo_tex = triplanar_texture(texture_albedo, uv1_power_normal, uv1_triplanar_pos);
    ALBEDO = albedo.rgb * albedo_tex.rgb;

    float metallic_tex = dot(triplanar_texture(texture_metallic, uv1_power_normal, uv1_triplanar_pos), metallic_texture_channel);
    METALLIC = metallic_tex * metallic;
    SPECULAR = specular;

    vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
    float roughness_tex = dot(triplanar_texture(texture_roughness, uv1_power_normal, uv1_triplanar_pos), roughness_texture_channel);
    ROUGHNESS = roughness_tex * roughness;

    ALPHA *= albedo.a * albedo_tex.a;
    ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
}