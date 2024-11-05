#define PI 3.1415

precision highp float;

uniform float iTime;
uniform vec2 iResolution;
uniform float Local_time;
uniform vec2 Ssun;
uniform float Condition;
uniform float Cam;

float noise(vec2 uv) 
{
        return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 fade(vec2 t) 
{
        return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float grad(int hash, vec2 pos) 
{
        float h = mod(float(hash), 8.0); 
        float u, v;

        if (h < 4.0) 
        {
                u = pos.x;
        }
        else 
        {
                u = pos.y; 
        }
        if (h < 4.0) 
        {
                v = pos.y; 
        }
        else 
        {
                v = pos.x; 
        }
        if (int(mod(h, 2.0)) == 0) 
        {
                u = -u; 
        }
        if (mod(h, 4.0) < 2.0) 
        {
                v = -v; 
        }

        return u + v; 
}

float perlin_noise(vec2 uv) 
{
        vec2 p0 = floor(uv);
        vec2 p1 = p0 + vec2(1.0, 0.0);
        vec2 p2 = p0 + vec2(0.0, 1.0);
        vec2 p3 = p0 + vec2(1.0, 1.0);

        vec2 f = fade(fract(uv));

        int h0 = int(mod(dot(p0, vec2(127.1, 311.7)), 289.0));
        int h1 = int(mod(dot(p1, vec2(127.1, 311.7)), 289.0));
        int h2 = int(mod(dot(p2, vec2(127.1, 311.7)), 289.0));
        int h3 = int(mod(dot(p3, vec2(127.1, 311.7)), 289.0));

        float g0 = grad(h0, uv - p0);
        float g1 = grad(h1, uv - p1);
        float g2 = grad(h2, uv - p2);
        float g3 = grad(h3, uv - p3);

        float nx0 = mix(g0, g1, f.x);
        float nx1 = mix(g2, g3, f.x);
        float nxy = mix(nx0, nx1, f.y);

        return nxy * 0.5 + 0.5;
}

float sdBox( vec3 p, vec3 b )
{
        vec3 q = abs(p) - b;
        return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdGround(vec3 p) {
        p.y += 6.5;
        p.y += perlin_noise(p.xz / 2.0); 
        return sdBox(p, vec3(100.0, 2.0, 100.0));
}

float sdCone( vec3 p, vec2 c, float h )
{
        vec2 q = h*vec2(c.x/c.y,-1.0);

        vec2 w = vec2( length(p.xz), p.y );
        vec2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
        vec2 b = w - q*vec2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
        float k = sign( q.y );
        float d = min(dot( a, a ),dot(b, b));
        float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
        return sqrt(d)*sign(s);
}

vec2 sdForest(vec3 p, float tmin)
{        
        p.xz = mod(p.xz, 4.0) - 2.0;

        float elem_id = 0.0;

        float dTree = sdCone(p, vec2(sin(radians(2.0)), cos(radians(2.0))), 5.0);
        if (dTree < tmin)
        {
                tmin = dTree;
                elem_id = 1.0;
        }
        for (int i=0; i<4 ; i++)
        {
                float offset = perlin_noise((float(i) + p.xz * 4.0)) * 0.1;
                float dLeaves = sdCone(p + vec3(0.0, -0.5+ float(i)*0.8 + offset , 0.0), vec2(sin(radians(50.0)), cos(radians(50.0))), 1.0);
                if (dLeaves < tmin)
                {
                        tmin = dLeaves;
                        elem_id = 2.0;
                }

        }
        return vec2(tmin, elem_id);
}

vec3 simulate_snow(vec2 uv, float time) {
        vec3 rainColor = vec3(0.6, 0.7, 0.9); 
        float speed = 2.0; 
        vec2 grid = floor(uv * 150.0); 
        float drop = fract(sin(dot(grid, vec2(12.9898, 78.233))) * 43758.5453);
        float dropSpeed = mod(time * speed + drop, 1.0);
        float rainPattern = smoothstep(0.95, 1.0, dropSpeed); 
        return mix(vec3(0.0), rainColor, rainPattern); 
}

mat2 rot2D(float angle) 
{
        float c = cos(angle);
        float s = sin(angle);
        return mat2(c, -s, s, c);
}

vec2 map(vec3 p)
{
        p.y -= 2.5;

        float tmin = p.y + 10.0;
        float out_col = 1.0;

        float dFloor = sdGround(p);
        if (dFloor < tmin)
        {
                tmin = dFloor;
                out_col = 2.0;
        }

        vec2 dForest = sdForest(p, tmin);
        if (dForest.x < tmin)
        {
                tmin = dForest.x;
                if (dForest.y < 1.2)
                {
                        out_col = 3.0;
                }
                else if (dForest.y < 2.2)
                {
                        out_col = 4.0;
                }
        }
        vec2 res = vec2(tmin, out_col);
        return res;
}


vec3 get_normal(vec3 p)
{
        vec3 n;
        vec2 e = vec2(0.01, 0.0);
        n.x = (map(p + e.xyy) - map(p - e.xyy)).x;
        n.y = (map(p + e.yxy) - map(p - e.yxy)).x;
        n.z = (map(p + e.yyx) - map(p - e.yyx)).x;
        return normalize(n);
}

vec2 ray_marching(vec3 ro, vec3 rd, float maxDist)
{    
        float dist = 0.0;
        float col_id = -1.0;

        for (int i = 0; i < 80; i++)
        {
                vec3 p = ro + rd * dist;
                vec2 d = map(p);

                if (d.x < 0.01) break;

                dist += d.x;
                col_id = d.y;

                if (dist > maxDist) break;
        }

        return vec2(dist, col_id);
}

vec3 render(vec2 uv)
{
        vec3 ro = vec3(0.0, 0.0, -4.0);
        vec3 rd = normalize(vec3(uv, 1.0));
        vec3 light_source = vec3(10.0, 0.0, 0.0);
        float angle = mod((PI / (Ssun.y - Ssun.x)) * (Local_time - Ssun.x), 2.0 * PI);
        light_source.xy *= rot2D(angle);

        ro.xz *= rot2D(-Cam);
        rd.xz *= rot2D(-Cam);

        vec3 color = vec3(1);
        vec2 rm = ray_marching(ro, rd, 40.0);

        //object colors
        if (rm.x < 40.0 && rm.y > 1.5)
        {   
                float dist = rm.x;
                vec3 p = ro + rd * dist;

                //snow
                float snow = 0.0;

                //light
                vec3 ambient = vec3(1.0);
                vec3 light_color = vec3(1.0);

                vec3 normal = get_normal(p);
                float diffuse_strength = max(0.0, dot(normalize(light_source), normal));
                vec3 diffuse = light_color * diffuse_strength;

                // Specular lighting
                vec3 reflect_source = normalize(reflect(-light_source, normal));
                float specular_strength = pow(max(0.0, dot(normalize(ro), reflect_source)), 15.0);
                vec3 specular = specular_strength * light_color;

                vec3 lighting = vec3(0.0);
                lighting = ambient * 0.1 + diffuse * 0.8 + specular * 0.6;

                //shadows
                vec3 lightDirection = normalize(light_source);
                float distToLightSource = length(light_source - p);

                if (rm.y < 2.2)
                {
                        color = vec3(0.239, 0.173, 0.071);
                        float i = smoothstep(1.0,6.0,p.y-(-36.0));
                        color *= 0.2+0.8*i*diffuse_strength;
                }
                else if (rm.y < 3.2)
                {
                        color = vec3(0.22, 0.145, 0.027);
                }
                else if (rm.y < 4.2)
                {
                        color = vec3(0.216, 0.31, 0.031);                }

                color *= lighting;

                //add shadows
                ro = p + normal * 0.1;
                rd = lightDirection;
                vec2 calcDist = ray_marching(ro, rd, distToLightSource);
                if (calcDist.x < distToLightSource)
                {
                        color = color * vec3(0.25);
                }

                //adapt scene based on condition
                if (Condition < 1.2)
                { 
                        color = pow(color, vec3(0.4545));
                }
                else if (Condition < 2.2)
                {

                }
                else if (Condition < 3.2)
                {
                        float g = 0.8 * normal.y * normal.y;
                        snow += smoothstep(0.2,0.6,g);
                        float fre = clamp(1.0+dot(normal, rd),0.0,1.0);
                        snow *= smoothstep(0.25,0.3,normal.y);
                        color = mix(color, vec3(0.7,0.75,0.8)*0.6, snow);
                }
        }
        //backgroud color
        else
        {
                vec3 cond = vec3(0.45,0.75,1.1); 
                if(Condition < 1.2)
                {
                        cond = vec3(0.529, 0.808, 0.980);

                }
                else if (Condition < 2.2)
                {
                        cond = vec3(0.663, 0.663, 0.663);
                }
                else if (Condition < 3.2)
                {
                        cond = vec3(0.529, 0.808, 0.980);
                }
                else if (Condition < 4.2)
                {
                        cond = vec3(0.663, 0.663, 0.663);
                }
                color = cond + rd.y*0.5;
                vec3 fog_col = vec3(0.58, 0.58, 0.58)*0.25;
                color = mix( color, fog_col, exp2(-8.0*max(rd.y,0.0)));

                //if night
                if (light_source.y < 0.0)
                {
                        color = vec3(0, 0.051, 0.18);
                }
        }
        //different animations
        if (Condition > 2.8 && Condition < 4.2)
        {
                vec3 b = simulate_snow(uv, iTime);
                color = 1.0 - (1.0 - color)*(1.0 - b);
        }
        return color;
}

void main()
{
        vec2 uv = 2. * gl_FragCoord.xy / iResolution.xy - 1.0;
        uv.x *= iResolution.x / iResolution.y;

        gl_FragColor = vec4(render(uv), 1.);  
}

