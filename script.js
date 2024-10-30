/**
 * @class       : script
 * @author      : mailitg (mailitg@$HOSTNAME)
 * @created     : Monday Oct 28, 2024 17:53:49 GMT
 * @description : script
 */

var gl;
var program;

async function init()
{
        //initialize context
        const canvas = document.getElementById("context");
        canvas.height = 800;
        canvas.width = 1200;
        gl = canvas.getContext("webgl");

        if (gl == null)
        {
                alert( "unable to initialize webgl");
                return;
        }

        //initialize fragment shader
        let response  = await fetch("./fragment.shader");
        let source = await response.text();

        const frag_shader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(frag_shader, source);
        gl.compileShader(frag_shader);
        if (!gl.getShaderParameter(frag_shader, gl.COMPILE_STATUS))
        {
                console.log("Error compiling fragment shader: " + gl.getShaderInfoLog(frag_shader));
                gl.deleteShader(frag_shader);
                return;
        }

        //initialize vertex shader
        response  = await fetch("./vertex.shader");
        source = await response.text();

        const vert_shader = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vert_shader, source);
        gl.compileShader(vert_shader);
        if (!gl.getShaderParameter(vert_shader, gl.COMPILE_STATUS))
        {
                console.log("Error compiling vertex shader: " + gl.getShaderInfoLog(vert_shader));
                gl.deleteShader(vert_shader);
                return;
        }


        //create program
        program = gl.createProgram();
        gl.attachShader(program, vert_shader);
        gl.attachShader(program, frag_shader);
        gl.linkProgram(program);
        if (!gl.getProgramParameter(program, gl.LINK_STATUS))
        {
                console.log("Error initializing program: ${gl.getProgramInfoLog(program)}");
                gl.deleteProgram(program);
                return;
        }

        gl.useProgram(program);

        //initialize buffer
        const vbo = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
        const positions = [
                -1, -1,
                1, -1,
                -1,  1,
                -1,  1,
                1, -1,
                1,  1,
        ];
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(positions), gl.STATIC_DRAW);

        //attribute the vertices to the vertex shader
        const vertex_position = gl.getAttribLocation(program, "position");
        gl.vertexAttribPointer(vertex_position, 2, gl.FLOAT, false, 0, 0);
        gl.enableVertexAttribArray(vertex_position);

        const resolution_loc = gl.getUniformLocation(program, "iResolution");
        gl.uniform2f(resolution_loc, canvas.width, canvas.height);

        requestAnimationFrame(render); 
}

function render(delta_time)
{
        gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        //draw
        gl.drawArrays(gl.TRIANGLES, 0, 6);

        const time_loc = gl.getUniformLocation(program, "iTime");
        gl.uniform1f(time_loc, delta_time);

        requestAnimationFrame(render); 
}

init();
