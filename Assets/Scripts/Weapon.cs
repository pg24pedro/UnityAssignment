using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// fire Projectiles limited by RPM, cycles through assigned muzzle transforms
public class Weapon : MonoBehaviour
{
    [SerializeField] private Projectile _projectilePrefab;
    [SerializeField] private float _RPM = 60f;
    [SerializeField] private Transform[] _muzzles;

    private float FirePeriod => 60f / _RPM;
    private float _lastFireTime;
    private int _muzzleIndex;

    // attempt to fire weapon, limited by RPM
    public void TryFire(Vector3 direction, int team)
    {
        // prevent firing if too soon
        if (Time.time < _lastFireTime + FirePeriod) return;
        _lastFireTime = Time.time;

        // select next muzzle to spawn from
        Transform muzzle = _muzzles[_muzzleIndex++ % _muzzles.Length];
        // spawn projectile from pool system and fire with team
        Projectile projectile = PoolSystem.Instance.Get(_projectilePrefab, muzzle.transform.position, Quaternion.LookRotation(direction)) as Projectile;
        projectile.Fire(team);
    }
}