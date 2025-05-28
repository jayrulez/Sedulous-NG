using Sedulous.Resources;
using Sedulous.Foundation.Mathematics;
using System;
namespace Sedulous.Engine.Renderer;

class Mesh : Resource
{
    public struct Vertex
    {
        public Vector3 Position;
        public Vector3 Normal;
        public Vector2 TexCoord;
        public Vector4 Color;
    }

    private Vertex[] mVertices;
    private uint32[] mIndices;
    private BoundingBox mBounds;

    public Span<Vertex> Vertices => mVertices;
    public Span<uint32> Indices => mIndices;
    public BoundingBox Bounds => mBounds;

    public this(Vertex[] vertices, uint32[] indices)
    {
        Id = Guid.Create();
        mVertices = vertices;
        mIndices = indices;
        CalculateBounds();
    }

    public ~this()
    {
        delete mVertices;
        delete mIndices;
    }

    private void CalculateBounds()
    {
        if (mVertices.Count == 0)
        {
            mBounds = BoundingBox(.Zero, .Zero);
            return;
        }

        var min = mVertices[0].Position;
        var max = mVertices[0].Position;

        for (var vertex in mVertices)
        {
            min = Vector3.Min(min, vertex.Position);
            max = Vector3.Max(max, vertex.Position);
        }

        mBounds = BoundingBox(min, max);
    }
}