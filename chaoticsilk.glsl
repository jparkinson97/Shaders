// silk2.glsl - smoother variant of silk.glsl
//
// Changes from silk.glsl:
//   - Removed the noise(st * 12.0) micro-texture — main cause of bumpiness
//   - Reduced m2 cross-pattern blend from 0.25 → 0.08 (less interference)
//   - Tightened amplitude decay from 0.58 → 0.50 (kills high-freq warp detail faster)
//   - Widened smoothstep color ranges slightly for softer vein edges

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Logistic map chaos: x = r * x * (1 - x)
// Requires input in [0,1]. At r > 3.57 the output becomes aperiodic / chaotic.
// Three iterations is enough for the signal to lose all memory of its initial value.
vec2 logisticChaos(vec2 p, float r) {
    vec2 q = fract(p * 0.18 + vec2(0.31, 0.72)); // fold into [0,1] with asymmetric offsets
    q = r * q * (1.0 - q);
    q = r * q * (1.0 - q);
    q = r * q * (1.0 - q);
    return q * 2.0 - 1.0; // re-centre to [-1,1]
}

vec2 sineWarp(vec2 p, float t) {
    float a = 1.5;
    for (int i = 0; i < 6; i++) {
        float phase = float(i) * 1.618;
        p.x += a * sin(p.y * 1.4 + t * 0.18 + phase * 2.39);
        p.y += a * cos(p.x * 1.6 + t * 0.14 + phase * 1.73);
        // Inject logistic chaos at each iteration — breaks the sine's inherent periodicity.
        // r = 3.9 sits well inside the chaotic regime. Scaled by a so chaos tapers with amplitude.
        vec2 chaos = logisticChaos(p + t * 0.07, 3.9);
        p += chaos * a * 0.35;
        a *= 0.50;
    }
    return p;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    vec2 st = uv - 0.5;
    st.x *= iResolution.x / iResolution.y;
    st *= 2.2;

    vec2 wp = sineWarp(st, iTime);

    float m1 = sin(wp.x * 1.8 + wp.y * 0.7) * 0.5 + 0.5;
    float m2 = sin(wp.x * 0.9 - wp.y * 1.4 + iTime * 0.08) * 0.5 + 0.5;

    // Reduced from 0.25 → 0.08: m2 adds just enough variety to avoid
    // the too-perfect sine look without creating interference bumps
    float pattern = mix(m1, m2, 0.08);
    // No micro-texture noise — that was the primary source of bumpiness

    // --- COLOR PALETTE ---
    vec3 deepNavy = vec3(0.047, 0.102, 0.141);
    vec3 navy     = vec3(0.231, 0.424, 0.502);
    vec3 orange   = vec3(0.929, 0.576, 0.306);
    vec3 cream    = vec3(0.569, 0.039, 0.024);

    vec3 color = deepNavy;
    // Slightly wider smoothstep ranges for gentler vein edges
    color = mix(color, navy,   smoothstep(0.08, 0.52, pattern));
    color = mix(color, orange, smoothstep(0.60, 0.86, pattern));
    color = mix(color, cream,  smoothstep(0.84, 0.97, pattern));

    // --- SILK SHEEN ---
    float sheenWave = sin(wp.x * 0.2 + wp.y * 0.1 - iTime * 0.4) * 0.5 + 0.5;
    float sheen = pow(sheenWave, 8.0);

    float isNavyRegion = 1.0 - smoothstep(0.50, 0.66, pattern);
    color += orange * 0.22 * sheen * isNavyRegion;
    color += cream  * 0.38 * sheen * (1.0 - isNavyRegion);

    // --- FILM GRAIN ---
    float frameTime = floor(iTime * 24.0);
    vec2 px = floor(fragCoord.xy / 7.5); // snap to 2.5px grid — controls grain size
    float gRaw = (hash(px + frameTime * 13.7) + hash(px * 1.3 + frameTime * 27.1 + 5.5)) * 0.5;
    float g = smoothstep(0.2, 0.8, gRaw) - 0.5; // steeper S-curve → sharper contrast between particles
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    float grainMask = luma * (1.0 - luma) * 4.0;
    color += g * grainMask * 0.18;

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}