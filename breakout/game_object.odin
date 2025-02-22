package main

GameObject :: struct {
	position:  [2]f32,
	size:      [2]f32,
	velocity:  [2]f32,
	color:     [3]f32,
	rotation:  f32,
	is_solid:  b32,
	destroyed: b32,
	sprite:    Texture2D,
}

init_game_object_blank :: proc() -> GameObject {
	return {
		position = {0.0, 0.0},
		size = {1.0, 1.0},
		velocity = {0.0, 0.0},
		color = {1.0, 1.0, 1.0},
		rotation = 0.0,
		is_solid = false,
		destroyed = false,
	}
}

init_game_object_args :: proc(
	Position: [2]f32,
	Size: [2]f32,
	Sprite: Texture2D,
	Color: [3]f32,
	Velocity: [2]f32,
) -> GameObject {
	return {
		position = Position,
		size = Size,
		velocity = Velocity,
		color = Color,
		sprite = Sprite,
		rotation = 0.0,
		is_solid = false,
		destroyed = false,
	}
}

init_game_object :: proc {
	init_game_object_args,
	init_game_object_blank,
}

draw_game_object :: proc(renderer: ^SpriteRenderer, game_object: ^GameObject) {
	draw_sprite(
		renderer,
		&game_object.sprite,
		game_object.position,
		game_object.size,
		game_object.rotation,
		game_object.color,
	)
}
