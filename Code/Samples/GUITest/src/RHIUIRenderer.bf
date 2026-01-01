namespace GUITest;

using Sedulous.GUI;
using Sedulous.Mathematics;
using Sedulous.RHI;
using Sedulous.RHI.HLSLShaderCompiler;
using System;
using System.Collections;

class RHIUIRenderer : IUIRenderer
{
	private GraphicsContext mGraphicsContext;
	private CommandQueue mCommandQueue;
	private SwapChain mSwapChain;
	private GraphicsPipelineState mPipeline;
	private Buffer mVertexBuffer;
	private Buffer mIndexBuffer;
	private Buffer mConstantBuffer;
	private ResourceSet mResourceSet;
	private ResourceLayout mResourceLayout;
	private Shader mVertexShader;
	private Shader mPixelShader;
	private CommandBuffer mCommandBuffer;

	private Size2F mViewportSize;
	private List<RectangleF> mClipStack = new .() ~ delete _;
	private List<Point2F> mTransformStack = new .() ~ delete _;
	private Point2F mCurrentTransform;

	// Batched vertices
	private List<UIVertex> mVertices = new .() ~ delete _;
	private List<uint16> mIndices = new .() ~ delete _;

	private const int MaxVertices = 65536;
	private const int MaxIndices = 65536 * 6 / 4;

	[CRepr]
	struct UIVertex
	{
		public Vector4 Position;
		public Vector4 Color;
		public Vector2 TexCoord;
	}

	[CRepr]
	struct Constants
	{
		public Matrix ProjectionMatrix;
	}

	public this(GraphicsContext graphicsContext, CommandQueue commandQueue, SwapChain swapChain)
	{
		mGraphicsContext = graphicsContext;
		mCommandQueue = commandQueue;
		mSwapChain = swapChain;

		CreateResources();
	}

	public ~this()
	{
		if (mResourceSet != null)
			mGraphicsContext.Factory.DestroyResourceSet(ref mResourceSet);
		if (mResourceLayout != null)
			mGraphicsContext.Factory.DestroyResourceLayout(ref mResourceLayout);
		if (mPipeline != null)
			mGraphicsContext.Factory.DestroyGraphicsPipeline(ref mPipeline);
		if (mVertexShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mVertexShader);
		if (mPixelShader != null)
			mGraphicsContext.Factory.DestroyShader(ref mPixelShader);
		if (mVertexBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref mVertexBuffer);
		if (mIndexBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref mIndexBuffer);
		if (mConstantBuffer != null)
			mGraphicsContext.Factory.DestroyBuffer(ref mConstantBuffer);
	}

	private void CreateResources()
	{
		// Create vertex buffer
		BufferDescription vbDesc = .((.)sizeof(UIVertex) * MaxVertices, .VertexBuffer, .Dynamic);
		mVertexBuffer = mGraphicsContext.Factory.CreateBuffer(null, vbDesc);

		// Create index buffer
		BufferDescription ibDesc = .((.)sizeof(uint16) * MaxIndices, .IndexBuffer, .Dynamic);
		mIndexBuffer = mGraphicsContext.Factory.CreateBuffer(null, ibDesc);

		// Create constant buffer
		BufferDescription cbDesc = .((.)sizeof(Constants), .ConstantBuffer, .Dynamic);
		mConstantBuffer = mGraphicsContext.Factory.CreateBuffer(null, cbDesc);

		// Compile shaders
		String shaderSource = """
			cbuffer Constants : register(b0) {
				row_major float4x4 ProjectionMatrix;
			};

			struct VSInput {
				float4 Position : POSITION;
				float4 Color : COLOR;
				float2 TexCoord : TEXCOORD0;
			};

			struct PSInput {
				float4 Position : SV_POSITION;
				float4 Color : COLOR;
				float2 TexCoord : TEXCOORD0;
			};

			PSInput VS(VSInput input) {
				PSInput output;
				output.Position = mul(float4(input.Position.xy, 0, 1), ProjectionMatrix);
				output.Color = input.Color;
				output.TexCoord = input.TexCoord;
				return output;
			}

			float4 PS(PSInput input) : SV_TARGET {
				return input.Color;
			}
			""";

		// Compile vertex shader
		List<uint8> vsBytes = scope .();
		String error = scope .();
		if (DxcShaderCompiler.CompileShader(mGraphicsContext, shaderSource, "VS", .Vertex, .Default, vsBytes, ref error) case .Err)
		{
			Console.WriteLine(scope $"Failed to compile vertex shader: {error}");
			return;
		}

		// Compile pixel shader
		List<uint8> psBytes = scope .();
		if (DxcShaderCompiler.CompileShader(mGraphicsContext, shaderSource, "PS", .Pixel, .Default, psBytes, ref error) case .Err)
		{
			Console.WriteLine(scope $"Failed to compile pixel shader: {error}");
			return;
		}

		// Create shader objects
		uint8[] vsBytesArr = scope .[vsBytes.Count];
		vsBytes.CopyTo(vsBytesArr);
		ShaderDescription vsDesc = .(.Vertex, "VS", vsBytesArr);
		mVertexShader = mGraphicsContext.Factory.CreateShader(vsDesc);

		uint8[] psBytesArr = scope .[psBytes.Count];
		psBytes.CopyTo(psBytesArr);
		ShaderDescription psDesc = .(.Pixel, "PS", psBytesArr);
		mPixelShader = mGraphicsContext.Factory.CreateShader(psDesc);

		// Create resource layout
		ResourceLayoutDescription layoutDesc = .(
			LayoutElementDescription(0, .ConstantBuffer, .Vertex)
		);
		mResourceLayout = mGraphicsContext.Factory.CreateResourceLayout(layoutDesc);

		// Create resource set
		ResourceSetDescription rsDesc = .(mResourceLayout, mConstantBuffer);
		mResourceSet = mGraphicsContext.Factory.CreateResourceSet(rsDesc);

		// Create pipeline
		var vertexLayouts = scope InputLayouts()
			.Add(scope LayoutDescription()
			.Add(ElementDescription(.Float4, .Position))
			.Add(ElementDescription(.Float4, .Color))
			.Add(ElementDescription(.Float2, .TexCoord))
			);

		ResourceLayout[] resourceLayouts = scope .(mResourceLayout);

		GraphicsShaderStateDescription shaderState = .();
		shaderState.VertexShader = mVertexShader;
		shaderState.PixelShader = mPixelShader;

		RenderStateDescription renderStates = .();
		renderStates.RasterizerState = RasterizerStates.None;
		renderStates.BlendState = BlendStates.AlphaBlend;
		renderStates.DepthStencilState = DepthStencilStates.None;

		GraphicsPipelineDescription pipelineDesc = .(
			.TriangleList,
			vertexLayouts,
			resourceLayouts,
			shaderState,
			renderStates,
			mSwapChain.FrameBuffer.OutputDescription
		);

		mPipeline = mGraphicsContext.Factory.CreateGraphicsPipeline(pipelineDesc);
	}

	// === IUIRenderer Implementation ===

	public Size2F ViewportSize => mViewportSize;

	public void BeginFrame()
	{
		mViewportSize = .(mSwapChain.FrameBuffer.Width, mSwapChain.FrameBuffer.Height);
		mVertices.Clear();
		mIndices.Clear();
		mClipStack.Clear();
		mTransformStack.Clear();
		mCurrentTransform = .Zero;

		mCommandBuffer = mCommandQueue.CommandBuffer();
		mCommandBuffer.Begin();

		// Clear screen
		ClearValue clearValue = .(ClearFlags.All, 1, 0);
		clearValue.ColorValues.Count = mSwapChain.FrameBuffer.ColorTargets.Count;
		for (int i = 0; i < clearValue.ColorValues.Count; i++)
			clearValue.ColorValues[i] = Color(30, 30, 30, 255).ToVector4();

		RenderPassDescription renderPass = .(mSwapChain.FrameBuffer, clearValue);
		mCommandBuffer.BeginRenderPass(renderPass);

		let viewports = scope Viewport[1](.(0, 0, mViewportSize.Width, mViewportSize.Height));
		let scissors = scope Rectangle[1](.(0, 0, (.)mViewportSize.Width, (.)mViewportSize.Height));
		mCommandBuffer.SetViewports(viewports);
		mCommandBuffer.SetScissorRectangles(scissors);
	}

	public void EndFrame()
	{
		// Flush any remaining draw calls
		FlushBatch();

		mCommandBuffer.EndRenderPass();
		mCommandBuffer.End();
		mCommandBuffer.Commit();

		mCommandQueue.Submit();
		mCommandQueue.WaitIdle();

		mSwapChain.Present();
	}

	public void PushClipRect(RectangleF rect)
	{
		FlushBatch();

		// Transform the clip rect
		let transformed = RectangleF(
			rect.X + mCurrentTransform.X,
			rect.Y + mCurrentTransform.Y,
			rect.Width,
			rect.Height
		);

		// Intersect with current clip rect if any
		if (mClipStack.Count > 0)
		{
			let current = mClipStack[mClipStack.Count - 1];
			let intersection = IntersectRects(current, transformed);
			mClipStack.Add(intersection);
		}
		else
		{
			mClipStack.Add(transformed);
		}

		ApplyCurrentClip();
	}

	public void PopClipRect()
	{
		FlushBatch();

		if (mClipStack.Count > 0)
			mClipStack.PopBack();

		ApplyCurrentClip();
	}

	public void PushTransform(Point2F offset)
	{
		mTransformStack.Add(mCurrentTransform);
		mCurrentTransform.X += offset.X;
		mCurrentTransform.Y += offset.Y;
	}

	public void PopTransform()
	{
		if (mTransformStack.Count > 0)
			mCurrentTransform = mTransformStack.PopBack();
	}

	private void ApplyCurrentClip()
	{
		if (mClipStack.Count > 0)
		{
			let clip = mClipStack[mClipStack.Count - 1];
			let scissors = scope Rectangle[1](.(
				(.)Math.Max(0, clip.X), (.)Math.Max(0, clip.Y),
				(.)Math.Max(0, clip.Width), (.)Math.Max(0, clip.Height)
			));
			mCommandBuffer.SetScissorRectangles(scissors);
		}
		else
		{
			let scissors = scope Rectangle[1](.(0, 0, (.)mViewportSize.Width, (.)mViewportSize.Height));
			mCommandBuffer.SetScissorRectangles(scissors);
		}
	}

	private RectangleF IntersectRects(RectangleF a, RectangleF b)
	{
		let x1 = Math.Max(a.X, b.X);
		let y1 = Math.Max(a.Y, b.Y);
		let x2 = Math.Min(a.X + a.Width, b.X + b.Width);
		let y2 = Math.Min(a.Y + a.Height, b.Y + b.Height);

		if (x2 <= x1 || y2 <= y1)
			return .(0, 0, 0, 0);

		return .(x1, y1, x2 - x1, y2 - y1);
	}

	// === Drawing ===

	public void DrawLine(Point2F start, Point2F end, Color color, float thickness = 1.0f)
	{
		// Calculate perpendicular offset for line thickness
		let dx = end.X - start.X;
		let dy = end.Y - start.Y;
		let len = Math.Sqrt(dx * dx + dy * dy);
		if (len < 0.001f) return;

		let nx = -dy / len * thickness * 0.5f;
		let ny = dx / len * thickness * 0.5f;

		let p0 = Point2F(start.X + nx, start.Y + ny);
		let p1 = Point2F(start.X - nx, start.Y - ny);
		let p2 = Point2F(end.X - nx, end.Y - ny);
		let p3 = Point2F(end.X + nx, end.Y + ny);

		AddQuad(p0, p1, p2, p3, color);
	}

	public void DrawRectangle(RectangleF rect, Color color, float thickness = 1.0f)
	{
		let r = TransformRect(rect);

		// Top
		DrawLine(.(r.X, r.Y), .(r.X + r.Width, r.Y), color, thickness);
		// Bottom
		DrawLine(.(r.X, r.Y + r.Height), .(r.X + r.Width, r.Y + r.Height), color, thickness);
		// Left
		DrawLine(.(r.X, r.Y), .(r.X, r.Y + r.Height), color, thickness);
		// Right
		DrawLine(.(r.X + r.Width, r.Y), .(r.X + r.Width, r.Y + r.Height), color, thickness);
	}

	public void FillRectangle(RectangleF rect, Color color)
	{
		let r = TransformRect(rect);

		let p0 = Point2F(r.X, r.Y);
		let p1 = Point2F(r.X, r.Y + r.Height);
		let p2 = Point2F(r.X + r.Width, r.Y + r.Height);
		let p3 = Point2F(r.X + r.Width, r.Y);

		AddQuad(p0, p1, p2, p3, color);
	}

	public void DrawRoundedRectangle(RectangleF rect, Color color, float cornerRadius, float thickness = 1.0f)
	{
		// Simplified: just draw a regular rectangle for now
		DrawRectangle(rect, color, thickness);
	}

	public void FillRoundedRectangle(RectangleF rect, Color color, float cornerRadius)
	{
		// Simplified: just fill a regular rectangle for now
		FillRectangle(rect, color);
	}

	public void DrawText(StringView text, IFont font, Point2F position, Color color)
	{
		// Text rendering not implemented - would need glyph textures
		if (font == null) return;

		// Draw a placeholder rectangle for the text bounds
		let size = font.MeasureString(text);
		let r = TransformRect(.(position.X, position.Y, size.Width, size.Height));
		// For now, just skip text (can't render without glyph atlas)
	}

	public void DrawText(StringView text, IFont font, RectangleF bounds, Color color,
						  TextAlignment alignment = .Left, TextWrapping wrapping = .NoWrap)
	{
		if (font == null) return;
		// Text rendering not implemented
	}

	public void DrawImage(IUITexture texture, RectangleF destRect, Color tint = .White)
	{
		// Image rendering not implemented yet
		FillRectangle(destRect, tint);
	}

	public void DrawImage(IUITexture texture, RectangleF destRect, RectangleF sourceRect, Color tint = .White)
	{
		DrawImage(texture, destRect, tint);
	}

	public void DrawNineSlice(IUITexture texture, RectangleF destRect, Thickness sliceMargins, Color tint = .White)
	{
		// Nine-slice not implemented yet
		FillRectangle(destRect, tint);
	}

	// === Batching ===

	private RectangleF TransformRect(RectangleF rect)
	{
		return .(
			rect.X + mCurrentTransform.X,
			rect.Y + mCurrentTransform.Y,
			rect.Width,
			rect.Height
		);
	}

	private void AddQuad(Point2F p0, Point2F p1, Point2F p2, Point2F p3, Color color)
	{
		if (mVertices.Count + 4 > MaxVertices || mIndices.Count + 6 > MaxIndices)
			FlushBatch();

		let colorVec = color.ToVector4();
		let baseIndex = (uint16)mVertices.Count;

		// Store screen coordinates - projection matrix handles conversion
		mVertices.Add(.() { Position = .(p0.X, p0.Y, 0, 1), Color = colorVec, TexCoord = .(0, 0) });
		mVertices.Add(.() { Position = .(p1.X, p1.Y, 0, 1), Color = colorVec, TexCoord = .(0, 1) });
		mVertices.Add(.() { Position = .(p2.X, p2.Y, 0, 1), Color = colorVec, TexCoord = .(1, 1) });
		mVertices.Add(.() { Position = .(p3.X, p3.Y, 0, 1), Color = colorVec, TexCoord = .(1, 0) });

		mIndices.Add(baseIndex + 0);
		mIndices.Add(baseIndex + 1);
		mIndices.Add(baseIndex + 2);
		mIndices.Add(baseIndex + 0);
		mIndices.Add(baseIndex + 2);
		mIndices.Add(baseIndex + 3);
	}

	private void FlushBatch()
	{
		if (mVertices.Count == 0 || mPipeline == null)
			return;

		// Update projection matrix (orthographic, screen-space)
		// Note: Vulkan RHI already flips Y via negative viewport height when ClipSpaceYInvertedSupported
		// So we use OpenGL-style projection: Y=0 at top, Y=height at bottom
		Constants constants = .();
		constants.ProjectionMatrix = Matrix.CreateOrthographicOffCenter(
			0, mViewportSize.Width,
			mViewportSize.Height, 0,  // bottom=height, top=0 (Y=0 maps to NDC +1 which is top after viewport flip)
			-1, 1
		);
		mGraphicsContext.UpdateBufferData(mConstantBuffer, &constants, (.)sizeof(Constants));

		// Update vertex buffer
		UIVertex[] vertexData = scope .[mVertices.Count];
		mVertices.CopyTo(vertexData);
		mGraphicsContext.UpdateBufferData(mVertexBuffer, vertexData.Ptr, (.)sizeof(UIVertex) * (.)mVertices.Count);

		// Update index buffer
		uint16[] indexData = scope .[mIndices.Count];
		mIndices.CopyTo(indexData);
		mGraphicsContext.UpdateBufferData(mIndexBuffer, indexData.Ptr, (.)sizeof(uint16) * (.)mIndices.Count);

		// Draw
		mCommandBuffer.SetGraphicsPipelineState(mPipeline);
		mCommandBuffer.SetResourceSet(mResourceSet);
		mCommandBuffer.SetVertexBuffers(scope .(mVertexBuffer));
		mCommandBuffer.SetIndexBuffer(mIndexBuffer, .UInt16);
		mCommandBuffer.DrawIndexed((.)mIndices.Count);

		// Clear batch
		mVertices.Clear();
		mIndices.Clear();
	}
}
