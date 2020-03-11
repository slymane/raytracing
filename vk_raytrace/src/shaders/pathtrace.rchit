#version 460
#extension GL_NV_ray_tracing : require
#extension GL_EXT_nonuniform_qualifier : enable
#extension GL_EXT_scalar_block_layout : enable
#extension GL_GOOGLE_include_directive : enable
#include "raycommon.glsl"
#include "wavefront.glsl"
#include "random.glsl"

layout(location = 0) rayPayloadInNV hitPayload prd;

layout(binding = 0, set = 0) uniform accelerationStructureNV topLevelAS;
layout(binding = 1, set = 1, scalar) buffer MatColorBufferObject { WaveFrontMaterial m[]; } materials[];
layout(binding = 2, set = 1, scalar) buffer ScnDesc { sceneDesc i[]; } scnDesc;
layout(binding = 3, set = 1) uniform sampler2D textureSamplers[];
layout(binding = 4, set = 1, scalar) buffer Vertices { Vertex v[]; } vertices[];
layout(binding = 5, set = 1) buffer Indices { uint i[]; } indices[];

layout(push_constant) uniform Constants
{
  vec4  clearColor;
  vec3  lightPosition;
  float lightIntensity;
  int   lightType;
  int   frameCounter;
  bool  pathTrace;
}
pushC;

hitAttributeNV vec3 attribs;

#define M_PI 3.1415926535897932384626433832795


// Given two random floats in [0,1], computes a corresponding
// evenly distributed unit vector in the y>0 hemisphere
vec3 generate_hemisphere_vector(float r1, float r2)
{
    float phi = r1 * 2 * M_PI;
    float theta = acos(1 - 2 * r2);
    return vec3(cos(theta) * sin(phi), sin(theta), cos(theta)*cos(phi));
}

mat3 transform_from_normal(vec3 N)
{
    vec3 u;
    if (abs(N.x) > abs(N.y)) 
        u = normalize(vec3(N.z, 0, -N.x)); 
    else 
        u = normalize(vec3(0, -N.z, N.y));
    
    vec3 w = cross(N, u);
    return mat3(u, N, w);
}

void main()
{
    // Object of this instance
    uint objId = scnDesc.i[gl_InstanceID].objId;

    // Indices of the triangle
    ivec3 ind = ivec3(indices[objId].i[3 * gl_PrimitiveID + 0],   //
                    indices[objId].i[3 * gl_PrimitiveID + 1],   //
                    indices[objId].i[3 * gl_PrimitiveID + 2]);  //
    // Vertex of the triangle
    Vertex v0 = vertices[objId].v[ind.x];
    Vertex v1 = vertices[objId].v[ind.y];
    Vertex v2 = vertices[objId].v[ind.z];

    // Since no intersection shader is specified, the hitAttributeNV structure contains
    // the barycentric beta/gamma coordinates of the triangle intersection
    const vec3 barycentrics = vec3(1.0 - attribs.x - attribs.y, attribs.x, attribs.y);

    // Computing the normal at hit position
    vec3 normal = v0.nrm * barycentrics.x + v1.nrm * barycentrics.y + v2.nrm * barycentrics.z;
    // Transforming the normal to world space
    normal = normalize(vec3(scnDesc.i[gl_InstanceID].transfoIT * vec4(normal, 0.0)));

    // Computing the coordinates of the hit position
    vec3 worldPos = v0.pos * barycentrics.x + v1.pos * barycentrics.y + v2.pos * barycentrics.z;
    // Transforming the position to world space
    worldPos = vec3(scnDesc.i[gl_InstanceID].transfo * vec4(worldPos, 1.0));

    uint seed = tea(gl_LaunchIDNV.y * gl_LaunchSizeNV.x + gl_LaunchIDNV.x, pushC.frameCounter);

    float r1 = rnd(seed);
    float r2 = rnd(seed);

    vec3 monteCarloDir = transform_from_normal(normal) * generate_hemisphere_vector(r1, r2);
    const float p = 1 / (2 * M_PI);
    float cos_theta = dot(monteCarloDir, normal);

    WaveFrontMaterial mat = materials[objId].m[v0.matIndex];

    vec3 incoming = vec3(0);

    if (prd.recursionDepth > 0)
    {
        prd.recursionDepth--;
        traceNV(
            topLevelAS,           // acceleration structure
            gl_RayFlagsOpaqueNV,  // rayFlags
            0xFF,                 // cullMask
            1,                    // sbtRecordOffset
            0,                    // sbtRecordStride
            0,                    // missIndex
            worldPos,               // ray origin
            0.001,                // ray min range
            monteCarloDir,            // ray direction
            10000.0,              // ray max range
            0                     // payload (location = 0)
        );
        prd.recursionDepth++;
    }

    prd.hitValue = mat.emission + ((mat.diffuse / M_PI) * prd.hitValue * cos_theta / p);
}
