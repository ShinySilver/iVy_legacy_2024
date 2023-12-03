#version 460

layout(local_size_x = 8,  local_size_y = 8) in;

layout(rgba8, binding = 0) uniform writeonly image2D outImage;

uniform uvec2 screenSize;
uniform uvec3 terrainSize;
uniform uint treeDepth;
uniform vec3 camPos;
uniform mat4 viewMat;
uniform mat4 projMat;

layout(std430, binding = 0) readonly buffer node_pool
{
    uint nodePool[];
};

layout(std430, binding = 1) readonly buffer chunk_pool
{
    uint chunkPool[];
};

vec3 getRayDir(ivec2 screenPos)
{
    vec2 screenSpace = (screenPos + vec2(0.5)) / vec2(screenSize);
	vec4 clipSpace = vec4(screenSpace * 2.0f - 1.0f, -1.0, 1.0);
	vec4 eyeSpace = vec4(vec2(inverse(projMat) * clipSpace), -1.0, 0.0);
	return normalize(vec3(inverse(viewMat) * eyeSpace));
}

float AABBIntersect(vec3 bmin, vec3 bmax, vec3 orig, vec3 invdir)
{
    vec3 t0 = (bmin - orig) * invdir;
    vec3 t1 = (bmax - orig) * invdir;

    vec3 vmin = min(t0, t1);
    vec3 vmax = max(t0, t1);

    float tmin = max(vmin.x, max(vmin.y, vmin.z));
    float tmax = min(vmax.x, min(vmax.y, vmax.z));

    if (!(tmax < tmin) && (tmax >= 0))
        return max(0, tmin);
    return -1;
}

void main()
{
    // make sure current thread is inside the window bounds
    if (any(greaterThanEqual(gl_GlobalInvocationID.xy, screenSize)))
        return;

    // calc ray direction for current pixel
    vec3 rayDir = getRayDir(ivec2(gl_GlobalInvocationID.xy));
    vec3 rayPos = camPos;

    // check if the camera is outside the voxel volume
    float intersect = AABBIntersect(vec3(0), vec3(terrainSize - 1), camPos, 1.0f / rayDir);

    // if it is outside the terrain, offset the ray so its starting position is in the voxel volume
    if (intersect > 0) {
        rayPos += rayDir * (intersect + 0.001);
    }

    // if the ray intersect the terrain, raytrace
    vec3 color = vec3(0.69, 0.88, 0.90); // this is the sky color
    if (intersect >= 0) {
        // do the raytracing here
        // TBD
    }

    // output color to texture
    imageStore(outImage, ivec2(gl_GlobalInvocationID.xy), vec4(color, 1));
}