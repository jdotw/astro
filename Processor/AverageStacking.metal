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
    float4 avgStacking(sample_t currentStack, sample_t newImage, float stackCount) {
        float4 avg = ((currentStack * stackCount) + newImage) / (stackCount + 1.0);
        avg = float4(avg.rgb, 1);
        return avg;
    }
}}
