using UnityEngine;

/// <summary>
/// Rotates the object around the global Y axis
/// </summary>
public class Rotate : MonoBehaviour
{
    /// <summary>
    /// Angle to rotate per second
    /// </summary>
    public float Speed = 10.0f;

    // Update is called once per frame
    void Update()
    {
        transform.Rotate(Vector3.up, Speed * Time.deltaTime, Space.World);
    }
}
