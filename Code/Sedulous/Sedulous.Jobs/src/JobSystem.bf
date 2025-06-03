using System;
using System.Threading;
using System.Collections;
using Sedulous.Logging.Abstractions;
using static System.Platform;
namespace Sedulous.Jobs;

using internal Sedulous.Jobs;

class JobSystem
{
	private readonly int mMinimumBackgroundWorkers;
	private readonly List<BackgroundWorker> mWorkers = new .() ~ delete _;
	private MainThreadWorker mMainThreadWorker = null;

	private readonly Monitor mJobsToRunMonitor = new .() ~ delete _;
	private readonly Queue<JobBase> mJobsToRun = new .() ~ delete _;

	private readonly Monitor mCompletedJobsMonitor = new .() ~ delete _;
	private readonly List<JobBase> mCompletedJobs = new .() ~ delete _;

	private readonly Monitor mCancelledJobsMonitor = new .() ~ delete _;
	private readonly List<JobBase> mCancelledJobs = new .() ~ delete _;

	private bool mIsRunning = false;

	public int WorkerCount => mWorkers?.Count ?? 0;

	private readonly ILogger mLogger;
	public ILogger Logger => mLogger;

	// todo: If platform does not support threading, then only main thread worker should be available
	public this(ILogger logger, int workerCount = 0)
	{
		var workerCount;

		mLogger = logger;

		mMinimumBackgroundWorkers = Math.Max(0, workerCount);

		BfpSystemResult result = .Ok;
		int coreCount = Platform.BfpSystem_GetNumLogicalCPUs(&result);
		if (result == .Ok)
		{
			mMinimumBackgroundWorkers = Math.Min(mMinimumBackgroundWorkers, coreCount - 1);
		}

		//CreateWorkers();
	}

	public ~this()
	{
		for (Worker worker in mWorkers)
		{
			delete worker;
		}

		delete mMainThreadWorker;
	}

	private void CreateWorkers()
	{
		mMainThreadWorker = new .(this, "Main Thread Worker");

		for (int i = 0; i < mMinimumBackgroundWorkers; i++)
		{
			BackgroundWorker worker = new .(this, scope $"Worker {i}", .Persistent);

			mWorkers.Add(worker);
		}
	}

	private void DestroyWorkers()
	{
		if(mMainThreadWorker != null)
		{
			delete mMainThreadWorker;
			mMainThreadWorker = null;
		}

		for(var worker in mWorkers)
		{
			delete worker;
		}
		mWorkers.Clear();
	}

	private void OnJobCompleted(JobBase job, Worker worker)
	{
		using (mCompletedJobsMonitor.Enter())
		{
			job.AddRef();
			mCompletedJobs.Add(job);
		}
	}

	private void OnJobCancelled(JobBase job, Worker worker)
	{
		using (mCancelledJobsMonitor.Enter())
		{
			job.AddRef();
			mCancelledJobs.Add(job);
		}
	}

	internal void HandleProcessedJob(JobBase job, Worker worker)
	{
		if (job.State == .Succeeded)
			OnJobCompleted(job, worker);
		else if (job.State == .Canceled)
			OnJobCancelled(job, worker);
	}

	internal void Startup()
	{
		if (mIsRunning)
		{
			Logger?.LogError("Startup called on JobSystem that is already running.");
			return;
		}

		CreateWorkers();

		mMainThreadWorker.Start();

		for (Worker worker in mWorkers)
		{
			if (!worker.IsRunning)
				worker.Start();
		}

		mIsRunning = true;
	}

	internal void Shutdown()
	{
		if (!mIsRunning)
		{
			Logger?.LogError("Shutdown called on JobSystem that is not running.");
			return;
		}

		for (Worker worker in mWorkers)
		{
			if (worker.State == .Paused)
				worker.Resume();

			worker.Stop();
		}

		mMainThreadWorker.Stop();

		while (mJobsToRun.Count > 0)
		{
			JobBase job = mJobsToRun.PopFront();
			defer job.ReleaseRef();
			job.Cancel();
			OnJobCancelled(job, null);
		}

		ClearCompletedJobs();

		ClearCancelledJobs();

		mIsRunning = false;

		DestroyWorkers();
	}

	internal void Update(int64 elapsedTicks)
	{
		if (!mIsRunning)
		{
			Logger?.LogError("Update called on JobSystem that is not running.");
			return;
		}

		delegate void(JobBase) requeueJob = scope (job) =>
			{
				using (mJobsToRunMonitor.Enter())
				{
						// We need to add a ref to the job to counter the previous release
						// We need to add the job back to the front of the queue
					job.AddRef();
					mJobsToRun.AddFront(job);
				}
			};

		// todo: if there are no jobs for x frames then pause workers to save CPU

		List<JobBase> jobsToRun = scope .();
		using (mJobsToRunMonitor.Enter())
		{
			jobsToRun.AddRange(mJobsToRun);
			mJobsToRun.Clear();
		}

		for (var job in jobsToRun)
		{
			defer job.ReleaseRef();

			if (!job.IsReady())
			{
				// Requeue job
				AddJob(job);
				continue;
			}

			// Queue the job on the main thread worker
			// if it has the RunOnMainThread flag or no background workers exist
			if (job.Flags.HasFlag(.RunOnMainThread) || mWorkers?.Count == 0)
			{
				if (mMainThreadWorker.QueueJob(job) case .Err)
				{
					Logger?.LogError("Failed to queue job on main thread worker '{}'.", mMainThreadWorker.Name);
					// Failed to queue the job on the worker
					// Re-queue the job, the lambda adds a ref to job to counter the previous release
					requeueJob(job);
				}
				continue;
			}

			// Try to get a worker to queue the job on
			if (!GetAvailableWorker(var worker))
			{
				// todo: determine if job can be run on main thread,
				// if yes then do so and continue instead of re-queueing, otherwise break

				// No available workers
				// We need to break here if there are no available workers
				// Requeue the job, the lambda adds a ref to job to counter the previous release
				requeueJob(job);

				continue;
			}

			switch (job.State) {
			case .Canceled:
				// If the job was canceled by this point
				OnJobCancelled(job, null);
				break;

			case .Succeeded:
				// If the job was completed by this point
				OnJobCompleted(job, null);
				break;

			default:
				// Queue the job to be run on the worker
				if (worker.QueueJob(job) case .Err)
				{
					Logger?.LogError("Failed to queue job on worker '{}'.", worker.Name);
					// Failed to queue the job on the worker
					// Requeue the job, the lambda adds a ref to job to counter the previous release
					requeueJob(job);
				}
				break;
			}
		}

		List<BackgroundWorker> deadWorkers = scope .();
		for (int i = 0; i < mWorkers.Count; i++)
		{
			var worker = mWorkers[i];
			// Update worker in case thread died
			worker.Update();

			// gather dead workers
			if (worker.State == .Dead)
			{
				deadWorkers.Add(worker);
			}
			/*if (worker.State == .Idle)
			{
				mWorkers[i].Pause();
			}*/
		}

		// Replace dead workers
		if (deadWorkers.Count > 0)
		{
			for (var deadWorker in deadWorkers)
			{
				var name = scope String(deadWorker.Name);
				var flags = deadWorker.Flags;
				mWorkers.Remove(deadWorker);

				if (deadWorker.Flags.HasFlag(.Persistent))
				{
					mWorkers.Add(new BackgroundWorker(this, name, flags));
				}

				delete deadWorker;
			}
		}

		// Process main thread jobs
		mMainThreadWorker.Update();

		ClearCompletedJobs();

		ClearCancelledJobs();
	}

	public void AddJob(JobBase job)
	{
		if (!mIsRunning)
		{
			Runtime.FatalError("JobSystem is not running.");
		}
		using (mJobsToRunMonitor.Enter())
		{
			job.AddRef();
			mJobsToRun.Add(job);
		}
	}

	public void AddJobs(Span<JobBase> jobs)
	{
		if (!mIsRunning)
		{
			Runtime.FatalError("JobSystem is not running.");
		}
		using (mJobsToRunMonitor.Enter())
		{
			for (JobBase job in jobs)
			{
				job.AddRef();
				mJobsToRun.Add(job);
			}
		}
	}

	public void AddJob(delegate void() jobDelegate, bool ownsJobDelegate, StringView? jobName = null, JobFlags flags = .None)
	{
		if (!mIsRunning)
		{
			Runtime.FatalError("JobSystem is not running.");
		}
		DelegateJob job = new DelegateJob(jobDelegate, ownsJobDelegate, jobName, flags | .AutoRelease);
		AddJob(job);
	}

	public void AddJob<T>(delegate T() jobDelegate,
		bool ownsJobDelegate,
		StringView? jobName = null,
		JobFlags flags = .None,
		delegate void(T result) onCompleted = null,
		bool ownsOnCompletedDelegate = true)
	{
		if (!mIsRunning)
		{
			Runtime.FatalError("JobSystem is not running.");
		}
		DelegateJob<T> job = new DelegateJob<T>(jobDelegate, ownsJobDelegate, jobName, flags | .AutoRelease, onCompleted, ownsOnCompletedDelegate);
		AddJob(job);
	}

	private bool GetAvailableWorker(out Worker worker)
	{
		for (int i = 0; i < mWorkers.Count; i++)
		{
			if (mWorkers[i].State == .Idle || mWorkers[i].State == .Paused)
			{
				worker = mWorkers[i];
				return true;
			}
		}

		worker = null;
		return false;
	}

	private void ClearCancelledJobs()
	{
		using (mCancelledJobsMonitor.Enter())
		{
			for (JobBase job in mCancelledJobs)
			{
				if (job.Flags.HasFlag(.AutoRelease))
				{
					job.ReleaseRef();
				}
				job.ReleaseRef();
			}
			mCancelledJobs.Clear();
		}
	}

	private void ClearCompletedJobs()
	{
		using (mCompletedJobsMonitor.Enter())
		{
			for (JobBase job in mCompletedJobs)
			{
				if (job.Flags.HasFlag(.AutoRelease))
				{
					job.ReleaseRef();
				}
				job.ReleaseRef();
			}
			mCompletedJobs.Clear();
		}
	}
}