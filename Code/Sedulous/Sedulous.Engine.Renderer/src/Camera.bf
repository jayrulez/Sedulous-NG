using Sedulous.Mathematics;
using Sedulous.SceneGraph;
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
	    return Matrix.CreateLookAt(
	        Entity.Transform.Position,
	        Entity.Transform.Position + Entity.Transform.Forward,
	        Entity.Transform.Up
	    );
	}

	private Matrix CalculateProjectionMatrix()
	{
	    return Matrix.CreatePerspectiveFieldOfView(
	        Radians.FromDegrees(FieldOfView),
	        AspectRatio,
	        NearPlane,
	        FarPlane
	    );
	}
}