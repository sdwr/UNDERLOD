// File: assets/shaders/hit_effect.frag

extern Image texture;

// Uniforms from Lua
uniform vec4 outline_color;
uniform vec2 texture_size;
uniform float outline_thickness;
uniform bool use_outline;
uniform bool use_flash;
uniform vec4 flash_color;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 original_color = Texel(texture, texture_coords);

    // --- Outline Logic ---
    if (use_outline && original_color.a < 0.1) {
        float max_alpha = 0.0;
        vec2 pixel_size = 1.0 / texture_size;

        for (float x = -outline_thickness; x <= outline_thickness; x += 1.0) {
            for (float y = -outline_thickness; y <= outline_thickness; y += 1.0) {
                max_alpha = max(max_alpha, Texel(texture, texture_coords + vec2(x, y) * pixel_size).a);
            }
        }
        if (max_alpha > 0.1) {
            return outline_color * color; // Return outline color for outline pixels
        }
    }

    // --- Sprite Pixel Logic ---
    if (original_color.a > 0.1) {
        // If hit, apply an additive flash effect
        if (use_flash) {
            // We combine the original color with the flash color.
            // Using 'max' creates a nice, bright flash effect.
            vec3 flashed_rgb = max(original_color.rgb, flash_color.rgb);
            return vec4(flashed_rgb, original_color.a) * color;
        }
        // Otherwise, just draw the normal sprite pixel
        return original_color * color;
    }

    // Return transparent for empty pixels
    return vec4(0.0);
}