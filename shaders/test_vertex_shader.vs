#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;
layout (location = 2) in vec2 aTextCoord;
layout (location = 3) in vec2 aInnerTextCoord;

out vec3 ourColor;
out vec2 TextCoord;
out vec2 InnerTextCoord;

uniform mat4 transform;

void main()
{
    gl_Position = transform * vec4(aPos, 1.0);
    ourColor = aColor;
    TextCoord = aTextCoord;
    InnerTextCoord = aInnerTextCoord;
}