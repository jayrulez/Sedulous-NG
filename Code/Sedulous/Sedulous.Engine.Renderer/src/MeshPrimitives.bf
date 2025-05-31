using Sedulous.Foundation.Mathematics;
using System;
using System.Collections;
namespace Sedulous.Engine.Renderer;

static class MeshPrimitives
{
    public static TextureResource CreateSolidColorTexture(uint32 width, uint32 height, Color color)
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
        
        return new TextureResource(width, height, .RGBA8, data);
    }
    
    public static TextureResource CreateCheckerboardTexture(uint32 width, uint32 height, uint32 checkerSize = 16)
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
        
        return new TextureResource(width, height, .RGBA8, data);
    }
}