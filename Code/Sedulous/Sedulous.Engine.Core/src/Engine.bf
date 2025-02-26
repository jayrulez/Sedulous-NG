using System;
using Sedulous.Foundation.Logging.Abstractions;
using System.Collections;
using System.Threading;
using Sedulous.Foundation.Logging.Debug;
namespace Sedulous.Engine.Core;

using internal Sedulous.Engine.Core;

sealed class Engine : IEngine
{
	private List<Subsystem> mSubsystems = new .() ~ delete _;

	public IEngine.EngineState State { get; private set; } = .Stopped;

	private bool mInitialized = false;

	private Dictionary<IEngine.UpdateStage, List<IEngine.RegisteredUpdateFunctionInfo>> mUpdateFunctions = new .() ~ delete _;
	private List<IEngine.RegisteredUpdateFunctionInfo> mUpdateFunctionsToRegister = new .() ~ delete _;
	private List<IEngine.RegisteredUpdateFunctionInfo> mUpdateFunctionsToUnregister = new .() ~ delete _;

	private readonly ILogger mLogger = null;
	private bool mOwnsLogger = false;

	public ILogger Logger => mLogger;

	// Current tick state.
	private static readonly TimeSpan MaxElapsedTime = TimeSpan.FromMilliseconds(500);
	private readonly EngineTimeTracker mPreUpdateTimeTracker = new .() ~ delete _;
	private readonly EngineTimeTracker mPostUpdateTimeTracker = new .() ~ delete _;
	private readonly EngineTimeTracker mUpdateTimeTracker = new .() ~ delete _;
	private readonly EngineTimeTracker mFixedUpdateTimeTracker = new .() ~ delete _;
	private int64 mAccumulatedElapsedTime = 0;
	private int32 mLagFrames = 0;
	private bool mRunningSlowly = false;

	/// Gets the default value for TargetElapsedTime.
	public static TimeSpan DefaultTargetElapsedTime { get; } = TimeSpan(TimeSpan.TicksPerSecond / 60);

	/// Gets the default value for InactiveSleepTime.
	public static TimeSpan DefaultInactiveSleepTime { get; } = TimeSpan.FromMilliseconds(20);

	public TimeSpan TargetElapsedTime { get; set; } = DefaultTargetElapsedTime;
	public TimeSpan InactiveSleepTime { get; set; } = DefaultInactiveSleepTime;

	//private readonly IEngineHost mHost;

	public this(/*IEngineHost host,*/ ILogger logger = null)
	{
		//mHost = host;
		if (logger == null)
		{
			mLogger = new DebugLogger(.Debug);
			mOwnsLogger = true;
		} else
		{
			mLogger = logger;
			mOwnsLogger = false;
		}

		Enum.MapValues<IEngine.UpdateStage>(scope (member) =>
			{
				mUpdateFunctions.Add(member, new .());
			});
	}

	public ~this()
	{
		Enum.MapValues<IEngine.UpdateStage>(scope (member) =>
			{
				delete mUpdateFunctions[member];
			});

		if (mOwnsLogger)
		{
			delete mLogger;
		}
		mOwnsLogger = false;
	}

	public Result<void> Initialize(EngineInitializer initializer)
	{
		mLogger.MimimumLogLevel = initializer.LogLevel;

		if (mInitialized)
		{
			mLogger.LogWarning("Engine already initialized.");
			return .Ok;
		}

		mLogger.LogInformation("Engine initialization started.");

		List<Subsystem> initializedSubsystems = scope .();
		bool subsystemsInitialized = true;

		for (var subsystem in initializer.Subsystems)
		{
			if (subsystem.Initialize(this) case .Ok)
			{
				mLogger.LogInformation("Subsystem '{0}' initialized.", subsystem.Name);
				initializedSubsystems.Add(subsystem);
			} else
			{
				subsystemsInitialized = false;
				mLogger.LogError("Initialization failed for subsystem '{0}'.", subsystem.Name);
				break;
			}
		}

		if (!subsystemsInitialized)
		{
			for (var subsystem in initializedSubsystems)
			{
				subsystem.Uninitialize();
				mLogger.LogInformation("Subsystem '{0}' uninitialized.", subsystem.Name);
			}
			return .Err;
		}

		mSubsystems.AddRange(initializer.Subsystems);

		mInitialized = true;

		for(var subsystem in mSubsystems)
		{
			subsystem.Initialized(this);
		}

		mLogger.LogInformation("Engine initialization completed.");

		State = .Running;

		return .Ok;
	}

	public void Shutdown()
	{
		if (!mInitialized)
		{
			mLogger.LogWarning("Engine was not previously initialized.");
			return;
		}

		State = .Stopped;

		for (var subsystem in mSubsystems.Reversed)
		{
			subsystem.Uninitialize();
			mLogger.LogInformation("Subsystem '{0}' uninitialized.", subsystem.Name);
		}

		mSubsystems.Clear();

		mInitialized = false;
		mLogger.LogInformation("Engine uninitialized.");
	}

	public void Update(int64 elapsedTicks)
	{
		#region Update methods
		void SortUpdateFunctions()
		{
			Enum.MapValues<IEngine.UpdateStage>(scope (member) =>
				{
					mUpdateFunctions[member].Sort(scope (lhs, rhs) =>
						{
							if (lhs.Priority == rhs.Priority)
							{
								return 0;
							}
							return lhs.Priority > rhs.Priority ? 1 : -1;
						});
				});
		}

		void RunUpdateFunctions(IEngine.UpdateStage phase, IEngine.UpdateInfo info)
		{
			for (ref IEngine.RegisteredUpdateFunctionInfo updateFunctionInfo in ref mUpdateFunctions[phase])
			{
				updateFunctionInfo.Function(info);
			}
		}

		void ProcessUpdateFunctionsToRegister()
		{
			if (mUpdateFunctionsToRegister.Count == 0)
				return;

			for (var info in mUpdateFunctionsToRegister)
			{
				mUpdateFunctions[info.Stage].Add(info);
			}
			mUpdateFunctionsToRegister.Clear();
			SortUpdateFunctions();
		}

		void ProcessUpdateFunctionsToUnregister()
		{
			if (mUpdateFunctionsToUnregister.Count == 0)
				return;

			for (var info in mUpdateFunctionsToUnregister)
			{
				var index = mUpdateFunctions[info.Stage].FindIndex(scope (registered) =>
					{
						return info.Id == registered.Id;
					});

				if (index >= 0)
				{
					mUpdateFunctions[info.Stage].RemoveAt(index);
				}
			}
			mUpdateFunctionsToUnregister.Clear();
			SortUpdateFunctions();
		}
		{
			ProcessUpdateFunctionsToRegister();
			ProcessUpdateFunctionsToUnregister();
		}


#endregion

		//if (InactiveSleepTime.Ticks > 0 /*&& mHost.IsSuspended*/)
		//	Thread.Sleep(InactiveSleepTime);

		mAccumulatedElapsedTime += elapsedTicks;
		if (mAccumulatedElapsedTime > MaxElapsedTime.Ticks)
			mAccumulatedElapsedTime = MaxElapsedTime.Ticks;

		// Pre-Update
		{
			RunUpdateFunctions(.PreUpdate, .()
				{
					Engine = this,
					Time = mPreUpdateTimeTracker.Increment(TimeSpan(elapsedTicks))
				});
		}

		// Fixed-Update
		{
			var fixedTicksToRun = (int32)(mAccumulatedElapsedTime / TargetElapsedTime.Ticks);
			if (fixedTicksToRun > 0)
			{
				mLagFrames += (fixedTicksToRun == 1) ? -1 : Math.Max(0, fixedTicksToRun - 1);

				if (mLagFrames == 0)
					mRunningSlowly = false;
				if (mLagFrames > 5)
					mRunningSlowly = true;

				var timeDeltaFixedUpdate = TargetElapsedTime;
				mAccumulatedElapsedTime -= fixedTicksToRun * TargetElapsedTime.Ticks;

				for (var i = 0; i < fixedTicksToRun; i++)
				{
					RunUpdateFunctions(.FixedUpdate, .()
						{
							Engine = this,
							Time = mFixedUpdateTimeTracker.Increment(timeDeltaFixedUpdate /*, mRunningSlowly*/)
						});
				}
			}
		}

		// Variable-Update
		{
			RunUpdateFunctions(.VariableUpdate, .()
				{
					Engine = this,
					Time = mUpdateTimeTracker.Increment(TimeSpan(elapsedTicks))
				});
		}

		// Post-Update
		{
			RunUpdateFunctions(.PostUpdate, .()
				{
					Engine = this,
					Time = mPostUpdateTimeTracker.Increment(TimeSpan(elapsedTicks))
				});
		}
	}

	public IEngine.RegisteredUpdateFunctionInfo RegisterUpdateFunction(IEngine.UpdateFunctionInfo info)
	{
		IEngine.RegisteredUpdateFunctionInfo registration = .(Guid.Create(), info.Stage, info.Priority, info.Function);
		mUpdateFunctionsToRegister.Add(registration);
		return registration;
	}

	public void RegisterUpdateFunctions(Span<IEngine.UpdateFunctionInfo> infos, List<IEngine.RegisteredUpdateFunctionInfo> registrations)
	{
		for (var info in infos)
		{
			registrations.Add(RegisterUpdateFunction(info));
		}
	}

	public void UnregisterUpdateFunction(IEngine.RegisteredUpdateFunctionInfo registration)
	{
		mUpdateFunctionsToUnregister.Add(registration);
	}

	public void UnregisterUpdateFunctions(Span<IEngine.RegisteredUpdateFunctionInfo> registrations)
	{
		for (var registration in registrations)
		{
			mUpdateFunctionsToUnregister.Add(registration);
		}
	}

	public Result<T> GetSubsystem<T>() where T : Subsystem
	{
		for (var subsystem in mSubsystems)
		{
			if (typeof(T).IsAssignableFrom(subsystem.GetType()))
			{
				return .Ok((T)subsystem);
			}
		}
		return .Err;
	}

	public bool TryGetSubsystem<T>(out T outSubsystem) where T : Subsystem
	{
		for (var subsystem in mSubsystems)
		{
			if (typeof(T).IsAssignableFrom(subsystem.GetType()))
			{
				outSubsystem = (T)subsystem;
				return true;
			}
		}
		outSubsystem = null;
		return false;
	}
}