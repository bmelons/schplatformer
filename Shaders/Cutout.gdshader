shader_type spatial;
render_mode cull_disabled, depth_draw_opaque,vertex_lighting;

// 1. Use filter_nearest_mipmap (or filter_nearest) so you aren't double-filtering
uniform sampler2D sprite_texture : source_color;
uniform sampler2D cardboard_texture : source_color;
uniform sampler2D paper_normal : hint_normal;

uniform vec4 cardboard_tint : source_color = vec4(0.72, 0.58, 0.42, 1.0);
uniform float alpha_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.85;
uniform float normal_depth : hint_range(0.0, 2.0) = 0.5;
uniform int border_size = 3;
const float r = 3.0;

int circle_height_at_width(float a) {
		// Godot Shader Language implementation
	float a_round = round(a);
	float division = a_round / float(border_size);
	float inside_sqrt = 1.0 - (division * division);
	int result = int(round(r * sqrt(inside_sqrt)));
	return result;
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

bool threscheck(vec2 uv, vec2 texel_size) {
    bool met_threshold = false;
    for (int ix = -border_size; ix <= border_size; ix++) {
		int ysize = circle_height_at_width(float(ix));
        for (int iy = -ysize; iy <= ysize; iy++) {
            vec2 sample_uv = uv + vec2(texel_size.x * float(ix), texel_size.y * float(iy));

            // Skip sampling if outside standard [0.0, 1.0] UV bounds
            if (sample_uv.x < 0.0 || sample_uv.x > 1.0 || sample_uv.y < 0.0 || sample_uv.y > 1.0) {
                continue;
            }

            vec4 sprite_col = texture_three_point(sprite_texture, sample_uv);
            if (sprite_col.a >= alpha_threshold) {
                met_threshold = true;
            }
        }
    }
    return met_threshold;
}

void fragment() {
    vec4 sprite_col = texture_three_point(sprite_texture, UV);
	vec2 texture_dimensions = vec2(textureSize(sprite_texture, 0));
    vec2 texel_size = 1.0 / texture_dimensions;
	
    if (!threscheck(UV,texel_size)) {
        discard;
    }

    if (FRONT_FACING) {
        vec4 card_col = texture_three_point(cardboard_texture, UV) * cardboard_tint;
        ALBEDO = mix(card_col.rgb, sprite_col.rgb, sprite_col.a);
        NORMAL_MAP = texture_three_point(paper_normal, UV).rgb;
    } else {
        NORMAL = -NORMAL;
        vec2 back_uv = vec2(1.0 - UV.x, UV.y);
        vec4 back_card = texture_three_point(cardboard_texture, back_uv) * cardboard_tint;
        ALBEDO = back_card.rgb;
        NORMAL_MAP = texture_three_point(paper_normal, back_uv).rgb;
    }

    ROUGHNESS = roughness_val;
    SPECULAR = 0.05;
    NORMAL_MAP_DEPTH = normal_depth;
}