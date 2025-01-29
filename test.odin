package main

import "core:fmt"
import "core:math"
import "core:os"
import "core:strings"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"


//Const set up
WINDOW_WIDTH :: 854
WINDOW_HEIGHT :: 480

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 6


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
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 4)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 1)
	window_handle: glfw.WindowHandle = glfw.CreateWindow(
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		"Hello Window",
		nil,
		nil,
	)
	if (window_handle == nil) {
		fmt.eprint("Failed to create glfw window! \n")
	}
	glfw.MakeContextCurrent(window_handle)
	glfw.SwapInterval(0)
	glfw.SetFramebufferSizeCallback(window_handle, frame_buffer_size_callback)
	//OpenGL set up
	gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, proc(p: rawptr, name: cstring) {
		(^rawptr)(p)^ = glfw.GetProcAddress(name)
	})

	gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
	//Shader set up
	fragmentShader, vertexShader: u32
	vertexShader = gl.CreateShader(gl.VERTEX_SHADER)
	fragmentShader = gl.CreateShader(gl.FRAGMENT_SHADER)

	test_shader: Shader = read_shader(
		"shaders/test_vertex_shader.vs",
		"shaders/test_fragment_shader.fs",
	)
	gl.ShaderSource(vertexShader, 1, &test_shader.vertex_source, nil)
	gl.ShaderSource(fragmentShader, 1, &test_shader.fragment_source, nil)

	gl.CompileShader(vertexShader)
	gl.CompileShader(fragmentShader)


	shader_success: i32
	test_shader.id = gl.CreateProgram()
	gl.AttachShader(test_shader.id, vertexShader)
	gl.AttachShader(test_shader.id, fragmentShader)
	gl.LinkProgram(test_shader.id)

	//Delete shaders after linking
	gl.DeleteShader(vertexShader)
	gl.DeleteShader(fragmentShader)

	gl.GetProgramiv(test_shader.id, gl.LINK_STATUS, &shader_success)
	if (shader_success == 0) {
		fmt.eprintln("SHADER ERROR")
		return
	}

	vertices := [?]f32 {
		// positions         // colors
		0.5,
		0.5,
		0.0,
		1.0,
		0.0,
		0.0, // bottom right
		-0.5,
		0.5,
		0.0,
		0.0,
		1.0,
		0.0, // bottom left
		0.0,
		-0.5,
		0.0,
		0.0,
		0.0,
		1.0, // top 
	}

	VAO: u32
	gl.GenVertexArrays(1, &VAO)
	gl.BindVertexArray(VAO)


	// a VBO is a Vertex Buffer Object which is used to manage memory. the GPU can store shit tons of stuff
	VBO: u32
	gl.GenBuffers(1, &VBO)

	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)
	// after this buffer data occurs, all buffer actions effect the currently bound VBO

	// position attribute
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * size_of(f32), cast(uintptr)0)
	gl.EnableVertexAttribArray(0)

	// color attribute
	gl.VertexAttribPointer(
		1,
		3,
		gl.FLOAT,
		gl.FALSE,
		6 * size_of(f32),
		cast(uintptr)(3 * size_of(f32)),
	)
	gl.EnableVertexAttribArray(1)

	gl.EnableVertexAttribArray(0)
	for (!glfw.WindowShouldClose(window_handle)) {
		process_input(window_handle)
		glfw.PollEvents()
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)


		use_shader(test_shader.id)

		time_value := glfw.GetTime()
		set_shader_float(
			test_shader.id,
			"horizontalOffset",
			cast(f32)((math.sin(time_value) / 2.0)),
		)

		gl.BindVertexArray(VAO)
		gl.DrawArrays(gl.TRIANGLES, 0, 3)

		glfw.SwapBuffers(window_handle)
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

read_shader :: proc(vertex_shader_path: string, fragment_shader_path: string) -> Shader {
	new_shader: Shader

	vertex_source_data, vert_err := os.read_entire_file_from_filename_or_err(vertex_shader_path)
	if vert_err != os.ERROR_NONE {
		// handle error
	}
	new_shader.vertex_source = convert_to_cstring(vertex_source_data)

	fragment_source_data, frag_err := os.read_entire_file_from_filename_or_err(
		fragment_shader_path,
	)
	if frag_err != os.ERROR_NONE {
		// handle error
	}

	new_shader.fragment_source = convert_to_cstring(fragment_source_data)

	return new_shader
}

convert_to_cstring :: proc(str: []u8) -> cstring {
	return cstring(raw_data(str))
}
