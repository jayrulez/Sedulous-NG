using Sedulous.Mathematics;
using Sedulous.SceneGraph;
using System;
namespace Sedulous.Engine.Renderer;

class Camera : Component
{
    private static ComponentTypeId sTypeId = ComponentRegistry.GetTypeId<Camera>();
    public override ComponentTypeId TypeId => sTypeId;
    
    public float FieldOfView = 60.0f;
    public float AspectRatio { get; set; } = 16.0f / 9.0f;
    public float NearPlane = 0.1f;
    public float FarPlane = 1000.0f;
    
    public Matrix ViewMatrix => CalculateViewMatrix();
    public Matrix ProjectionMatrix => CalculateProjectionMatrix();
    
    private Matrix CalculateViewMatrix()
    {
        // Since your Vector3.Forward is already (0,0,-1), 
        // the Transform.Forward is already pointing in the correct direction
        var transform = Entity.Transform;
        var position = transform.Position;
        var right = transform.Right;
        var up = transform.Up;
        var forward = transform.Forward; // This is already in -Z direction
        
        // View matrix is the inverse of the camera's world transform
        // For a right-handed system with -Z forward:
        return Matrix(
            right.X,    right.Y,    right.Z,    0,
            up.X,       up.Y,       up.Z,       0,
            -forward.X, -forward.Y, -forward.Z, 0,  // -forward = backward direction
            -Vector3.Dot(right, position), 
            -Vector3.Dot(up, position), 
            -Vector3.Dot(-forward, position),
            1
        );
    }
    
    private Matrix CalculateProjectionMatrix()
    {
        // Convert FOV to radians properly
        float fovRadians = FieldOfView * (Math.PI_f / 180.0f);
        
        // Check if your Matrix.CreatePerspectiveFieldOfView creates a right-handed or left-handed projection
        // If it's creating a left-handed projection, we need to flip it
        var projection = Matrix.CreatePerspectiveFieldOfView(
            fovRadians,
            AspectRatio,
            NearPlane,
            FarPlane
        );
        
        // Flip the X axis to convert from left-handed to right-handed
        // This is a common fix when the coordinate system is reversed
        projection.M11 *= -1;
        
        return projection;
    }
}