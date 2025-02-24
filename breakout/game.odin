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

Direction :: enum {
	UP,
	LEFT,
	DOWN,
	RIGHT,
}

Collision :: struct {
	hit:        b32,
	direction:  Direction,
	difference: [2]f32,
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
	do_collisions(game, &ball)

	if ball.position.y >= f32(game.height) {
		reset_level(game)
		reset_player(game, &ball)
	}
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

vector_direction :: proc(target: [2]f32) -> Direction {
	compass: [4][2]f32 = {{0.0, 1.0}, {1.0, 0.0}, {0.0, -1.0}, {-1.0, 0.0}}
	max: f32 = 0.0
	best_match := -1

	for i := 0; i < len(compass); i += 1 {
		dot_product := f32(linalg.dot(linalg.normalize(target), compass[i]))

		if dot_product > max {
			max = dot_product
			best_match = i
		}
	}

	return Direction(best_match)
}


check_collision :: proc(one: ^BallObject, two: ^GameObject) -> Collision {
	center := one.position + one.radius
	aabb_half_extents: [2]f32 = {two.size.x / 2.0, two.size.y / 2.0}
	aabb_center: [2]f32 = {
		two.position.x + aabb_half_extents.x,
		two.position.y + aabb_half_extents.y,
	}
	difference: [2]f32 = center - aabb_center
	clamped: [2]f32 = linalg.clamp(difference, -aabb_half_extents, aabb_half_extents)
	closest: [2]f32 = aabb_center + clamped
	difference = closest - center

	collision: Collision

	collision.hit = linalg.length(difference) <= one.radius
	if (collision.hit) {
		collision.direction = vector_direction(difference)
		collision.difference = difference
	} else {
		collision.direction = Direction.UP
		collision.difference = {0.0, 0.0}
	}

	return collision
}

do_collisions :: proc(game: ^Game, ball_object: ^BallObject) {
	for &brick in game.levels[game.level].bricks {
		if !brick.destroyed {

			collision := check_collision(ball_object, &brick)
			if collision.hit {
				if !brick.is_solid {
					brick.destroyed = true
				}

				if collision.direction == Direction.LEFT ||
				   collision.direction == Direction.RIGHT {
					ball.velocity.x = -ball.velocity.x
					penetration := ball.radius - linalg.abs(collision.difference.x)

					if collision.direction == Direction.LEFT {
						ball.position.x += penetration
					} else {
						ball.position.x -= penetration
					}
				} else {
					ball.velocity.y = -ball.velocity.y
					penetration := ball.radius - linalg.abs(collision.difference.y)
					if collision.direction == Direction.UP {
						ball.position.y -= penetration
					} else {
						ball.position.y += penetration
					}
				}

			}
		}
	}

	player_collision := check_collision(ball_object, &player)
	if (!ball_object.stuck && player_collision.hit) {
		// check where it hit the board, and change velocity based on where it hit the board
		center_board := player.position.x + player.size.x / 2.0
		distance := ball_object.position.x + ball_object.radius - center_board
		percentage := distance / (player.size.x / 2.0)

		// then move accordingly
		strength: f32 = 2.0
		old_velocity := ball_object.velocity

		ball_object.velocity.x = initial_ball_velocity.x * percentage * strength
		ball_object.velocity.y = -ball_object.velocity.y
		ball_object.velocity = linalg.normalize(ball_object.velocity) * linalg.length(old_velocity)
		
		// Sticky Paddle Bug
		ball.velocity.y = -1.0 * abs(ball.velocity.y)
	}
}

reset_level :: proc(game: ^Game) {
	if game.level == 0 {
		load_game_level(&game.levels[0], "files/1_level.txt", game.width, game.height / 2)
	} else if game.level == 1 {
		load_game_level(&game.levels[1], "files/2_level.txt", game.width, game.height / 2)
	} else if game.level == 2 {
		load_game_level(&game.levels[2], "files/3_level.txt", game.width, game.height / 2)
	} else if game.level == 3 {
		load_game_level(&game.levels[3], "files/4_level.txt", game.width, game.height / 2)
	}
}

reset_player :: proc(game: ^Game, ball_object: ^BallObject) {
	player.size = player_size
	player.position = {f32(game.width) / 2.0 - player_size.x / 2.0, f32(game.height) - player_size.y}
	reset_ball_object(
		ball_object,
		player.position + {player_size.x / 2.0 - ball_object.radius, -(ball_object.radius * 2.0)},
		initial_ball_velocity,
	)
}
