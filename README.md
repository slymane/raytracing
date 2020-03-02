# Simple Hardware Ray Tracing - Jagi Natarajan | Eric Slyman

## Hardware accelerated ray tracing with JS/WebGL and C++/Vulkan.

### The WebGL Raytracer

#### What Happened Before The Initial Commit?

- Assignment three code distilled to essential components
- WebGL ported to WebGL2
- glsl ported to version 3.0
- glsl source moved from DOMString to shader file
- Javascript linear algebra ported to full light.gl version
- Barebones ray tracer implemented in glsl vertex shader

#### Setting It Up

Because we didn't want to embed our shader files directly in the javascript, it is necessary to run a simple web server to get this project working. Navigate to the Web directory and run `python3 -m http.server`, then point your browser to `localhost:8000`. You should see a lambertian-shaded sphere, smoothly alternating between two colors.

### The Vulkan Raytracer 

#### Requirements

- An NVIDIA GPU with support for the `VK_NV_ray_trace` extension (>= GTX 1060)
- [Visual Studio](https://visualstudio.microsoft.com/downloads/) (Install the Desktop Development With C++ package)
- [Vulkan SDK](https://vulkan.lunarg.com/sdk/home)

#### Project Overview

The VKExamples.sln solution within the vk_raytrace folder contains the VKExample1 project, which was originally a boilerplate Vulkan project with all the necessary code to do object-order rendering of OBJ models. We have extended this project to perform rendering via hardware-accelerated raytracing, closely following [this tutorial](https://nvpro-samples.github.io/vk_raytracing_tutorial/). Our plan is to use the boilerplate structure we've established to implement more complex real-time raytracing features.

Assuming the above requirements are satisfied, the solution should build and launch the vulkan window successfully, showing a plane with several reflective spheres. A debug panel allows for control of some of the scene properties, and on-the-fly toggling between using raytracing and the original object-order renderer that the example project contained.