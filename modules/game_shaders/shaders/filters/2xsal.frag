// https://github.com/libretro/glsl-shaders/blob/master/xsal/shaders/2xsal.glsl

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
// in variables go here as COMPAT_VARYING whatever

// fragment compatibility #defines
#define Source Texture
//#define vTexCoord TEX0.xy

COMPAT_VARYING vec2 v_TexCoord;

float intensity = 1.0;
uniform vec2 u_Resolution;
#define InputSize u_Resolution * intensity // Width and height in pixels of game screen
#define SourceSize vec4(InputSize, 1.0 / InputSize) //either TextureSize or InputSize
// #define outsize vec4(OutputSize, 1.0 / OutputSize) // Not in use

void main()
{
    vec2 texsize = SourceSize.xy;
    float dx     = pow(texsize.x, -1.0) * 0.25;
    float dy     = pow(texsize.y, -1.0) * 0.25;
    vec3  dt     = vec3(1.0, 1.0, 1.0);


    vec2 UL =    v_TexCoord + vec2(-dx, -dy);
    vec2 UR =    v_TexCoord + vec2( dx, -dy);
    vec2 DL =    v_TexCoord + vec2(-dx,  dy);
    vec2 DR =    v_TexCoord + vec2( dx,  dy);


    vec3 c00 = COMPAT_TEXTURE(Source, UL).xyz;
    vec3 c20 = COMPAT_TEXTURE(Source, UR).xyz;
    vec3 c02 = COMPAT_TEXTURE(Source, DL).xyz;
    vec3 c22 = COMPAT_TEXTURE(Source, DR).xyz;

    float m1 = dot(abs(c00 - c22), dt) + 0.001;
    float m2 = dot(abs(c02 - c20), dt) + 0.001;

    FragColor = vec4((m1*(c02 + c20) + m2*(c22 + c00))/(2.0*(m1 + m2)), 1.0);
}
