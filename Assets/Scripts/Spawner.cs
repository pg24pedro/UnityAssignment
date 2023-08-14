using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

// spawns Units up to a limiting count
public class Spawner : MonoBehaviour
{
    [SerializeField] private int _team = 0;
    [SerializeField] private Transform _target;
    [SerializeField] private Unit _prefab;
    [SerializeField] private int _count = 10;
    [SerializeField] private float _spawnPeriod = 2f;

    private List<Unit> _units = new List<Unit>();

    private IEnumerator Start()
    {
        WaitForSeconds wait = new WaitForSeconds(_spawnPeriod);

        while (true)
        {
            // limit spawn rate based on period
            yield return wait;

            // wait while limit is reached
            while (_units.Count >= _count) yield return wait;

            // spawn pooled Unit, initialize with correct team/color
            Unit spawned = PoolSystem.Instance.Get(_prefab, transform.position, transform.rotation) as Unit;
            spawned.GetComponent<TeamColor>().SetColorFromTeam(_team);
            spawned.Init(_team, _target.position);

            // add to tracking list and listen for Unit death
            _units.Add(spawned);
            spawned.OnDeath.AddListener(OnUnitDeath);
        }
    }

    // remove Unit from tracking list on death
    private void OnUnitDeath(Unit dead)
    {
        if (!_units.Contains(dead)) return;
        dead.OnDeath.RemoveListener(OnUnitDeath);
        _units.Remove(dead);
    }
}
