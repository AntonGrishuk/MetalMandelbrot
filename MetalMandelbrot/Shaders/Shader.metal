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
    float oldScale;
    float2 viewSize;
    float2 translation;
    float2 anchor;
};

float4 mandelbrotPointColor(float x, float y);

/*-----------------------------------*/

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
//    float old_scale = uniforms.oldScale;
    
    float translation_x = uniforms.translation[0];
    float translation_y = uniforms.translation[1];
    
//    float anchor_x = uniforms.anchor[0] + translation_x;
//    float anchor_y = uniforms.anchor[1] + translation_y;
    
    float x = point[0] + translation_x - width * 0.5;
    float y = point[1] + translation_y - height * 0.5;
    
    x /= scale;
    y /= scale;
    
//    anchor_x *= scale;
//    anchor_y *= scale;
    
    /*Increase parametrized height, because Mandelprot Set is located between -1 an 1 by y axis.*/
    x *= 2 * k;
    y *= 2 * k;
    
//    anchor_x *= 2 * k;
//    anchor_y *= 2 * k;
    
//    float pinsh_shift_x = anchor_x * (1 - old_scale / scale);
//    float pinsh_shift_y = anchor_y * (1 - old_scale / scale);
    
//    x -= pinsh_shift_x;
//    y -= pinsh_shift_y;
    
    if ((x > -0.005 / scale && x < 0.005 / scale) || (y > -0.005 / scale && y < 0.005 / scale)) {
        return float4(1, 0, 0, 1);
    }
        
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
