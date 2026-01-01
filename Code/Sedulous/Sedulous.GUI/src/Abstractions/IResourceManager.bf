using System;
namespace Sedulous.GUI;

interface IResourceManager
{
	Result<IUITexture> LoadTexture(StringView path);
	void UnloadTexture(IUITexture texture);
}