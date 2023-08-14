using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// set Unit renderer color based on team
public class TeamColor : MonoBehaviour
{
    [SerializeField] private Color[] _colors;
    [SerializeField] private Material _material;

    public int Team { get; private set; }
    public Color Color => _colors[Team];

    public void SetColorFromTeam(int team)
    {
        Team = team;
        Color color = _colors[team];

        // create singular new material instance to share for all renderers
        Material teamMaterial = Instantiate(_material);
        // assign team color parameter on material
        teamMaterial.SetColor("_Color", color);
        // assign material to each renderer
        foreach (Renderer renderer in GetComponentsInChildren<Renderer>())
        {
            renderer.material = teamMaterial;
        }
    }
}
