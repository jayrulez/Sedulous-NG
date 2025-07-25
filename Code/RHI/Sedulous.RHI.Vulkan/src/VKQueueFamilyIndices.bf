using Bulkan;

namespace Sedulous.RHI.Vulkan;

internal struct VKQueueFamilyIndices
{
	public const uint32 VK_QUEUE_FAMILY_IGNORED = uint32.MaxValue;

	public uint32 GraphicsFamily;

	public uint32 Presentfamily;

	public uint32 CopyFamily;

	public uint32 ComputeFamily;

	public bool GraphicsFamilySupported => GraphicsFamily != uint32.MaxValue;

	public bool PresentFamilySupported => Presentfamily != uint32.MaxValue;

	public bool CopyQueueSupported => CopyFamily != uint32.MaxValue;

	public bool ComputeFamilySupported => ComputeFamily != uint32.MaxValue;

	/// <summary>
	/// Finds the queue families supported.
	/// </summary>
	/// <param name="context">The graphics context object.</param>
	/// <param name="physicalDevice">The physical device object.</param>
	/// <param name="surface">The desired surface type.</param>
	/// <returns>The supported queue family indices.</returns>
	public static VKQueueFamilyIndices FindQueueFamilies(VKGraphicsContext context, VkPhysicalDevice physicalDevice, VkSurfaceKHR? surface)
	{
		VKQueueFamilyIndices indices = default(VKQueueFamilyIndices);
		indices.GraphicsFamily = uint32.MaxValue;
		indices.Presentfamily = uint32.MaxValue;
		indices.CopyFamily = uint32.MaxValue;
		indices.ComputeFamily = uint32.MaxValue;
		uint32 queueFamilyCount = 0;
		VulkanNative.vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueFamilyCount, null);
		VkQueueFamilyProperties* queueFamilies = scope VkQueueFamilyProperties[(int32)queueFamilyCount]*;
		VulkanNative.vkGetPhysicalDeviceQueueFamilyProperties(physicalDevice, &queueFamilyCount, queueFamilies);
		VkBool32 presentSupported = default(VkBool32);
		for (uint32 i = 0; i < queueFamilyCount; i++)
		{
			VkQueueFamilyProperties q = queueFamilies[i];
			if (surface.HasValue)
			{
				VulkanNative.vkGetPhysicalDeviceSurfaceSupportKHR(physicalDevice, i, surface.Value, &presentSupported);
				if (indices.Presentfamily == uint32.MaxValue && q.queueCount != 0 && (bool)presentSupported)
				{
					indices.Presentfamily = i;
				}
			}
			if (indices.GraphicsFamily == uint32.MaxValue && q.queueCount != 0 && (q.queueFlags & VkQueueFlags.VK_QUEUE_GRAPHICS_BIT) != VkQueueFlags.None)
			{
				indices.GraphicsFamily = i;
			}
			if (indices.CopyFamily == uint32.MaxValue && q.queueCount != 0 && (q.queueFlags & VkQueueFlags.VK_QUEUE_TRANSFER_BIT) != VkQueueFlags.None)
			{
				indices.CopyFamily = i;
			}
			if (indices.ComputeFamily == uint32.MaxValue && q.queueCount != 0 && (q.queueFlags & VkQueueFlags.VK_QUEUE_COMPUTE_BIT) != VkQueueFlags.None)
			{
				indices.ComputeFamily = i;
			}
		}
		for (uint32 i = 0; i < queueFamilyCount; i++)
		{
			VkQueueFamilyProperties q = queueFamilies[i];
			if (q.queueCount != 0 && (q.queueFlags & VkQueueFlags.VK_QUEUE_TRANSFER_BIT) == VkQueueFlags.VK_QUEUE_TRANSFER_BIT && (q.queueFlags & VkQueueFlags.VK_QUEUE_GRAPHICS_BIT) != VkQueueFlags.VK_QUEUE_GRAPHICS_BIT && (q.queueFlags & VkQueueFlags.VK_QUEUE_COMPUTE_BIT) != VkQueueFlags.VK_QUEUE_COMPUTE_BIT)
			{
				indices.CopyFamily = i;
				break;
			}
		}
		for (uint32 i = 0; i < queueFamilyCount; i++)
		{
			VkQueueFamilyProperties q = queueFamilies[i];
			if (q.queueCount != 0 && (q.queueFlags & VkQueueFlags.VK_QUEUE_COMPUTE_BIT) == VkQueueFlags.VK_QUEUE_COMPUTE_BIT && (q.queueFlags & VkQueueFlags.VK_QUEUE_GRAPHICS_BIT) != VkQueueFlags.VK_QUEUE_GRAPHICS_BIT)
			{
				indices.ComputeFamily = i;
				break;
			}
		}
		return indices;
	}
}
