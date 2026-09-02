// NOTE: Shader automatically converted from Godot Engine 4.7.2.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_disabled, vertex_lighting;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

void vertex() {
	// Shading Mode: Per Vertex
	ROUGHNESS = roughness;

	UV = UV * uv1_scale.xy + uv1_offset.xy;
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
void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture_three_point(texture_albedo, base_uv);

	// Vertex Color Use as Albedo: Enabled
	albedo_tex *= COLOR;

	ALBEDO = albedo.rgb * albedo_tex.rgb;
	ALPHA = albedo.a;

	float metallic_tex = dot(texture_three_point(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture_three_point(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
}
