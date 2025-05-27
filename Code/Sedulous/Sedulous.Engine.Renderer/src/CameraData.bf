using Sedulous.Foundation.Mathematics;
using System;
namespace Sedulous.Engine.Renderer;

[CRepr]
struct CameraData
{
    public Matrix ViewMatrix;
    public Matrix ProjectionMatrix;
    public Matrix ViewProjectionMatrix;
    public Vector3 Position;
    public Vector3 Forward;
}