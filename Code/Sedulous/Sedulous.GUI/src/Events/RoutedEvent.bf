namespace Sedulous.GUI;

using System;
using System.Collections;

enum RoutingStrategy
{
	Tunnel,   // Root to target (Preview events)
	Bubble,   // Target to root (normal events)
	Direct    // Only on target
}

delegate void RoutedEventHandler(UIElement sender, RoutedEventArgs e);

class RoutedEvent
{
	public readonly String Name ~ delete _;
	public readonly RoutingStrategy Strategy;
	public readonly Type OwnerType;

	private static Dictionary<String, RoutedEvent> sRegistry = new .() ~ DeleteDictionaryAndKeysAndValues!(_);
	private static int32 sNextId = 0;

	public readonly int32 Id;

	private this(StringView name, RoutingStrategy strategy, Type ownerType)
	{
		Name = new .(name);
		Strategy = strategy;
		OwnerType = ownerType;
		Id = sNextId++;
	}

	public static RoutedEvent Register(StringView name, RoutingStrategy strategy, Type ownerType)
	{
		let key = scope String()..AppendF("{}:{}", ownerType.GetName(.. scope .()), name);

		if (sRegistry.TryGetValue(key, let existing))
			return existing;

		let evt = new RoutedEvent(name, strategy, ownerType);
		sRegistry[new String(key)] = evt;
		return evt;
	}

	public static RoutedEvent Register<TOwner>(StringView name, RoutingStrategy strategy)
	{
		return Register(name, strategy, typeof(TOwner));
	}
}
