package main

import "core:fmt"
import gl "vendor:OpenGL"
import "vendor:glfw"

SCR_WIDTH  :: 800
SCR_HEIGHT :: 600

//The OpenGL version: 4.6 
GL_MAJOR :: 4
GL_MINOR :: 6

main :: proc(){
    // Initialzaiton of glfw, eprintln return error if tpye if glfw is not initialized correctly
    if !glfw.Init(){
        fmt.eprintln("Failed to initialize GLFW")
        return
    }
    // Runs when main exits: shuts GLFW down and frees its resources.
    defer glfw.Terminate()
    
    // Let GLFW know what kind of OpenGL context we want
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_MAJOR)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_MINOR)
    // Core profile = modern OpenGL only, no legacy fixed-function stuff.
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    window := glfw.CreateWindow(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGL", nil, nil)
    if window == nil{
        fmt.eprintln("Failed to create GLFW window")
    }
    
    defer glfw.DestroyWindow(window)
	// Make this window's OpenGL context the active one on this thread.
	// OpenGL calls do nothing without a current context.
	glfw.MakeContextCurrent(window)

    // Register our function to be called whenever the window is resized.
	glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)

    // OpenGL functions live in the graphics driver, so we have to look up
	// their addresses at runtime. This does that, using GLFW's lookup
	// function. (Same job as gladLoadGLLoader in the C++ tutorial.)
	// Must come after MakeContextCurrent.
    // if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
    // {
    //     std::cout << "Failed to initialize GLAD" << std::endl;
    //     return -1;
    // }  
      
    gl.load_up_to(GL_MAJOR, GL_MINOR, glfw.gl_set_proc_address)

    for !glfw.WindowShouldClose(window){
        process_input(window)

		// Rendering: set the color used to clear the screen (R, G, B, A)...
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		// ...then clear the color buffer with that color.
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// Swap front and back buffers. We draw into a hidden back buffer
		// and swap it onto the screen to avoid flickering.
		glfw.SwapBuffers(window)
		// Process pending events (keyboard, mouse, resize, close button)
		// and trigger the callbacks for them.
		glfw.PollEvents()


    }
}

// Called every frame to check for input.
process_input :: proc(window: glfw.WindowHandle) {
	// If Escape is currently pressed, flag the window to close.
	// The render loop's WindowShouldClose check then ends the loop.
	if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
		glfw.SetWindowShouldClose(window, true)
	}
}

// Called by GLFW when the window is resized.
// "c" means it uses the C calling convention, which GLFW requires.
// Such procs have no Odin context, so avoid fmt or allocations in here.
framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	// Tell OpenGL the drawing area: lower-left corner (0, 0) and the new size.
	gl.Viewport(0, 0, width, height)
}

