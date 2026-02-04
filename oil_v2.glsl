// --- NOISE FUNCTIONS ---
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

// --- MAIN ---
void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    // Normalize coordinates
    vec2 st = fragCoord.xy / iResolution.xy;
    st.x *= iResolution.x / iResolution.y;

    // Zoom in slightly to get larger shapes
    st *= 0.8;

    // Domain Warping
    // We increase the influence of time and offset to make it "oilier"
    vec2 q = vec2(0.);
    q.x = fbm(st + 0.01 * iTime);
    q.y = fbm(st + vec2(1.0));

    vec2 r = vec2(0.);
    // Increased the multiplier on 'q' (from 1.0 to 3.0) to make the swirl tighter
    r.x = fbm(st + 3.0 * q + vec2(1.7, 9.2) + 0.15 * iTime);
    r.y = fbm(st + 3.0 * q + vec2(8.3, 2.8) + 0.126 * iTime);

    float f = fbm(st + r);

    // --- SHARPENING & CONTRAST ---
    // This is the key to the "Sharp" and "Black Heavy" look.
    // We curve the noise value so that midtones get crushed to black,
    // and highlights pop suddenly.
    
    // 1. Crushing the blacks:
    // Any noise value below 0.3 becomes 0.0.
    // The transition from 0.3 to 1.0 becomes sharper.
    float sharpF = smoothstep(0.3, 1.0, f);
    
    // 2. Non-linear curve:
    // Power of 3.0 makes the falloff very steep.
    sharpF = pow(sharpF, 3.0); 

    // --- COLORS ---
    // Deep dark teal (almost black)
    vec3 colorBlackTeal = vec3(0.0, 0.02, 0.04); 
    // Deep red/rust for the transition
    vec3 colorRed = vec3(0.7, 0.05, 0.05); 
    // Bright glowing orange
    vec3 colorOrange = vec3(1.0, 0.5, 0.1);

    // Mix 1: Background to Red
    // We use the raw 'f' slightly modified for the background glow, 
    // but the sharpF for the main structure.
    vec3 color = mix(colorBlackTeal, colorRed, smoothstep(0.4, 0.8, f));
    
    // Mix 2: Red to Bright Orange
    // This adds the "hot" inner core using the sharpened value
    color = mix(color, colorOrange, smoothstep(0.1, 0.9, sharpF));

    // --- POST PROCESSING ---
    
    // Vignette (darkens corners)
    vec2 uv = fragCoord.xy / iResolution.xy;
    float vignette = 1.0 - smoothstep(0.5, 1.5, length(uv - 0.5) * 1.5);
    color *= vignette;

    // Heavy Grain
    // Increased intensity (0.15) and added it before clamping to maintain darkness
    float grain = (random(st * iTime * 99.0) - 0.5) * 0.15;
    
    // Apply grain mostly to the mid-tones/highlights, keep blacks cleanish
    color += grain * length(color);

    fragColor = vec4(color, 1.0);
}
