/* 
@title: NormalToHeightMap_v01
@author: melmass
*/

// inspired by https://stannum.io/blog/data/debump.c

#bind layer src float4
#bind layer !&dst float

#bind parm kernelSize float val=10.0
#bind parm highPassThreshold float val=0.6
#bind parm normalizeOutput float val=1.0

#bind parm gradientScale float val=2.0
#bind parm gradientBias float val=50.0

float ctldisf(float x, float y) { return sqrt(x * x + y * y); }

@KERNEL
void normalToHeightMap() {

    const int2 pos = (int2)(get_global_id(0), get_global_id(1));
    const int2 size = (int2)(@src.xres, @src.yres);
    
    if (pos.x >= size.x || pos.y >= size.y) return;

    float4 _N = @src.bufferIndex(pos);

    float3 N = _N.rgb;
    N = (float3)(2.0,2.0,2.0) * N - (float3)(1.0,1.0,1.0);
    if (length(N) < 1e-3) {
        @dst.setIndex(pos, 0.0f);
        return;
    }

    float Gy = 0.0;
    float Gx = 0.0;
    const int halfKernelSize = @kernelSize / 2;
    
    for (int y = -halfKernelSize; y <= halfKernelSize; ++y) {
        for (int x = -halfKernelSize; x <= halfKernelSize; ++x) {
            const int2 neighborPos = pos + (int2)(x, y);
            
            if (neighborPos.x < 0 || neighborPos.x >= size.x ||
                neighborPos.y < 0 || neighborPos.y >= size.y) {
                continue;
            }

            float4 _Nn = @src.bufferIndex(neighborPos);
            float3 Nn = _Nn.rgb;
            Nn = (float3)(2.0,2.0,2.0) * Nn - (float3)(1.0,1.0,1.0);

            const float distanceWeight = ctldisf((float)(x), (float)(y)) / 
                                        ctldisf((float)halfKernelSize, (float)halfKernelSize);
            const float normalConsistency = dot(Nn, N);

            if (normalConsistency > @highPassThreshold) {
                Gy += distanceWeight * Nn.y * @gradientScale;
                Gx -= distanceWeight * Nn.x * @gradientScale;
            }
        }
    }

    const float gradientLength = sqrt(Gx*Gx + Gy*Gy) + @gradientBias;
    if (gradientLength > 1e-3) {
        Gy /= gradientLength;
        Gx /= gradientLength;
    } else {
        @dst.setIndex(pos, 0.5f);
        return;
    }

    float height = 0.5;
    for (int x = 0; x < pos.x + 1; ++x) {
        height -= Gx * 2.0f / size.x;
    }
    for (int y = 0; y < pos.y + 1; ++y) {
        height += Gy * 2.0f / size.y;
    }

    if (@normalizeOutput) {
        height = (height - 0.5) / 0.5; 
        height = clamp(height, -1.0f, 1.0f);
        height = (height + 1.0f) * 0.5;
    } 

    @dst.setIndex(pos, height);
}
