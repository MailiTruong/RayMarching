/**
 * @class       : script
 * @author      : mailitg (mailitg@$HOSTNAME)
 * @created     : Monday Oct 28, 2024 17:53:49 GMT
 * @description : script
 */

var gl;
var program;

function parse_time_to_float(timeStr) 
{
        const [time, period] = timeStr.trim().toLowerCase().split(' '); 
        let [hours, minutes] = time.split(':').map(Number); 

        if (period === "pm" && hours !== 12) hours += 12; 
        if (period === "am" && hours === 12) hours = 0;   

        return hours + minutes / 60; 
}


function categorize_weather(description) 
{
        description = description.toLowerCase();
        for (const [category, keywords] of Object.entries(weather_categories)) {
                if (keywords.some(keyword => description.includes(keyword))) { 
                        return category; 
                }
        }
        console.log("Unable to determine weather");
        return 0.0; 
}


const weather_categories = {
        1.0: ["sunny", "clear", "mostly sunny", "partly sunny","fair"],
        2.0: ["cloudy", "mostly cloudy", "partly cloudy", "overcast"],
        3.0: ["snow", "snowy", "light snow", "heavy snow", "blizzard", "flurries"],
        4.0: ["rain", "showers", "drizzle", "light rain", "heavy rain", "thunderstorms"]
};

var url = "https://weather.com/weather/today/l/d2a540efb4e9604b3c1d01b7851a1d9d2ab4c7b3ba428e5799936ac54404c035";

document.getElementById("get-url-form").addEventListener("submit", function(event)
        {
                event.preventDefault();

                const _url = document.getElementById("wurl").value;
                if (_url) 
                {
                        url = _url;
                        fetch_weather_data();
                }
        })

function fetch_weather_data()
{
        const xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function () {
                if (xhr.readyState === 4 && xhr.status === 200) {

                        const parser = new DOMParser();
                        const doc = parser.parseFromString(xhr.responseText, "text/html");

                        const place = doc.querySelector(".CurrentConditions--location--yub4l").textContent;
                        const time = doc.querySelector(".CurrentConditions--timestamp--LqnOd").textContent;
                        const temp = doc.querySelector(".CurrentConditions--tempValue--zUBSz").textContent;
                        const condition = doc.querySelector(".CurrentConditions--phraseValue---VS-k").textContent;
                        const sunriseSunsetElements = doc.querySelectorAll(".TwcSunChart--dateValue--TzXBr");
                        const sunrise = sunriseSunsetElements[0].textContent;
                        const sunset = sunriseSunsetElements[1].textContent;

                        document.getElementById("place").textContent = place;
                        document.getElementById("temp").textContent = temp;
                        document.getElementById("time").textContent = time;

                        const words = time.trim().toLowerCase().split(' ');
                        const time_num = words[2] + " " + words[3];
                        const local_time = gl.getUniformLocation(program, "Local_time");
                        gl.uniform1f(local_time, parse_time_to_float(time_num));

                        const Ssun_loc = gl.getUniformLocation(program, "Ssun");
                        gl.uniform2f(Ssun_loc, parse_time_to_float(sunrise), parse_time_to_float(sunset));


                        const condition_loc = gl.getUniformLocation(program, "Condition");
                        gl.uniform1f(condition_loc, categorize_weather(condition));
                }
        };
        xhr.send();
}

async function init()
{
        //initialize context
        const canvas = document.getElementById("context");
        canvas.height = 1080;
        canvas.width = 1920;
        gl = canvas.getContext("webgl");

        if (gl == null)
        {
                console.log( "unable to initialize webgl");
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

        // attribute the vertices to the vertex shader
        const vertex_position = gl.getAttribLocation(program, "position");
        gl.vertexAttribPointer(vertex_position, 2, gl.FLOAT, false, 0, 0);
        gl.enableVertexAttribArray(vertex_position);

        const resolution_loc = gl.getUniformLocation(program, "iResolution");
        gl.uniform2f(resolution_loc, canvas.width, canvas.height);

        // handle mouse grab and move
        // Handle mouse move
        var xpos = 0;
        var last_xpos = 0;
        var mouse_state = 0;
        var cam_roty = 0.0;
        function handle_rotate(dx)
        {
                cam_roty += dx / canvas.width * 2.0 * Math.PI;
                const cam_loc = gl.getUniformLocation(program, "Cam");
                gl.uniform1f(cam_loc, cam_roty);
        }

        function update_cursor_pos(event)
        {
                var rect = canvas.getBoundingClientRect();
                xpos = Math.floor((event.clientX - rect.left) * (canvas.width / rect.width));
        }

        canvas.addEventListener("mouseup", () => mouse_state = 0);
        canvas.addEventListener("mousedown", (event) => {
                mouse_state = 1;
                update_cursor_pos(event);
                last_xpos = xpos;
        });
        canvas.addEventListener("mousemove", function(event)
                {
                        if (mouse_state === 1)
                        {
                                event.preventDefault();

                                update_cursor_pos(event);
                                handle_rotate(xpos - last_xpos);

                                last_xpos = xpos;
                        }
                })

        canvas.addEventListener("touchend", () => mouse_state = 0);
        canvas.addEventListener("touchstart", (event) => {
                if (event.touches.length === 1) 
                {
                        mouse_state = 1;
                        const touch = event.touches[0];
                        update_cursor_pos(touch);
                        last_xpos = xpos;
                }
        });
        canvas.addEventListener("touchmove", function handleTouchMove(event)
                {
                        if (mouse_state === 1 && event.touches.length === 1) {
                                event.preventDefault();
                                const touch = event.touches[0];

                                update_cursor_pos(touch);
                                handle_rotate(xpos - last_xpos);

                                last_xpos = xpos;
                        }
                });

        requestAnimationFrame(render); 
}

const fetch_interval = 60;
var start_time;
var last_time = 0;
var fps_timer = 0;
var fetch_timer = 0;
const fps_span = document.getElementById("fps");

function render(timestamp)
{
        if (start_time === undefined) start_time = timestamp;
        const delta_time = (timestamp - last_time) / 1000.0;

        gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        //draw
        gl.drawArrays(gl.TRIANGLES, 0, 6);

        const time_loc = gl.getUniformLocation(program, "iTime");
        gl.uniform1f(time_loc, delta_time); 

        if (fps_timer == 0 || fps_timer > 0.5)
        {
                fps_span.textContent = parseInt(1.0 / delta_time);
                fps_timer = 0;

        }
        if (fetch_timer == 0 || fetch_timer > fetch_interval)
        {
                fetch_weather_data();
                fetch_timer = 0;
        }

        fps_timer += delta_time;
        fetch_timer += delta_time;
        last_time = timestamp;

        requestAnimationFrame(render); 
}

init();
