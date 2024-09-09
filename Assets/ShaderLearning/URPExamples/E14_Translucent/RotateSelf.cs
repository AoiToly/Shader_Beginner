using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotateSelf : MonoBehaviour
{
    public float Speed = 20;
    void Update()
    {
        transform.Rotate(0, Speed * Time.deltaTime, 0);
    }
}
