using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class Test : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Q))
        {
            GetComponent<Image>().material.SetFloat("_GrayEnabled", -1);
            Debug.Log(1);
        }
        if (Input.GetKeyDown(KeyCode.W))
        {
            GetComponent<Image>().material.SetFloat("_GrayEnabled", 1);
            Debug.Log(2);
        }
    }
}
