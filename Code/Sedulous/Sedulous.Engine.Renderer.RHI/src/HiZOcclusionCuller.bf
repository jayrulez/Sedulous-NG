using Sedulous.Mathematics;
using System;

namespace Sedulous.Engine.Renderer.RHI;

/// Hi-Z (Hierarchical-Z) occlusion culler.
/// Tests bounding boxes against a hierarchical depth buffer to skip
/// rendering objects that are completely hidden behind other geometry.
class HiZOcclusionCuller
{
	private RHIRendererSubsystem mRenderer;
	private Matrix mPrevViewProjection;
	private bool mHasValidData = false;

	public this(RHIRendererSubsystem renderer)
	{
		mRenderer = renderer;
	}

	/// Store view-projection matrix for next frame's testing
	/// Must be called each frame with the current camera's VP matrix
	public void SetViewProjection(Matrix viewProjection)
	{
		mPrevViewProjection = viewProjection;
	}

	/// Update the culler's state at the start of each frame
	/// Call this before testing any bounding boxes
	public void BeginFrame()
	{
		mHasValidData = mRenderer.HiZDataValid;
	}

	/// Test if a bounding box is potentially visible.
	/// Returns true if the object should be rendered, false if definitely occluded.
	/// Uses previous frame's Hi-Z data (one frame latency).
	public bool TestBoundingBox(BoundingBox worldBounds)
	{
		// If no Hi-Z data available, assume visible
		if (!mHasValidData || mRenderer.HiZReadbackData == null)
			return true;

		uint32 hiZSize = mRenderer.HiZSize;
		float[] hiZData = mRenderer.HiZReadbackData;

		// Project bounding box corners to screen space
		Vector3[] corners = scope .[8];
		worldBounds.GetCorners(corners);

		float minX = float.MaxValue, maxX = float.MinValue;
		float minY = float.MaxValue, maxY = float.MinValue;
		float minZ = float.MaxValue;  // Nearest depth (closest to camera)

		for (int i = 0; i < 8; i++)
		{
			Vector4 clip = Vector4.Transform(Vector4(corners[i], 1.0f), mPrevViewProjection);

			// Behind camera check - if any corner is behind, assume visible
			if (clip.W <= 0.001f)
				return true;

			// Perspective divide to NDC
			float ndcX = clip.X / clip.W;
			float ndcY = clip.Y / clip.W;
			float ndcZ = clip.Z / clip.W;

			// Convert to screen space [0, 1]
			float screenX = ndcX * 0.5f + 0.5f;
			float screenY = -ndcY * 0.5f + 0.5f;  // Flip Y for texture coordinates

			minX = Math.Min(minX, screenX);
			maxX = Math.Max(maxX, screenX);
			minY = Math.Min(minY, screenY);
			maxY = Math.Max(maxY, screenY);
			minZ = Math.Min(minZ, ndcZ);  // Nearest point
		}

		// Clamp to screen bounds [0, 1]
		minX = Math.Clamp(minX, 0.0f, 1.0f);
		maxX = Math.Clamp(maxX, 0.0f, 1.0f);
		minY = Math.Clamp(minY, 0.0f, 1.0f);
		maxY = Math.Clamp(maxY, 0.0f, 1.0f);

		// Object completely outside screen
		if (minX >= maxX || minY >= maxY)
			return false;

		// Convert to Hi-Z texel coordinates
		int x0 = (int)(minX * (float)(hiZSize - 1));
		int x1 = (int)(maxX * (float)(hiZSize - 1));
		int y0 = (int)(minY * (float)(hiZSize - 1));
		int y1 = (int)(maxY * (float)(hiZSize - 1));

		// Clamp to valid range
		x0 = Math.Clamp(x0, 0, (int)(hiZSize - 1));
		x1 = Math.Clamp(x1, 0, (int)(hiZSize - 1));
		y0 = Math.Clamp(y0, 0, (int)(hiZSize - 1));
		y1 = Math.Clamp(y1, 0, (int)(hiZSize - 1));

		// Find max depth in the Hi-Z region covered by this object
		// Max depth = furthest from camera = conservative test
		float maxHiZDepth = 0.0f;
		for (int y = y0; y <= y1; y++)
		{
			for (int x = x0; x <= x1; x++)
			{
				float depth = hiZData[y * (int)hiZSize + x];
				maxHiZDepth = Math.Max(maxHiZDepth, depth);
			}
		}

		// Object is occluded if its nearest point is further than the max Hi-Z depth
		// (meaning everything in the Hi-Z region is closer to the camera than this object)
		bool isOccluded = minZ > maxHiZDepth;

		return !isOccluded;
	}
}
