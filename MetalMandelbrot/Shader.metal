//
//  Shader.metal
//  MetalMandelbrot
//
//  Created by Anton Hryshchuk on 09.08.2021.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn
{
    float3 position [[ attribute(0) ]];
    float4 color    [[ attribute(1) ]];
};

struct VertexOut
{
    float4 position [[ position ]];
    float4 color;
    float size [[point_size]];
};

vertex
VertexOut vertexShader(VertexIn vert [[ stage_in ]])
{
    VertexOut out;
    out.position = float4(vert.position, 1.0f);
    out.color = vert.color;
    out.size = 5;
    return out;
}

fragment
float4 fragmentShader(VertexOut frag [[ stage_in ]])
{
    return frag.color;
}
