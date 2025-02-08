package main
import gl "vendor:OpenGL"
import "core:fmt"
import "core:os"
import "core:strings"

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
