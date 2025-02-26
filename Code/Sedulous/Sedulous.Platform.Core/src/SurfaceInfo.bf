using System;

namespace Sedulous.Platform.Core;

/// <summary>
/// Surface information structure.
/// </summary>
public struct SurfaceInfo : IEquatable<SurfaceInfo>
{
	public struct Win32NativeSurface
	{
		public void* Hwnd;
	}

	public struct UWPNativeSurface
	{
		public void* Surface;
	}

	public struct X11NativeSurface
	{
		public void* Display;
		public uint64 Window;
	}

	public struct XcbNativeSurface
	{
		public void* connection;
		public uint64 Window;
	}

	public struct WaylandNativeSurface
	{
		public void* Display;
		public void* Surface;
	}

	public struct AndroidNativeSurface
	{
		public void* Window;
		public void* Surface;
	}

	public struct MetalIOSNativeSurface
	{
		public void* View;
	}

	public struct MetalMacOSNativeSurface
	{
		public void* CAMetalLayer;
	}

	[Union]
	public struct NativeSurface
	{
		public Win32NativeSurface Win32;
		public UWPNativeSurface UWP;
		public X11NativeSurface X11;
		public XcbNativeSurface Xcb;
		public WaylandNativeSurface Wayland;
		public AndroidNativeSurface Android;
		public MetalIOSNativeSurface MetalIOS;
		public MetalMacOSNativeSurface MetalMacOS;
	}

	/// <summary>
	/// Surface technologies.
	/// </summary>
	public enum NativeSurfaceType
	{
		Unspecified,
		Win32,
		UWP,
		WinUI,
		X11,
		Xcb,
		Wayland,
		Android,
		MetalIOS,
		MetalMacOS
	}

	/// <summary>
	/// The surface type.
	/// </summary>
	public NativeSurfaceType Type = .Unspecified;
	public using private NativeSurface NativeSurface;

	/// <summary>
	/// Determines whether the specified <see cref="T:System.Object" /> is equal to this instance.
	/// </summary>
	/// <param name="other">The object used for comparison.</param>
	/// <returns>
	/// <c>true</c> if the specified <see cref="T:System.Object" /> is equal to this instance; otherwise, <c>false</c>.
	/// </returns>
	public bool Equals(SurfaceInfo other)
	{
		return Type == other.Type && NativeSurface == other.NativeSurface;
	}

	/// <summary>
	/// Returns a hash code for this instance.
	/// </summary>
	/// <returns>
	/// A hash code for this instance, suitable for use in hashing algorithms and data structures like a hash table.
	/// </returns>
	public int GetHashCode()
	{
		return (((int)Type).GetHashCode() * 397) ^ HashCode.Generate(NativeSurface);
	}
}
