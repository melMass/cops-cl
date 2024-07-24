/*
@title: weave_v02
@author: melmass
@description: adaptation of the OSL Weave shader by Zap Andersson
*/


// osl shader:
// https://github.com/ADN-DevTech/3dsMax-OSL-Shaders/blob/master/3ds%20Max%20Shipping%20Shaders/Weave.osl

#import "mtlx_noise_internal.h"
#import "random.h"

#bind layer !&outColor float4
#bind layer !&outBump float val=0.5
#bind layer !&outId float3
#bind layer !&outOpacity float

#bind parm scale float val=0.04
#bind parm width float val=0.5
#bind parm roundness float val=1.0
#bind parm roundnessBump float val=1.0
#bind parm roundShadow float val=0.5
#bind parm weaveBump float val=0.5
#bind parm weaveShadow float val=0.25
#bind parm frizz float val=0.0
#bind parm frizzBump float val=0.0
#bind parm frizzScale float val=0.1
#bind parm bendyness float val=0.2
#bind parm bendynessScale float val=3.0
#bind parm braidAmplitude float val=0.0
#bind parm braidFrequency float val=0.5
#bind parm opacityFade float val=0.0
#bind parm seed int val=1
#bind parm u_color float4 val={0.0, 0.5, 0.5, 1.0}
#bind parm v_color float4 val={0.0, 0.25, 0.5, 1.0}

@KERNEL
{
    const int2 pos = (int2)(get_global_id(0), get_global_id(1));
    const int2 size = (int2)(@outColor.xres, @outColor.yres);

    if (pos.x >= size.x || pos.y >= size.y) return;
    
    @scale = fit01(@scale,0.0f,0.1f);
    @frizzScale = max(0.0001f,@frizzScale);
    @bendynessScale = max(0.0001f,@bendynessScale);

    float2 uvw = (float2)(pos.x, pos.y) * @scale;
    
    // add frizz to the width
    float frizz = mx_perlin_noise_float_2(uvw / @frizzScale, (int2)(1, 1));
    float w2 = @width + frizz * @frizz;
    float w = w2 * 0.5f;
    
    int uf = (int)floor(uvw.x);
    int vf = (int)floor(uvw.y);
    
    // compute bending
    float braidOffset = @braidAmplitude * sin(uvw.y * @braidFrequency * M_PI * 2.0f);
    float ubend = mx_perlin_noise_float_2(uvw.y / @bendynessScale + 13.0f * uf, (int2)(1, 1)) * @bendyness + braidOffset;
    float vbend = mx_perlin_noise_float_2(uvw.x / @bendynessScale + 23.0f * vf, (int2)(1, 1)) * @bendyness;
    
    // compute thread coordinates
    float sx = uvw.x - uf + ubend;
    float sy = uvw.y - vf + vbend;
    
    int onU = (sy > 0.5f - w && sy < 0.5f + w);
    int onV = (sx > 0.5f - w && sx < 0.5f + w);
    
    float uu = (sy - (0.5f - w)) / w2;
    float vv = (sx - (0.5f - w)) / w2;
    
    // odd or even U / V
    int oddU = uf % 2;
    int oddV = vf % 2;

    // Are we on neither thread?
    if (onU == 0 && onV == 0)
    {
        // set background color to black/transparent per layer
        @outColor.setIndex(pos, (float4)(0.0f, 0.0f, 0.0f, 0.0f));
        @outBump.setIndex(pos, 0.0f);
        @outId.setIndex(pos, (float3)(0.0f, 0.0f, 0.0f));
        @outOpacity.setIndex(pos, 0.0f);
        return;
    }
    
    int U_on_top = (oddU ^ oddV) == 0;
    
    int per = 1;
    
    // both - disambiguate
    if (onU && onV)
    {
        onU = U_on_top;
        onV = (onU == 0);
    }
    
    // random ID for thread
    int ThreadID = 1 + (int)((mx_cell_noise_float_1((float)uf + @seed + 45, per) * onV + mx_cell_noise_float_1((float)vf + @seed + 32, per) * onU) * 1024.0f) + onU;
    float3 IdColor = VEXrandom_1_3((float)ThreadID + @seed);

    // which color to return
    float4 Col;
    if (onU)
        Col = @u_color;
    else
        Col = @v_color;
    
    // compute bump and fake "shadowing"
    float r = @roundness;
    float weave = (onU) ? sin((uvw.x + oddV) * M_PI) : sin((uvw.y + oddU + 1.0f) * M_PI);
    
    float ubulge = sin(uu * M_PI);
    float vbulge = sin(vv * M_PI);
    
    float bulge = pow((onU ? ubulge : vbulge), r);
    
    float opacity = max(pow(ubulge, @opacityFade), pow(vbulge, @opacityFade));
    
    float bump = 0.2f + weave * @weaveBump + bulge * @roundnessBump + frizz * @frizzBump;
    
    Col *= mix(1.0f, bulge, @roundShadow);
    Col *= mix(1.0f, weave, @weaveShadow);
    
    @outColor.setIndex(pos, Col);
    @outBump.setIndex(pos, bump);
    @outId.setIndex(pos, IdColor);
    @outOpacity.setIndex(pos, opacity);
}

