using System;
using Sedulous.Models;
using Sedulous.Engine.Core.SceneGraph;
using Sedulous.Foundation.Mathematics;
using System.Collections;
namespace Sedulous.Engine.Navigation;

/**
* Navigation plugin interface to add navigation constrained by a navigation mesh
*/
interface INavigationEngine
{
	/**
	 * plugin name
	 */
	StringView Name {get;}

	/**
	 * Creates a navigation mesh
	 * @param meshes array of all the geometry used to compute the navigation mesh
	 * @param parameters bunch of parameters used to filter geometry
	 */
	void CreateNavMesh(Span<Mesh> meshes, INavMeshParameters parameters);

	/**
	 * Create a navigation mesh debug mesh
	 * @param scene is where the mesh will be added
	 * @returns debug display mesh
	 */
	Mesh CreateDebugNavMesh(Scene scene);

	/**
	 * Get a navigation mesh constrained position, closest to the parameter position
	 * @param position world position
	 * @returns the closest point to position constrained by the navigation mesh
	 */
	Vector3 GetClosestPoint(Vector3 position);

	/**
	 * Get a navigation mesh constrained position, closest to the parameter position
	 * @param position world position
	 * @param result output the closest point to position constrained by the navigation mesh
	 */
	void GetClosestPointToRef(Vector3 position, ref Vector3 result);

	/**
	 * Get a navigation mesh constrained position, within a particular radius
	 * @param position world position
	 * @param maxRadius the maximum distance to the constrained world position
	 * @returns the closest point to position constrained by the navigation mesh
	 */
	Vector3 GetRandomPointAround(Vector3 position, float maxRadius);

	/**
	 * Get a navigation mesh constrained position, within a particular radius
	 * @param position world position
	 * @param maxRadius the maximum distance to the constrained world position
	 * @param result output the closest point to position constrained by the navigation mesh
	 */
	void GetRandomPointAroundToRef(Vector3 position, float maxRadius, ref Vector3 result);

	/**
	 * Compute the final position from a segment made of destination-position
	 * @param position world position
	 * @param destination world position
	 * @returns the resulting point along the navmesh
	 */
	Vector3 MoveAlong(Vector3 position, Vector3 destination);

	/**
	 * Compute the final position from a segment made of destination-position
	 * @param position world position
	 * @param destination world position
	 * @param result output the resulting point along the navmesh
	 */
	void MoveAlongToRef(Vector3 position, Vector3 destination, ref Vector3 result);

	/**
	 * Compute a navigation path from start to end. Returns an empty array if no path can be computed.
	 * Path is straight.
	 * @param start world position
	 * @param end world position
	 * @returns array containing world position composing the path
	 */
	void ComputePath(Vector3 start, Vector3 end, List<Vector3> pathPositions);

	/**
	 * Compute a navigation path from start to end. Returns an empty array if no path can be computed.
	 * Path follows navigation mesh geometry.
	 * @param start world position
	 * @param end world position
	 * @returns array containing world position composing the path
	 */
	void ComputePathSmooth(Vector3 start, Vector3 end, List<Vector3> pathPositions);

	/**
	 * If this plugin is supported
	 * @returns true if plugin is supported
	 */
	bool IsSupported();

	/**
	 * Create a new Crowd so you can add agents
	 * @param maxAgents the maximum agent count in the crowd
	 * @param maxAgentRadius the maximum radius an agent can have
	 * @param scene to attach the crowd to
	 * @returns the crowd you can add agents to
	 */
	ICrowd CreateCrowd(int32 maxAgents, float maxAgentRadius, Scene scene);

	/**
	 * Set the Bounding box extent for doing spatial queries (getClosestPoint, getRandomPointAround, ...)
	 * The queries will try to find a solution within those bounds
	 * default is (1,1,1)
	 * @param extent x,y,z value that define the extent around the queries point of reference
	 */
	void SetDefaultQueryExtent(Vector3 extent);

	/**
	 * Get the Bounding box extent specified by setDefaultQueryExtent
	 * @returns the box extent values
	 */
	Vector3 GetDefaultQueryExtent();

	/**
	 * build the navmesh from a previously saved state using getNavmeshData
	 * @param data the Uint8Array returned by getNavmeshData
	 */
	void BuildFromNavmeshData(Span<uint8> data);

	/**
	 * returns the navmesh data that can be used later. The navmesh must be built before retrieving the data
	 * @returns data the Uint8Array that can be saved and reused
	 */
	Span<uint8> GetNavmeshData();

	/**
	 * Get the Bounding box extent result specified by setDefaultQueryExtent
	 * @param result output the box extent values
	 */
	void GetDefaultQueryExtentToRef(ref Vector3 result);

	/**
	 * Set the time step of the navigation tick update.
	 * Default is 1/60.
	 * A value of 0 will disable fixed time update
	 * @param newTimeStep the new timestep to apply to this world.
	 */
	void SetTimeStep(float newTimeStep);

	/**
	 * Get the time step of the navigation tick update.
	 * @returns the current time step
	 */
	float GetTimeStep();

	/**
	 * If delta time in navigation tick update is greater than the time step
	 * a number of sub iterations are done. If more iterations are need to reach deltatime
	 * they will be discarded.
	 * A value of 0 will set to no maximum and update will use as many substeps as needed
	 * @param newStepCount the maximum number of iterations
	 */
	void SetMaximumSubStepCount(int32 newStepCount);

	/**
	 * Get the maximum number of iterations per navigation tick update
	 * @returns the maximum number of iterations
	 */
	int32 GetMaximumSubStepCount();

	/**
	 * Creates a cylinder obstacle and add it to the navigation
	 * @param position world position
	 * @param radius cylinder radius
	 * @param height cylinder height
	 * @returns the obstacle freshly created
	 */
	IObstacle AddCylinderObstacle(Vector3 position, float radius, float height);

	/**
	 * Creates an oriented box obstacle and add it to the navigation
	 * @param position world position
	 * @param extent box size
	 * @param angle angle in radians of the box orientation on Y axis
	 * @returns the obstacle freshly created
	 */
	IObstacle AddBoxObstacle(Vector3 position, Vector3 extent, float angle);

	/**
	 * Removes an obstacle created by addCylinderObstacle or addBoxObstacle
	 * @param obstacle obstacle to remove from the navigation
	 */
	void RemoveObstacle(IObstacle obstacle);

	/**
	 * Release all resources
	 */
	void Dispose();
}