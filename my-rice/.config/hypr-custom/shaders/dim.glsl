#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float brightness = 0.30; // 20%

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    pixColor.rgb *= brightness;
    fragColor = pixColor;
}
