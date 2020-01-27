// https://github.com/libretro/glsl-shaders/blob/master/pal/shaders/pal-singlepass.glsl

#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D

#ifdef GL_ES
    #ifdef GL_FRAGMENT_PRECISION_HIGH
    precision highp float;
    #else
    precision mediump float;
    #endif
    #define COMPAT_PRECISION mediump
#else
    #define COMPAT_PRECISION
#endif

// uniform COMPAT_PRECISION int FrameDirection; // Not in use
uniform COMPAT_PRECISION int FrameCount;
// uniform COMPAT_PRECISION vec2 OutputSize; // Not in use
// uniform COMPAT_PRECISION vec2 TextureSize;
// uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
//COMPAT_VARYING vec4 TEX0;

// fragment compatibility #defines
#define Source Texture
//#define vTexCoord TEX0.xy

COMPAT_VARYING vec2 v_TexCoord;

uniform vec2 u_Resolution;
#define InputSize u_Resolution // Width and height in pixels of game screen
#define SourceSize vec4(InputSize, 1.0 / InputSize) //either TextureSize or InputSize
// #define outsize vec4(OutputSize, 1.0 / OutputSize) // Not in use

#define FIR_GAIN 1.5
#define FIR_INVGAIN 1.1
#define PHASE_NOISE 1.0

/* Subcarrier frequency */
#define FSC          4433618.75

/* Line frequency */
#define FLINE        15625.

#define VISIBLELINES 312.

#define PI           3.14159265358

#define RGB_to_YIQ  mat3( 0.299, 0.595716,  0.211456, 0.587, -0.274453, -0.522591, 0.114, -0.321263, 0.311135 )
#define YIQ_to_RGB  mat3( 1.0, 1.0, 1.0, 0.9563, -0.2721, -1.1070, 0.6210, -0.6474, 1.7046 )
#define RGB_to_YUV  mat3( 0.299, -0.14713, 0.615, 0.587, -0.28886, -0.514991, 0.114, 0.436, -0.10001 )
#define YUV_to_RGB  mat3( 1.0, 1.0, 1.0, 0.0, -0.39465, 2.03211, 1.13983, -0.58060, 0.0 )

#define fetch(ofs,center,invx) COMPAT_TEXTURE(Source, vec2((ofs) * (invx) + center.x, center.y))

#define FIRTAPS 20.
float FIR1 = -0.008030271;
float FIR2 = 0.003107906;
float FIR3 = 0.016841352;
float FIR4 = 0.032545161;
float FIR5 = 0.049360136;
float FIR6 = 0.066256720;
float FIR7 = 0.082120150;
float FIR8 = 0.095848433;
float FIR9 = 0.106453014;
float FIR10 = 0.113151423;
float FIR11 = 0.115441842;
float FIR12 = 0.113151423;
float FIR13 = 0.106453014;
float FIR14 = 0.095848433;
float FIR15 = 0.082120150;
float FIR16 = 0.066256720;
float FIR17 = 0.049360136;
float FIR18 = 0.032545161;
float FIR19 = 0.016841352;
float FIR20 = 0.003107906;

/* subcarrier counts per scan line = FSC/FLINE = 283.7516 */
/* We save the reciprocal of this only to optimize it */
float counts_per_scanline_reciprocal = 1.0 / (FSC/FLINE);

float width_ratio;
float height_ratio;
float altv;
float invx;

/* http://byteblacksmith.com/improvements-to-the-canonical-one-liner-glsl-rand-for-opengl-es-2-0/ */
float rand(vec2 co)
{
    float a  = 12.9898;
    float b  = 78.233;
    float c  = 43758.5453;
    float dt = dot(co.xy, vec2(a, b));
    float sn = mod(dt,3.14);

    return fract(sin(sn) * c);
}

float modulated(vec2 xy, float sinwt, float coswt)
{
    vec3 rgb = fetch(0., xy, invx).xyz;
    vec3 yuv = RGB_to_YUV * rgb;

    return clamp(yuv.x + yuv.y * sinwt + yuv.z * coswt, 0.0, 1.0);
}

vec2 modem_uv(vec2 xy, float ofs) {
    float t  = (xy.x + ofs * invx) * SourceSize.x;
    float wt = t * 2. * PI / width_ratio;

    float sinwt = sin(wt);
    float coswt = cos(wt + altv);

    vec3 rgb = fetch(ofs, xy, invx).xyz;
    vec3 yuv = RGB_to_YUV * rgb;
    float signal = clamp(yuv.x + yuv.y * sinwt + yuv.z * coswt, 0.0, 1.0);

    if (PHASE_NOISE != 0.)
    {
        /* .yy is horizontal noise, .xx looks bad, .xy is classic noise */
        vec2 seed = xy.yy * float(FrameCount);
        wt        = wt + PHASE_NOISE * (rand(seed) - 0.5);
        sinwt     = sin(wt);
        coswt     = cos(wt + altv);
    }

    return vec2(signal * sinwt, signal * coswt);
}

void main()
{
    vec2 xy      = v_TexCoord;
    width_ratio  = SourceSize.x * (counts_per_scanline_reciprocal);
    height_ratio = SourceSize.y / VISIBLELINES;
    altv         = mod(floor(xy.y * VISIBLELINES + 0.5), 2.0) * PI;
    invx         = 0.25 * (counts_per_scanline_reciprocal); // equals 4 samples per Fsc period

    // lowpass U/V at baseband
    vec2 filtered = vec2(0.0, 0.0);

    vec2 uv;
    // #define macro_loopz(c)  uv = modem_uv(xy, float(c) - FIRTAPS*0.5); filtered += FIR_GAIN * uv * FIR##c;

    uv = modem_uv(xy, 1. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR1;

    uv = modem_uv(xy, 2. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR2;

    uv = modem_uv(xy, 3. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR3;

    uv = modem_uv(xy, 4. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR4;

    uv = modem_uv(xy, 5. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR5;

    uv = modem_uv(xy, 6. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR6;

    uv = modem_uv(xy, 7. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR7;

    uv = modem_uv(xy, 8. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR8;

    uv = modem_uv(xy, 9. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR9;

    uv = modem_uv(xy, 10. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR10;

    uv = modem_uv(xy, 11. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR11;

    uv = modem_uv(xy, 12. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR12;

    uv = modem_uv(xy, 13. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR13;

    uv = modem_uv(xy, 14. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR14;

    uv = modem_uv(xy, 15. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR15;

    uv = modem_uv(xy, 16. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR16;

    uv = modem_uv(xy, 17. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR17;

    uv = modem_uv(xy, 18. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR18;

    uv = modem_uv(xy, 19. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR19;

    uv = modem_uv(xy, 20. - FIRTAPS*0.5);
    filtered += FIR_GAIN * uv * FIR20;

    // macro_loopz(1)
    // macro_loopz(2)
    // macro_loopz(3)
    // macro_loopz(4)
    // macro_loopz(5)
    // macro_loopz(6)
    // macro_loopz(7)
    // macro_loopz(8)
    // macro_loopz(9)
    // macro_loopz(10)
    // macro_loopz(11)
    // macro_loopz(12)
    // macro_loopz(13)
    // macro_loopz(14)
    // macro_loopz(15)
    // macro_loopz(16)
    // macro_loopz(17)
    // macro_loopz(18)
    // macro_loopz(19)
    // macro_loopz(20)

    float t  = xy.x * SourceSize.x;
    float wt = t * 2. * PI / width_ratio;

    float sinwt = sin(wt);
    float coswt = cos(wt + altv);

    float luma = modulated(xy, sinwt, coswt) - FIR_INVGAIN * (filtered.x * sinwt + filtered.y * coswt);
    vec3 yuv_result = vec3(luma, filtered.x, filtered.y);

    FragColor = vec4(YUV_to_RGB * yuv_result, 1.0);
}
