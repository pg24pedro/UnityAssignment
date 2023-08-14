using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

// updates Animator with normalized "Speed" value from NavMeshAgent
public class MechAnimations : MonoBehaviour
{
    [SerializeField] private float _dampTime = 0.1f;

    private Animator _animator;
    private NavMeshAgent _agent;

    private void Start()
    {
        _animator = GetComponent<Animator>();
        _agent = GetComponent<NavMeshAgent>();
    }

    private void Update()
    {
        _animator.SetFloat("Speed", _agent.velocity.magnitude / _agent.speed, _dampTime, Time.deltaTime);
    }
}