float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < 3; i++) {
        value += amplitude * noise(p * frequency);
        p *= 2.0; // Lacunarity
        amplitude *= 0.5; // Gain
    }
    return value;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 st = fragCoord.xy / iResolution.xy;
    st.x *= iResolution.x / iResolution.y;

    st *= 0.6;

    vec2 q = vec2(0.);
    q.x = fbm(st + 0.02 * iTime);
    q.y = fbm(st + vec2(1.0));

    vec2 r = vec2(0.);
    r.x = fbm(st + 0.6 * q + vec2(1.7, 9.2) + 0.08 * iTime);
    r.y = fbm(st + 0.6 * q + vec2(8.3, 2.8) + 0.06 * iTime);

    float f = fbm(st + r);

    float height = smoothstep(0.2, 1.0, f); 
    
    height = height * height; 

    vec3 colDeep = vec3(0.0, 0.1, 0.2);
    vec3 colBlue = vec3(0.0, 0.4, 0.6);
    vec3 colGold = vec3(1.0, 0.75, 0.2);
    vec3 colRed  = vec3(1.0, 0.1, 0.1);

    vec3 color = vec3(0.0);
    
    float t1 = smoothstep(0.0, 0.4, height);
    color = mix(colDeep, colBlue, t1);
    
    float t2 = smoothstep(0.3, 0.7, height);
    color = mix(color, colGold, t2);
    
    float t3 = smoothstep(0.6, 1.0, height);
    color = mix(color, colRed, t3);

    float valOffset = fbm(st + r + vec2(0.01));
    float slope = (f - valOffset) * 10.0; // Strength of the shadow/highlight
    
    float specular = clamp(slope, 0.0, 1.0);
    
    color += vec3(1.0, 0.9, 0.8) * specular * 0.3 * height;

    float grain = (random(st * iTime * 10.0) - 0.5) * 0.08;
    
    color += grain * sqrt(height);

    vec2 uv = fragCoord.xy / iResolution.xy;
    float vignette = 1.0 - smoothstep(0.5, 1.5, length(uv - 0.5) * 1.5);
    color *= vignette;
    
    fragColor = vec4(color, 1.0);
}
