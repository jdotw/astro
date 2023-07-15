//
//  AverageStacking.metal
//  Astro
//
//  Created by James Wilson on 15/7/2023.
//

#include <metal_stdlib>
using namespace metal;

#include <CoreImage/CoreImage.h>

extern "C" { namespace coreimage {
    // 1
    float4 avgStacking(sample_t currentStack, sample_t newImage, float stackCount) {
        // 2
        float4 avg = ((currentStack * stackCount) + newImage) / (stackCount + 1.0);
        // 3
        avg = float4(avg.rgb, 1); 
        // 4
        return avg;
    }
}}
