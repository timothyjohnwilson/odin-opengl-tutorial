package main
import "core:fmt"
import linalg "core:math/linalg"

Game :: struct {
	state:  GameState,
	keys:   [1024]b32,
	width:  u32,
	height: u32,
	levels: [dynamic]GameLevel,
	level: i32
}

GameState :: enum {
	GAME_ACTIVE,
	GAME_MENU,
	GAME_WIN,
}

sprite_renderer: SpriteRenderer
init :: proc(game: ^Game) {
	loaded_shader := load_shader("shaders/sprite.vs", "shaders/sprite.frag", "sprite")

	projection := linalg.matrix_ortho3d_f32(
		0.0,
		f32(game.width),
		f32(game.height),
		0.0,
		-1.0,
		1.0,
		false,
	)

	sprite_renderer.shader = get_shader("sprite")
	use_shader(sprite_renderer.shader)
	set_shader_int(sprite_renderer.shader, "image", 0)
	set_shader_matrix4(sprite_renderer.shader, "projection", &projection)
	init_render_data(&sprite_renderer)

	load_texture("textures/background.jpg", false, "background")
	load_texture("textures/awesomeface.png", true, "face")
	load_texture("textures/block.png", false, "block")
	load_texture("textures/block_solid.png", false, "block_solid")

	level_1: GameLevel
	load_game_level(&level_1, "files/1_level.txt", game.width, game.height / 2)
	level_2: GameLevel
	load_game_level(&level_2, "files/2_level.txt", game.width, game.height / 2)
	level_3: GameLevel
	load_game_level(&level_3, "files/3_level.txt", game.width, game.height / 2)
	level_4: GameLevel
	load_game_level(&level_4, "files/4_level.txt", game.width, game.height / 2)

	append(&game.levels, level_1, level_2, level_3, level_4)
	game.level = 0
}

process_input :: proc(dt: f32) {

}

update :: proc(dt: f32) {

}

render :: proc(game: ^Game) {
	if(game.state == GameState.GAME_ACTIVE)
    {
		background := get_texture("background")
		draw_sprite(&sprite_renderer, &background,{0.0, 0.0}, {f32(game.width), f32(game.height)}, 0.0, {1.0, 1.0, 1.0})
		draw_game_level(&game.levels[game.level], &sprite_renderer)
    }
}
