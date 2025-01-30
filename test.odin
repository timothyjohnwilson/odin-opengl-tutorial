package main

import "core:fmt"
import "core:math"
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

Shader_4f :: struct {
	x: f32,
	y: f32,
	z: f32,
	w: f32,
}


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
		// top right position
		0.5,
		0.5,
		0.0,

		// top right color
		1.0,
		0.0,
		0.0,

		// top right texture coordinate
		1.0,
		1.0,

		// bottom right position
		0.5,
		-0.5,
		0.0,

		// bottom right color
		0.0,
		1.0,
		0.0,

		// bottom right texture coordinate
		1.0,
		0.0,

		// bottom left position
		-0.5,
		-0.5,
		0.0,

		// bottom left color
		0.0,
		0.0,
		1.0,

		//bottom left texture coordinate
		0.0,
		0.0,

		// top left position
		-0.5,
		0.5,
		0.0,

		// top left color
		1.0,
		1.0,
		0.0,

		// top left texture coordinate
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

	total_size:i32 = 8 * size_of(f32)

	// position attribute
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, total_size, cast(uintptr)0)
	gl.EnableVertexAttribArray(0)

	// color attribute
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, total_size, cast(uintptr)(3 * size_of(f32)))
	gl.EnableVertexAttribArray(1)

	// texture position
	gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, total_size, cast(uintptr)(6 * size_of(f32)))
	gl.EnableVertexAttribArray(2)

	// Load the textures
	texture: u32

	gl.GenTextures(1, &texture)
	gl.BindTexture(gl.TEXTURE_2D, texture)

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

	el_index := 0

	use_shader(our_shader.id)
	set_shader_int(our_shader.id, "ourTexture", 0)

	for (!glfw.WindowShouldClose(window_handle)) {
		process_input(window_handle)

		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.ActiveTexture(gl.TEXTURE0)
		gl.BindTexture(gl.TEXTURE_2D, texture)

		use_shader(our_shader.id)
		gl.BindVertexArray(VAO)
		gl.DrawElements(gl.TRIANGLES, len(indices), gl.UNSIGNED_INT, nil)

		res := gl.GetError()

		glfw.SwapBuffers(window_handle)
		glfw.PollEvents()
	}
}

frame_buffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}

process_input :: proc(window: glfw.WindowHandle) {
	if (glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS) {
		glfw.SetWindowShouldClose(window, true)
	}
	if (glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS) {
		gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
	}

	if (glfw.GetKey(window, glfw.KEY_F) == glfw.PRESS) {
		gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
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

set_shader_4f :: proc(id: u32, name: string, value: Shader_4f) {
	uniform_name := strings.clone_to_cstring(name)
	gl.Uniform4f(gl.GetUniformLocation(id, uniform_name), value.x, value.y, value.z, value.w)
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
