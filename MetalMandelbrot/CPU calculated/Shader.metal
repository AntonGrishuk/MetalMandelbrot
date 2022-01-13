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

struct FragmentUniforms
{
    float zoom;
};

vertex
VertexOut vertexShader(VertexIn vert [[ stage_in ]])
{
    VertexOut out;
    out.position = float4(vert.position, 1.0f);
    out.color = vert.color;
    out.size = 1;
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

/*-----------------------------------*/

vertex
float4 fragCalculatedVertexShader(const device float3 *vert,
                                  uint vid [[ vertex_id ]])
{
    float3 point = vert[vid];
//    if (point[0] > 0.2 && point[0] < 0.3 ) {
//        return float4(0, 0, 0, 1);
//    }
    
    return float4(point, 1.0);
}

fragment
float4 fragmentCalculatedShader(float4 point [[ position ]],
                                const device float *size,
                                constant FragmentUniforms &uniforms [[buffer(1)]])
{
    float preX = 0;
    float preY = 0;
    float xn = 0;
    float yn = 0;
    float x = (point[0] + 1) / size[1];
    float y = (point[1] + 1) / size[1];
    
    x*= 2 * uniforms.zoom;
    y*= 2 * uniforms.zoom;

    x -= 1.7;
    y -= uniforms.zoom;
    float max = 200;
    
    float4 color = float4(0, 0, 0, 1);
    
    for (float i = 0; i <= max; i++) {
        xn = preX * preX - preY * preY + x;
        yn = 2 * preY * preX + y;
        preY = yn;
        preX = xn;
        
        

        if (xn*xn + yn*yn < 4) {
            color = float4(1, 1, 1, 1);
        } else {
            color = float4(1 / (xn*xn + yn*yn), 1 / (xn*xn + yn*yn), 1 / (xn*xn + yn*yn), 1);
            return color;
        }
    }
        
    return color;
}
