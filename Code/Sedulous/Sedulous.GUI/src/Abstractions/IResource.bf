namespace Sedulous.GUI;

using Sedulous.Mathematics;
using System;

interface IUITexture : IDisposable
{
	uint32 Width { get; }
	uint32 Height { get; }
	Size2F Size { get; }
}
