namespace Sedulous.Engine.Renderer.SDL;

class Cube
{
	public static float[?] Vertices = .(
		// Positions       // Normals         // UVs
		-1, -1, -1,   0,  0, -1,   0, 0,  // Front face
		 1, -1, -1,   0,  0, -1,   1, 0,
		 1,  1, -1,   0,  0, -1,   1, 1,
		-1,  1, -1,   0,  0, -1,   0, 1,

		-1, -1,  1,   0,  0,  1,   0, 0,  // Back face
		 1, -1,  1,   0,  0,  1,   1, 0,
		 1,  1,  1,   0,  0,  1,   1, 1,
		-1,  1,  1,   0,  0,  1,   0, 1
		);

	public static uint32[?] Indices = .(
		0, 1, 2, 2, 3, 0,  // Front
		4, 5, 6, 6, 7, 4,  // Back
		0, 4, 7, 7, 3, 0,  // Left
		1, 5, 6, 6, 2, 1,  // Right
		3, 2, 6, 6, 7, 3,  // Top
		0, 1, 5, 5, 4, 0   // Bottom
		);
}