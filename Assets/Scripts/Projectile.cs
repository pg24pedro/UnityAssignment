using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// damages Units in (optional) radius
// spawns Explosion prefab when dealing damage
// set up to work with pool system
public class Projectile : PooledObject
{
    [Header("Projectile")]
    [SerializeField] private float _damage = 10f;
    [SerializeField] private float _lifeTime = 3f;
    [SerializeField] private float _velocity = 10f;
    [SerializeField] private float _explosionRadius = 5f;
    [SerializeField] private Explosion _explosionPrefab;
    [SerializeField] private LayerMask _unitMask;

    public int Team { get; set; }

    private static Collider[] _hits = new Collider[24];
    private Rigidbody _rigidbody;
    private TrailRenderer _trail;

    private void Awake()
    {
        _rigidbody = GetComponent<Rigidbody>();
        _trail = GetComponent<TrailRenderer>();
    }

    // clears trail segments when enabled
    private void OnEnable()
    {
        if (_trail != null) _trail.Clear();
    }

    // launch projectile forwards, assigning team for collision/damage purposes
    public void Fire(int team)
    {
        Team = team;
        _rigidbody.velocity = transform.forward * _velocity;
        Invoke(nameof(Release), _lifeTime);
    }

    // return projecile to pool
    private void Release()
    {
        if (!gameObject.activeInHierarchy) return;
        Pool?.Release(this);
    }

    // deal damage when passing through enemy
    private void OnTriggerEnter(Collider other)
    {
        
        // filter for allies
        if(other.TryGetComponent(out Unit hit) && hit.Team == Team) return;

        if(other.GetComponent<Unit>() == false) return;

        // do AoE damage if radius is non-zero
        if(_explosionRadius > 0f)
        {
            // find nearby colliders and damage enemies (comparing team)
            int count = Physics.OverlapSphereNonAlloc(transform.position, _explosionRadius, _hits, _unitMask);
            for (int i = 0; i < count; i++)
            {
                if (_hits[i].TryGetComponent(out Unit unit) && unit.Team != Team) unit.Damage(_damage);
            }

            // spawn explosion prefab from pool system
            Explosion explosion = PoolSystem.Instance.Get(_explosionPrefab, transform.position, transform.rotation) as Explosion;
            explosion.Radius = _explosionRadius;
        }
        else // single target damage fallback
        {
            hit.Damage(_damage);
           
        }

        // return to pool
        Release();
    }

    private void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.position, _explosionRadius);
    }
}
