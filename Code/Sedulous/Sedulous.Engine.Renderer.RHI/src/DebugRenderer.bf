using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Mathematics;

namespace Sedulous.Engine.Renderer.RHI;

/// Simple debug renderer for drawing lines, rays, and shapes
/// Used for visualizing light directions, bounding boxes, etc.
class DebugRenderer
{
	private const int MAX_LINES = 4096;

	private GraphicsContext mGraphicsContext;
	private List<DebugLineVertex> mLineVertices = new .() ~ delete _;
	private Buffer mVertexBuffer;
	private Buffer mUniformBuffer;
	private bool mBuffersDirty = true;

	public this(GraphicsContext context)
	{
		mGraphicsContext = context;

		// Create dynamic vertex buffer
		var vertexBufferDesc = BufferDescription(
			(uint32)(sizeof(DebugLineVertex) * MAX_LINES * 2),
			.VertexBuffer,
			.Dynamic,
			.Write
		);
		mVertexBuffer = context.Factory.CreateBuffer(vertexBufferDesc);

		// Create uniform buffer with initial data to ensure valid descriptor
		var defaultUniforms = DebugUniforms() { ViewProjection = .Identity };
		var uniformBufferDesc = BufferDescription(
			sizeof(DebugUniforms),
			.ConstantBuffer,
			.Dynamic,
			.Write
		);
		mUniformBuffer = context.Factory.CreateBuffer(&defaultUniforms, uniformBufferDesc);
	}

	public ~this()
	{
		if (mVertexBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref mVertexBuffer);
		if (mUniformBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref mUniformBuffer);
	}

	public Buffer VertexBuffer => mVertexBuffer;
	public Buffer UniformBuffer => mUniformBuffer;
	public int LineCount => mLineVertices.Count / 2;

	/// Clear all debug primitives (call at start of frame)
	public void Clear()
	{
		mLineVertices.Clear();
		mBuffersDirty = true;
	}

	/// Draw a line between two points
	public void DrawLine(Vector3 start, Vector3 end, Color color)
	{
		if (mLineVertices.Count >= MAX_LINES * 2)
			return;

		mLineVertices.Add(.() { Position = start, Color = color });
		mLineVertices.Add(.() { Position = end, Color = color });
		mBuffersDirty = true;
	}

	/// Draw a ray from origin in direction
	public void DrawRay(Vector3 origin, Vector3 direction, float length, Color color)
	{
		DrawLine(origin, origin + direction * length, color);
	}

	/// Draw a directional light indicator (sun rays)
	public void DrawDirectionalLight(Vector3 direction, Vector3 sceneCenter, float radius, Color color)
	{
		// Normalize direction
		var dir = Vector3.Normalize(direction);

		// Position the "sun" behind the scene in the opposite direction of light
		var sunPos = sceneCenter - dir * radius * 2;

		// Draw main direction line
		DrawLine(sunPos, sceneCenter, color);

		// Draw radiating lines to show it's a directional light
		// Create perpendicular vectors
		var up = Math.Abs(dir.Y) < 0.99f ? Vector3.UnitY : Vector3.UnitX;
		var right = Vector3.Normalize(Vector3.Cross(up, dir));
		up = Vector3.Cross(dir, right);

		// Draw rays in a pattern
		float raySpacing = radius * 0.3f;
		for (int i = -1; i <= 1; i++)
		{
			for (int j = -1; j <= 1; j++)
			{
				if (i == 0 && j == 0) continue; // Skip center (already drawn)

				var offset = right * (i * raySpacing) + up * (j * raySpacing);
				var rayStart = sunPos + offset;
				var rayEnd = sceneCenter + offset;
				DrawLine(rayStart, rayEnd, color);
			}
		}

		// Draw a circle at the sun position
		DrawCircle(sunPos, dir, radius * 0.2f, color, 12);
	}

	/// Draw a circle in 3D space
	public void DrawCircle(Vector3 center, Vector3 normal, float radius, Color color, int segments = 16)
	{
		var n = Vector3.Normalize(normal);
		var up = Math.Abs(n.Y) < 0.99f ? Vector3.UnitY : Vector3.UnitX;
		var right = Vector3.Normalize(Vector3.Cross(up, n));
		up = Vector3.Cross(n, right);

		var prevPoint = center + right * radius;
		for (int i = 1; i <= segments; i++)
		{
			float angle = (i / (float)segments) * Math.PI_f * 2;
			var point = center + right * (Math.Cos(angle) * radius) + up * (Math.Sin(angle) * radius);
			DrawLine(prevPoint, point, color);
			prevPoint = point;
		}
	}

	/// Draw a wireframe box
	public void DrawBox(Vector3 min, Vector3 max, Color color)
	{
		// Bottom face
		DrawLine(.(min.X, min.Y, min.Z), .(max.X, min.Y, min.Z), color);
		DrawLine(.(max.X, min.Y, min.Z), .(max.X, min.Y, max.Z), color);
		DrawLine(.(max.X, min.Y, max.Z), .(min.X, min.Y, max.Z), color);
		DrawLine(.(min.X, min.Y, max.Z), .(min.X, min.Y, min.Z), color);

		// Top face
		DrawLine(.(min.X, max.Y, min.Z), .(max.X, max.Y, min.Z), color);
		DrawLine(.(max.X, max.Y, min.Z), .(max.X, max.Y, max.Z), color);
		DrawLine(.(max.X, max.Y, max.Z), .(min.X, max.Y, max.Z), color);
		DrawLine(.(min.X, max.Y, max.Z), .(min.X, max.Y, min.Z), color);

		// Vertical edges
		DrawLine(.(min.X, min.Y, min.Z), .(min.X, max.Y, min.Z), color);
		DrawLine(.(max.X, min.Y, min.Z), .(max.X, max.Y, min.Z), color);
		DrawLine(.(max.X, min.Y, max.Z), .(max.X, max.Y, max.Z), color);
		DrawLine(.(min.X, min.Y, max.Z), .(min.X, max.Y, max.Z), color);
	}

	/// Draw an arrow
	public void DrawArrow(Vector3 start, Vector3 end, Color color, float headSize = 0.1f)
	{
		DrawLine(start, end, color);

		var dir = Vector3.Normalize(end - start);
		var length = Vector3.Distance(start, end);
		var arrowHeadLength = Math.Min(headSize, length * 0.3f);

		// Create perpendicular vectors for arrow head
		var up = Math.Abs(dir.Y) < 0.99f ? Vector3.UnitY : Vector3.UnitX;
		var right = Vector3.Normalize(Vector3.Cross(up, dir));
		up = Vector3.Cross(dir, right);

		var headBase = end - dir * arrowHeadLength;
		var headWidth = arrowHeadLength * 0.5f;

		DrawLine(end, headBase + right * headWidth, color);
		DrawLine(end, headBase - right * headWidth, color);
		DrawLine(end, headBase + up * headWidth, color);
		DrawLine(end, headBase - up * headWidth, color);
	}

	/// Upload vertex data to GPU
	public void UpdateBuffers(CommandBuffer commandBuffer, Matrix viewProjection)
	{
		// Always update uniform buffer to ensure descriptor is valid
		var uniforms = DebugUniforms() { ViewProjection = viewProjection };
		commandBuffer.UpdateBufferData(mUniformBuffer, &uniforms, (uint32)sizeof(DebugUniforms));

		// Update vertex buffer only if we have lines
		if (mBuffersDirty && mLineVertices.Count > 0)
		{
			commandBuffer.UpdateBufferData(mVertexBuffer, mLineVertices.Ptr, (uint32)(mLineVertices.Count * sizeof(DebugLineVertex)));
			mBuffersDirty = false;
		}
	}
}
