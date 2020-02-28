#version 300 es
#define FLT_MAX 3.402823466e+38

precision mediump float;
out vec4 fragmentColor;

uniform float WindowHeight;
uniform float WindowWidth;

struct Ray {
    vec3 origin;
    vec3 direction;
};

struct Sphere {
    vec3 center;
    float radius;
    vec3 color;
};

struct PointLight {
    float intensity;
    vec3 position;
};

struct CanonicalCamera {
    float canv_height;
    float canv_width;
};

struct HitRecord {
    bool valid;
    float t;
    vec3 intersection;
    vec3 normal;
    Sphere object;
};

struct Scene {
    vec3 background;
    Sphere object;
    PointLight light;
};

Ray pixel_to_ray(CanonicalCamera camera, float i, float j) {
    float vp_height = camera.canv_height / camera.canv_width;
    float u =  ((j - 0.5)    / camera.canv_width       - 0.5);
    float v = -((i - 0.5)    / camera.canv_height      - 0.5) * vp_height;
    float w = -1.0;

    return Ray(vec3(0, 0, 0), normalize(vec3(u, v, w)));
}

HitRecord ray_intersect(Ray ray, Sphere object) {
    vec3 dist = ray.origin - object.center;
    float B = dot(ray.direction, dist);
    float C = dot(dist, dist) - pow(object.radius, 2.0);

    float t;
    bool valid;
    float delta = pow(B, 2.0) - C;
    if (delta > 0.0) {
        delta = sqrt(delta);
        float pos = -B + delta;
        float neg = -B - delta;
        t = min(pos, neg);
        valid = true;
    } else if (delta == 0.0) {
        t = -B;
        valid = true;
    } else {
        t = 0.0;
        valid = false;
    }

    vec3 intersection = ray.origin + ray.direction * t;
    vec3 normal = normalize(intersection - object.center);

    return HitRecord(valid, t, intersection, normal, object);
}

HitRecord closest_intersect(Ray ray, Sphere object, float tmin, float tmax) {
    HitRecord hr = ray_intersect(ray, object);
    
    if (hr.t < tmin || hr.t > tmax) {
        hr.valid = false;
    }

    return hr;
}

vec3 traceray(Scene scene, Ray ray, float tmin, float tmax) {
    HitRecord hr = closest_intersect(ray, scene.object, tmin, tmax);

    if (hr.valid) {
        return hr.object.color;  
    }
    return scene.background;
}

Scene get_scene1() {
    vec3 bg = vec3(0.95, 0.95, 0.95);
    Sphere object = Sphere(vec3(-0.5, -0.5, -6), 1.0, vec3(0.73, 0, 0.17));
    PointLight light = PointLight(0.8, vec3(0, 0, 0));
    return Scene(bg, object, light);
}

void main() {
    Scene scene = get_scene1();
    CanonicalCamera camera = CanonicalCamera(WindowHeight, WindowWidth);
    Ray ray = pixel_to_ray(camera, gl_FragCoord.y, gl_FragCoord.x);
    vec3 color = traceray(scene, ray, 1.0, FLT_MAX);
    fragmentColor = vec4(color, 1.0);
}