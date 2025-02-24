package main
import "core:fmt"

GameLevel :: struct {
	bricks: [dynamic]GameObject,
}

init_game_level :: proc(
	game_level: ^GameLevel,
	tile_data: [dynamic][dynamic]u32,
	level_width: u32,
	level_height: u32,
) {
	height := len(tile_data)
	width := len(tile_data[0])
	unit_width := f32(level_width) / f32(width)
	unit_height := f32(level_height) / f32(height)

	y_index := 0
	x_index := 0
	for y in tile_data {
		for x in y {
			brick := x
			if brick == 1 {
				pos: [2]f32 = {unit_width * f32(x_index), unit_height * f32(y_index)}
				size: [2]f32 = {unit_width, unit_height}
				color: [3]f32 = {0.8, 0.8, 0.7}
				velocity: [2]f32 = {0.0, 0.0}
				sprite := get_texture("block_solid")
				game_object := init_game_object(pos, size, sprite, color, velocity)
				game_object.is_solid = true
				append(&game_level.bricks, game_object)
			} else if brick > 1 {
				color: [3]f32 = {1.0, 1.0, 1.0}
				if brick == 2 {
					color = {0.2, 0.6, 1.0}
				} else if brick == 3 {
					color = {0.0, 0.7, 0.0}
				} else if brick == 4 {
					color = {0.8, 0.8, 0.4}
				} else if brick == 5 {
					color = {1.0, 0.5, 0.0}
				}

				pos: [2]f32 = {unit_width * f32(x_index), unit_height * f32(y_index)}
				size: [2]f32 = {unit_width, unit_height}
				sprite := get_texture("block")
				velocity: [2]f32 = {0.0, 0.0}
				game_object := init_game_object(pos, size, sprite, color, velocity)
				append(&game_level.bricks, game_object)
			}
			x_index += 1
		}
		x_index = 0
		y_index += 1
	}
}

load_game_level :: proc(
	game_level: ^GameLevel,
	path: string,
	level_width: u32,
	level_height: u32,
) {
	clear_dynamic_array(&game_level.bricks)
	tile_data, err := load_level_from_file(path)
	if len(tile_data) > 0 {
		init_game_level(game_level, tile_data, level_width, level_height)
	}
}

is_completed :: proc(game_level: ^GameLevel) -> b32 {
	for brick in game_level.bricks {
		if !brick.is_solid && !brick.destroyed {
			return false
		}
	}

	return true
}

draw_game_level :: proc(sprite_renderer: ^SpriteRenderer, game_level: ^GameLevel) {

	for brick in game_level.bricks {
		if !brick.destroyed {
			sprite := brick.sprite
			draw_sprite(
				sprite_renderer,
				&sprite,
				brick.position,
				brick.size,
				brick.rotation,
				brick.color,
			)
		}
	}
}
