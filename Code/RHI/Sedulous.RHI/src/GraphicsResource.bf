using System;

namespace Sedulous.RHI;

/// <summary>
/// A resource interface that provides common actions for all resources.
/// </summary>
public abstract class GraphicsResource : IDisposable
{
	/// <summary>
	/// Indicates if the instance has been disposed.
	/// </summary>
	private bool disposed;

	/// <summary>
	/// Reference to the device context.
	/// </summary>
	public GraphicsContext Context;

	/// <summary>
	/// Gets the native pointer.
	/// </summary>
	public abstract void* NativePointer { get; }

	/// <summary>
	/// Gets a value indicating whether the graphic resource has been disposed of.
	/// </summary>
	public bool Disposed => disposed;

	/// <summary>
	/// Initializes a new instance of the <see cref="T:Sedulous.RHI.GraphicsResource" /> class.
	/// </summary>
	/// <param name="context">The device context.</param>
	protected this(GraphicsContext context)
	{
		Context = context;
	}

	/// <summary>
	/// Finalizes an instance of the <see cref="T:Sedulous.RHI.GraphicsResource" /> class.
	/// </summary>
	public ~this()
	{
		Dispose(disposing: false);
	}

	/// <inheritdoc />
	public void Dispose()
	{
		Dispose(disposing: true);
	}

	/// <summary>
	/// Releases unmanaged and optionally managed resources.
	/// </summary>
	/// <param name="disposing"><c>true</c> to release both managed and unmanaged resources; <c>false</c> to release only unmanaged resources.</param>
	protected virtual void Dispose(bool disposing)
	{
		if (!disposed)
		{
			if (disposing)
			{
				Destroy();
			}
			disposed = true;
		}
	}

	/// <summary>
	/// Destroy graphics native resources.
	/// </summary>
	protected abstract void Destroy();
}
