using Sedulous.Foundation.Mathematics;
namespace Sedulous.Engine.Renderer;

class Camera
{
	public Vector3 Position;
	public Vector3 Forward = Vector3.Forward;
	public Vector3 Up = Vector3.Up;

	public float FOV = 60.0f;
	public float AspectRatio = 16.0f / 9.0f;
	public float NearClip = 0.1f;
	public float FarClip = 100.0f;

	public Matrix ViewMatrix => Matrix.CreateLookAt(Position, Position + Forward, Up);

	public Matrix ProjectionMatrix => Matrix.CreatePerspectiveFieldOfView(Radians.FromDegrees(FOV), AspectRatio, NearClip, FarClip);
}