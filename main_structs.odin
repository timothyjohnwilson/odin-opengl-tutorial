package main

GameState :: struct {
	opacity:         f32,
	up_is_pressed:   b32,
	down_is_pressed: b32,
	camera_speed:    f32,
	camera_delta:    f32,
	camera_pos:      [3]f32,
	camera_front:    [3]f32,
	camera_up:       [3]f32,
	direction:       [3]f32,
	mouse_xpos:      f32,
	mouse_ypos:      f32,
	mouse_yaw:       f32,
	mouse_pitch:     f32,
	sensitivity:     f32,
}
