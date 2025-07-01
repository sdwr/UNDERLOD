// flashy_fire.frag

// Uniforms sent from Lua
extern number time;
extern number flash_amount; // A value from 0.0 to 1.0 to control on-hit flashes

// 2D noise function (same as before)
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = fract(sin(dot(i, vec2(12.9898, 78.233))) * 43758.5);
    float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(12.9898, 78.233))) * 43758.5);
    float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(12.9898, 78.233))) * 43758.5);
    float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(12.9898, 78.233))) * 43758.5);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.y * u.x;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords;

    // 1. Base Fire Layer (smoother, darker)
    float base_noise = noise(uv * vec2(3.0, 5.0) - vec2(0.0, time * 1.5));
    base_noise = pow(base_noise, 2.0);

    vec3 base_color = mix(vec3(0.8, 0.2, 0.0), vec3(1.0, 0.6, 0.0), base_noise);

    // 2. Hotspots / Embers Layer (sharp, bright, and fast)
    float hotspot_noise = noise(uv * vec2(8.0, 15.0) - vec2(time * 0.5, time * 2.5));
    float hotspot_pattern = smoothstep(0.6, 0.75, hotspot_noise);

    // 3. Combine Layers & Add Flash
    vec3 final_color = base_color + vec3(1.0, 1.0, 0.5) * hotspot_pattern;
    final_color += vec3(1.0, 1.0, 0.8) * flash_amount;

    // ====================================================================
    // 4. MODIFIED ALPHA CALCULATION
    // ====================================================================

    // First, get the combined intensity of the fire patterns
    float combined_pattern = base_noise + hotspot_pattern;

    // Second, remap this intensity from its original [0,1] range to your desired [0.4, 0.7] range
    float remapped_alpha = mix(0.4, 0.7, combined_pattern);

    // Finally, add the flash amount on top and clamp to ensure alpha doesn't exceed 1.0
    float final_alpha = clamp(remapped_alpha + flash_amount, 0.0, 1.0);

    return vec4(final_color, final_alpha);
}