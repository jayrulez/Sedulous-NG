using System;
namespace Sedulous.RHI.Renderer;

using System.Diagnostics;
using SDL3Native;
using Sedulous.RHI.Vulkan;
using Sedulous.Logging.Debug;
using Sedulous.Mathematics;
using Sedulous.Logging.Abstractions;
using Sedulous.Platform.SDL3;
using System.Collections;
using System.IO;

class Program
{
	private static Vector4[] VertexData = new Vector4[]
		( // TriangleList
		Vector4(0f, 0.5f, 0.0f, 1.0f), Vector4(1.0f, 0.0f, 0.0f, 1.0f),
		Vector4(0.5f, -0.5f, 0.0f, 1.0f), Vector4(0.0f, 1.0f, 0.0f, 1.0f),
		Vector4(-0.5f, -0.5f, 0.0f, 1.0f), Vector4(0.0f, 0.0f, 1.0f, 1.0f)
		) ~ delete _;

	public static void Main()
	{
		ILogger logger = scope DebugLogger(.Trace);
		var windowSystem = scope SDL3WindowSystem("RHI", 1280, 720);

		var window = windowSystem.PrimaryWindow;

		var graphicsContext = scope VKGraphicsContext(logger);
		defer graphicsContext.Dispose();

		graphicsContext.CreateDevice(scope ValidationLayer(logger));

		Sedulous.RHI.SurfaceInfo surfaceInfo = *(Sedulous.RHI.SurfaceInfo*)&window.SurfaceInfo;

		SwapChainDescription swapChainDescription = CreateSwapChainDescription((.)window.Width, (.)window.Height, ref surfaceInfo);
		var swapChain = graphicsContext.CreateSwapChain(swapChainDescription);
		defer graphicsContext.DestroySwapChain(ref swapChain);

		var commandQueue = graphicsContext.Factory.CreateCommandQueue();
		defer graphicsContext.Factory.DestroyCommandQueue(ref commandQueue);

		var viewports = scope Viewport[1](.(0, 0, window.Width, window.Height));
		var scissors = scope Rectangle[1]();
		window.OnResized.Add(scope (width, height) => {
			commandQueue.WaitIdle();
			viewports[0] = Viewport(0, 0, width, height);
			scissors[0] = Rectangle(0, 0, (.)width, (.)height);
			swapChain.ResizeSwapChain((.)width, (.)height);
		});

		// Compile Vertex and Pixel shaders
		uint8[] psBytes = null;
		uint8[] vsBytes = null;

		if (graphicsContext.BackendType == .Vulkan)
		{
			List<uint8> shaderBytes = scope .();
			if (File.ReadAll("Shaders/FragmentShader.spirv", shaderBytes) case .Err)
			{
				Runtime.FatalError("Failed to load pixel shader.");
			}
			psBytes = scope :: .[shaderBytes.Count];
			shaderBytes.CopyTo(psBytes);

			shaderBytes.Clear();
			if (File.ReadAll("Shaders/VertexShader.spirv", shaderBytes) case .Err)
			{
				Runtime.FatalError("Failed to load vertex shader.");
			}
			vsBytes = scope :: .[shaderBytes.Count];
			shaderBytes.CopyTo(vsBytes);
		}

		ShaderDescription vertexShaderDescription = ShaderDescription(.Vertex, "VS", vsBytes);
		ShaderDescription pixelShaderDescription = ShaderDescription(.Pixel, "PS", psBytes);

		Shader vertexShader = graphicsContext.Factory.CreateShader(vertexShaderDescription);
		defer graphicsContext.Factory.DestroyShader(ref vertexShader);

		Shader pixelShader = graphicsContext.Factory.CreateShader(pixelShaderDescription);
		defer graphicsContext.Factory.DestroyShader(ref pixelShader);

		BufferDescription vertexBufferDescription = BufferDescription((.)sizeof(Vector4) * (.)VertexData.Count, BufferFlags.VertexBuffer, ResourceUsage.Default);
		var vertexBuffer = graphicsContext.Factory.CreateBuffer(VertexData, vertexBufferDescription);
		defer graphicsContext.Factory.DestroyBuffer(ref vertexBuffer);

		// Prepare Pipeline
		var vertexLayouts = scope InputLayouts()
			.Add(scope LayoutDescription()
			.Add(ElementDescription(ElementFormat.Float4, ElementSemanticType.Position))
			.Add(ElementDescription(ElementFormat.Float4, ElementSemanticType.Color))
			);

		GraphicsPipelineDescription pipelineDescription = GraphicsPipelineDescription
			{
				PrimitiveTopology = PrimitiveTopology.TriangleList,
				InputLayouts = vertexLayouts,
				Shaders = GraphicsShaderStateDescription()
					{
						VertexShader = vertexShader,
						PixelShader = pixelShader
					},
				RenderStates = RenderStateDescription()
					{
						RasterizerState = RasterizerStates.CullBack,
						BlendState = BlendStates.Opaque,
						DepthStencilState = DepthStencilStates.ReadWrite
					},
				Outputs = swapChain.FrameBuffer.OutputDescription,
				ResourceLayouts = null
			};

		var graphicsPipelineState = graphicsContext.Factory.CreateGraphicsPipeline(pipelineDescription);
		defer graphicsContext.Factory.DestroyGraphicsPipeline(ref graphicsPipelineState);

		windowSystem.StartMainLoop();
		while (windowSystem.IsRunning)
		{
			windowSystem.RunOneFrame(scope (elapsedTime) => {
				CommandBuffer commandBuffer = commandQueue.CommandBuffer();

				commandBuffer.Begin();

				ClearValue clearValue = .(ClearFlags.All, 1, 0);
				clearValue.ColorValues.Count = swapChain.FrameBuffer.ColorTargets.Count;
				for(int i = 0; i < clearValue.ColorValues.Count; i++)
					clearValue.ColorValues[i] = Color.CornflowerBlue.ToVector4();

				RenderPassDescription renderPassDescription = RenderPassDescription(swapChain.FrameBuffer, clearValue);
				commandBuffer.BeginRenderPass(renderPassDescription);

				commandBuffer.SetViewports(viewports);
				commandBuffer.SetScissorRectangles(scissors);
				commandBuffer.SetGraphicsPipelineState(graphicsPipelineState);
				commandBuffer.SetVertexBuffers(scope Buffer[1](vertexBuffer));

				commandBuffer.Draw((.)VertexData.Count / 2);

				commandBuffer.EndRenderPass();
				commandBuffer.End();

				commandBuffer.Commit();

				commandQueue.Submit();
				commandQueue.WaitIdle();

				swapChain.Present();
			});
		}
		commandQueue.WaitIdle();
		windowSystem.StopMainLoop();
	}

	private static TextureSampleCount SampleCount = TextureSampleCount.None;

	private static SwapChainDescription CreateSwapChainDescription(uint32 width, uint32 height, ref SurfaceInfo surfaceInfo)
	{
		return SwapChainDescription()
			{
				Width = width,
				Height = height,
				SurfaceInfo = surfaceInfo,
				ColorTargetFormat = PixelFormat.R8G8B8A8_UNorm,
				ColorTargetFlags = TextureFlags.RenderTarget | TextureFlags.ShaderResource,
				DepthStencilTargetFormat = PixelFormat.D24_UNorm_S8_UInt,
				DepthStencilTargetFlags = TextureFlags.DepthStencil,
				SampleCount = SampleCount,
				IsWindowed = true,
				RefreshRate = 60
			};
	}
}