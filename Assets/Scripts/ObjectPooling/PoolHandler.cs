using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Pool;

public class PoolHandler
{
    public LinkedPool<PooledObject> Pool { get; private set; }

    private PooledObject _prefab;
    private Vector3 _hidePosition = new Vector3(0f, -1000f, 0f);

    public PoolHandler(PooledObject prefab, int poolSize)
    {
        _prefab = prefab;
        Pool = new LinkedPool<PooledObject>(OnCreateItem, OnTakeItem, OnReturnItem, OnDestroyItem, true, poolSize);
        Debug.Log($"{_prefab.name} pool initialized with size {poolSize}");
    }

    private PooledObject OnCreateItem()
    {
        PooledObject instantiated = GameObject.Instantiate(_prefab, _hidePosition, Quaternion.identity);
        instantiated.Pool = Pool;

        return instantiated;
    }

    private void OnTakeItem(PooledObject obj)
    {
        obj.gameObject.SetActive(true);
    }

    private void OnReturnItem(PooledObject obj)
    {
        obj.transform.position = _hidePosition;
        obj.gameObject.SetActive(false);
    }

    private void OnDestroyItem(PooledObject obj)
    {
        GameObject.Destroy(obj.gameObject);
    }
}