using System;
using System.Collections;
using Sedulous.Engine.Core.Resources;
namespace Sedulous.Engine.Renderer;

class Shader : Resource
{
    public enum ShaderStage
    {
        Vertex,
        Fragment,
        Geometry,
        Compute
    }

    private Dictionary<ShaderStage, uint8[]> mShaderCode = new .() ~ delete _;
    private String mName = new .() ~ delete _;

    public StringView Name => mName;

    public this(StringView name)
    {
        Id = Guid.Create();
        mName.Set(name);
    }

    public ~this()
    {
        for (var codeEntry in mShaderCode)
        {
            delete codeEntry.value;
        }
    }

    public void SetShaderCode(ShaderStage stage, uint8[] code)
    {
        if (mShaderCode.ContainsKey(stage))
        {
            delete mShaderCode[stage];
        }

        var codeCopy = new uint8[code.Count];
        code.CopyTo(codeCopy);
        mShaderCode[stage] = codeCopy;
    }

    public Span<uint8> GetShaderCode(ShaderStage stage)
    {
        if (mShaderCode.TryGetValue(stage, var code))
        {
            return code;
        }
        return .();
    }

    public bool HasStage(ShaderStage stage)
    {
        return mShaderCode.ContainsKey(stage);
    }
}