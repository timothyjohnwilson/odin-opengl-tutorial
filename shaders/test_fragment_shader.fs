#version 330 core
out vec4 FragColor;

in vec3 ourColor;
in vec2 TextCoord;
in vec2 InnerTextCoord;

uniform sampler2D texture1;
uniform sampler2D texture2;
uniform float opacity;


void main()
{
    FragColor = mix(texture(texture1, TextCoord), texture(texture2, InnerTextCoord), opacity);
}