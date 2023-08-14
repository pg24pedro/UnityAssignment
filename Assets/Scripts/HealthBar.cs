using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

// displays Unit HealthPercentage on canvas Image component with Image Type set to Filled
// updates bar color to match Unit team color
public class HealthBar : MonoBehaviour
{
    [SerializeField] private Image _bar;

    private Unit _unit;
    private TeamColor _teamColor;

    private void Awake()
    {
        _unit = GetComponentInParent<Unit>();
        _teamColor = _unit.GetComponent<TeamColor>();
    }

    private void Update()
    {
        _bar.color = _teamColor.Color;
        transform.rotation = Camera.main.transform.rotation;
        _bar.fillAmount = _unit.HealthPercentage;
    }
}