using System;
using Bulkan;

namespace Sedulous.RHI.Vulkan;

/// <summary>
/// Ray tracing helpers.
/// </summary>
public static class VKRaytracingHelpers
{
	/// <summary>
	/// Data buffer.
	/// </summary>
	public struct BufferData
	{
		/// <summary>
		/// Vulkan buffer resource.
		/// </summary>
		public VkBuffer Buffer;

		/// <summary>
		/// Device memory resources.
		/// </summary>
		public VkDeviceMemory Memory;
	}

	/// <summary>
	/// Creates an Acceleration Structure buffer.
	/// </summary>
	/// <param name="context">The Vulkan context.</param>
	/// <param name="bufferSize">The buffer size.</param>
	/// <param name="usage">The buffer usage.</param>
	/// <returns>The buffer memory address.</returns>
	public static BufferData CreateBuffer(VKGraphicsContext context, uint64 bufferSize, VkBufferUsageFlags usage)
	{
		VkBufferCreateInfo bufferInfo = VkBufferCreateInfo()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
				size = bufferSize,
				usage = usage,
				flags = VkBufferCreateFlags.None,
				sharingMode = VkSharingMode.VK_SHARING_MODE_EXCLUSIVE
			};
		VkBuffer newBuffer = default(VkBuffer);
		VulkanNative.vkCreateBuffer(context.VkDevice, &bufferInfo, null, &newBuffer);
		VkMemoryRequirements memoryRequirements = default(VkMemoryRequirements);
		VulkanNative.vkGetBufferMemoryRequirements(context.VkDevice, newBuffer, &memoryRequirements);
		VkMemoryAllocateFlagsInfo memoryAllocateFlagsInfo = VkMemoryAllocateFlagsInfo()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_FLAGS_INFO,
				flags = VkMemoryAllocateFlags.VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT
			};
		VkMemoryAllocateInfo memoryAllocateInfo = VkMemoryAllocateInfo()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
				pNext = &memoryAllocateFlagsInfo,
				allocationSize = memoryRequirements.size,
				memoryTypeIndex = (uint32)VKHelpers.FindMemoryType(context, memoryRequirements.memoryTypeBits, VkMemoryPropertyFlags.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT | VkMemoryPropertyFlags.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
			};
		VkDeviceMemory deviceMemory = default(VkDeviceMemory);
		VulkanNative.vkAllocateMemory(context.VkDevice, &memoryAllocateInfo, null, &deviceMemory);
		VulkanNative.vkBindBufferMemory(context.VkDevice, newBuffer, deviceMemory, 0uL);
		return BufferData()
			{
				Buffer = newBuffer,
				Memory = deviceMemory
			};
	}

	/// <summary>
	/// Creates a staging buffer from data.
	/// </summary>
	/// <param name="context">The Vulkan context.</param>
	/// <param name="data">The source data pointer.</param>
	/// <param name="bufferSize">The buffer size.</param>
	/// <param name="usage">The buffer usage.</param>
	/// <returns>The buffer memory address.</returns>
	public static BufferData CreateMappedBuffer(VKGraphicsContext context, void* data, uint64 bufferSize, VkBufferUsageFlags usage)
	{
		VkBufferCreateInfo bufferInfo = VkBufferCreateInfo()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
				size = bufferSize,
				usage = usage,
				flags = VkBufferCreateFlags.None,
				sharingMode = VkSharingMode.VK_SHARING_MODE_EXCLUSIVE
			};
		VkBuffer newBuffer = default(VkBuffer);
		VulkanNative.vkCreateBuffer(context.VkDevice, &bufferInfo, null, &newBuffer);
		VkMemoryRequirements memoryRequirements = default(VkMemoryRequirements);
		VulkanNative.vkGetBufferMemoryRequirements(context.VkDevice, newBuffer, &memoryRequirements);
		VkMemoryAllocateFlagsInfo memoryAllocateFlagsInfo = VkMemoryAllocateFlagsInfo()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_FLAGS_INFO,
				flags = VkMemoryAllocateFlags.VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT
			};
		VkMemoryAllocateInfo memoryAllocateInfo = VkMemoryAllocateInfo()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
				pNext = &memoryAllocateFlagsInfo,
				allocationSize = memoryRequirements.size,
				memoryTypeIndex = (uint32)VKHelpers.FindMemoryType(context, memoryRequirements.memoryTypeBits, VkMemoryPropertyFlags.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT | VkMemoryPropertyFlags.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)
			};
		VkDeviceMemory deviceMemory = default(VkDeviceMemory);
		VulkanNative.vkAllocateMemory(context.VkDevice, &memoryAllocateInfo, null, &deviceMemory);
		VulkanNative.vkBindBufferMemory(context.VkDevice, newBuffer, deviceMemory, 0uL);
		if (data != null)
		{
			void* dataPointer = default(void*);
			VulkanNative.vkMapMemory(context.VkDevice, deviceMemory, 0uL, bufferSize, VkMemoryMapFlags.None, &dataPointer);
			Internal.MemCpy(dataPointer, (void*)data, (uint32)bufferSize);
			VulkanNative.vkUnmapMemory(context.VkDevice, deviceMemory);
		}
		return BufferData()
			{
				Buffer = newBuffer,
				Memory = deviceMemory
			};
	}
}
