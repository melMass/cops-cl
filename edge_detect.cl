/*
@title: edge_detect_v01
@author: melmass
*/

// INFO: kept for reference but it should be broke down into multiple kernels to work properly.
// the builtin EdgeDetect COP is built like that and is a great reference.

#bind layer src float
#bind layer !&dst float

#bind parm low_threshold float
#bind parm high_threshold float
#bind parm gaussian_sigma float

float gaussian(float x, float sigma) {
    return exp(-(x*x) / (2.0f * sigma*sigma)) / (sqrt(2.0f * M_PI) * sigma);
}

@KERNEL
{
    const int2 pos = (int2)(get_global_id(0), get_global_id(1));
    const int2 size = (int2)(@src.xres, @src.yres);
    
    if (pos.x >= size.x || pos.y >= size.y) return;

    float blurred = 0.0f;
    const int radius = (int)(3.0f * @gaussian_sigma);
    float sum = 0.0f;
    
    for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
            int2 samplePos = pos + (int2)(dx, dy);
            if (samplePos.x >= 0 && samplePos.x < size.x && samplePos.y >= 0 && samplePos.y < size.y) {
                float sample = @src.bufferIndex(samplePos);
                float weight = gaussian(length((float2)(dx, dy)), @gaussian_sigma);
                blurred += sample * weight;
                sum += weight;
            }
        }
    }
    blurred /= sum;

    // compute gradient
    float gx = 0.0f, gy = 0.0f;
    float sobelX[3] = {-1.0f, 0.0f, 1.0f};
    float sobelY[3] = {1.0f, 2.0f, 1.0f};

    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            int2 samplePos = pos + (int2)(i, j);
            float sampleBlurred = 0.0f;
            float sampleSum = 0.0f;
            
            // hacky way to sample blurred pixel...
            for (int dy = -radius; dy <= radius; dy++) {
                for (int dx = -radius; dx <= radius; dx++) {
                    int2 blurPos = samplePos + (int2)(dx, dy);
                    if (blurPos.x >= 0 && blurPos.x < size.x && blurPos.y >= 0 && blurPos.y < size.y) {
                        float sample = @src.bufferIndex(blurPos);
                        float weight = gaussian(length((float2)(dx, dy)), @gaussian_sigma);
                        sampleBlurred += sample * weight;
                        sampleSum += weight;
                    }
                }
            }
            sampleBlurred /= sampleSum;
            
            gx += sampleBlurred * sobelX[i+1] * sobelY[j+1];
            gy += sampleBlurred * sobelY[i+1] * sobelX[j+1];
        }
    }

    float gradientMagnitude = sqrt(gx*gx + gy*gy);
    float gradientDirection = atan2(gy, gx);
    
    float angle = (gradientDirection > 0 ? gradientDirection : (gradientDirection + M_PI)) * 180.0f / M_PI;
    int2 q = (int2)(0, 0), r = (int2)(0, 0);
    
    if ((angle >= 0 && angle < 22.5) || (angle >= 157.5 && angle <= 180)) {
        q = r = (int2)(1, 0);
    } else if (angle >= 22.5 && angle < 67.5) {
        q = (int2)(1, 1); r = (int2)(-1, -1);
    } else if (angle >= 67.5 && angle < 112.5) {
        q = r = (int2)(0, 1);
    } else if (angle >= 112.5 && angle < 157.5) {
        q = (int2)(-1, 1); r = (int2)(1, -1);
    }

    float magnitudeQ = 0.0f, magnitudeR = 0.0f;
    float sumQ = 0.0f, sumR = 0.0f;

    
    for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
            int2 qPos = pos + q + (int2)(dx, dy);
            int2 rPos = pos + r + (int2)(dx, dy);
            float weight = gaussian(length((float2)(dx, dy)), @gaussian_sigma);
            
            if (qPos.x >= 0 && qPos.x < size.x && qPos.y >= 0 && qPos.y < size.y) {
                magnitudeQ += @src.bufferIndex(qPos) * weight;
                sumQ += weight;
            }
            if (rPos.x >= 0 && rPos.x < size.x && rPos.y >= 0 && rPos.y < size.y) {
                magnitudeR += @src.bufferIndex(rPos) * weight;
                sumR += weight;
            }
        }
    }
    magnitudeQ /= sumQ;
    magnitudeR /= sumR;

    if (gradientMagnitude < magnitudeQ || gradientMagnitude < magnitudeR) {
        gradientMagnitude = 0.0f;
    }

    // edge
    float result;
    if (gradientMagnitude > @high_threshold) {
        result = 1.0f;
    } else if (gradientMagnitude > @low_threshold) {
        result = 0.5f;
    } else {
        result = 0.0f;
    }

    @dst.setIndex(pos, result);
}
