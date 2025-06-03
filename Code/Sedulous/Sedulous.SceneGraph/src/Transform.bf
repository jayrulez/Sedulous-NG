using Sedulous.Mathematics;
using System;
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
    private bool mTransformChanged = false; // Track if transform changed this frame
    
    // Forward vector (typically -Z in right-handed systems)
    public Vector3 Forward
    {
        get
        {
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
            // Always return the cached matrix
            // It will be updated during the transform update phase
            return mWorldMatrix;
        }
    }
    
    // Called by the scene during transform update phase
    internal void UpdateTransform()
    {
        if (mWorldMatrixDirty)
        {
            UpdateWorldMatrix();
            mWorldMatrixDirty = false;
        }
    }
    
    // Check if transform changed this frame (used by Scene)
    internal bool WasTransformChanged()
    {
        return mTransformChanged;
    }
    
    // Reset the changed flag (called by Scene after sending message)
    internal void ResetChangedFlag()
    {
        mTransformChanged = false;
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
	}
	
	// Overload that uses default up vector
	public void LookAt(Vector3 target)
	{
	    LookAt(target, Vector3.Up);
	}
    
    private void UpdateWorldMatrix()
    {
        // Calculate local matrix
        var localMatrix = Matrix.CreateScale(mScale) * 
                         Matrix.CreateFromQuaternion(mRotation) * 
                         Matrix.CreateTranslation(mPosition);
        
        // Apply parent's world matrix if exists
        if (Entity != null && Entity.Parent != null)
        {
            mWorldMatrix = localMatrix * Entity.Parent.Transform.WorldMatrix;
        }
        else
        {
            mWorldMatrix = localMatrix;
        }
    }
    
    private void MarkDirty()
    {
        mWorldMatrixDirty = true;
        mTransformChanged = true;
        
        // Mark children as dirty too since parent transform affects them
        if (Entity != null)
        {
            for (var child in Entity.Children)
            {
                child.Transform.MarkDirty();
            }
        }
    }
    
    // World space properties (read-only, calculated from WorldMatrix)
    public Vector3 WorldPosition
    {
        get
        {
            var m = WorldMatrix;
            return Vector3(m.M41, m.M42, m.M43);
        }
    }
    
    public Quaternion WorldRotation
    {
        get
        {
            // Extract rotation from world matrix (assuming no skew)
            var m = WorldMatrix;
            
            // Remove scale from matrix
            var scaleX = Math.Sqrt(m.M11 * m.M11 + m.M12 * m.M12 + m.M13 * m.M13);
            var scaleY = Math.Sqrt(m.M21 * m.M21 + m.M22 * m.M22 + m.M23 * m.M23);
            var scaleZ = Math.Sqrt(m.M31 * m.M31 + m.M32 * m.M32 + m.M33 * m.M33);
            
            var rotMatrix = Matrix(
                m.M11 / scaleX, m.M12 / scaleX, m.M13 / scaleX, 0,
                m.M21 / scaleY, m.M22 / scaleY, m.M23 / scaleY, 0,
                m.M31 / scaleZ, m.M32 / scaleZ, m.M33 / scaleZ, 0,
                0, 0, 0, 1
            );
            
            return Quaternion.CreateFromRotationMatrix(rotMatrix);
        }
    }
    
    public Vector3 WorldScale
    {
        get
        {
            var m = WorldMatrix;
            var scaleX = Math.Sqrt(m.M11 * m.M11 + m.M12 * m.M12 + m.M13 * m.M13);
            var scaleY = Math.Sqrt(m.M21 * m.M21 + m.M22 * m.M22 + m.M23 * m.M23);
            var scaleZ = Math.Sqrt(m.M31 * m.M31 + m.M32 * m.M32 + m.M33 * m.M33);
            return Vector3(scaleX, scaleY, scaleZ);
        }
    }
}