#version 460
#extension GL_NV_ray_tracing : require
#extension GL_EXT_nonuniform_qualifier : enable
#extension GL_EXT_scalar_block_layout : enable
#extension GL_GOOGLE_include_directive : enable
#include "raycommon.glsl"
#include "wavefront.glsl"
#include "random.glsl"

// This shader performs recursive path tracing using monte-carlo sampling
// Upon a ray intersection, pick a random direction in the hemisphere centered
// around the hit normal, and trace a new ray recursively, passing back the color.
// The monte carlo integration is handled in the ray generation shader, where
// the current frame is averaged with all previously identical frames using the frameCounter.

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
    float phi = r1 * 2.0 * M_PI;
    float theta = acos(1.0 - r2);
    // Similar to our A1 sphere calculation, except theta=0 is the top of the hemisphere
    return vec3(sin(theta) * cos(phi), cos(theta), sin(theta)*sin(phi));
}

// Returns a matrix that will transform a (0,1,0)-relative hemisphere vector
// to be relative to a specified normal vector instead
mat3 normal_y_basis(vec3 N)
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

    // Generate two random values - the seed is passed as a reference, so it changes after each call to rnd()
    float r1 = rnd(prd.seed);
    float r2 = rnd(prd.seed);

    // Compute the new ray reflected direction
    vec3 monteCarloDir = normal_y_basis(normal) * generate_hemisphere_vector(r1, r2);
    // Lambert's cosine law - this is equivalent to the dot(L, N) calculation in direct illumination models
    float cos_theta = max(dot(monteCarloDir, normal), 0);

    WaveFrontMaterial mat = materials[objId].m[v0.matIndex];

    if (prd.recursionDepth > 0)
    {
        // Send out the monte-carlo ray
        prd.recursionDepth--;
        traceNV(
            topLevelAS,           // acceleration structure
            gl_RayFlagsOpaqueNV,  // rayFlags
            0xFF,                 // cullMask
            1,                    // sbtRecordOffset
            0,                    // sbtRecordStride
            0,                    // missIndex
            worldPos,             // ray origin
            0.001,                // ray min range
            monteCarloDir,        // ray direction
            10000.0,              // ray max range
            0                     // payload (location = 0)
        );
        prd.recursionDepth++;

        if (mat.textureId >= 0)
        {
            uint txtId = mat.textureId + scnDesc.i[gl_InstanceID].txtOffset;
            vec2 texCoord =
                v0.texCoord * barycentrics.x + v1.texCoord * barycentrics.y + v2.texCoord * barycentrics.z;
            mat.diffuse *= texture(textureSamplers[txtId], texCoord).xyz;
        }

        // Compute the color at this intersection
        prd.hitValue = mat.emission + (2 * mat.diffuse * prd.hitValue * cos_theta);
    }
    else
    {
        // If we are at maximum depth, we can't calculate any diffuse
        prd.hitValue = mat.emission;
    }
}
