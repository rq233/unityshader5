
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassGroup : MonoBehaviour
{
    [Tooltip("是否打开编辑")]
    public bool editorMode = false;
    [Tooltip("预制体")]
    public GameObject grassPrefab = null;
    [Tooltip("地形")]
    public Terrain terrain = null;
    [Tooltip("随机朝向")]
    public bool roodomRotationY = true;
    [Tooltip("随时缩放最小值")]
    public float minScale = 1;
    [Tooltip("随时缩放最小值")]
    public float maxScale = 1;
    [Tooltip("半径")]
    [HideInInspector]
    public float radius = 1;
    [Tooltip("数量")]
    [HideInInspector]
    public int count = 1;
 
    // Use this for initialization
    void Start ()
    {
        editorMode = false;
    }
    /// <summary>
    /// 生成子草
    /// </summary>
    /// <param name="postion"></param>
    public void AddGrassNode(Vector3 postion)
    {
        if (grassPrefab == null)
        {
            Debug.LogError("草预制件不能为空！！！！！");
            return;
        }
 
        if (terrain == null)
        {
            Debug.LogError("地形不能为空！！！！！");
            return;
        }
 
        for (int i = 0;i<count; i++)
        {
            GameObject go = GameObject.Instantiate(grassPrefab);
            go.transform.SetParent(transform);
            Vector2 p = Random.insideUnitCircle * radius;//将位置设置为一个半径为radius中心点在原点的圆圈内的某个点X.  
            Vector2 pos2 = p.normalized * (p.magnitude);
            Vector3 pos3 = new Vector3(pos2.x, 0, pos2.y) + postion;
            float y = terrain.SampleHeight(pos3);
            Vector3 pos = new Vector3(pos3.x ,y, pos3.z);
            go.transform.position = pos;
            if (roodomRotationY)
                go.transform.Rotate(new Vector3(0, 0, 1),Random.Range(0,360) );
            float scale = Random.Range(minScale, maxScale);
            go.transform.localScale = new Vector3(scale, scale, scale);
            go.name = "grass_" + transform.childCount.ToString();
        }
    }
}