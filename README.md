# Droppy - Interactive Weather Visualization

Droppy is an interactive weather visualization tool that displays dynamic weather data along with visual elements such as snow, rain and the position of the sun based on time, using WebGL. It allows users to input a location URL, fetch weather data, and view it with real-time rendering on a 3D canvas, if it's daytime, raining, having a bright blue sky and so on. For the moment I can only do the research using URLs from this website [The Weather Channel](https://weather.com/) but the goal will be to be able to use an API so that the user doesn't have to copy the URL himself and have more realist graphism. 

## Features

- **Dynamic Weather Visualization**: View 3D weather elements like snow, rain and bright light based on real-time data.
- **Real-Time Data Fetching**: Fetch weather details like location, temperature, and time based on user input.
- **Interactive Canvas**: A 3D rendered canvas that simulates a weather environment and visual effects such as snow, temperature-based lighting, and time transitions.
- **Dynamic Sun Position Visualization**: You can witness the sun rising and setting and be in it's accurate position for whatever city you choose.

## Demo

![Droppy Demo](demo.gif)

## Technologies 

- **WebGl**: Used to create the 3D canvas visualization.
- **Ray Marching**

## Installing

If you like this project, you can either use it via [this link](https://mailitruong.github.io/RayMarching/) or feel free to clone this repository. Here's how you can do:

1. **Clone the Repository**:
   - Run the following command:
     ```bash
     git clone https://github.com/MailiTruong/RayMarching.git
     cd RayMarching
     ```
2. **Create a python server:**
     ```bash
     python3 -m http.server 8000
     ```
     
## Acknowledgements

- Thanks to [The Weather Channel](https://weather.com/) for providing the weather data.
- Special thanks to the WebGL community for the resources on shader programming and canvas rendering techniques.

