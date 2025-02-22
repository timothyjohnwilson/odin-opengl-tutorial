package main

import "core:fmt"
import gl "vendor:OpenGL"
import glfw "vendor:glfw"


SCREEN_WIDTH: u32 = 800
SCREEN_HEIGHT: u32 = 600

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 1

Breakout: Game = {
	width  = SCREEN_WIDTH,
	height = SCREEN_HEIGHT,
}

main :: proc() {
	glfw.Init()
	defer glfw.Terminate()
	glfw.WindowHint(glfw.RESIZABLE, glfw.TRUE)
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, glfw.TRUE)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MAJOR)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MINOR)
	window_handle: glfw.WindowHandle = glfw.CreateWindow(
		i32(SCREEN_WIDTH),
		i32(SCREEN_HEIGHT),
		"Breakout",
		nil,
		nil,
	)
	if (window_handle == nil) {
		fmt.eprint("Failed to create glfw window! \n")
		return
	}

	// glfw.SetInputMode(window_handle, glfw.CURSOR, glfw.CURSOR_DISABLED)
	glfw.MakeContextCurrent(window_handle)
	glfw.SwapInterval(0)
	glfw.SetFramebufferSizeCallback(window_handle, frame_buffer_size_callback)

	//OpenGL set up
	gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, proc(p: rawptr, name: cstring) {
		(^rawptr)(p)^ = glfw.GetProcAddress(name)
	})

	glfw.SetKeyCallback(window_handle, key_callback)

	width, height := glfw.GetFramebufferSize(window_handle) // GetFramebufferSize helps mitigate MacOS' high dpi screens
	gl.Viewport(0, 0, width, height)
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
	init(&Breakout)

	delta_time: f64 = 0.0
	last_frame: f64 = 0.0

	for (!glfw.WindowShouldClose(window_handle)) {
		current_frame := glfw.GetTime()
		delta_time = current_frame - last_frame
		last_frame = current_frame
		glfw.PollEvents()

		process_input(&Breakout, f32(delta_time))

		update(&Breakout, f32(delta_time))

		gl.ClearColor(0.0, 0.0, 0.0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		render(&Breakout)

		glfw.SwapBuffers(window_handle)
	}

	clear()
	glfw.Terminate()
}


key_callback :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: i32) {
	//     // when a user presses the escape key, we set the WindowShouldClose property to true, closing the application
	if (key == glfw.KEY_ESCAPE && action == glfw.PRESS) {
		glfw.SetWindowShouldClose(window, true)
	}
	if (key >= 0 && key < 1024) {
		if (action == glfw.PRESS) {
			Breakout.keys[key] = true
		} else if (action == glfw.RELEASE) {
			Breakout.keys[key] = false
		}
	}
}

// make sure the viewport matches the new window dimensions; note that width and 
// height will be significantly larger than specified on retina displays.
frame_buffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}
