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

float sdTree(vec3 p)
{        
    //p.xz = mod(p.xz, 3.0) - 1.5;
    return sdCone(p, vec2(sin(radians(2.0)), cos(radians(2.0))), 5.0);

}

float sdLeaves(vec3 p)
{
        p.y += 3.0;    
        //p.z += 2.0;

        return sdCone(p, vec2(sin(radians(50.0)), cos(radians(50.0))), 1.0);
}

mat2 rot2D(float angle) 
{
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

float map(vec3 p)
{
    p.y -= 3.0;
    p.xz = mod(p.xz, 3.0) - 1.5;
    float dTree = sdTree(p); 
    float dFloor = sdPlane(p);
    float dLeaves = sdLeaves(p);
    return min(dTree, min(dFloor, dLeaves));
}

vec3 get_normal(vec3 p)
{
    vec3 n;
    vec2 e = vec2(0.01, 0.0);
    n.x = map(p + e.xyy) - map(p - e.xyy);
    n.y = map(p + e.yxy) - map(p - e.yxy);
    n.z = map(p + e.yyx) - map(p - e.yyx);
    return normalize(n);
}

float ray_marching(vec3 ro, vec3 rd)
{    
    float dist = 0.0;

    for (int i = 0; i < 80; i++)
    {
        vec3 p = ro + rd * dist;
        
        float d = map(p);
        
        if (d < 0.001) break;
        
        dist += d;
        
        if (dist > 100.0) break;
    }
    
    return dist;
}

vec3 render(vec2 uv, vec2 m)
{
    vec3 ro = vec3(0.0, 0.0, -3.0);
    vec3 rd = normalize(vec3(uv, 1.0));
    vec3 light_source = vec3(10.0, 0.0, 0.0);
    float angle = mod((PI / (Ssun.y - Ssun.x)) * (Local_time - Ssun.x), 2.0 * PI);
    light_source.xy *= rot2D(angle);
    //light_source.xy *= rot2D(PI / 2.0);
    
    //ro.yz *= rot2D(-m.y);
    //rd.yz *= rot2D(-m.y);
    
    ro.xz *= rot2D(-m.x);
    rd.xz *= rot2D(-m.x);
        
    //ro.x += m.y * 5.0;
      
    float dist = ray_marching(ro, rd);
    vec3 p = ro + rd * dist;
    
    vec3 color = vec3(0.0);
   
    if (dist < 20.0)
    {   
        vec3 light_color = vec3(1.0);
        // ambient
        float ambient_strength = 0.15;
        float d = map(p);
        // diffuse
        float diffuse_strength = max(ambient_strength, dot(normalize(light_source), get_normal(p)));
        
        if (d - sdTree(p) < 0.01)
        {
            color = vec3(0.36, 0.25, 0.20) * diffuse_strength;
        }
        else if (d - sdPlane(p) < 0.01)
        {
            color = vec3(0.0, 0.55, 0.40) * diffuse_strength;   
        }
        else if (d - sdLeaves(p) < 0.01)
        {
            color = vec3(0.0, 0.55, 0.40) * diffuse_strength;   
        }
        //color *= diffuse_strength * light_color;
    }
    else
    {
        color = vec3(0.1, 0.4, 0.7);
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

