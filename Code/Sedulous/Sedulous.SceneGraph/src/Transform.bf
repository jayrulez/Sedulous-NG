using Sedulous.Mathematics;
namespace Sedulous.SceneGraph;

using internal Sedulous.SceneGraph;

class Transform
{
	public Entity Entity { get; internal set; }

    public Vector3 Position { get; set; } = .Zero;
    public Quaternion Rotation { get; set; } = .Identity;
    public Vector3 Scale { get; set; } = .One;
    
    // World space cached values
    private Matrix mWorldMatrix = .Identity;
    private bool mWorldMatrixDirty = true;

    // Forward and Up vectors
    public Vector3 Forward
    {
        get
        {
			
            return Vector3.Transform(Vector3.Forward, Rotation);
        }
    }

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
	    Vector3 forward = Vector3.Normalize(target - Position);
	    Vector3 right = Vector3.Normalize(Vector3.Cross(up, forward));
	    Vector3 actualUp = Vector3.Cross(forward, right);
	    
	    // Create rotation matrix from basis vectors
	    Matrix rotMatrix = Matrix(
	        right.X, right.Y, right.Z, 0,
	        actualUp.X, actualUp.Y, actualUp.Z, 0,
	        forward.X, forward.Y, forward.Z, 0,
	        0, 0, 0, 1
	    );
	    
	    // Convert to quaternion
	    Rotation = Quaternion.CreateFromRotationMatrix(rotMatrix);
	    MarkDirty();
	}

	// Overload that uses default up vector
	public void LookAt(Vector3 target)
	{
	    LookAt(target, Vector3.Up);
	}
    
    private void UpdateWorldMatrix()
    {
        mWorldMatrix = Matrix.CreateScale(Scale) * 
                      Matrix.CreateFromQuaternion(Rotation) * 
                      Matrix.CreateTranslation(Position);
    }
    
    public void MarkDirty()
    {
        if (!mWorldMatrixDirty)
        {
            mWorldMatrixDirty = true;
            
            // Publish transform change message
            Entity.Scene.SceneGraph.MessageBus.Publish(new TransformChangedMessage(Entity, WorldMatrix));
        }
    }
}