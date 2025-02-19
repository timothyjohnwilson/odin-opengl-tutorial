package main

import "core:fmt"
import linalg "core:math/linalg"
import gl "vendor:OpenGL"

SpriteRenderer :: struct {
	shader:   Shader,
	quad_vao: u32,
}


init_render_data :: proc(sprite_renderer: ^SpriteRenderer) {
	// configure VAO/VBO
	VBO: u32
	vertices := [?]f32 {
		0.0,
		1.0,
		0.0,
		1.0,
		1.0,
		0.0,
		1.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		0.0,
		1.0,
		0.0,
		1.0,
		1.0,
		1.0,
		1.0,
		1.0,
		1.0,
		0.0,
		1.0,
		0.0,
	}

	gl.GenVertexArrays(1, &sprite_renderer.quad_vao)
	gl.GenBuffers(1, &VBO)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	gl.BindVertexArray(sprite_renderer.quad_vao)
	gl.EnableVertexAttribArray(0)

	gl.VertexAttribPointer(0, 4, gl.FLOAT, gl.FALSE, 4 * size_of(f32), cast(uintptr)0)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)
}

draw_sprite :: proc(
	sprite_renderer: ^SpriteRenderer,
	texture: ^Texture2D,
	position: [2]f32,
	size: [2]f32 = {10.0, 10.0},
	rotate: f32 = 0.0,
	color: [3]f32,
) {
	// prepare transformations
	model := linalg.matrix4_translate_f32({position.x, position.y, 0.0})
	model *= linalg.matrix4_translate_f32({0.5 * size.x, 0.5 * size.y, 0.0})
	model *= linalg.matrix4_rotate_f32(linalg.to_radians(rotate), {0.0, 0.0, 1.0})
	model *= linalg.matrix4_translate_f32({-0.5 * size.x, -0.5 * size.y, 0.0})
	model *= linalg.matrix4_scale_f32({size.x, size.y, 1.0})

	// model := linalg.MATRIX4F32_IDENTITY

	set_shader_matrix4(sprite_renderer.shader, "model", &model)
	the_color := color
	set_shader_vector3f(sprite_renderer.shader, "spriteColor", &the_color)

	gl.ActiveTexture(gl.TEXTURE0)
	bind_texture(texture)

	use_shader(sprite_renderer.shader)
	gl.BindVertexArray(sprite_renderer.quad_vao)
	gl.DrawArrays(gl.TRIANGLES, 0, 6)
}
