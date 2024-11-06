# Droppy - Interactive Weather Visualization

Droppy is an interactive weather visualization tool that displays dynamic weather data along with visual elements such as snow, rain and the position of the sun based on time, using WebGL and shaders. It allows users to input a location URL, fetch weather data, and view it with real-time rendering on a 3D canvas, if it's daytime, raining, having a bright blue sky and so on.

## Features

- **Dynamic Weather Visualization**: View 3D weather elements like snow, rain and bright light based on real-time data.
- **Real-Time Data Fetching**: Fetch weather details like location, temperature, and time based on user input.
- **Interactive Canvas**: A 3D rendered canvas that simulates a weather environment and visual effects such as snow, temperature-based lighting, and time transitions.
- **Dynamic Sun Position Visualization**: You can witness the sun rising and setting and be in it's accurate position for whatever city you choose.

## Demo

![Droppy Demo](path/to/your/gif.gif)

## Technologies Used

- **JavaScript**: Handles the logic for weather data fetching and canvas rendering.
- **WebGL/Shader Programming**: Used to create the 3D canvas visualization.
- **Weather API**: Fetches weather data based on the provided URL (you can use any compatible weather API service, e.g., OpenWeatherMap, WeatherStack, etc.).

## Installing

If you like this project, you can either use it via [this link](https://mailitruong.github.io/RayMarching/) or feel free to clone this repository. Here's how you can do:

1. **Copy the URL (either HTTPS or SSH) provided.**

2. **Open your terminal and navigate to the directory where you want to clone**:
     ```bash
     cd path/to/your/directory
     ```

4. **Clone the Repository**:
   - Run the following command, replacing `repository-url` with the URL you copied earlier:
     ```bash
     git clone repository-url
     ```
5. Submit a pull request

## Acknowledgements

- Thanks to [OpenWeatherMap](https://openweathermap.org/) (or the weather API service you are using) for providing the weather data.
- Special thanks to the WebGL community for the resources on shader programming and canvas rendering techniques.
