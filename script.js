/**
 * @class       : script
 * @author      : mailitg (mailitg@$HOSTNAME)
 * @created     : Monday Oct 28, 2024 17:53:49 GMT
 * @description : script
 */

var gl;
var program;

function parseTimeToFloat(timeStr) 
{
        const [time, period] = timeStr.trim().toLowerCase().split(' '); 
        let [hours, minutes] = time.split(':').map(Number); 

        if (period === "pm" && hours !== 12) hours += 12; 
        if (period === "am" && hours === 12) hours = 0;   

        return hours + minutes / 60; 
}


function categorizeWeather(description) 
{
        description = description.toLowerCase();
        for (const [category, keywords] of Object.entries(weatherCategories)) {
                if (keywords.some(keyword => description.includes(keyword))) { 
                        return category; 
                }
        }
        console.log("Unable to determine weather");
        return 0.0; 
}


const weatherCategories = {
        1.0: ["sunny", "clear", "mostly sunny", "partly sunny","fair"],
        2.0: ["cloudy", "mostly cloudy", "partly cloudy", "overcast"],
        3.0: ["snow", "snowy", "light snow", "heavy snow", "blizzard", "flurries"],
        4.0: ["rain", "showers", "drizzle", "light rain", "heavy rain", "thunderstorms"]
};

function fetchWeatherData()
{
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "https://weather.com/weather/today/l/18e81cdf57491c51a6fba3c57732b7b61bdf511fc2b613570316978b9f20687a", true);
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
                        gl.uniform1f(local_time, parseTimeToFloat(time_num));

                        const Ssun_loc = gl.getUniformLocation(program, "Ssun");
                        gl.uniform2f(Ssun_loc, parseTimeToFloat(sunrise), parseTimeToFloat(sunset));


                        const condition_loc = gl.getUniformLocation(program, "Condition");
                        gl.uniform1f(condition_loc, categorizeWeather(condition));
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

        //attribute the vertices to the vertex shader
        const vertex_position = gl.getAttribLocation(program, "position");
        gl.vertexAttribPointer(vertex_position, 2, gl.FLOAT, false, 0, 0);
        gl.enableVertexAttribArray(vertex_position);

        const resolution_loc = gl.getUniformLocation(program, "iResolution");
        gl.uniform2f(resolution_loc, canvas.width, canvas.height);

        requestAnimationFrame(render); 
}

let lastFetchTime = 0;
const fetchInterval = 60000;

function render(delta_time)
{
        gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        //draw
        gl.drawArrays(gl.TRIANGLES, 0, 6);

        const time_loc = gl.getUniformLocation(program, "iTime");
        gl.uniform1f(time_loc, delta_time);

        let xMouse = 0;
        let yMouse = 0;

        const mouse_loc = gl.getUniformLocation(program, "iMouse");
        document.getElementById("context").addEventListener("mousemove", function(e)
                {
                        xMouse = e.offsetX;
                        yMouse = e.offsetY;
                        document.getElementById("mouse-pos").textContent ="x : " + xMouse + " y : " + yMouse;
                        gl.uniform2f(mouse_loc, xMouse, yMouse);
                })
        if (Date.now() - lastFetchTime >= fetchInterval)
        {
                fetchWeatherData();
                lastFetchTime = Date.now();
        }

        requestAnimationFrame(render); 
}

init();
