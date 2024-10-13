//
//  Shader.metal
//  MetalMandelbrot
//
//  Created by Anton Hryshchuk on 09.08.2021.
//

#include <metal_stdlib>
using namespace metal;

struct FragmentUniforms
{
    float scale;
    float2 viewSize;
    float2 translation;
};

float4 mandelbrotPointColor(float x, float y);

vertex
float4 fragCalculatedVertexShader(const device float3 *vert,
                                  uint vid [[ vertex_id ]])
{
    float3 point = vert[vid];
    return float4(point, 1.0);
}

fragment
float4 fragmentCalculatedShader(float4 point [[ position ]],
                                constant FragmentUniforms &uniforms [[buffer(0)]])
{
    float width = uniforms.viewSize[0];
    float height = uniforms.viewSize[1];
    float k = 1 / height;
    float scale = uniforms.scale;
    
    float translation_x = uniforms.translation[0];
    float translation_y = uniforms.translation[1];
    
    float x = point[0] + translation_x - width * 0.5;
    float y = point[1] + translation_y - height * 0.5;
    
    x /= scale;
    y /= scale;

    x *= 2 * k;
    y *= 2 * k;
        
    return mandelbrotPointColor(x, y);
}

float4 mandelbrotPointColor(float x, float y) {
    float pre_x = 0;
    float pre_y = 0;
    float xn = 0;
    float yn = 0;

    float max_iterations = 250;

    float4 color = float4(0, 0, 0, 1);

    int threshold = 4;
    
    float4 color_0 = float4(0.0f, 0.0f, 0.0f, 1.0f);
    float4 color_1 = float4(0.0f, 0.2f, 0.5f, 1.0f);
    float4 color_2 = float4(1.0f, 0.8f, 0.0f, 1.0f);
    float4 color_3 = float4(1.0f, 0.0f, 0.4f, 1.0f);
    
    float fraction = 0.0f;
    float color_ranges[] = {0, 5, 20, 70};

    for (float i = 0; i <= max_iterations; i++) {
        xn = pre_x * pre_x - pre_y * pre_y + x;
        yn = 2 * pre_y * pre_x + y;
        pre_y = yn;
        pre_x = xn;

        if (xn * xn + yn * yn > threshold) {
            if (i < color_ranges[1])
            {
                fraction = (i - color_ranges[0]) / (color_ranges[1] - color_ranges[0]);
                return mix(color_0, color_1, fraction);
            }
            else if(i < color_ranges[2])
            {
                fraction = (i - color_ranges[1]) / (color_ranges[2] - color_ranges[1]);
                return mix(color_1, color_2, fraction);
            }
            else
            {
                fraction = (i - color_ranges[2]) / (color_ranges[3] - color_ranges[2]);
                return mix(color_2, color_3, fraction);
            }
        }
    }

    return color;
}
