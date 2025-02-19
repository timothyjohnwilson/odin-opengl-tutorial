package main
import "core:fmt"
import linalg "core:math/linalg"

Game :: struct {
	state:  GameState,
	keys:   [1024]b32,
	width:  u32,
	height: u32,
}

GameState :: enum {
	GAME_ACTIVE,
	GAME_MENU,
	GAME_WIN,
}

sprite_renderer: SpriteRenderer
init :: proc(game: Game) {
	vertex_shader := "shaders/sprite.vs"
	fragment_shader := "shaders/sprite.frag"
	load_shader(&vertex_shader, &fragment_shader, "sprite")

	sprite_renderer.shader = get_shader("sprite")
	use_shader(sprite_renderer.shader)
	set_shader_int(sprite_renderer.shader, "image", 0)

	projection := linalg.matrix_ortho3d_f32(
		0.0,
		f32(game.width),
		f32(game.height),
		0.0,
		-1.0,
		1.0,
		false,
	)
	set_shader_matrix4(sprite_renderer.shader, "projection", &projection)

	new_texture := load_texture("textures/awesomeface.png", true, "face")
	init_render_data(&sprite_renderer)
}

process_input :: proc(dt: f32) {

}

update :: proc(dt: f32) {

}

render :: proc() {
	face_texture := get_texture("face")

	draw_sprite(
		&sprite_renderer,
		&face_texture,
		{200.0, 200.0},
		{300.0, 400.0},
		45.0,
		{0.0, 1.0, 0.0},
	)
}
