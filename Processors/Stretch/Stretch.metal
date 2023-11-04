//
//  Stretch.metal
//  Astro
//
//  Created by James Wilson on 15/7/2023.
//

#include <metal_stdlib>
#include <metal_geometric>
using namespace metal;

#include <CoreImage/CoreImage.h>

extern "C" { namespace coreimage {
    float4 stretch(sample_t sample, float midtone, float shadowClip) {
        // NOTE: We found out the hard way that when the
        // pixel data is sent to the metal shader, it undergoes
        // a conversion from srgb to linear which means in
        // the shader itself we have to undo this and switch
        // back to srgb to ensure these shadowClip and midtone
        // values are relevant to the pixel data in the shader
        //
        // Hence the call to liner_to_srgb on the sample and the
        // corresponding srgb_to_linear on the output
        float4 linear = linear_to_srgb(sample);
        float in = (linear.r + linear.g + linear.b) / 3;
        float out = in;
        if (in < shadowClip) {
            out = 0.0;
        } else {
            float normalised = (in - shadowClip) / (1.0 - shadowClip);
            out = (midtone - 1.0) * normalised / ((((2.0 * midtone) - 1.0) * normalised) - midtone);
        }
        return srgb_to_linear(float4(out, out, out, 1.0));
    }
}}
