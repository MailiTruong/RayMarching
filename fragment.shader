#define PI 3.1415

precision highp float;

uniform float iTime;
uniform vec2 iResolution;
uniform vec2 iMouse;
uniform float Local_time;
uniform vec2 Ssun;
uniform float Condition;

float sdPlane(vec3 p)
{
        //p.z += 2.9 * sin(3.0 * p.x * 1.1 + 2.0) + 0.6 * sin(2.0 * p.x * 0.5 + 1.0);
        //p.y += 0.3 * sin(5.0 * p.x + 0.9) * sin(5.0 * p.z + 0.60);
        float distortion = 5.0; //* sin(0.2 * p.x + 1.5) * sin(0.1 * p.z + 1.5);
        p.y += distortion;

        return p.y;
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
        p.xz = mod(p.xz, 3.0) - 1.5;
        float elemId = 0.0;

        float dTree = sdCone(p, vec2(sin(radians(2.0)), cos(radians(2.0))), 5.0);
        if (dTree < tmin)
        {
                tmin = dTree;
                elemId = 1.0;
        }
        for (int i=0; i<4 ; i++)
        {
                float dLeaves = sdCone(p + vec3(0.0, -0.5+ float(i)*0.8, 0.0), vec2(sin(radians(50.0)), cos(radians(50.0))), 1.0);
                if (dLeaves < tmin)
                {
                        tmin = dLeaves;
                        elemId = 2.0;
                }

        }
        return vec2(tmin, elemId);
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
        float outCol = 1.0;

        float dFloor = sdPlane(p);
        if (dFloor < tmin)
        {
                tmin = dFloor;
                outCol = 2.0;
        }

        vec2 dForest = sdForest(p, tmin);
        if (dForest.x < tmin)
        {
                tmin = dForest.x;
                if (dForest.y < 1.2)
                {
                        outCol = 3.0;
                }
                else if (dForest.y < 2.2)
                {
                        outCol = 4.0;
                }
        }
        vec2 res = vec2(tmin, outCol);
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

vec2 ray_marching(vec3 ro, vec3 rd)
{    
        float dist = 0.0;
        float colId = -1.0;

        for (int i = 0; i < 80; i++)
        {
                vec3 p = ro + rd * dist;
                vec2 d = map(p);

                if (d.x < 0.001) break;

                dist += d.x;
                colId = d.y;

                if (dist > 100.0) break;
        }

        return vec2(dist, colId);
}

vec3 render(vec2 uv, vec2 m)
{
        vec3 ro = vec3(0.0, 0.0, -3.0);
        vec3 rd = normalize(vec3(uv, 1.0));
        vec3 light_source = vec3(10.0, 0.0, 0.0);
        float angle = mod((PI / (Ssun.y - Ssun.x)) * (Local_time - Ssun.x), 2.0 * PI);
        light_source.xy *= rot2D(angle);

        ro.xz *= rot2D(-m.x);
        rd.xz *= rot2D(-m.x);

        vec3 color = vec3(1);
        vec2 rm = ray_marching(ro, rd);

        if (rm.x < 100.0 && rm.y > 1.5)
        {   
                float dist = rm.x;
                vec3 p = ro + rd * dist;
                float snow = 0.0;
                vec3 light_color = vec3(1.0);
                // ambient
                float ambient_strength = 0.15;
                // diffuse
                float diffuse_strength = max(ambient_strength, dot(normalize(light_source), get_normal(p)));

                if (rm.y < 2.2)
                {
                        color = vec3(0.4,0.3,0.1)*0.52;
                        float i = smoothstep(1.0,6.0,p.y-(-36.0));
                        color *= 0.2+0.8*i*diffuse_strength;
                }
                else if (rm.y < 3.2)
                {
                        color = vec3(0.8, 0.4, 0.2) * diffuse_strength;   
                }
                else if (rm.y < 4.2)
                {
                        color = vec3(0.3,0.8,0.2) * diffuse_strength;
                }

                //float g = 0.5 + 0.5*fbm1(iChannel0,0.21*pos);
                //g -= 0.8*nor.x*nor.x;
                //snow *= smoothstep(0.2,0.6,g);in one of if and outside here 
                //float fre = clamp(1.0+dot(nor,rd),0.0,1.0);
                //float occ = focc*calcOcclusion( pos, nor, time, occs, px );

                //snow *= smoothstep(0.25,0.3,nor.y);
                //if( abs(tm.y-2.0)<0.5 )
                //{
                //snow = max(snow,clamp(1.0-occ*occ*3.5,0.0,1.0));
                // snow = max(snow,cma.x);
                //  }

                // col = mix( col, vec3(0.7,0.75,0.8)*0.6, snow);

        }
        else
        {
                float coef = 1.0;
                color = vec3(0.45,0.75,1.1); //+ rd.y*0.5*coef;
                vec3 fogcol = vec3(1.3,0.5,1.0)*0.25*coef;
                color = mix( color, fogcol, exp2(-8.0*max(rd.y,0.0)) ); 
        }

        return color;
}

void main()
{
        vec2 uv = 2. * gl_FragCoord.xy / iResolution.xy - 1.0;
        uv.x *= iResolution.x / iResolution.y;
        vec2 m = 2. * iMouse.xy / iResolution.xy - 1.0;
        m.x *= iResolution.x / iResolution.y;

        gl_FragColor = vec4(render(uv, m), 1.);  
}

