HitRecord ray_intersect(Ray ray, Sphere object) {
    vec3 dist = ray.origin - object.center;
    float B = 2.0 * dot(ray.direction, dist);
    float C = dot(dist, dist) - pow(object.radius, 2.0);

    float t;
    bool valid;
    float delta = pow(B, 2.0) - 4.0 * C;
    if (delta > 0.0) {
        delta = sqrt(delta);
        float pos = (-B + delta) / 2.0;
        float neg = (-B - delta) / 2.0;
        t = min(pos, neg);
        valid = true;
    } else if (delta == 0.0) {
        t = -B / 2.0;
        valid = true;
    } else {
        t = 0.0;
        valid = false;
    }

    vec3 intersection = ray.origin + ray.direction * t;
    vec3 normal = normalize(intersection - object.center);

    return HitRecord(valid, t, intersection, normal, object);
}