// Receives the texture from love.graphics.draw()
extern Image texture;

// Uniforms sent from our Lua code
uniform vec4 outline_color;    // The RGBA color of the outline
uniform vec2 texture_size;     // The width and height of the texture
uniform bool use_outline;      // A simple switch to turn the effect on/off

// This is an 8-direction check for a more solid outline.
const vec2 offsets[8] = vec2[](
    vec2(-1.0, -1.0), vec2(0.0, -1.0), vec2(1.0, -1.0),
    vec2(-1.0,  0.0),                  vec2(1.0,  0.0),
    vec2(-1.0,  1.0), vec2(0.0,  1.0), vec2(1.0,  1.0)
);

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Get the original color from the texture at the current pixel
    vec4 original_color = Texel(texture, texture_coords);

    // If the outline is turned off, just draw the sprite normally
    if (!use_outline) {
        return original_color;
    }

    // If the current pixel is NOT transparent, draw it normally
    if (original_color.a > 0.1) {
        return original_color;
    }

    // --- Outline Logic ---
    // If the current pixel IS transparent, check its neighbors.
    float max_alpha = 0.0;
    vec2 pixel_size = 1.0 / texture_size;

    for (int i = 0; i < 8; i++) {
        // Find the alpha of the neighboring pixel
        float neighbor_alpha = Texel(texture, texture_coords + offsets[i] * pixel_size).a;
        // Keep track of the highest alpha value among neighbors
        max_alpha = max(max_alpha, neighbor_alpha);
    }

    // If any neighbor was visible (alpha > 0), then this is an outline pixel.
    if (max_alpha > 0.1) {
        return outline_color * color;
    }

    // Otherwise, it's just empty space.
    return original_color;
}