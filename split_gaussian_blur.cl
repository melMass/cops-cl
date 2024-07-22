/*
@title: split_gaussian_blur_v01
@author: melmass
*/

#bind layer src float4
#bind layer !&blurred float4

#bind parm sigma float4
#bind parm sigmaMultiplier float


float gaussian(float x, float sigma) {
    return exp(-(x*x) / (2.0f * sigma*sigma)) / (sqrt(2.0f * M_PI) * sigma);
}

@KERNEL
{
    @sigma = max(0.00001f, @sigma) * @sigmaMultiplier;
    const int2 pos = (int2)(get_global_id(0), get_global_id(1));
    const int2 size = (int2)(@src.xres, @src.yres);

    if (pos.x >= size.x || pos.y >= size.y) return;

    float4 blurredColor = 0.0f;
    float sumR = 0.0f;
    float sumG = 0.0f;
    float sumB = 0.0f;

    float alpha = 0.0f;
    float sumAlpha = 0.0f;

    const int radius = (int)(3.0f * max(max(@sigma.x, @sigma.y), max(@sigma.z, @sigma.w)));

    for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
            int2 samplePos = pos + (int2)(dx, dy);
            if (samplePos.x >= 0 && samplePos.x < size.x && samplePos.y >= 0 && samplePos.y < size.y) {
                float4 sample = @src.bufferIndex(samplePos);

                float weightR = gaussian(length((float2)(dx, dy)), @sigma.x);
                float weightG = gaussian(length((float2)(dx, dy)), @sigma.y);
                float weightB = gaussian(length((float2)(dx, dy)), @sigma.z);
                float weightA = gaussian(length((float2)(dx, dy)), @sigma.w);

                blurredColor.x += sample.x * weightR;
                blurredColor.y += sample.y * weightG;
                blurredColor.z += sample.z * weightB;
                alpha += sample.w * weightA;

                sumR += weightR;
                sumG += weightG;
                sumB += weightB;
                sumAlpha += weightA;
            }
        }
    }

    if (sumR > 0.0f) blurredColor.x /= sumR;
    if (sumG > 0.0f) blurredColor.y /= sumG;
    if (sumB > 0.0f) blurredColor.z /= sumB;
    if (sumAlpha > 0.0f) alpha /= sumAlpha;

    blurredColor.w = alpha;

    @blurred.setIndex(pos, blurredColor);
}
