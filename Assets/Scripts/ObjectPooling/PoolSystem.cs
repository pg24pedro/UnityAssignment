using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PoolSystem : MonoBehaviour
{
    private static PoolSystem _instance;
    public static PoolSystem Instance
    {
        get
        {
            if (_instance == null)
            {
                GameObject go = new GameObject("PoolSystem");
                _instance = go.AddComponent<PoolSystem>();
                Debug.Log("Pool System initialized");
            }

            return _instance;
        }
        private set => _instance = value;
    }

    private static Dictionary<PooledObject, PoolHandler> _poolHandlers;

    private void Awake()
    {
        if (_instance != null)
        {
            Debug.LogWarning("Duplicate Pool System created, destroying!");
            Destroy(gameObject);
            return;
        }

        Instance = this;
        _poolHandlers = new Dictionary<PooledObject, PoolHandler>();
    }

    public PooledObject Get(PooledObject prefab, Vector3 position, Quaternion rotation)
    {
        if(!_poolHandlers.ContainsKey(prefab))
        {
            PoolHandler pool = new PoolHandler(prefab, prefab.PoolSize);
            _poolHandlers.Add(prefab, pool);
        }

        PooledObject po = _poolHandlers[prefab].Pool.Get();
        po.transform.SetPositionAndRotation(position, rotation);
        return po;
    }
}
