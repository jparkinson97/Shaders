float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 3; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    // Normalize coordinates
    vec2 st = fragCoord.xy / iResolution.xy;
    
    // Fix aspect ratio
    st.x *= iResolution.x / iResolution.y;

    // Domain Warping
    vec2 q = vec2(0.);
    q.x = fbm(st + 0.00 * iTime);
    q.y = fbm(st + vec2(1.0));

    vec2 r = vec2(0.);
    r.x = fbm(st + 1.0 * q + vec2(1.7, 9.2) + 0.15 * iTime);
    r.y = fbm(st + 1.0 * q + vec2(8.3, 2.8) + 0.126 * iTime);

    float f = fbm(st + r);

    vec3 colorTeal = vec3(0.0, 0.16, 0.21);
    vec3 colorOrange = vec3(1.0, 0.4, 0.0);
    vec3 colorRed = vec3(1.0, 0.0, 0.0);

    vec3 color = mix(colorTeal, colorOrange, clamp(f*f*4.0, 0.0, 1.0));
    color = mix(color, colorRed, clamp(length(q), 0.0, 1.0));

    float grain = (random(st * iTime) - 0.5) * 0.1;

    fragColor = vec4(color + grain, 1.0);
}
