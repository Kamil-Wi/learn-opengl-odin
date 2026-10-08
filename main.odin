package main

import "core:fmt"
import gl "vendor:OpenGL"
import "vendor:glfw"

SCR_WIDTH  :: 800
SCR_HEIGHT :: 600
GL_MAJOR   :: 3
GL_MINOR   :: 3

// Shader source as cstring constants (Odin adds the null terminator for us,
// so there is no "\0" like in the C++ version). Backticks make raw
// multi-line strings.
VERTEX_SHADER_SOURCE : cstring : `#version 330 core
layout (location = 0) in vec3 aPos;
void main()
{
    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
}`

FRAGMENT_SHADER_SOURCE : cstring : `#version 330 core
out vec4 FragColor;
void main()
{
    FragColor = vec4(1.0, 0.5, 0.2, 1.0);
}`

main :: proc() {
	if !glfw.Init() {
		fmt.eprintln("Failed to initialize GLFW")
		return
	}
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	when ODIN_OS == .Darwin {
		glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, glfw.TRUE)
	}

	window := glfw.CreateWindow(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL", nil, nil)
	if window == nil {
		fmt.eprintln("Failed to create GLFW window")
		return
	}
	defer glfw.DestroyWindow(window)

	glfw.MakeContextCurrent(window)
	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)
	gl.load_up_to(GL_MAJOR, GL_MINOR, glfw.gl_set_proc_address)

	// --- Build the shader program ----------------------------------
	vertex_shader, ok_vs := compile_shader(VERTEX_SHADER_SOURCE, gl.VERTEX_SHADER)
	if !ok_vs { return }
	fragment_shader, ok_fs := compile_shader(FRAGMENT_SHADER_SOURCE, gl.FRAGMENT_SHADER)
	if !ok_fs { return }

	shader_program := gl.CreateProgram()
	gl.AttachShader(shader_program, vertex_shader)
	gl.AttachShader(shader_program, fragment_shader)
	gl.LinkProgram(shader_program)
	defer gl.DeleteProgram(shader_program)

	success: i32
	gl.GetProgramiv(shader_program, gl.LINK_STATUS, &success)
	if success == 0 {
		info_log: [512]u8
		length: i32
		gl.GetProgramInfoLog(shader_program, len(info_log), &length, &info_log[0])
		fmt.eprintln("ERROR::SHADER::PROGRAM::LINKING_FAILED\n", string(info_log[:length]))
		return
	}

	// The shader objects are copied into the program at link time,
	// so we no longer need them.
	gl.DeleteShader(vertex_shader)
	gl.DeleteShader(fragment_shader)

	// --- Vertex data ------------------------------------------------
	// Three vertices in normalized device coordinates (-1..1), z = 0.
	vertices := [?]f32{
		-0.5, -0.5, 0.0, // bottom left
		 0.5, -0.5, 0.0, // bottom right
		 0.0,  0.5, 0.0, // top
	}

	vao, vbo: u32
	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	defer gl.DeleteVertexArrays(1, &vao)
	defer gl.DeleteBuffers(1, &vbo)

	// 1. Bind the VAO first: it records everything configured below.
	gl.BindVertexArray(vao)

	// 2. Copy the vertices into a GPU buffer (the VBO).
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices, gl.STATIC_DRAW)

	// 3. Describe the layout: attribute 0, 3 floats per vertex, not
	//    normalized, stride = 3 floats, offset 0 (the last arg is a plain
	//    integer offset in Odin, no (void*) cast).
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 3 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	// Unbinding is optional. Never unbind an EBO while a VAO is bound.
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindVertexArray(0)

	// Uncomment for wireframe mode:
	// gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

	// --- Render loop ------------------------------------------------
	for !glfw.WindowShouldClose(window) {
		process_input(window)

		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.UseProgram(shader_program)
		gl.BindVertexArray(vao)
		gl.DrawArrays(gl.TRIANGLES, 0, 3) // primitive, start index, vertex count

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
}

// Compiles one shader and prints the error log on failure.
compile_shader :: proc(source: cstring, shader_type: u32) -> (shader: u32, ok: bool) {
	shader = gl.CreateShader(shader_type)

	// ShaderSource wants a pointer to an array of strings, so we need
	// an addressable local even though we only have one string.
	src := source
	gl.ShaderSource(shader, 1, &src, nil)
	gl.CompileShader(shader)

	success: i32
	gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		info_log: [512]u8
		length: i32
		gl.GetShaderInfoLog(shader, len(info_log), &length, &info_log[0])
		fmt.eprintln("ERROR::SHADER::COMPILATION_FAILED\n", string(info_log[:length]))
		gl.DeleteShader(shader)
		return 0, false
	}
	return shader, true
}

process_input :: proc(window: glfw.WindowHandle) {
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}
}

framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}