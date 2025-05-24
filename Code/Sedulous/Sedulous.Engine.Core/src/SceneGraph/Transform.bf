using Sedulous.Foundation.Mathematics;
namespace Sedulous.Engine.Core.SceneGraph;

using internal Sedulous.Engine.Core.SceneGraph;

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
            if (Entity?.Scene?.mEngine != null)
            {
                Entity.Scene.mEngine.Messages.Publish(new TransformChangedMessage(Entity, WorldMatrix));
            }
        }
    }
}