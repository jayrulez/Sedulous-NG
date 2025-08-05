using System;
using Sedulous.Logging.Abstractions;
using System.Collections;
using Sedulous.Jobs;
using Sedulous.Resources;
using Sedulous.SceneGraph;
using Sedulous.Messaging;
using Sedulous.Utilities;
namespace Sedulous.Engine.Core;

typealias EngineInitializingCallback = delegate Result<void>(EngineInitializer initializer);
typealias EngineInitializedCallback = delegate void(IEngine engine);
typealias EngineShuttingDownCallback = delegate void(IEngine engine);

interface IEngine
{
	public enum UpdateStage
	{
		PreUpdate,
		PostUpdate,
		VariableUpdate,
		FixedUpdate,
	}

	public enum EngineState
	{
		Stopped,
		Running,
		Paused
	}

	public struct UpdateInfo
	{
		public IEngine Engine;
		public Time Time;

		public this(IEngine engine, Time time)
		{
			Engine = engine;
			Time = time;
		}
	}

	public struct RegisteredUpdateFunctionInfo
	{
		public Guid Id;
		public UpdateStage Stage;
		public int Priority;
		public UpdateFunction Function;

		internal this(Guid id, UpdateStage stage, int priority, UpdateFunction @function)
		{
			this.Id = id;
			this.Stage = stage;
			this.Priority = priority;
			this.Function = @function;
		}
	}

	public typealias UpdateFunction = delegate void(UpdateInfo info);

	public struct UpdateFunctionInfo
	{
		public int Priority;
		public UpdateStage Stage;
		public UpdateFunction Function;
	}
	
	MessageBus Messages { get; }
	Span<Subsystem> Subsystems { get; }
	EngineState State { get; }
	ILogger Logger { get; }
	JobSystem JobSystem { get; }
	ResourceSystem ResourceSystem { get; }
	SceneGraphSystem SceneGraphSystem { get; }

	[NoDiscard] IEngine.RegisteredUpdateFunctionInfo RegisterUpdateFunction(UpdateFunctionInfo info);

	void RegisterUpdateFunctions(Span<UpdateFunctionInfo> infos, List<IEngine.RegisteredUpdateFunctionInfo> registrations);

	void UnregisterUpdateFunction(IEngine.RegisteredUpdateFunctionInfo registration);

	void UnregisterUpdateFunctions(Span<IEngine.RegisteredUpdateFunctionInfo> registrations);

	Result<T> GetSubsystem<T>() where T : Subsystem;

	bool TryGetSubsystem<T>(out T outSubsystem) where T : Subsystem;
}