package main
import "core:fmt"
import "core:os"
import "core:strings"
import gl "vendor:OpenGL"

Shader :: struct {
	id:              u32,
	vertex_source:   cstring,
	fragment_source: cstring,
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

generate_shader :: proc(
	vertex_code: ^cstring,
	fragment_code: ^cstring,
	geometry_code: ^cstring = nil,
) -> Shader {
	new_shader: Shader

	vertex_shader := gl.CreateShader(gl.VERTEX_SHADER)
	gl.ShaderSource(vertex_shader, 1, vertex_code, nil)
	gl.CompileShader(vertex_shader)
	check_compile_errors(vertex_shader, "VERTEX")

	fragment_shader := gl.CreateShader(gl.FRAGMENT_SHADER)
	gl.ShaderSource(fragment_shader, 1, fragment_code, nil)
	gl.CompileShader(fragment_shader)
	check_compile_errors(fragment_shader, "FRAGMENT")

	geometry_shader: u32
	if (geometry_code != nil) {
		geometry_shader := gl.CreateShader(gl.GEOMETRY_SHADER)
		gl.ShaderSource(geometry_shader, 1, geometry_code, nil)
		gl.CompileShader(geometry_shader)
		check_compile_errors(geometry_shader, "GEOMETRY")
	}

	new_shader.id = gl.CreateProgram()
	gl.AttachShader(new_shader.id, vertex_shader)
	gl.AttachShader(new_shader.id, fragment_shader)
	if (geometry_code != nil) {
		gl.AttachShader(new_shader.id, geometry_shader)
	}

	gl.LinkProgram(new_shader.id)
	check_compile_errors(new_shader.id, "PROGRAM")

	gl.DeleteShader(vertex_shader)
	gl.DeleteShader(fragment_shader)
	if (geometry_code != nil) {
		gl.DeleteShader(geometry_shader)
	}

	return new_shader
}

check_compile_errors :: proc(object: u32, type: string) {
	success: i32
	info_log: [^]u8

	if (type != "PROGRAM") {
		gl.GetShaderiv(object, gl.COMPILE_STATUS, &success)
		if (!bool(success)) {
			gl.GetShaderInfoLog(object, 1024, nil, info_log)
			fmt.print("| ERROR::SHADER: Compile-time error: Type: ")
			fmt.println(type)
			fmt.println(info_log)
			fmt.println("\n -- --------------------------------------------------- -- ")
		}
	} else {
		gl.GetProgramiv(object, gl.LINK_STATUS, &success)
		if (!bool(success)) {
			gl.GetProgramInfoLog(object, 1024, nil, info_log)
			fmt.println("| ERROR::Shader: Link-time error: Type: ")
			fmt.println(type)
			fmt.println(info_log)
			fmt.println("\n -- --------------------------------------------------- -- ")
		}
	}
}
