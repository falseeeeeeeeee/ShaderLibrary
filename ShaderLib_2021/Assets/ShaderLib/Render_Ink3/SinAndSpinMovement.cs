using UnityEngine;

public class SinAndSpinMovement : MonoBehaviour
{
    public Vector3 speedRange = new Vector3(1f, 1f, 1f); // 移动的速度范围
    public Vector3 spinSpeedRange = new Vector3(50f, 50f, 50f); // 自旋转速度范围
    public Vector3 maxDistance = new Vector3(2f, 3f, 4f); // 限制物体移动位置的最大范围

    private Vector3 initialPosition;
    private Vector3 initialRotation;
    private Vector3 amplitudeRange;
    private Vector3 direction;

    void Start()
    {
        // 记录物体的初始位置
        initialPosition = transform.position;

        // 设置振幅大小为物体位置的随机值
        float randomAmplitudeX = Random.Range(-maxDistance.x, maxDistance.x);
        float randomAmplitudeY = Random.Range(-maxDistance.y, maxDistance.y);
        float randomAmplitudeZ = Random.Range(-maxDistance.z, maxDistance.z);

        // 计算振幅范围
        amplitudeRange = new Vector3(randomAmplitudeX, randomAmplitudeY, randomAmplitudeZ);

        // 计算随机移动方向
        direction = new Vector3(Random.Range(-1f, 1f), Random.Range(-1f, 1f), Random.Range(-1f, 1f)).normalized;

        // 记录物体的初始旋转
        initialRotation = transform.eulerAngles;
    }

    void Update()
    {
        // 计算sin值，根据时间移动物体位置
        float yPos = initialPosition.y + Mathf.Sin(Time.time * speedRange.y * direction.y) * amplitudeRange.y;
        float xPos = initialPosition.x + Mathf.Sin(Time.time * speedRange.x * direction.x) * amplitudeRange.x;
        float zPos = initialPosition.z + Mathf.Sin(Time.time * speedRange.z * direction.z) * amplitudeRange.z;

        // 更新物体位置
        transform.position = new Vector3(xPos, yPos, zPos);

        // 如果达到最大范围，反转移动方向
        if (Mathf.Abs(xPos - initialPosition.x) > maxDistance.x || Mathf.Abs(yPos - initialPosition.y) > maxDistance.y || Mathf.Abs(zPos - initialPosition.z) > maxDistance.z)
        {
            direction = -direction;
        }

        // 计算自旋转
        float spinX = initialRotation.x + Time.time * spinSpeedRange.x;
        float spinY = initialRotation.y + Time.time * spinSpeedRange.y;
        float spinZ = initialRotation.z + Time.time * spinSpeedRange.z;

        // 更新物体旋转
        transform.rotation = Quaternion.Euler(spinX, spinY, spinZ);
    }
}
