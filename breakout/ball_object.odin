package main
BallObject :: struct {
	using game_object: GameObject,
	radius:            f32,
	stuck:             b32,
}

init_ball_object_blank :: proc() -> BallObject {
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

init_ball_object_args :: proc(
	Position: [2]f32,
	Radius: f32,
	Velocity: [2]f32,
	Sprite: Texture2D,
) -> BallObject {
	return {
		position = Position,
		velocity = Velocity,
		sprite = Sprite,
		radius = Radius,
		color = {1.0, 1.0, 1.0},
		size = {Radius * 2.0, Radius * 2},
		stuck = true,
		rotation = 0.0,
		is_solid = false,
		destroyed = false,
	}
}

init_ball_object :: proc {
	init_ball_object_args,
	init_ball_object_blank,
}

move_ball_object :: proc(
	ball_object: ^BallObject,
	player: ^GameObject,
	dt: f32,
	window_width: u32,
) -> [2]f32 {
	if !ball_object.stuck {
		// move the ball
		ball_object.position += ball_object.velocity * dt
		// check if outside window bounds; if so, reverse velocity and restore at correct position
		if (ball_object.position.x <= 0.0) {
			ball_object.velocity.x = -ball_object.velocity.x
			ball_object.position.x = 0.0
		} else if (ball_object.position.x + ball_object.size.x >= f32(window_width)) {
			ball_object.velocity.x = -ball_object.velocity.x
			ball_object.position.x = f32(window_width) - ball_object.size.x
		}
		if (ball_object.position.y <= 0.0) {
			ball_object.velocity.y = -ball_object.velocity.y
			ball_object.position.y = 0.0
		}

	}
	return ball_object.position
}

reset_ball_object :: proc(ball_object: ^BallObject, position: [2]f32, velocity: [2]f32) {
	ball_object.position = position
	ball_object.velocity = velocity
	ball_object.stuck = true
}
