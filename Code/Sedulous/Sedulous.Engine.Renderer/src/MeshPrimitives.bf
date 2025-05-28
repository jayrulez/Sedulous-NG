using Sedulous.Foundation.Mathematics;
using System;
using System.Collections;
using static Sedulous.Engine.Renderer.Mesh;
namespace Sedulous.Engine.Renderer;

static class MeshPrimitives
{
    public static Mesh CreateCube(float size = 1.0f)
    {
        var halfSize = size * 0.5f;
        
        var vertices = new Mesh.Vertex[]
        (
            // Front face
            Mesh.Vertex { Position = Vector3(-halfSize, -halfSize,  halfSize), Normal = Vector3(0, 0, 1), TexCoord = Vector2(0, 0), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3( halfSize, -halfSize,  halfSize), Normal = Vector3(0, 0, 1), TexCoord = Vector2(1, 0), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3( halfSize,  halfSize,  halfSize), Normal = Vector3(0, 0, 1), TexCoord = Vector2(1, 1), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3(-halfSize,  halfSize,  halfSize), Normal = Vector3(0, 0, 1), TexCoord = Vector2(0, 1), Color = Vector4.One },
            
            // Back face
            Mesh.Vertex { Position = Vector3(-halfSize, -halfSize, -halfSize), Normal = Vector3(0, 0, -1), TexCoord = Vector2(1, 0), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3(-halfSize,  halfSize, -halfSize), Normal = Vector3(0, 0, -1), TexCoord = Vector2(1, 1), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3( halfSize,  halfSize, -halfSize), Normal = Vector3(0, 0, -1), TexCoord = Vector2(0, 1), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3( halfSize, -halfSize, -halfSize), Normal = Vector3(0, 0, -1), TexCoord = Vector2(0, 0), Color = Vector4.One },
            
            // Top face
            Mesh.Vertex { Position = Vector3(-halfSize,  halfSize, -halfSize), Normal = Vector3(0, 1, 0), TexCoord = Vector2(0, 1), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3(-halfSize,  halfSize,  halfSize), Normal = Vector3(0, 1, 0), TexCoord = Vector2(0, 0), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3( halfSize,  halfSize,  halfSize), Normal = Vector3(0, 1, 0), TexCoord = Vector2(1, 0), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3( halfSize,  halfSize, -halfSize), Normal = Vector3(0, 1, 0), TexCoord = Vector2(1, 1), Color = Vector4.One },
            
            // Bottom face
            Mesh.Vertex { Position = Vector3(-halfSize, -halfSize, -halfSize), Normal = Vector3(0, -1, 0), TexCoord = Vector2(1, 1), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3( halfSize, -halfSize, -halfSize), Normal = Vector3(0, -1, 0), TexCoord = Vector2(0, 1), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3( halfSize, -halfSize,  halfSize), Normal = Vector3(0, -1, 0), TexCoord = Vector2(0, 0), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3(-halfSize, -halfSize,  halfSize), Normal = Vector3(0, -1, 0), TexCoord = Vector2(1, 0), Color = Vector4.One },
            
            // Right face
            Mesh.Vertex { Position = Vector3( halfSize, -halfSize, -halfSize), Normal = Vector3(1, 0, 0), TexCoord = Vector2(1, 0), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3( halfSize,  halfSize, -halfSize), Normal = Vector3(1, 0, 0), TexCoord = Vector2(1, 1), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3( halfSize,  halfSize,  halfSize), Normal = Vector3(1, 0, 0), TexCoord = Vector2(0, 1), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3( halfSize, -halfSize,  halfSize), Normal = Vector3(1, 0, 0), TexCoord = Vector2(0, 0), Color = Vector4.One },
            
            // Left face
            Mesh.Vertex { Position = Vector3(-halfSize, -halfSize, -halfSize), Normal = Vector3(-1, 0, 0), TexCoord = Vector2(0, 0), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3(-halfSize, -halfSize,  halfSize), Normal = Vector3(-1, 0, 0), TexCoord = Vector2(1, 0), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3(-halfSize,  halfSize,  halfSize), Normal = Vector3(-1, 0, 0), TexCoord = Vector2(1, 1), Color = Vector4.One },
            Mesh.Vertex { Position = Vector3(-halfSize,  halfSize, -halfSize), Normal = Vector3(-1, 0, 0), TexCoord = Vector2(0, 1), Color = Vector4.One }
        );
        
        var indices = new uint32[]
        (
            0,  1,  2,    0,  2,  3,    // front
            4,  5,  6,    4,  6,  7,    // back
            8,  9,  10,   8,  10, 11,   // top
            12, 13, 14,   12, 14, 15,   // bottom
            16, 17, 18,   16, 18, 19,   // right
            20, 21, 22,   20, 22, 23    // left
        );
        
        return new Mesh(vertices, indices);
    }
    
	public static Mesh CreatePlane(float width = 1.0f, float height = 1.0f, uint32 widthSegments = 1, uint32 heightSegments = 1)
	{
	    var vertices = scope List<Mesh.Vertex>();
	    var indices = scope List<uint32>();
	    
	    // Generate vertices
	    for (uint32 y = 0; y <= heightSegments; y++)
	    {
	        for (uint32 x = 0; x <= widthSegments; x++)
	        {
	            var u = (float)x / widthSegments;
	            var v = (float)y / heightSegments;
	            
	            var vertex = Mesh.Vertex
	            {
	                Position = Vector3(
	                    (u - 0.5f) * width,
	                    0.0f,
	                    (v - 0.5f) * height
	                ),
	                Normal = Vector3.Up,
	                TexCoord = Vector2(u, v),
	                Color = Vector4.One
	            };
	            
	            vertices.Add(vertex);
	        }
	    }
	    
	    // Generate indices
	    for (uint32 y = 0; y < heightSegments; y++)
	    {
	        for (uint32 x = 0; x < widthSegments; x++)
	        {
	            var a = (y + 0) * (widthSegments + 1) + (x + 0);
	            var b = (y + 1) * (widthSegments + 1) + (x + 0);
	            var c = (y + 1) * (widthSegments + 1) + (x + 1);
	            var d = (y + 0) * (widthSegments + 1) + (x + 1);
	            
	            // First triangle
	            indices.Add(a);
	            indices.Add(b);
	            indices.Add(d);
	            
	            // Second triangle
	            indices.Add(b);
	            indices.Add(c);
	            indices.Add(d);
	        }
	    }
	    
	    var vertexArray = new Mesh.Vertex[vertices.Count];
	    vertices.CopyTo(vertexArray);
	    
	    var indexArray = new uint32[indices.Count];
	    indices.CopyTo(indexArray);
	    
	    return new Mesh(vertexArray, indexArray);
	}
    
    public static Mesh CreateSphere(float radius = 1.0f, uint32 rings = 16, uint32 sectors = 32)
    {
        var vertices = scope List<Mesh.Vertex>();
        var indices = scope List<uint32>();
        
        float R = 1.0f / (rings - 1);
        float S = 1.0f / (sectors - 1);
        
        // Generate vertices
        for (uint32 r = 0; r < rings; r++)
        {
            for (uint32 s = 0; s < sectors; s++)
            {
                var y = Math.Sin(-Math.PI_f / 2 + Math.PI_f * r * R);
                var x = Math.Cos(2 * Math.PI_f * s * S) * Math.Sin(Math.PI_f * r * R);
                var z = Math.Sin(2 * Math.PI_f * s * S) * Math.Sin(Math.PI_f * r * R);
                
                var vertex = Mesh.Vertex
                {
                    Position = Vector3(x, y, z) * radius,
                    Normal = Vector3(x, y, z),
                    TexCoord = Vector2(s * S, r * R),
                    Color = Vector4.One
                };
                
                vertices.Add(vertex);
            }
        }
        
        // Generate indices
        for (uint32 r = 0; r < rings - 1; r++)
        {
            for (uint32 s = 0; s < sectors - 1; s++)
            {
                var curRow = r * sectors;
                var nextRow = (r + 1) * sectors;
                
                indices.Add(curRow + s);
                indices.Add(nextRow + s);
                indices.Add(nextRow + (s + 1));
                
                indices.Add(curRow + s);
                indices.Add(nextRow + (s + 1));
                indices.Add(curRow + (s + 1));
            }
        }
        
        var vertexArray = new Mesh.Vertex[vertices.Count];
        vertices.CopyTo(vertexArray);
        
        var indexArray = new uint32[indices.Count];
        indices.CopyTo(indexArray);
        
        return new Mesh(vertexArray, indexArray);
    }
    
    public static Texture CreateSolidColorTexture(uint32 width, uint32 height, Color color)
    {
        var data = new uint8[width * height * 4];
        
        var r = (uint8)(color.R * 255);
        var g = (uint8)(color.G * 255);
        var b = (uint8)(color.B * 255);
        var a = (uint8)(color.A * 255);
        
        for (int i = 0; i < data.Count; i += 4)
        {
            data[i] = r;
            data[i + 1] = g;
            data[i + 2] = b;
            data[i + 3] = a;
        }
        
        return new Texture(width, height, .RGBA8, data);
    }
    
    public static Texture CreateCheckerboardTexture(uint32 width, uint32 height, uint32 checkerSize = 16)
    {
        var data = new uint8[width * height * 4];
        
        for (uint32 y = 0; y < height; y++)
        {
            for (uint32 x = 0; x < width; x++)
            {
                var checkX = (x / checkerSize) % 2;
                var checkY = (y / checkerSize) % 2;
                var isWhite = (checkX + checkY) % 2 == 0;
                
                var colorValue = isWhite ? (uint8)255 : (uint8)64;
                
                var index = (y * width + x) * 4;
                data[index] = colorValue;     // R
                data[index + 1] = colorValue; // G
                data[index + 2] = colorValue; // B
                data[index + 3] = 255;        // A
            }
        }
        
        return new Texture(width, height, .RGBA8, data);
    }
}