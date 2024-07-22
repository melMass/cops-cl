/*
@title: gaussian_glow_v01
@author: melmass
*/

#bind layer src float4
#bind layer !&dst float4

#bind parm intensity float
#bind parm threshold float
#bind parm radius float

float gaussian(float x, float sigma) {
    return exp(-(x*x) / (2.0f * sigma*sigma)) / (sqrt(2.0f * M_PI) * sigma);
}

@KERNEL
{
    const int2 pos = (int2)(get_global_id(0), get_global_id(1));
    const int2 size = (int2)(@src.xres, @src.yres);
    
    if (pos.x >= size.x || pos.y >= size.y) return;

    float4 original = @src.bufferIndex(pos);
    float brightness = dot(original.rgb, (float3)(0.299f, 0.587f, 0.114f));
    float4 glowPixel = (brightness > @threshold) ? original : (float4)(0.0f);

    float4 blurred = (float4)(0.0f);
    float weightSum = 0.0f;
    int blurRadius = (int)@radius;

    for (int dy = -blurRadius; dy <= blurRadius; dy++) {
        for (int dx = -blurRadius; dx <= blurRadius; dx++) {
            int2 samplePos = pos + (int2)(dx, dy);
            if (samplePos.x >= 0 && samplePos.x < size.x && samplePos.y >= 0 && samplePos.y < size.y) {
                float4 sample = @src.bufferIndex(samplePos);
                float sampleBrightness = dot(sample.rgb, (float3)(0.299f, 0.587f, 0.114f));
                float4 sampleGlow = (sampleBrightness > @threshold) ? sample : (float4)(0.0f);
                
                float weight = gaussian(length((float2)(dx, dy)), @radius / 3.0f);
                blurred += sampleGlow * weight;
                weightSum += weight;
            }
        }
    }
    blurred /= weightSum;
    float4 result = original + blurred * @intensity;
    result = clamp(result, 0.0f, 1.0f);
    @dst.setIndex(pos, result);
}
