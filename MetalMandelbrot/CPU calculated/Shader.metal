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
    float2 position;
    float2 translation;
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

float4 mandelbrotPointColor(float x, float y);

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
    float x = point[0] + uniforms.translation[0];
    float y = point[1] + uniforms.translation[1];
    
    float width = size[0];
    float height = size[1];
    float k = 1 / height;
    
    /*Set origin to the center*/
    y -= height / 2;
    x -= width / 2;

    /*Increase parametrized height, because Mandelprot Set is located between -1 an 1 by y axis.*/
    x *= 2;
    y *= 2;
    
    /* Apply zoom and set scale*/
    x *= k * uniforms.zoom;
    y *= k * uniforms.zoom;
        
    return mandelbrotPointColor(x, y);
}

float4 mandelbrotPointColor(float x, float y) {
    float preX = 0;
    float preY = 0;
    float xn = 0;
    float yn = 0;
    
    float max = 150;
    
    float4 color = float4(0, 0, 0, 1);
    
    int threshold = 4;
    
    for (float i = 0; i <= max; i++) {
        xn = preX * preX - preY * preY + x;
        yn = 2 * preY * preX + y;
        preY = yn;
        preX = xn;

        if (xn*xn + yn*yn > threshold) {
            color = float4(4 / (xn*xn + yn*yn), 2 / (xn*xn + yn*yn), 4 / (xn*xn + yn*yn), 1);
            return color;
        }
    }
    
    
    if (xn*xn + yn*yn < threshold) {
        color = float4(.7, 1, .6, 1);
    }
        
    return color;
}
