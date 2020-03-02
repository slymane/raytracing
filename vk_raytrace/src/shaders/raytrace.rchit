#version 460
#extension GL_NV_ray_tracing : require
#extension GL_EXT_nonuniform_qualifier : enable
#extension GL_EXT_scalar_block_layout : enable
#extension GL_GOOGLE_include_directive : enable
#include "raycommon.glsl"
#include "wavefront.glsl"


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
}
pushC;

hitAttributeNV vec3 attribs;

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

    // Vector toward the light
    vec3  L;
    float lightIntensity = pushC.lightIntensity;
    float lightDistance  = 100000.0;

    // Point light
    if(pushC.lightType == 0)
    {
        vec3 lDir      = pushC.lightPosition - worldPos;
        lightDistance  = length(lDir);
        lightIntensity = pushC.lightIntensity / (lightDistance * lightDistance);
        L              = normalize(lDir);
    }
    else // Directional light
    {
        L = normalize(pushC.lightPosition - vec3(0));
    }

    WaveFrontMaterial mat = materials[objId].m[v0.matIndex];

    vec3 diffuse = computeDiffuse(mat, L, normal);
    if (mat.textureId >= 0)
    {
        uint txtId = mat.textureId + scnDesc.i[gl_InstanceID].txtOffset;
        vec2 texCoord =
            v0.texCoord * barycentrics.x + v1.texCoord * barycentrics.y + v2.texCoord * barycentrics.z;
        diffuse *= texture(textureSamplers[txtId], texCoord).xyz;
    }

    vec3 specular = computeSpecular(mat, gl_WorldRayDirectionNV, L, normal);

    vec3 hitValue = vec3(0);
    vec3 attenuation = prd.attenuation;

    if (mat.illum == 3 && prd.recursionDepth > 0)
    {
        vec3 origin = worldPos;
        vec3 direction = reflect(gl_WorldRayDirectionNV, normal);
        prd.attenuation = prd.attenuation * mat.specular;

        prd.recursionDepth--;

        traceNV(
            topLevelAS,           // acceleration structure
            gl_RayFlagsOpaqueNV,  // rayFlags
            0xFF,                 // cullMask
            0,                    // sbtRecordOffset
            0,                    // sbtRecordStride
            0,                    // missIndex
            origin,               // ray origin
            0.001,                // ray min range
            direction,            // ray direction
            10000.0,              // ray max range
            0                     // payload (location = 0)
        );

        prd.recursionDepth++;
    }

    prd.hitValue += vec3(lightIntensity * attenuation * (diffuse + specular));
}
