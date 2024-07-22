/*
@title: voronoi_v01
@author: melmass
*/

#import "random.h"

#bind layer !&dst float
#bind parm num_points int

@KERNEL
{
    const int2 pos = (int2)(get_global_id(0), get_global_id(1));
    const int2 size = (int2)(@dst.xres, @dst.yres);

    if (pos.x >= size.x || pos.y >= size.y) return;

    float minDist = FLT_MAX;
    for (int i = 0; i < @num_points; i++) {
        float r1 = VEXrandom_1_1(i) * size.x;
        float r2 = VEXrandom_1_1(i + 1) * size.y;
        
        float2 point = (float2)((int)r1 % size.x, (int)r2 % size.y);
        float dist = distance((float2)(pos.x, pos.y), point);
        if (dist < minDist) {
            minDist = dist;
            
        }
      
    }

    @dst.setIndex(pos, minDist / size.x);
}
