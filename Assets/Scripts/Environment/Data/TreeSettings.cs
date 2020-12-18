using UnityEngine;
using System.Collections;

[CreateAssetMenu()]
public class TreeSettings : UpdatableData {

    [Header("Trees")]
    public int seed;
    public MeshRenderer treePrefab;
    [Range (0, 1)]
    public float treeProbability = 0.2f;
    static System.Random prng;
    
    public float treeSpawnMultiplier;
    public AnimationCurve treeSpawnCurve;

    public float minHeight {
        get {
            return treeSpawnMultiplier * treeSpawnCurve.Evaluate (0);
        }
    }

    public float maxHeight {
        get {
            return treeSpawnMultiplier * treeSpawnCurve.Evaluate (1);
        }
    }

}