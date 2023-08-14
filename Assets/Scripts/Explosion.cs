using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// scales a prefab mesh over time based on AnimationCurve
public class Explosion : PooledObject
{
    [Header("Explosion")]
    [SerializeField] private float _duration = 0.25f;
    [SerializeField] private AnimationCurve _scaleAnimation;

    public float Radius { get; set; } = 5f;

    private void OnEnable()
    {
        StartCoroutine(Animate());
    }

    private IEnumerator Animate()
    {
        float timer = 0f;
        while (timer < _duration)
        {
            timer += Time.deltaTime;
            float progress = timer / _duration;
            transform.localScale = _scaleAnimation.Evaluate(progress) * 2f * Radius * Vector3.one;

            yield return null;
        }

        Pool.Release(this);
    }
}