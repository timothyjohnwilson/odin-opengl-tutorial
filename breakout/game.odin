package main
import "core:fmt"
import linalg "core:math/linalg"
import glfw "vendor:glfw"

Game :: struct {
	state:  GameState,
	keys:   [1024]b32,
	width:  u32,
	height: u32,
	levels: [dynamic]GameLevel,
	level:  i32,
}

GameState :: enum {
	GAME_ACTIVE,
	GAME_MENU,
	GAME_WIN,
}

player_size: [2]f32 = {100.0, 20.0}
player_velocity: f32 = 500.0

initial_ball_velocity: [2]f32 = {100.0, -350.0}
ball_radius: f32 = 12.5
ball: BallObject

player: GameObject

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
	load_texture("textures/paddle.png", true, "paddle")

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

	player_pos: [2]f32 = {
		f32((game.width / 2.0)) - f32((player_size.x / 2.0)),
		f32(game.height) - player_size.y,
	}

	player_texture := get_texture("paddle")
	player = init_game_object_args(
		player_pos,
		player_size,
		player_texture,
		{1.0, 1.0, 1.0},
		{0.0, 0.0},
	)

	ball_pos := player_pos + {player_size.x / 2.0 - ball_radius, -ball_radius * 2.0}

	ball_texture := get_texture("face")
	ball = init_ball_object(ball_pos, ball_radius, initial_ball_velocity, ball_texture)
}

process_input :: proc(game: ^Game, dt: f32) {
	if game.state == GameState.GAME_ACTIVE {
		velocity := player_velocity * dt
		if game.keys[glfw.KEY_A] {
			if player.position.x >= 0.0 {
				player.position.x -= velocity
				if (ball.stuck) {
					ball.position.x -= velocity
				}
			}
		}

		if game.keys[glfw.KEY_D] {
			if player.position.x <= f32(game.width) - player.size.x {
				player.position.x += velocity
				if (ball.stuck) {
					ball.position.x += velocity
				}
			}
		}

		if game.keys[glfw.KEY_SPACE] {
			ball.stuck = false
		}
	}
}

update :: proc(game: ^Game, dt: f32) {
	move_ball_object(&ball, &player, dt, game.width)
}

render :: proc(game: ^Game) {
	if (game.state == GameState.GAME_ACTIVE) {
		background := get_texture("background")
		draw_sprite(
			&sprite_renderer,
			&background,
			{0.0, 0.0},
			{f32(game.width), f32(game.height)},
			0.0,
			{1.0, 1.0, 1.0},
		)
		draw_game_level(&sprite_renderer, &game.levels[game.level])
		draw_game_object(&sprite_renderer, &player)
		draw_game_object(&sprite_renderer, &ball)
	}
}


// AABB - AABB collision
check_collision :: proc(one: GameObject, two: GameObject) -> b32 {
	// collision x-axis?
	collision_x :=
		one.position.x + one.size.x >= two.position.x &&
		two.position.x + two.size.x >= one.position.x

	// collision y-axis?
	collision_y :=
		one.position.y + one.size.y >= two.position.y &&
		two.position.y + two.size.y >= one.position.y
	// collision only if on both axes
	return collision_x && collision_y
}
