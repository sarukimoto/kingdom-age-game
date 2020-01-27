// https://github.com/libretro/glsl-shaders/blob/master/xsal/shaders/2xsal-level2-pass2.glsl

/*
    Default Uniforms:

    u_TransformMatrix
    u_ProjectionMatrix
    u_TextureMatrix
    u_Color
    u_Opacity
    u_Time
    u_Tex0
    u_Tex1
    u_Tex2
    u_Tex3
    u_Resolution
*/

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

float intensity = 1.5;
uniform vec2 u_Resolution;
#define InputSize u_Resolution * intensity // Width and height in pixels of game screen // textureSize(Source, 0)
#define SourceSize vec4(InputSize, 1.0 / InputSize) //either TextureSize or InputSize
// #define outsize vec4(OutputSize, 1.0 / OutputSize) // Not in use

void main()
{
    vec2 tex = v_TexCoord;
    //vec2 texsize = IN.texture_size;
    float dx = 0.25*SourceSize.z;
    float dy = 0.25*SourceSize.w;
    vec3  dt = vec3(1.0, 1.0, 1.0);

    vec4 yx = vec4(dx, dy, -dx, -dy);
    vec4 xh = yx*vec4(3.0, 1.0, 3.0, 1.0);
    vec4 yv = yx*vec4(1.0, 3.0, 1.0, 3.0);

    vec3 c11 = COMPAT_TEXTURE(Source, tex        ).xyz;
    vec3 s00 = COMPAT_TEXTURE(Source, tex + yx.zw).xyz;
    vec3 s20 = COMPAT_TEXTURE(Source, tex + yx.xw).xyz;
    vec3 s22 = COMPAT_TEXTURE(Source, tex + yx.xy).xyz;
    vec3 s02 = COMPAT_TEXTURE(Source, tex + yx.zy).xyz;
    vec3 h00 = COMPAT_TEXTURE(Source, tex + xh.zw).xyz;
    vec3 h20 = COMPAT_TEXTURE(Source, tex + xh.xw).xyz;
    vec3 h22 = COMPAT_TEXTURE(Source, tex + xh.xy).xyz;
    vec3 h02 = COMPAT_TEXTURE(Source, tex + xh.zy).xyz;
    vec3 v00 = COMPAT_TEXTURE(Source, tex + yv.zw).xyz;
    vec3 v20 = COMPAT_TEXTURE(Source, tex + yv.xw).xyz;
    vec3 v22 = COMPAT_TEXTURE(Source, tex + yv.xy).xyz;
    vec3 v02 = COMPAT_TEXTURE(Source, tex + yv.zy).xyz;

    float m1 = 1.0/(dot(abs(s00 - s22), dt) + 0.00001);
    float m2 = 1.0/(dot(abs(s02 - s20), dt) + 0.00001);
    float h1 = 1.0/(dot(abs(s00 - h22), dt) + 0.00001);
    float h2 = 1.0/(dot(abs(s02 - h20), dt) + 0.00001);
    float h3 = 1.0/(dot(abs(h00 - s22), dt) + 0.00001);
    float h4 = 1.0/(dot(abs(h02 - s20), dt) + 0.00001);
    float v1 = 1.0/(dot(abs(s00 - v22), dt) + 0.00001);
    float v2 = 1.0/(dot(abs(s02 - v20), dt) + 0.00001);
    float v3 = 1.0/(dot(abs(v00 - s22), dt) + 0.00001);
    float v4 = 1.0/(dot(abs(v02 - s20), dt) + 0.00001);

    vec3 t1 = 0.5*(m1*(s00 + s22) + m2*(s02 + s20))/(m1 + m2);
    vec3 t2 = 0.5*(h1*(s00 + h22) + h2*(s02 + h20) + h3*(h00 + s22) + h4*(h02 + s20))/(h1 + h2 + h3 + h4);
    vec3 t3 = 0.5*(v1*(s00 + v22) + v2*(s02 + v20) + v3*(v00 + s22) + v4*(v02 + s20))/(v1 + v2 + v3 + v4);

    float k1 = 1.0/(dot(abs(t1 - c11), dt) + 0.00001);
    float k2 = 1.0/(dot(abs(t2 - c11), dt) + 0.00001);
    float k3 = 1.0/(dot(abs(t3 - c11), dt) + 0.00001);

    FragColor = vec4((k1*t1 + k2*t2 + k3*t3)/(k1 + k2 + k3), 1.0);
}
