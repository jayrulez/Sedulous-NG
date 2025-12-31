namespace Sedulous.RHI.HLSLShaderCompiler;

enum DxcShaderStage : uint32
{
    Vertex,
    Hull,
    Domain,
    Geometry,
    Pixel,
    Compute,
    Amplification,
    Mesh,
    Library,
    Count,
}