using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;
using UnityEngine.Events;

// filter type to control Unit targeting
public enum UnitType
{
    None,
    Ground,
    Flyer
}

// unified class for all Units in project
// handles health, damage, movement, targeting, and attacks
public class Unit : PooledObject
{
    [Header("Unit")]
    [SerializeField] private UnitType _unitType = UnitType.Ground;
    [SerializeField] private int _team;
    [SerializeField] private float _currentHealth = 100f;
    [SerializeField] private float _maxHealth = 100f;

    [Header("Targeting")]
    [SerializeField] private LayerMask _unitMask;
    [SerializeField] private LayerMask _occlusionMask;
    [SerializeField] private float _visionRadius = 10f;
    [SerializeField] private float _attackDistance = 5f;
    [SerializeField] private Transform _center;
    [SerializeField] private UnitType _ignoreType = UnitType.None;

    public int Team { get => _team; set => _team = value; }
    public Vector3 Position => transform.position;
    public Vector3 CenterPosition => _center.position;
    public Vector3 Objective { get; set; }
    public float HealthPercentage => _currentHealth / _maxHealth;
    public bool IsAlive => _currentHealth > 0f;
    public UnitType UnitType => _unitType;

    public UnityEvent<Unit> OnDeath;
    public UnityEvent OnDamage;

    private Unit _target;
    private NavMeshAgent _agent;
    private Weapon _weapon;
    private Collider[] _hits = new Collider[24];

    private void Awake()
    {
        _agent = GetComponent<NavMeshAgent>();
        _weapon = GetComponent<Weapon>();
    }

    // initialize Unit with team and objective destination
    public void Init(int team, Vector3 objective)
    {
        Team = team;
        Objective = objective;
        _currentHealth = _maxHealth;
        _target = null;
        _agent.enabled = true;
    }

    // disable NavMeshAgent when disabled (returned to pool)
    private void OnDisable()
    {
        _agent.enabled = false;
    }

    private void Update()
    {
        // find new target if current is null or dead
        if (_target == null || !_target.IsAlive) _target = FindTarget();

        if (_target != null && _target.IsAlive)
        {
            // attack target if within range and visible
            if(Vector3.Distance(CenterPosition, _target.CenterPosition) < _attackDistance && CanSee(_target.CenterPosition))
            {
                Stop();
                Vector3 dirToTarget = (_target.CenterPosition - CenterPosition).normalized;
                _weapon.TryFire(dirToTarget, Team);
            }
            else // otherwise move to target
            {
                Moveto(_target.Position);
            }
        }
        else // move to Objective if no target is found
        {
            Moveto(Objective);
        }
    }

    // navigate to destination
    private void Moveto(Vector3 destination)
    {
        _agent.isStopped = false;
        _agent.SetDestination(destination);
    }

    // stop movement
    private void Stop()
    {
        _agent.ResetPath();
        _agent.isStopped = true;
    }

    // find new valid target to attack
    private Unit FindTarget()
    {
        // find all colliders in range on Unit layer
        _hits = Physics.OverlapSphere(CenterPosition, _visionRadius, _unitMask);

        for (int i = 0; i < _hits.Length; i++)
        {
            Collider hit = _hits[i];
            // filter for a Unit that is alive, an enemy, and not an ignored type
            if (hit.TryGetComponent(out Unit unit) && 
                unit.IsAlive && 
                unit.Team != Team && 
                unit.UnitType != _ignoreType &&
                CanSee(unit.CenterPosition)) return unit;
        }

        // fallback return null if no target is found
        return null;
    }

    // test visiblity of a position
    private bool CanSee(Vector3 position)
    {
        return !Physics.Linecast(CenterPosition, position, _occlusionMask);
    }

    // damage Unit if alive
    public void Damage(float amount)
    {
        if (!IsAlive) return;

        _currentHealth = Mathf.Clamp(_currentHealth - amount, 0f, _maxHealth);
        OnDamage.Invoke();
        

        if (!IsAlive)
        {
            OnDeath.Invoke(this);
            Pool.Release(this);
        }
        
    }

    private void OnDrawGizmosSelected()
    {
        // visualize vision and attack distances (white/red sphere)
        Gizmos.color = Color.white;
        Gizmos.DrawWireSphere(Position, _visionRadius);

        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(Position, _attackDistance);

        // visualize possible attack targets (yellow line)
        if (_hits != null)
        {
            Gizmos.color = Color.yellow;
            for (int i = 0; i < _hits.Length; i++)
            {
                if (_hits[i] == null) continue;
                Gizmos.DrawLine(CenterPosition, _hits[i].transform.position);
            }
        }

        // visualize target (red line)
        if(_target != null)
        {
            Gizmos.color = Color.red;
            Gizmos.DrawLine(CenterPosition, _target.CenterPosition);
        }
    }
}