namespace Sedulous.Engine.Navigation;

interface IAgentParameters
{
	/**
	 *  Agent radius. [Limit: >= 0]
	 */
	float Radius { get; }

	/**
	 * Agent height. [Limit: > 0]
	 */
	float Height { get; }

	/**
	 *  Maximum allowed acceleration. [Limit: >= 0]
	 */
	float MaxAcceleration { get; }

	/**
	 * Maximum allowed speed. [Limit: >= 0]
	 */
	float MaxSpeed { get; }

	/**
	 * Defines how close a collision element must be before it is considered for steering behaviors. [Limits: > 0]
	 */
	float CollisionQueryRange { get; }

	/**
	 * The path visibility optimization range. [Limit: > 0]
	 */
	float PathOptimizationRange { get; }

	/**
	 * How aggressive the agent manager should be at avoiding collisions with this agent. [Limit: >= 0]
	 */
	float SeparationWeight { get; }

	/**
	 * Observers will be notified when agent gets inside the virtual circle with this Radius around destination point.
	 * Default is agent radius
	 */
	float? ReachRadius { get; }
}