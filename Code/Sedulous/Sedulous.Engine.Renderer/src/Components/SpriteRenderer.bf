using Sedulous.SceneGraph;
using Sedulous.Resources;
using Sedulous.Mathematics;

namespace Sedulous.Engine.Renderer;

class SpriteRenderer : Component
{
    //private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<SpriteRenderer>();
    //public override ComponentTypeId TypeId => sTypeId;
    
    // Texture and appearance
    public ResourceHandle<TextureResource> Texture { get; set; } ~ _.Release();
    public Color Color { get; set; } = .White;
    
    // Sprite source rectangle (for sprite sheets)
    public Rectangle? SourceRect { get; set; } = null;  // null means use entire texture
    
    // Sprite pivot/anchor point (0,0 = top-left, 0.5,0.5 = center, 1,1 = bottom-right)
    public Vector2 Pivot { get; set; } = Vector2(0.5f, 0.5f);
    
    // Flip options
    public bool FlipX { get; set; } = false;
    public bool FlipY { get; set; } = false;
    
    // Size in world units (if null, uses texture pixel size)
    public Vector2? Size { get; set; } = null;
    
    // Sorting layer and order
    public int32 SortingLayer { get; set; } = 0;
    public int32 OrderInLayer { get; set; } = 0;
    
    // Billboard options (for 3D sprites)
    public enum BillboardMode
    {
        None,              // Normal sprite, no billboarding

        // Position-based: sprite faces camera's world position
        FacePosition,      // Face camera position (rotates when camera moves)
        FacePositionY,     // Face camera position, Y-axis only

        // View-aligned: sprite aligns with camera's view plane (screen-aligned)
        ViewAligned,       // Always flat on screen (rotates with camera view)
        ViewAlignedY       // Flat on screen horizontally, Y-axis constrained
    }
    public BillboardMode Billboard { get; set; } = .None;
    
    // Get the actual size to render
    public Vector2 GetRenderSize()
    {
        if (Size.HasValue)
            return Size.Value;
            
        // Use texture dimensions
        if (Texture.IsValid && Texture.Resource != null && Texture.Resource.Image != null)
        {
            var image = Texture.Resource.Image;
            
            if (SourceRect.HasValue)
            {
                return Vector2(SourceRect.Value.Width, SourceRect.Value.Height);
            }
            else
            {
                return Vector2((float)image.Width, (float)image.Height);
            }
        }
        
        return Vector2(1, 1); // Default size
    }
    
    // Get UV coordinates for the sprite
    public void GetUVs(out Vector2 uvMin, out Vector2 uvMax)
    {
        uvMin = Vector2(0, 0);
        uvMax = Vector2(1, 1);
        
        if (Texture.IsValid && Texture.Resource != null && Texture.Resource.Image != null && SourceRect.HasValue)
        {
            var image = Texture.Resource.Image;
            var rect = SourceRect.Value;
            
            uvMin.X = rect.X / (float)image.Width;
            uvMin.Y = rect.Y / (float)image.Height;
            uvMax.X = (rect.X + rect.Width) / (float)image.Width;
            uvMax.Y = (rect.Y + rect.Height) / (float)image.Height;
        }
        
        // Apply flipping
        if (FlipX)
        {
            var temp = uvMin.X;
            uvMin.X = uvMax.X;
            uvMax.X = temp;
        }
        
        if (FlipY)
        {
            var temp = uvMin.Y;
            uvMin.Y = uvMax.Y;
            uvMax.Y = temp;
        }
    }
}