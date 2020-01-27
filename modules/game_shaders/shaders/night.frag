// https://github.com/libretro/glsl-shaders/blob/master/linear/linearize.glsl

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
// uniform COMPAT_PRECISION int FrameCount; // Not in use
// uniform COMPAT_PRECISION vec2 OutputSize; // Not in use
// uniform COMPAT_PRECISION vec2 TextureSize;
// uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
//COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
//#define vTexCoord TEX0.xy

COMPAT_VARYING vec2 v_TexCoord;

uniform vec2 u_Resolution;
#define InputSize u_Resolution // Width and height in pixels of game screen
#define SourceSize vec4(InputSize, 1.0 / InputSize) //either TextureSize or InputSize
// #define outsize vec4(OutputSize, 1.0 / OutputSize) // Not in use

vec3 gamma(vec3 v)
{
   return v * v;
}

void main()
{
   FragColor = vec4(gamma(COMPAT_TEXTURE(Source, v_TexCoord).rgb), 1.0);
}
