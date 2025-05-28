using Sedulous.Foundation.Mathematics;
using System.Collections;
using System;
namespace Sedulous.Geometry;

public class Mesh
{
	private VertexBuffer mVertexBuffer ~ delete _;
	private IndexBuffer mIndexBuffer ~ delete _;
	private List<SubMesh> mSubMeshes ~ delete _;
	private BoundingBox mBounds;
	private bool mBoundsDirty = true;

	// Common vertex data accessors
	private int32 mPositionOffset = -1;
	private int32 mNormalOffset = -1;
	private int32 mUVOffset = -1;
	private int32 mColorOffset = -1;

	public VertexBuffer Vertices => mVertexBuffer;
	public IndexBuffer Indices => mIndexBuffer;
	public List<SubMesh> SubMeshes => mSubMeshes;

	public this()
	{
		mSubMeshes = new List<SubMesh>();
	}

	// Initialize with a specific vertex format
	public void Initialize(int32 vertexSize, IndexBuffer.IndexFormat indexFormat = .UInt16)
	{
		delete mVertexBuffer;
		delete mIndexBuffer;

		mVertexBuffer = new VertexBuffer(vertexSize);
		mIndexBuffer = new IndexBuffer(indexFormat);
	}

	// Common vertex format setup (position, normal, uv, color)
	public void SetupCommonVertexFormat()
	{
		Initialize(sizeof(Vector3) + sizeof(Vector3) + sizeof(Vector2) + sizeof(uint32));

		mPositionOffset = 0;
		mVertexBuffer.AddAttribute("position", .Vec3, mPositionOffset, sizeof(Vector3));

		mNormalOffset = sizeof(Vector3);
		mVertexBuffer.AddAttribute("normal", .Vec3, mNormalOffset, sizeof(Vector3));

		mUVOffset = sizeof(Vector3) * 2;
		mVertexBuffer.AddAttribute("uv", .Vec2, mUVOffset, sizeof(Vector2));

		mColorOffset = sizeof(Vector3) * 2 + sizeof(Vector2);
		mVertexBuffer.AddAttribute("color", .Color32, mColorOffset, sizeof(uint32));
	}

	// Vertex data helpers
	public void SetPosition(int32 vertexIndex, Vector3 position)
	{
		if (mPositionOffset >= 0)
		{
			mVertexBuffer.SetVertexData(vertexIndex, mPositionOffset, position);
			mBoundsDirty = true;
		}
	}

	public Vector3 GetPosition(int32 vertexIndex)
	{
		if (mPositionOffset >= 0)
			return mVertexBuffer.GetVertexData<Vector3>(vertexIndex, mPositionOffset);
		return .Zero;
	}

	public void SetNormal(int32 vertexIndex, Vector3 normal)
	{
		if (mNormalOffset >= 0)
			mVertexBuffer.SetVertexData(vertexIndex, mNormalOffset, normal);
	}

	public void SetUV(int32 vertexIndex, Vector2 uv)
	{
		if (mUVOffset >= 0)
			mVertexBuffer.SetVertexData(vertexIndex, mUVOffset, uv);
	}

	public void SetColor(int32 vertexIndex, uint32 color)
	{
		if (mColorOffset >= 0)
			mVertexBuffer.SetVertexData(vertexIndex, mColorOffset, color);
	}

	// Direct vertex buffer access for custom formats
	public void SetVertexAttribute<T>(int32 vertexIndex, int32 attributeOffset, T value) where T : struct
	{
		mVertexBuffer.SetVertexData(vertexIndex, attributeOffset, value);
	}

	public T GetVertexAttribute<T>(int32 vertexIndex, int32 attributeOffset) where T : struct
	{
		return mVertexBuffer.GetVertexData<T>(vertexIndex, attributeOffset);
	}

	// Add a sub-mesh
	public void AddSubMesh(SubMesh subMesh)
	{
		mSubMeshes.Add(subMesh);
	}

	// Compute bounds
	public BoundingBox GetBounds()
	{
		if (mBoundsDirty && mPositionOffset >= 0)
		{
			if (mVertexBuffer.VertexCount > 0)
			{
				Vector3 firstPos = GetPosition(0);
				mBounds = BoundingBox(firstPos, firstPos);

				for (int32 i = 1; i < mVertexBuffer.VertexCount; i++)
				{
					mBounds.Expand(GetPosition(i));
				}
			}
			else
			{
				mBounds = BoundingBox(.Zero, .Zero);
			}
			mBoundsDirty = false;
		}
		return mBounds;
	}

	// Create a simple triangle mesh
	public static Mesh CreateTriangle()
	{
		let mesh = new Mesh();
		mesh.SetupCommonVertexFormat();

		mesh.Vertices.Resize(3);
		mesh.Indices.Resize(3);

		// Vertices
		mesh.SetPosition(0, .(-1, -1, 0));
		mesh.SetPosition(1, .(1, -1, 0));
		mesh.SetPosition(2, .(0, 1, 0));

		mesh.SetNormal(0, .(0, 0, 1));
		mesh.SetNormal(1, .(0, 0, 1));
		mesh.SetNormal(2, .(0, 0, 1));

		mesh.SetUV(0, .(0, 1));
		mesh.SetUV(1, .(1, 1));
		mesh.SetUV(2, .(0.5f, 0));

		// Indices
		mesh.Indices.SetIndex(0, 0);
		mesh.Indices.SetIndex(1, 1);
		mesh.Indices.SetIndex(2, 2);

		// Sub-mesh
		mesh.AddSubMesh(SubMesh(0, 3));

		return mesh;
	}

	// Create a quad mesh
	public static Mesh CreateQuad(float width = 1.0f, float height = 1.0f)
	{
		let mesh = new Mesh();
		mesh.SetupCommonVertexFormat();

		mesh.Vertices.Resize(4);
		mesh.Indices.Resize(6);

		float hw = width * 0.5f;
		float hh = height * 0.5f;

		// Vertices
		mesh.SetPosition(0, .(-hw, -hh, 0));
		mesh.SetPosition(1, .(hw, -hh, 0));
		mesh.SetPosition(2, .(hw, hh, 0));
		mesh.SetPosition(3, .(-hw, hh, 0));

		for (int32 i = 0; i < 4; i++)
			mesh.SetNormal(i, .(0, 0, 1));

		mesh.SetUV(0, .(0, 1));
		mesh.SetUV(1, .(1, 1));
		mesh.SetUV(2, .(1, 0));
		mesh.SetUV(3, .(0, 0));

		// Indices
		mesh.Indices.SetIndex(0, 0);
		mesh.Indices.SetIndex(1, 1);
		mesh.Indices.SetIndex(2, 2);
		mesh.Indices.SetIndex(3, 0);
		mesh.Indices.SetIndex(4, 2);
		mesh.Indices.SetIndex(5, 3);

		mesh.AddSubMesh(SubMesh(0, 6));

		return mesh;
	}

	// Create a cube mesh
	public static Mesh CreateCube(float size = 1.0f)
	{
		let mesh = new Mesh();
		mesh.SetupCommonVertexFormat();

		// 24 vertices (4 per face, no sharing due to different normals)
		mesh.Vertices.Resize(24);
		mesh.Indices.Resize(36);

		float h = size * 0.5f;

		// Positions and normals for each face
		Vector3[24] positions = .( // Front face
			.(-h, -h, h), .(h, -h, h), .(h, h, h), .(-h, h, h), // Back face
			.(h, -h, -h), .(-h, -h, -h), .(-h, h, -h), .(h, h, -h), // Top face
			.(-h, h, h), .(h, h, h), .(h, h, -h), .(-h, h, -h), // Bottom face
			.(-h, -h, -h), .(h, -h, -h), .(h, -h, h), .(-h, -h, h), // Right face
			.(h, -h, h), .(h, -h, -h), .(h, h, -h), .(h, h, h), // Left face
			.(-h, -h, -h), .(-h, -h, h), .(-h, h, h), .(-h, h, -h)
			);

		Vector3[6] normals = .(
			.(0, 0, 1), // Front
			.(0, 0, -1), // Back
			.(0, 1, 0), // Top
			.(0, -1, 0), // Bottom
			.(1, 0, 0), // Right
			.(-1, 0, 0) // Left
			);

		// Set vertices
		for (int32 i = 0; i < 24; i++)
		{
			mesh.SetPosition(i, positions[i]);
			mesh.SetNormal(i, normals[i / 4]);

			// Simple UV mapping
			int32 faceVertex = i % 4;
			switch (faceVertex)
			{
			case 0: mesh.SetUV(i, .(0, 1));
			case 1: mesh.SetUV(i, .(1, 1));
			case 2: mesh.SetUV(i, .(1, 0));
			case 3: mesh.SetUV(i, .(0, 0));
			}
		}

		// Set indices
		int32 idx = 0;
		for (int32 face = 0; face < 6; face++)
		{
			int32 baseVertex = face * 4;
			mesh.Indices.SetIndex(idx++, (uint32)(baseVertex + 0));
			mesh.Indices.SetIndex(idx++, (uint32)(baseVertex + 1));
			mesh.Indices.SetIndex(idx++, (uint32)(baseVertex + 2));
			mesh.Indices.SetIndex(idx++, (uint32)(baseVertex + 0));
			mesh.Indices.SetIndex(idx++, (uint32)(baseVertex + 2));
			mesh.Indices.SetIndex(idx++, (uint32)(baseVertex + 3));
		}

		mesh.AddSubMesh(SubMesh(0, 36));

		return mesh;
	}

	// Create a sphere mesh
	public static Mesh CreateSphere(float radius = 0.5f, int32 segments = 32, int32 rings = 16)
	{
		let mesh = new Mesh();
		mesh.SetupCommonVertexFormat();

		int32 vertexCount = (rings + 1) * (segments + 1);
		int32 indexCount = rings * segments * 6;

		mesh.Vertices.Resize(vertexCount);
		mesh.Indices.Resize(indexCount);

		// Generate vertices
		int32 v = 0;
		for (int32 y = 0; y <= rings; y++)
		{
			float ringAngle = Math.PI_f * y / rings;
			float ringRadius = Math.Sin(ringAngle);
			float ringY = Math.Cos(ringAngle);

			for (int32 x = 0; x <= segments; x++)
			{
				float segmentAngle = 2.0f * Math.PI_f * x / segments;

				Vector3 pos = .(
					Math.Cos(segmentAngle) * ringRadius * radius,
					ringY * radius,
					Math.Sin(segmentAngle) * ringRadius * radius
					);

				mesh.SetPosition(v, pos);
				mesh.SetNormal(v, .(pos.X / radius, pos.Y / radius, pos.Z / radius));
				mesh.SetUV(v, .((float)x / segments, (float)y / rings));
				v++;
			}
		}

		// Generate indices
		int32 idx = 0;
		for (int32 y = 0; y < rings; y++)
		{
			for (int32 x = 0; x < segments; x++)
			{
				int32 a = y * (segments + 1) + x;
				int32 b = a + 1;
				int32 c = a + segments + 1;
				int32 d = c + 1;

				mesh.Indices.SetIndex(idx++, (uint32)a);
				mesh.Indices.SetIndex(idx++, (uint32)c);
				mesh.Indices.SetIndex(idx++, (uint32)b);
				mesh.Indices.SetIndex(idx++, (uint32)b);
				mesh.Indices.SetIndex(idx++, (uint32)c);
				mesh.Indices.SetIndex(idx++, (uint32)d);
			}
		}

		mesh.AddSubMesh(SubMesh(0, indexCount));

		return mesh;
	}

	// Create a cylinder mesh
	public static Mesh CreateCylinder(float radius = 0.5f, float height = 1.0f, int32 segments = 32)
	{
		let mesh = new Mesh();
		mesh.SetupCommonVertexFormat();

		// Vertices: top center + top ring + bottom ring + bottom center + sides
		int32 vertexCount = 2 + segments * 4; // centers + 2 rings * 2 (for caps and sides)
		int32 indexCount = segments * 12; // top + bottom + sides

		mesh.Vertices.Resize(vertexCount);
		mesh.Indices.Resize(indexCount);

		float halfHeight = height * 0.5f;
		int32 v = 0;

		// Top center
		mesh.SetPosition(v, .(0, halfHeight, 0));
		mesh.SetNormal(v, .(0, 1, 0));
		mesh.SetUV(v, .(0.5f, 0.5f));
		v++;

		// Top ring (for cap)
		for (int32 i = 0; i < segments; i++)
		{
			float angle = 2.0f * Math.PI_f * i / segments;
			float x = Math.Cos(angle) * radius;
			float z = Math.Sin(angle) * radius;

			mesh.SetPosition(v, .(x, halfHeight, z));
			mesh.SetNormal(v, .(0, 1, 0));
			mesh.SetUV(v, .(x / radius * 0.5f + 0.5f, z / radius * 0.5f + 0.5f));
			v++;
		}

		// Bottom center
		mesh.SetPosition(v, .(0, -halfHeight, 0));
		mesh.SetNormal(v, .(0, -1, 0));
		mesh.SetUV(v, .(0.5f, 0.5f));
		v++;

		// Bottom ring (for cap)
		for (int32 i = 0; i < segments; i++)
		{
			float angle = 2.0f * Math.PI_f * i / segments;
			float x = Math.Cos(angle) * radius;
			float z = Math.Sin(angle) * radius;

			mesh.SetPosition(v, .(x, -halfHeight, z));
			mesh.SetNormal(v, .(0, -1, 0));
			mesh.SetUV(v, .(x / radius * 0.5f + 0.5f, z / radius * 0.5f + 0.5f));
			v++;
		}

		// Side vertices (duplicated for proper normals and UVs)
		int32 sideStart = v;
		for (int32 i = 0; i <= segments; i++)
		{
			float angle = 2.0f * Math.PI_f * i / segments;
			float x = Math.Cos(angle) * radius;
			float z = Math.Sin(angle) * radius;
			Vector3 normal = .(x / radius, 0, z / radius);

			// Top vertex
			mesh.SetPosition(v, .(x, halfHeight, z));
			mesh.SetNormal(v, normal);
			mesh.SetUV(v, .((float)i / segments, 0));
			v++;

			// Bottom vertex
			mesh.SetPosition(v, .(x, -halfHeight, z));
			mesh.SetNormal(v, normal);
			mesh.SetUV(v, .((float)i / segments, 1));
			v++;
		}

		// Generate indices
		int32 idx = 0;

		// Top cap
		for (int32 i = 0; i < segments; i++)
		{
			mesh.Indices.SetIndex(idx++, 0); // center
			mesh.Indices.SetIndex(idx++, (uint32)(1 + (uint32)i));
			mesh.Indices.SetIndex(idx++, (uint32)(1 + ((uint32)i + 1) % (uint32)segments));
		}

		// Bottom cap
		int32 bottomCenterIdx = 1 + segments;
		for (int32 i = 0; i < segments; i++)
		{
			mesh.Indices.SetIndex(idx++, (uint32)bottomCenterIdx); // center
			mesh.Indices.SetIndex(idx++, (uint32)(bottomCenterIdx + 1 + (i + 1) % segments));
			mesh.Indices.SetIndex(idx++, (uint32)(bottomCenterIdx + 1 + i));
		}

		// Sides
		for (int32 i = 0; i < segments; i++)
		{
			int32 topLeft = sideStart + i * 2;
			int32 bottomLeft = topLeft + 1;
			int32 topRight = topLeft + 2;
			int32 bottomRight = topRight + 1;

			mesh.Indices.SetIndex(idx++, (uint32)topLeft);
			mesh.Indices.SetIndex(idx++, (uint32)bottomLeft);
			mesh.Indices.SetIndex(idx++, (uint32)topRight);
			mesh.Indices.SetIndex(idx++, (uint32)topRight);
			mesh.Indices.SetIndex(idx++, (uint32)bottomLeft);
			mesh.Indices.SetIndex(idx++, (uint32)bottomRight);
		}

		mesh.AddSubMesh(SubMesh(0, indexCount));

		return mesh;
	}

	// Create a cone mesh
	public static Mesh CreateCone(float radius = 0.5f, float height = 1.0f, int32 segments = 32)
	{
		let mesh = new Mesh();
		mesh.SetupCommonVertexFormat();

		int32 vertexCount = 1 + segments * 2 + 1; // tip + base ring + base center
		int32 indexCount = segments * 6; // sides + base

		mesh.Vertices.Resize(vertexCount);
		mesh.Indices.Resize(indexCount);

		float halfHeight = height * 0.5f;
		int32 v = 0;

		// Tip vertex
		mesh.SetPosition(v, .(0, halfHeight, 0));
		mesh.SetNormal(v, .(0, 1, 0)); // Simplified normal
		mesh.SetUV(v, .(0.5f, 0));
		v++;

		// Base ring vertices (for sides)
		for (int32 i = 0; i < segments; i++)
		{
			float angle = 2.0f * Math.PI_f * i / segments;
			float x = Math.Cos(angle) * radius;
			float z = Math.Sin(angle) * radius;

			// Calculate proper normal for cone surface
			Vector3 normal = .(x, radius, z);
			float len = Math.Sqrt(normal.X * normal.X + normal.Y * normal.Y + normal.Z * normal.Z);
			normal.X /= len;
			normal.Y /= len;
			normal.Z /= len;

			mesh.SetPosition(v, .(x, -halfHeight, z));
			mesh.SetNormal(v, normal);
			mesh.SetUV(v, .((float)i / segments, 1));
			v++;
		}

		// Base center
		mesh.SetPosition(v, .(0, -halfHeight, 0));
		mesh.SetNormal(v, .(0, -1, 0));
		mesh.SetUV(v, .(0.5f, 0.5f));
		int32 baseCenterIdx = v;
		v++;

		// Base ring vertices (for bottom cap)
		for (int32 i = 0; i < segments; i++)
		{
			float angle = 2.0f * Math.PI_f * i / segments;
			float x = Math.Cos(angle) * radius;
			float z = Math.Sin(angle) * radius;

			mesh.SetPosition(v, .(x, -halfHeight, z));
			mesh.SetNormal(v, .(0, -1, 0));
			mesh.SetUV(v, .(x / radius * 0.5f + 0.5f, z / radius * 0.5f + 0.5f));
			v++;
		}

		// Generate indices
		int32 idx = 0;

		// Cone sides
		for (int32 i = 0; i < segments; i++)
		{
			mesh.Indices.SetIndex(idx++, 0); // tip
			mesh.Indices.SetIndex(idx++, (uint32)(1 + ((uint32)i + 1) % (uint32)segments));
			mesh.Indices.SetIndex(idx++, (uint32)(1 + (uint32)i));
		}

		// Base
		for (int32 i = 0; i < segments; i++)
		{
			mesh.Indices.SetIndex(idx++, (uint32)baseCenterIdx);
			mesh.Indices.SetIndex(idx++, (uint32)(baseCenterIdx + 1 + i));
			mesh.Indices.SetIndex(idx++, (uint32)(baseCenterIdx + 1 + (i + 1) % segments));
		}

		mesh.AddSubMesh(SubMesh(0, indexCount));

		return mesh;
	}

	// Create a torus mesh
	public static Mesh CreateTorus(float radius = 1.0f, float tubeRadius = 0.3f, int32 segments = 32, int32 tubeSegments = 16)
	{
		let mesh = new Mesh();
		mesh.SetupCommonVertexFormat();

		int32 vertexCount = (segments + 1) * (tubeSegments + 1);
		int32 indexCount = segments * tubeSegments * 6;

		mesh.Vertices.Resize(vertexCount);
		mesh.Indices.Resize(indexCount);

		// Generate vertices
		int32 v = 0;
		for (int32 i = 0; i <= segments; i++)
		{
			float u = (float)i / segments;
			float theta = u * 2.0f * Math.PI_f;
			float cosTheta = Math.Cos(theta);
			float sinTheta = Math.Sin(theta);

			for (int32 j = 0; j <= tubeSegments; j++)
			{
				float v2 = (float)j / tubeSegments;
				float phi = v2 * 2.0f * Math.PI_f;
				float cosPhi = Math.Cos(phi);
				float sinPhi = Math.Sin(phi);

				float x = (radius + tubeRadius * cosPhi) * cosTheta;
				float y = tubeRadius * sinPhi;
				float z = (radius + tubeRadius * cosPhi) * sinTheta;

				Vector3 position = .(x, y, z);
				Vector3 center = .(radius * cosTheta, 0, radius * sinTheta);
				Vector3 normal = position - center;
				float len = Math.Sqrt(normal.X * normal.X + normal.Y * normal.Y + normal.Z * normal.Z);
				normal.X /= len;
				normal.Y /= len;
				normal.Z /= len;

				mesh.SetPosition(v, position);
				mesh.SetNormal(v, normal);
				mesh.SetUV(v, .(u, v2));
				v++;
			}
		}

		// Generate indices
		int32 idx = 0;
		for (int32 i = 0; i < segments; i++)
		{
			for (int32 j = 0; j < tubeSegments; j++)
			{
				int32 a = i * (tubeSegments + 1) + j;
				int32 b = a + 1;
				int32 c = a + tubeSegments + 1;
				int32 d = c + 1;

				mesh.Indices.SetIndex(idx++, (uint32)a);
				mesh.Indices.SetIndex(idx++, (uint32)c);
				mesh.Indices.SetIndex(idx++, (uint32)b);
				mesh.Indices.SetIndex(idx++, (uint32)b);
				mesh.Indices.SetIndex(idx++, (uint32)c);
				mesh.Indices.SetIndex(idx++, (uint32)d);
			}
		}

		mesh.AddSubMesh(SubMesh(0, indexCount));

		return mesh;
	}

	// Create a plane mesh with subdivisions
	public static Mesh CreatePlane(float width = 10.0f, float depth = 10.0f, int32 widthSegments = 10, int32 depthSegments = 10)
	{
		let mesh = new Mesh();
		mesh.SetupCommonVertexFormat();

		int32 vertexCount = (widthSegments + 1) * (depthSegments + 1);
		int32 indexCount = widthSegments * depthSegments * 6;

		mesh.Vertices.Resize(vertexCount);
		mesh.Indices.Resize(indexCount);

		float halfWidth = width * 0.5f;
		float halfDepth = depth * 0.5f;
		float segmentWidth = width / widthSegments;
		float segmentDepth = depth / depthSegments;

		// Generate vertices
		int32 v = 0;
		for (int32 z = 0; z <= depthSegments; z++)
		{
			for (int32 x = 0; x <= widthSegments; x++)
			{
				float xPos = -halfWidth + x * segmentWidth;
				float zPos = -halfDepth + z * segmentDepth;

				mesh.SetPosition(v, .(xPos, 0, zPos));
				mesh.SetNormal(v, .(0, 1, 0));
				mesh.SetUV(v, .((float)x / widthSegments, (float)z / depthSegments));
				v++;
			}
		}

		// Generate indices
		int32 idx = 0;
		for (int32 z = 0; z < depthSegments; z++)
		{
			for (int32 x = 0; x < widthSegments; x++)
			{
				int32 a = z * (widthSegments + 1) + x;
				int32 b = a + 1;
				int32 c = a + widthSegments + 1;
				int32 d = c + 1;

				mesh.Indices.SetIndex(idx++, (uint32)a);
				mesh.Indices.SetIndex(idx++, (uint32)c);
				mesh.Indices.SetIndex(idx++, (uint32)b);
				mesh.Indices.SetIndex(idx++, (uint32)b);
				mesh.Indices.SetIndex(idx++, (uint32)c);
				mesh.Indices.SetIndex(idx++, (uint32)d);
			}
		}

		mesh.AddSubMesh(SubMesh(0, indexCount));

		return mesh;
	}

	// Example: Create mesh with custom vertex format
	public static Mesh CreateCustomFormatExample()
	{
		let mesh = new Mesh();

		// Custom format: Position (Vec3) + UV (Vec2) + Tangent (Vec3) + Bitangent (Vec3)
		int32 vertexSize = sizeof(Vector3) + sizeof(Vector2) + sizeof(Vector3) + sizeof(Vector3);
		mesh.Initialize(vertexSize, .UInt16);

		// Define attribute offsets
		int32 posOffset = 0;
		int32 uvOffset = sizeof(Vector3);
		int32 tangentOffset = sizeof(Vector3) + sizeof(Vector2);
		int32 bitangentOffset = sizeof(Vector3) + sizeof(Vector2) + sizeof(Vector3);

		// Add attributes for debugging/tooling
		mesh.Vertices.AddAttribute("position", .Vec3, posOffset, sizeof(Vector3));
		mesh.Vertices.AddAttribute("uv", .Vec2, uvOffset, sizeof(Vector2));
		mesh.Vertices.AddAttribute("tangent", .Vec3, tangentOffset, sizeof(Vector3));
		mesh.Vertices.AddAttribute("bitangent", .Vec3, bitangentOffset, sizeof(Vector3));

		// Create a simple quad with custom format
		mesh.Vertices.Resize(4);
		mesh.Indices.Resize(6);

		// Set vertex data using direct access
		for (int32 i = 0; i < 4; i++)
		{
			// Position
			Vector3 pos = .Zero;
			switch (i)
			{
			case 0: pos = .(-1, 0, -1);
			case 1: pos = .(1, 0, -1);
			case 2: pos = .(1, 0, 1);
			case 3: pos = .(-1, 0, 1);
			}
			mesh.SetVertexAttribute(i, posOffset, pos);

			// UV
			Vector2 uv = .Zero;
			switch (i)
			{
			case 0: uv = .(0, 0);
			case 1: uv = .(1, 0);
			case 2: uv = .(1, 1);
			case 3: uv = .(0, 1);
			}
			mesh.SetVertexAttribute(i, uvOffset, uv);

			// Tangent & Bitangent (simplified for this example)
			mesh.SetVertexAttribute(i, tangentOffset, Vector3(1, 0, 0));
			mesh.SetVertexAttribute(i, bitangentOffset, Vector3(0, 0, 1));
		}

		// Set indices
		mesh.Indices.SetIndex(0, 0);
		mesh.Indices.SetIndex(1, 1);
		mesh.Indices.SetIndex(2, 2);
		mesh.Indices.SetIndex(3, 0);
		mesh.Indices.SetIndex(4, 2);
		mesh.Indices.SetIndex(5, 3);

		mesh.AddSubMesh(SubMesh(0, 6));

		return mesh;
	}
}