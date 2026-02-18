// silk.glsl - Navy and Orange Silk / Marbled Effect
//
// Key technique: sine-based iterative domain warping.
// Unlike FBM domain warping (which creates isotropic blobs),
// iterative sine warping produces long, flowing ribbon structures —
// the kind you see in marble veins, shot silk, or paint pours.
//
// The marble pattern comes from sin(warpedCoord), which bands naturally.
// FBM of a warped coordinate averages out structure; sin preserves it.

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i),                   hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

// Sine-based iterative domain warp.
// Each iteration displaces p by a sine/cosine of the current p,
// creating feedback loops that produce sinuous, elongated flow structures.
// Slower time multipliers (0.14-0.18) keep the animation graceful.
vec2 sineWarp(vec2 p, float t) {
    float a = 1.5;
    for (int i = 0; i < 6; i++) {
        float phase = float(i) * 1.618; // golden ratio phase spacing — avoids repetition artifacts
        p.x += a * sin(p.y * 1.4 + t * 0.18 + phase * 2.39);
        p.y += a * cos(p.x * 1.6 + t * 0.14 + phase * 1.73);
        a *= 0.58; // amplitude decay per octave
    }
    return p;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;

    // Center + aspect ratio correction
    vec2 st = uv - 0.5;
    st.x *= iResolution.x / iResolution.y;
    st *= 2.2; // scale: lower = larger veins, higher = finer

    // Domain warp
    vec2 wp = sineWarp(st, iTime);

    // Primary marble/silk pattern.
    // sin() of warped coordinates creates natural banding (veins).
    // The 1.8 / 0.7 ratio gives diagonal bands at ~22 degrees.
    float m1 = sin(wp.x * 1.8 + wp.y * 0.7) * 0.5 + 0.5;

    // Secondary cross-pattern — adds complexity without destroying vein structure.
    // Slow independent time drift (0.08) keeps it from locking to primary.
    float m2 = sin(wp.x * 0.9 - wp.y * 1.4 + iTime * 0.08) * 0.5 + 0.5;

    // Blend: 75% primary so the main vein direction is dominant
    float pattern = mix(m1, m2, 0.25);

    // Micro-texture: very subtle noise to break up the too-perfect sine bands,
    // simulates thread weave or fine grain in the fabric
    float micro = noise(st * 12.0 + iTime * 0.03);
    pattern = mix(pattern, micro, 0.06);
    pattern = clamp(pattern, 0.0, 1.0);

    // --- COLOR PALETTE ---
    // Navy is the ground color; orange appears only as veins at pattern peaks.
    // The split: navy covers 0.0–0.62, orange 0.62–0.84, cream tips 0.84+.
    // This means ~62% of the image stays navy — matching a navy-dominant fabric.
    vec3 deepNavy = vec3(0.03, 0.05, 0.25); // darkest shadow in the folds
    vec3 navy     = vec3(0.08, 0.14, 0.42); // main navy fill
    vec3 orange   = vec3(1.0,  0.52, 0.06); // vivid orange vein
    vec3 cream    = vec3(1.0,  0.87, 0.55); // bright highlight at peak

    vec3 color = deepNavy;
    color = mix(color, navy,   smoothstep(0.10, 0.50, pattern)); // navy fill
    color = mix(color, orange, smoothstep(0.62, 0.84, pattern)); // orange veins
    color = mix(color, cream,  smoothstep(0.84, 0.96, pattern)); // cream tips

    // --- SILK IRIDESCENCE / SHEEN ---
    // Shot silk (and many marbled textures) have a characteristic traveling sheen:
    // a band of light appears to sweep across the surface.
    // On navy areas: the sheen takes on an orange-gold tint (classic iridescence).
    // On orange areas: it becomes a bright cream-white specular highlight.
    //
    // We use warped coords (wp) so the band follows the fabric structure,
    // not the flat screen space.
    float sheenWave = sin(wp.x * 0.2 + wp.y * 0.1 - iTime * 0.4) * 0.5 + 0.5;
    float sheen = pow(sheenWave, 8.0); // high power = narrow, focused band

    float isNavyRegion = 1.0 - smoothstep(0.50, 0.66, pattern);
    color += orange * 0.22 * sheen * isNavyRegion;       // orange sheen on navy
    color += cream  * 0.38 * sheen * (1.0 - isNavyRegion); // cream sheen on orange

    // --- VIGNETTE ---
    float vignette = 1.0 - smoothstep(0.38, 1.05, length(uv - 0.5) * 1.8);
    color *= vignette;

    // --- FILM GRAIN ---
    // Real film grain has two properties simple noise lacks:
    //   1. It snaps per-frame rather than animating continuously.
    //   2. It's luminance-dependent: strongest in midtones, invisible in
    //      deep blacks and blown-out whites (the silver halide response curve).
    float frameTime = floor(iTime * 24.0); // snap to 24fps
    vec2 px = fragCoord.xy;
    // Average two offset samples to break up the hash grid pattern slightly
    float g = (hash(px + frameTime * 13.7) + hash(px * 1.3 + frameTime * 27.1 + 5.5)) * 0.5 - 0.5;
    // Luminance of the current pixel
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    // Peaks at luma = 0.5, falls to zero at 0 and 1
    float grainMask = luma * (1.0 - luma) * 4.0;
    color += g * grainMask * 0.18;

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
