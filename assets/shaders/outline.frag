// Receives the texture from love.graphics.draw()
extern Image texture;

// Uniforms sent from our Lua code
uniform vec4 outline_color;
uniform vec2 texture_size;
uniform bool use_outline;
uniform float outline_thickness; // ✨ New uniform for thickness

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 original_color = Texel(texture, texture_coords);

    if (!use_outline || outline_thickness <= 0.0) {
        return original_color;
    }

    if (original_color.a > 0.1) {
        return original_color;
    }

    // --- New Thickness Logic ---
    float max_alpha = 0.0;
    vec2 pixel_size = 1.0 / texture_size;

    // Loop in a square around the current pixel, based on the thickness
    for (float x = -outline_thickness; x <= outline_thickness; x += 1.0) {
        for (float y = -outline_thickness; y <= outline_thickness; y += 1.0) {
            // We can skip the center pixel, but it doesn't really matter
            if (x == 0.0 && y == 0.0) {
                continue;
            }
            float neighbor_alpha = Texel(texture, texture_coords + vec2(x, y) * pixel_size).a;
            max_alpha = max(max_alpha, neighbor_alpha);
        }
    }

    if (max_alpha > 0.1) {
        return outline_color * color;
    }

    return original_color;
}