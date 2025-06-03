using Sedulous.Mathematics;
namespace Sedulous.SceneGraph;
using internal Sedulous.SceneGraph;

class Transform
{
	public Entity Entity { get; internal set; }
	
	// Private backing fields
	private Vector3 mPosition = .Zero;
	private Quaternion mRotation = .Identity;
	private Vector3 mScale = .One;
	
	// Properties with dirty tracking
	public Vector3 Position 
	{ 
		get => mPosition;
		set
		{
			if (mPosition != value)
			{
				mPosition = value;
				MarkDirty();
			}
		}
	}
	
	public Quaternion Rotation 
	{ 
		get => mRotation;
		set
		{
			if (mRotation != value)
			{
				mRotation = value;
				MarkDirty();
			}
		}
	}
	
	public Vector3 Scale 
	{ 
		get => mScale;
		set
		{
			if (mScale != value)
			{
				mScale = value;
				MarkDirty();
			}
		}
	}
    
    // World space cached values
    private Matrix mWorldMatrix = .Identity;
    private bool mWorldMatrixDirty = true;
    
    // Forward vector (typically -Z in right-handed systems)
    public Vector3 Forward
    {
        get
        {
            // This depends on your coordinate system
            // If Vector3.Forward is (0,0,-1), this might need to be negated
            return Vector3.Transform(Vector3.Forward, Rotation);
        }
    }
    
    // Right vector (typically +X)
    public Vector3 Right
    {
        get
        {
            return Vector3.Transform(Vector3.Right, Rotation);
        }
    }
    
    // Up vector (typically +Y)
    public Vector3 Up
    {
        get
        {
            return Vector3.Transform(Vector3.Up, Rotation);
        }
    }
    
    public Matrix WorldMatrix
    {
        get
        {
            if (mWorldMatrixDirty)
            {
                UpdateWorldMatrix();
                mWorldMatrixDirty = false;
            }
            return mWorldMatrix;
        }
    }
    
	public void LookAt(Vector3 target, Vector3 up)
	{
	    // In your coordinate system, Forward = (0,0,-1), so we need to calculate
	    // the actual forward direction (from position to target)
	    Vector3 zaxis = Vector3.Normalize(Position - target); // This is like "backward"
	    Vector3 xaxis = Vector3.Normalize(Vector3.Cross(up, zaxis)); // Right
	    Vector3 yaxis = Vector3.Cross(zaxis, xaxis); // Actual up
	    
	    // Create rotation matrix
	    // Note: zaxis is pointing away from target (backward direction)
	    // So -zaxis is the forward direction
	    Matrix rotMatrix = Matrix(
	        xaxis.X,    yaxis.X,    zaxis.X,    0,
	        xaxis.Y,    yaxis.Y,    zaxis.Y,    0,
	        xaxis.Z,    yaxis.Z,    zaxis.Z,    0,
	        0,          0,          0,          1
	    );
	    
	    // Convert to quaternion
	    Rotation = Quaternion.CreateFromRotationMatrix(rotMatrix);
	    // No need to call MarkDirty() here - setting Rotation property already does it
	}
	
	// Overload that uses default up vector
	public void LookAt(Vector3 target)
	{
	    LookAt(target, Vector3.Up);
	}
    
    private void UpdateWorldMatrix()
    {
        mWorldMatrix = Matrix.CreateScale(mScale) * 
                      Matrix.CreateFromQuaternion(mRotation) * 
                      Matrix.CreateTranslation(mPosition);
    }
    
    private void MarkDirty()
    {
        if (!mWorldMatrixDirty)
        {
            mWorldMatrixDirty = true;
            
            // Publish transform change message - listeners can access transform via Entity.Transform
            Entity.Scene.SceneGraph.MessageBus.Publish(new TransformChangedMessage(Entity));
        }
    }
}