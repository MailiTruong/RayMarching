precision highp float;

uniform float iTime;
uniform vec2 iResolution;

float map(vec3 p)
{
        return length(p) - 1.;
}

void main()
{
        float u = 2. * gl_FragCoord.x / iResolution.x - 1.;
        float v = 2. * gl_FragCoord.y / iResolution.y - 1.;
        u *= iResolution.x / iResolution.y;

        vec2 uv = vec2(u, v);

        vec3 ro = vec3(0., 0., -3.);
        vec3 rd = normalize(vec3(uv, 1.));
        float r = 0.;

        for (int i = 0; i < 80; i++)
        {
                vec3 p = ro + rd * r;
                r += map(p);
        }

        vec3 col = vec3(r) * 0.2;
        gl_FragColor = vec4(col, 1.);  
}
