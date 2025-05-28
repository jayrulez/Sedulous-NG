using System.Collections;
using Sedulous.Foundation.Mathematics;
using Sedulous.Engine.Core.SceneGraph;
namespace Sedulous.Engine.Navigation;

/**
* Crowd Interface. A Crowd is a collection of moving agents constrained by a navigation mesh
*/
interface ICrowd {
    /**
     * Add a new agent to the crowd with the specified parameter a corresponding transformNode.
     * You can attach anything to that node. The node position is updated in the scene update tick.
     * @param pos world position that will be constrained by the navigation mesh
     * @param parameters agent parameters
     * @param transform hooked to the agent that will be update by the scene
     * @returns agent index
     */
    int32 AddAgent(Vector3 pos, IAgentParameters parameters, Transform transform);

    /**
     * Returns the agent position in world space
     * @param index agent index returned by addAgent
     * @returns world space position
     */
    Vector3 GetAgentPosition(int32 index);

    /**
     * Gets the agent position result in world space
     * @param index agent index returned by addAgent
     * @param result output world space position
     */
    void GetAgentPositionToRef(int32 index, ref Vector3 result);

    /**
     * Gets the agent velocity in world space
     * @param index agent index returned by addAgent
     * @returns world space velocity
     */
    Vector3 GetAgentVelocity(int32 index);

    /**
     * Gets the agent velocity result in world space
     * @param index agent index returned by addAgent
     * @param result output world space velocity
     */
    void GetAgentVelocityToRef(int32 index, ref Vector3 result);

    /**
     * Gets the agent next target point on the path
     * @param index agent index returned by addAgent
     * @returns world space position
     */
    Vector3 GetAgentNextTargetPath(int32 index);

    /**
     * Gets the agent state
     * @param index agent index returned by addAgent
     * @returns agent state
     */
    int32 GetAgentState(int32 index);

    /**
     * returns true if the agent in over an off mesh link connection
     * @param index agent index returned by addAgent
     * @returns true if over an off mesh link connection
     */
    bool OverOffmeshConnection(int32 index);

    /**
     * Gets the agent next target point on the path
     * @param index agent index returned by addAgent
     * @param result output world space position
     */
    void GetAgentNextTargetPathToRef(int32 index, ref Vector3 result);

    /**
     * remove a particular agent previously created
     * @param index agent index returned by addAgent
     */
    void RemoveAgent(int32 index);

    /**
     * get the list of all agents attached to this crowd
     * @returns list of agent indices
     */
    void GetAgents(List<int32> agentIndices);

    /**
     * Tick update done by the Scene. Agent position/velocity/acceleration is updated by this function
     * @param deltaTime in seconds
     */
    void Update(float deltaTime);

    /**
     * Asks a particular agent to go to a destination. That destination is constrained by the navigation mesh
     * @param index agent index returned by addAgent
     * @param destination targeted world position
     */
    void AgentGoto(int32 index, Vector3 destination);

    /**
     * Teleport the agent to a new position
     * @param index agent index returned by addAgent
     * @param destination targeted world position
     */
    void AgentTeleport(int32 index, Vector3 destination);

    /**
     * Update agent parameters
     * @param index agent index returned by addAgent
     * @param parameters agent parameters
     */
    void UpdateAgentParameters(int32 index, IAgentParameters parameters);

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
     * Get the Bounding box extent result specified by setDefaultQueryExtent
     * @param result output the box extent values
     */
    void GetDefaultQueryExtentToRef(ref Vector3 result);

    /**
     * Get the next corner points composing the path (max 4 points)
     * @param index agent index returned by addAgent
     * @returns array containing world position composing the path
     */
    void GetCorners(int32 index, List<Vector3> corners);

    /**
     * Release all resources
     */
    void Dispose();
}