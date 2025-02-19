package main

import "core:fmt"
import "core:os"
import "core:strings"
import gl "vendor:OpenGL"
import stbi "vendor:stb/image"

// RESOURCE MANAGER
// Important functions
// load_shader
// get_shader
// load_texture
// get_texture

// NOTE(tim): Perhaps set hard limit on array length?
shaders := make(map[string]Shader)
textures := make(map[string]Texture2D)

vert_frag_geo_shader :: proc(
	vertex_shader_path: ^string,
	fragment_shader_path: ^string,
	geometry_shader_path: ^string,
	name: string,
) -> Shader {
	new_shader, error_code := load_shader_from_file(
		vertex_shader_path,
		fragment_shader_path,
		geometry_shader_path,
	)

	shaders[name] = new_shader
	return shaders[name]
}

vert_frag_shader :: proc(
	vertex_shader_path: ^string,
	fragment_shader_path: ^string,
	name: string,
) -> Shader {
	new_shader, error_code := load_shader_from_file(vertex_shader_path, fragment_shader_path)

	shaders[name] = new_shader
	return shaders[name]
}

load_shader :: proc {
	vert_frag_geo_shader,
	vert_frag_shader,
}

get_shader :: proc(name: string) -> Shader {
	return shaders[name]
}

load_texture :: proc(file: string, alpha: bool, name: string) -> Texture2D {
	new_texture, error_code := load_texture_from_file(file, alpha)
	textures[name] = new_texture

	return textures[name]
}

get_texture :: proc(name: string) -> Texture2D {
	return textures[name]
}

clear :: proc() {
	for key, value in shaders {
		gl.DeleteProgram(value.id)
	}

	for key, value in textures {
		texture_to_delete: []u32 = {value.id}
		gl.DeleteTextures(1, raw_data(texture_to_delete))
	}
}

load_vert_frag_shader_from_file :: proc(
	vertex_shader_path: ^string,
	fragment_shader_path: ^string,
) -> (
	Shader,
	i32,
) {

	new_shader: Shader

	vertex_code, vert_err := os.read_entire_file_from_filename_or_err(vertex_shader_path^)
	if vert_err != os.ERROR_NONE {
		fmt.eprintln("VERTEX SHADER ERROR")
		return new_shader, -1
	}

	fragment_code, frag_err := os.read_entire_file_from_filename_or_err(fragment_shader_path^)
	if frag_err != os.ERROR_NONE {
		fmt.eprintln("FRAGMENT SHADER ERROR")
		return new_shader, -1
	}


	vertex_cstring := convert_to_cstring(vertex_code)
	fragment_cstring := convert_to_cstring(fragment_code)

	new_shader = generate_shader(&vertex_cstring, &fragment_cstring)

	return new_shader, 0
}

load_vert_frag_geo_shader_from_file :: proc(
	vertex_shader_path: ^string,
	fragment_shader_path: ^string,
	geometry_shader_path: ^string,
) -> (
	Shader,
	i32,
) {

	new_shader: Shader

	vertex_code, vert_err := os.read_entire_file_from_filename_or_err(vertex_shader_path^)
	if vert_err != os.ERROR_NONE {
		fmt.eprintln("VERTEX SHADER ERROR")
		return new_shader, -1
	}

	fragment_code, frag_err := os.read_entire_file_from_filename_or_err(fragment_shader_path^)
	if frag_err != os.ERROR_NONE {
		fmt.eprintln("FRAGMENT SHADER ERROR")
		return new_shader, -1
	}

	geometry_code, geo_err := os.read_entire_file_from_filename_or_err(geometry_shader_path^)
	if geo_err != os.ERROR_NONE {
		fmt.eprintln("GEOMETRY SHADER ERROR")
		return new_shader, -1
	}


	vertex_cstring := convert_to_cstring(vertex_code)
	fragment_cstring := convert_to_cstring(fragment_code)
	geometry_cstring := convert_to_cstring(geometry_code)

	new_shader = generate_shader(&vertex_cstring, &fragment_cstring, &geometry_cstring)

	return new_shader, 0
}


load_shader_from_file :: proc {
	load_vert_frag_geo_shader_from_file,
	load_vert_frag_shader_from_file,
}


load_texture_from_file :: proc(path: string, alpha: bool) -> (Texture2D, i32) {
	texture: Texture2D
	texture.wrap_s = gl.REPEAT
	texture.wrap_t = gl.REPEAT
	texture.filter_min = gl.LINEAR
	texture.filter_max = gl.LINEAR

	if (alpha) {
		texture.internal_format = gl.RGBA
		texture.image_format = gl.RGBA
	}


	width, height, nrChannels: i32
	data := stbi.load(
		strings.clone_to_cstring(path),
		&width,
		&height,
		&nrChannels,
		0,
	)
	if data == nil {
		fmt.eprintln(stbi.failure_reason())
		return texture, -1
	}

	init_texture(&texture)
	generate_texture(&texture, width, height, data)

	stbi.image_free(data)

	return texture, 0
}


convert_to_cstring :: proc(str: []u8) -> cstring {
	return cstring(raw_data(str))
}
