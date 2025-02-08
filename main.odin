package main

import "core:fmt"
import "core:math"
import linalg "core:math/linalg"
import "core:os"
import "core:strings"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"
import stbi "vendor:stb/image"


//Const set up
WINDOW_WIDTH :: 854
WINDOW_HEIGHT :: 480

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 1


Shader :: struct {
	id:              u32,
	vertex_source:   cstring,
	fragment_source: cstring,
}
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

game_state: GameState = {
	opacity      = 0.2,
	camera_pos   = {0.0, 0.0, 3.0},
	camera_front = {0.0, 0.0, -1.0},
	camera_up    = {0.0, 1.0, 0.0},
	camera_speed = 1,
	mouse_xpos   = f32(WINDOW_WIDTH / 2),
	mouse_ypos   = f32(WINDOW_HEIGHT / 2),
	mouse_yaw    = -90.0,
	mouse_pitch  = 0.0,
	sensitivity  = 0.2,
}

first_mouse: b32 = true


main :: proc() {
	//initialise glfw
	glfw.Init()
	defer glfw.Terminate()
	glfw.WindowHint(glfw.RESIZABLE, glfw.TRUE)
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, glfw.TRUE)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MAJOR)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MINOR)
	window_handle: glfw.WindowHandle = glfw.CreateWindow(
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		"Hello Window",
		nil,
		nil,
	)
	if (window_handle == nil) {
		fmt.eprint("Failed to create glfw window! \n")
		return
	}

	glfw.SetInputMode(window_handle, glfw.CURSOR, glfw.CURSOR_DISABLED)
	glfw.MakeContextCurrent(window_handle)
	glfw.SwapInterval(0)
	glfw.SetFramebufferSizeCallback(window_handle, frame_buffer_size_callback)

	//OpenGL set up
	gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, proc(p: rawptr, name: cstring) {
		(^rawptr)(p)^ = glfw.GetProcAddress(name)
	})

	//Shader set up
	our_shader, error := load_and_compile_shader(
		"shaders/test_vertex_shader.vs",
		"shaders/test_fragment_shader.fs",
	)
	if error != 0 {
		fmt.println("Error loading shader")
		return
	}

	vertices := [?]f32 {
		-0.5,
		-0.5,
		-0.5,
		0.0,
		0.0,
		0.5,
		-0.5,
		-0.5,
		1.0,
		0.0,
		0.5,
		0.5,
		-0.5,
		1.0,
		1.0,
		0.5,
		0.5,
		-0.5,
		1.0,
		1.0,
		-0.5,
		0.5,
		-0.5,
		0.0,
		1.0,
		-0.5,
		-0.5,
		-0.5,
		0.0,
		0.0,
		-0.5,
		-0.5,
		0.5,
		0.0,
		0.0,
		0.5,
		-0.5,
		0.5,
		1.0,
		0.0,
		0.5,
		0.5,
		0.5,
		1.0,
		1.0,
		0.5,
		0.5,
		0.5,
		1.0,
		1.0,
		-0.5,
		0.5,
		0.5,
		0.0,
		1.0,
		-0.5,
		-0.5,
		0.5,
		0.0,
		0.0,
		-0.5,
		0.5,
		0.5,
		1.0,
		0.0,
		-0.5,
		0.5,
		-0.5,
		1.0,
		1.0,
		-0.5,
		-0.5,
		-0.5,
		0.0,
		1.0,
		-0.5,
		-0.5,
		-0.5,
		0.0,
		1.0,
		-0.5,
		-0.5,
		0.5,
		0.0,
		0.0,
		-0.5,
		0.5,
		0.5,
		1.0,
		0.0,
		0.5,
		0.5,
		0.5,
		1.0,
		0.0,
		0.5,
		0.5,
		-0.5,
		1.0,
		1.0,
		0.5,
		-0.5,
		-0.5,
		0.0,
		1.0,
		0.5,
		-0.5,
		-0.5,
		0.0,
		1.0,
		0.5,
		-0.5,
		0.5,
		0.0,
		0.0,
		0.5,
		0.5,
		0.5,
		1.0,
		0.0,
		-0.5,
		-0.5,
		-0.5,
		0.0,
		1.0,
		0.5,
		-0.5,
		-0.5,
		1.0,
		1.0,
		0.5,
		-0.5,
		0.5,
		1.0,
		0.0,
		0.5,
		-0.5,
		0.5,
		1.0,
		0.0,
		-0.5,
		-0.5,
		0.5,
		0.0,
		0.0,
		-0.5,
		-0.5,
		-0.5,
		0.0,
		1.0,
		-0.5,
		0.5,
		-0.5,
		0.0,
		1.0,
		0.5,
		0.5,
		-0.5,
		1.0,
		1.0,
		0.5,
		0.5,
		0.5,
		1.0,
		0.0,
		0.5,
		0.5,
		0.5,
		1.0,
		0.0,
		-0.5,
		0.5,
		0.5,
		0.0,
		0.0,
		-0.5,
		0.5,
		-0.5,
		0.0,
		1.0,
	}

	indices := [?]u32 {
		//first triangle
		0,
		1,
		3,

		//second triangle
		1,
		2,
		3,
	}

	// VAO: "Vertex Array Object" - stores the configuration of the vertex data
	// VBO: "Vertex Buffer Object" - manages memory. the GPU can store shit tons of stuff
	// EBO: "Element Buffer Object" - stores indices that define how vertices connect to geometric primitives
	VAO, VBO, EBO: u32
	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)
	gl.GenBuffers(1, &EBO)

	gl.BindVertexArray(VAO)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices, gl.STATIC_DRAW)

	total_size: i32 = 5 * size_of(f32)

	// position attribute
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, total_size, cast(uintptr)0)
	gl.EnableVertexAttribArray(0)

	// texture position
	gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, total_size, cast(uintptr)(3 * size_of(f32)))
	gl.EnableVertexAttribArray(1)

	// Load the first texture
	texture1: u32

	gl.GenTextures(1, &texture1)
	gl.BindTexture(gl.TEXTURE_2D, texture1)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	width, height, nrChannels: i32
	data := stbi.load("textures/container.jpg", &width, &height, &nrChannels, 0)
	if data == nil {
		fmt.eprintln(stbi.failure_reason())
		return
	}

	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, data)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	stbi.image_free(data)

	// Load the second texture
	texture2: u32
	gl.GenTextures(1, &texture2)
	gl.BindTexture(gl.TEXTURE_2D, texture2)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	stbi.set_flip_vertically_on_load(cast(i32)1)
	data = stbi.load("textures/awesomeface.png", &width, &height, &nrChannels, 0)
	if data == nil {
		fmt.eprintln(stbi.failure_reason())
		return
	}

	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, data)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	stbi.image_free(data)

	use_shader(our_shader.id)
	set_shader_int(our_shader.id, "texture1", 0)
	set_shader_int(our_shader.id, "texture2", 1)

	cubePositions := [?][3]f32 {
		{0.0, 0.0, 0.0},
		{2.0, 5.0, -15.0},
		{-1.5, -2.2, -2.5},
		{-3.8, -2.0, -12.3},
		{2.4, -0.4, -3.5},
		{-1.7, 3.0, -7.5},
		{1.3, -2.0, -2.5},
		{1.5, 2.0, -2.5},
		{1.5, 0.2, -1.5},
		{-1.3, 1.0, -1.5},
	}

	gl.Enable(gl.DEPTH_TEST)


	last_frame: f32 = 0.0

	glfw.SetCursorPosCallback(window_handle, cast(glfw.CursorPosProc)process_mouse_input)

	for (!glfw.WindowShouldClose(window_handle)) {
		current_frame := f32(glfw.GetTime())
		game_state.camera_delta = current_frame - last_frame
		last_frame = current_frame

		width, height := glfw.GetWindowSize(window_handle)
		process_input(window_handle, &game_state)
		set_shader_float(our_shader.id, "opacity", game_state.opacity)

		game_state.direction.x =
			linalg.cos(linalg.to_radians(game_state.mouse_yaw)) *
			linalg.cos(linalg.to_radians(game_state.mouse_pitch))
		game_state.direction.y = linalg.sin(linalg.to_radians(game_state.mouse_pitch))
		game_state.direction.z =
			linalg.sin(linalg.to_radians(game_state.mouse_yaw)) *
			linalg.cos(linalg.to_radians(game_state.mouse_pitch))

		game_state.camera_front = linalg.normalize(game_state.direction)

		view := linalg.matrix4_look_at_f32(
			game_state.camera_pos,
			game_state.camera_pos + game_state.camera_front,
			game_state.camera_up,
		)

		set_shader_matrix4(our_shader.id, "view", &view)


		projection := linalg.matrix4_perspective_f32(
			f32(linalg.to_radians(45.0)),
			f32(width) / f32(height), // window width & window height to keep everything sized correctly
			0.1,
			100.0,
		)
		set_shader_matrix4(our_shader.id, "projection", &projection)

		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, texture1)
		gl.ActiveTexture(gl.TEXTURE1)
		gl.BindTexture(gl.TEXTURE_2D, texture2)

		use_shader(our_shader.id)
		gl.BindVertexArray(VAO)

		time_modifier := glfw.GetTime()

		for i := 0; i < 10; i += 1 {
			model := linalg.MATRIX4F32_IDENTITY
			model *= linalg.matrix4_translate_f32(cubePositions[i])
			angle := f32(0)
			if i % 3 == 0 {
				angle = f32(time_modifier)
			} else {
				angle = cast(f32)(20.0 * i)
			}
			model *= linalg.matrix4_rotate_f32(angle, {1.0, 0.3, 0.5})

			set_shader_matrix4(our_shader.id, "model", &model)
			gl.DrawArrays(gl.TRIANGLES, 0, 36)
		}


		res := gl.GetError()

		glfw.SwapBuffers(window_handle)
		glfw.PollEvents()
	}
}

process_mouse_input :: proc(window: glfw.WindowHandle, xpos64: f64, ypos64: f64) {
	xpos := f32(xpos64)
	ypos := f32(ypos64)
	if first_mouse == true // initially set to true
	{
		game_state.mouse_xpos = xpos
		game_state.mouse_ypos = ypos
		first_mouse = false
	}

	xoffset := xpos - game_state.mouse_xpos
	yoffset := game_state.mouse_ypos - ypos
	game_state.mouse_xpos = xpos
	game_state.mouse_ypos = ypos

	game_state.mouse_yaw += (xoffset * game_state.sensitivity)
	game_state.mouse_pitch += (yoffset * game_state.sensitivity)

	game_state.mouse_pitch = linalg.clamp(game_state.mouse_pitch, -89.0, 89.0)
}

frame_buffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

process_input :: proc(window: glfw.WindowHandle, game_state: ^GameState) {
	// Kill Window with Escape
	if (glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS) {
		glfw.SetWindowShouldClose(window, true)
	}

	// Camera Movement
	if (glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS) {
		game_state.camera_pos +=
			(game_state.camera_speed * game_state.camera_delta) * game_state.camera_front
	}
	if (glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS) {
		game_state.camera_pos -=
			(game_state.camera_speed * game_state.camera_delta) * game_state.camera_front
	}
	if (glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS) {
		game_state.camera_pos -=
			linalg.vector_normalize(
				linalg.vector_cross3(game_state.camera_front, game_state.camera_up),
			) *
			(game_state.camera_speed * game_state.camera_delta)
	}
	if (glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS) {
		game_state.camera_pos +=
			linalg.vector_normalize(
				linalg.vector_cross3(game_state.camera_front, game_state.camera_up),
			) *
			(game_state.camera_speed * game_state.camera_delta)
	}

}

use_shader :: proc(id: u32) {
	gl.UseProgram(id)
}

set_shader_bool :: proc(id: u32, name: string, value: bool) {
	uniform_name := strings.clone_to_cstring(name)

	gl.Uniform1i(gl.GetUniformLocation(id, uniform_name), cast(i32)value)
}

set_shader_int :: proc(id: u32, name: string, value: i32) {
	uniform_name := strings.clone_to_cstring(name)
	gl.Uniform1i(gl.GetUniformLocation(id, uniform_name), value)
}

set_shader_float :: proc(id: u32, name: string, value: f32) {
	uniform_name := strings.clone_to_cstring(name)
	gl.Uniform1f(gl.GetUniformLocation(id, uniform_name), value)
}

set_shader_matrix4 :: proc(id: u32, name: string, value: ^matrix[4, 4]f32) {
	uniform_name := strings.clone_to_cstring(name)
	gl.UniformMatrix4fv(gl.GetUniformLocation(id, uniform_name), 1, gl.FALSE, &value[0][0])
}

load_and_compile_shader :: proc(
	vertex_shader_path: string,
	fragment_shader_path: string,
) -> (
	Shader,
	i32,
) {
	new_shader: Shader

	vertex_source_data, vert_err := os.read_entire_file_from_filename_or_err(vertex_shader_path)
	if vert_err != os.ERROR_NONE {
		fmt.eprintln("SHADER ERROR")
		return new_shader, -1
	}
	new_shader.vertex_source = convert_to_cstring(vertex_source_data)

	fragment_source_data, frag_err := os.read_entire_file_from_filename_or_err(
		fragment_shader_path,
	)
	if frag_err != os.ERROR_NONE {
		fmt.eprintln("SHADER ERROR")
		return new_shader, -1
	}

	new_shader.fragment_source = convert_to_cstring(fragment_source_data)

	fragmentShader, vertexShader: u32
	vertexShader = gl.CreateShader(gl.VERTEX_SHADER)
	fragmentShader = gl.CreateShader(gl.FRAGMENT_SHADER)

	gl.ShaderSource(vertexShader, 1, &new_shader.vertex_source, nil)
	gl.ShaderSource(fragmentShader, 1, &new_shader.fragment_source, nil)

	gl.CompileShader(vertexShader)
	gl.CompileShader(fragmentShader)

	new_shader.id = gl.CreateProgram()
	gl.AttachShader(new_shader.id, vertexShader)
	gl.AttachShader(new_shader.id, fragmentShader)
	gl.LinkProgram(new_shader.id)

	//Delete shaders after linking
	gl.DeleteShader(vertexShader)
	gl.DeleteShader(fragmentShader)

	shader_success: i32
	gl.GetProgramiv(new_shader.id, gl.LINK_STATUS, &shader_success)
	if (shader_success == 0) {
		fmt.eprintln("SHADER ERROR")
		return new_shader, -1
	}
	return new_shader, 0
}

convert_to_cstring :: proc(str: []u8) -> cstring {
	return cstring(raw_data(str))
}
