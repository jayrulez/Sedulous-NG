namespace Sedulous.Engine.Navigation;

interface INavMeshParameters
{
	/**
	 * The xz-plane cell size to use for fields. [Limit: > 0] [Units: wu]
	 */
	float CellSize { get; }

	/**
	 * The y-axis cell size to use for fields. [Limit: > 0] [Units: wu]
	 */
	float CellHeight { get; }

	/**
	 * The maximum slope that is considered walkable. [Limits: 0 <= value < 90] [Units: Degrees]
	 */
	float WalkableSlopeAngle { get; }

	/**
	 * Minimum floor to 'ceiling' height that will still allow the floor area to
	 * be considered walkable. [Limit: >= 3] [Units: vx]
	 */
	float WalkableHeight { get; }

	/**
	 * Maximum ledge height that is considered to still be traversable. [Limit: >=0] [Units: vx]
	 */
	float WalkableClimb { get; }

	/**
	 * The distance to erode/shrink the walkable area of the heightfield away from
	 * obstructions.  [Limit: >=0] [Units: vx]
	 */
	float WalkableRadius { get; }

	/**
	 * The maximum allowed length for contour edges along the border of the mesh. [Limit: >=0] [Units: vx]
	 */
	float MaxEdgeLength { get; }

	/**
	 * The maximum distance a simplified contour's border edges should deviate
	 * the original raw contour. [Limit: >=0] [Units: vx]
	 */
	float MaxSimplificationError { get; }

	/**
	 * The minimum number of cells allowed to form isolated island areas. [Limit: >=0] [Units: vx]
	 */
	float MinRegionArea { get; }

	/**
	 * Any regions with a span count smaller than this value will, if possible,
	 * be merged with larger regions. [Limit: >=0] [Units: vx]
	 */
	float MergeRegionArea { get; }

	/**
	 * The maximum number of vertices allowed for polygons generated during the
	 * contour to polygon conversion process. [Limit: >= 3]
	 */
	int32 MaxVertsPerPoly { get; }

	/**
	 * Sets the sampling distance to use when generating the detail mesh.
	 * (For height detail only.) [Limits: 0 or >= 0.9] [Units: wu]
	 */
	float DetailSampleDist { get; }

	/**
	 * The maximum distance the detail mesh surface should deviate from heightfield
	 * data. (For height detail only.) [Limit: >=0] [Units: wu]
	 */
	float DetailSampleMaxError { get; }

	/**
	 * If using obstacles, the navmesh must be subdivided internaly by tiles.
	 * This member defines the tile cube side length in world units.
	 * If no obstacles are needed, leave it undefined or 0.
	 */
	float? TileSize { get; }

	/**
	 * The size of the non-navigable border around the heightfield.
	 */
	float? BorderSize { get; }
}