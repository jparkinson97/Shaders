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
    
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p * frequency);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 st = fragCoord.xy / iResolution.xy;
    st.x *= iResolution.x / iResolution.y;

    st *= 1.5;

    vec2 q = vec2(0.);
    q.x = fbm(st + 0.05 * iTime);
    q.y = fbm(st + vec2(1.0));

    vec2 r = vec2(0.);
    r.x = fbm(st + 1.0 * q + vec2(1.7, 9.2) + 0.15 * iTime);
    r.y = fbm(st + 1.0 * q + vec2(8.3, 2.8) + 0.126 * iTime);

    // 'height' is the final elevation of the sheet
    float height = fbm(st + r);

    // User Request: Low=Dark Blue, Mid=Yellow, High=Red
    
    vec3 colLow = vec3(0.02, 0.05, 0.15); 
    vec3 colMid = vec3(1.0, 0.8, 0.2);   
    vec3 colHigh = vec3(0.8, 0.05, 0.1); 

    vec3 color = vec3(0.0);

    float t1 = smoothstep(0.0, 0.6, height);
    color = mix(colLow, colMid, t1);

    float t2 = smoothstep(0.4, 1.0, height);
    color = mix(color, colHigh, t2);

    float valOffset = fbm(st + r + vec2(0.01)); // Sample slightly to the right
    float slope = (height - valOffset) * 15.0;  // Calculate steepness
    
    float specular = clamp(slope, 0.0, 1.0);
    color += vec3(1.0, 0.9, 0.8) * specular * 0.3;

    float grain = (random(st * iTime * 5.0) - 0.5) * 0.05;
    color += grain;

    vec2 uv = fragCoord.xy / iResolution.xy;
    float vignette = 1.0 - smoothstep(0.5, 1.5, length(uv - 0.5) * 1.5);
    color *= vignette;
    
    color = pow(color, vec3(1.1));

    fragColor = vec4(color, 1.0);
}
