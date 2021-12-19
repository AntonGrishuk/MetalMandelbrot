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
    out.size = 10;
    return out;
}

fragment
float4 fragmentShader(VertexOut frag [[ stage_in ]])
{
    return frag.color;
}

kernel
void pointColor(device const float2 *position [[ buffer(0) ]],
                device float3 *result [[ buffer(1) ]],
                uint index [[thread_position_in_grid]])
{
    
    float preX = 0;
    float preY = 0;
    float xn = 0;
    float yn = 0;
    float x = position[index].x;
    float y = position[index].y;

    float max = 20;
    
    float3 color = float3(1, 0, 0);
    
    for (float i = 0; i <= max; i++) {
        xn = preX * preX - preY * preY + x;
        yn = 2 * preY * preX + y;
        preY = yn;
        preX = xn;

        if (xn*xn + yn*yn > 4) {
            result[index] = color;
            break;
        } else {
            float colorComponent = i / max;
            color = float3(colorComponent, colorComponent, colorComponent);
        }
    }
        
    result[index] = color;
}
