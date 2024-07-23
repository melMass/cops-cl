/*
@title: pixelize_v01
@author: melmass
*/

#bind layer !&outColor float4
#bind layer src float4

#bind parm PixelSize int val=10

// 0 average | 1 nearest neighbor
#bind parm Mode int val=0 


@KERNEL
{
    const int2 pos = (int2)(get_global_id(0), get_global_id(1));
    const int2 size = (int2)(@outColor.xres, @outColor.yres);

    if (pos.x >= size.x || pos.y >= size.y) return;

    int blockX = pos.x / @PixelSize;
    int blockY = pos.y / @PixelSize;

    int originX = blockX * @PixelSize;
    int originY = blockY * @PixelSize;


    float4 outputColor;

    // average
    if (@Mode == 0) {
        float4 accumulatedColor = (float4)(0.0f, 0.0f, 0.0f, 0.0f);
        int count = 0;
        for (int y = 0; y < @PixelSize; y++) {
            for (int x = 0; x < @PixelSize; x++) {
                int2 blockPos = (int2)(originX + x, originY + y);
                if (blockPos.x < size.x && blockPos.y < size.y) {
                    accumulatedColor += @src.bufferIndex(blockPos);
                    count++;
                }
            }
        }
        outputColor = accumulatedColor / (float)count;
        
    // nearest neighbor
    } else {
        int2 nearestPos = (int2)(originX, originY);
        if (nearestPos.x >= size.x || nearestPos.y >= size.y) return;
        outputColor = @src.bufferIndex(nearestPos);
    }

    @outColor.setIndex(pos, outputColor);
}
