uniform float u_Time;
uniform sampler2D u_Tex0;
varying vec2 v_TexCoord;

vec4 grayscale(vec4 color)
{
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    return vec4(gray, gray, gray, 1);
}

void main()
{
    vec4 color = grayscale(texture2D(u_Tex0, v_TexCoord));
    color = 1.0 - color; // negative
    gl_FragColor = color;
}
