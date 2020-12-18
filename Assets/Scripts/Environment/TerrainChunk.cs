using UnityEngine;

public class TerrainChunk
{

	const float colliderGenerationDistanceThreshold = 5;
	public event System.Action<TerrainChunk, bool> onVisibilityChanged;
	public Vector2 coord;

	GameObject meshObject;
	Vector2 sampleCentre;
	Bounds bounds;

	MeshRenderer meshRenderer;
	MeshFilter meshFilter;
	MeshCollider meshCollider;

	LODInfo[] detailLevels;
	LODMesh[] lodMeshes;
	int colliderLODIndex;

	HeightMap heightMap;
	bool heightMapReceived;
	int previousLODIndex = -1;
	bool hasSetCollider;
	float maxViewDst;

	HeightMapSettings heightMapSettings;
	MeshSettings meshSettings;
	TreeSettings treeSettings;
	Transform viewer;

	public TerrainChunk(Vector2 coord, HeightMapSettings heightMapSettings, MeshSettings meshSettings, TreeSettings treeSettings, LODInfo[] detailLevels, int colliderLODIndex, Transform parent, Transform viewer, Material material)
	{
		this.coord = coord;
		this.detailLevels = detailLevels;
		this.colliderLODIndex = colliderLODIndex;
		this.heightMapSettings = heightMapSettings;
		this.meshSettings = meshSettings;
		this.viewer = viewer;
		this.treeSettings = treeSettings;

		Debug.Log("Mesh Scale: " + meshSettings.meshScale);
		Debug.Log("Mesh World Size: " + meshSettings.meshWorldSize);




		sampleCentre = coord * meshSettings.meshWorldSize / meshSettings.meshScale;
		Vector2 position = coord * meshSettings.meshWorldSize;
		bounds = new Bounds(position, Vector2.one * meshSettings.meshWorldSize);

		Debug.Log("Sample Center: " + sampleCentre);


		meshObject = new GameObject("Terrain Chunk");
		meshRenderer = meshObject.AddComponent<MeshRenderer>();
		meshFilter = meshObject.AddComponent<MeshFilter>();
		meshCollider = meshObject.AddComponent<MeshCollider>();
		meshRenderer.material = material;

		meshObject.transform.position = new Vector3(position.x, 0, position.y);
		meshObject.transform.parent = parent;
		SetVisible(false);

		lodMeshes = new LODMesh[detailLevels.Length];
		for (int i = 0; i < detailLevels.Length; i++)
		{
			lodMeshes[i] = new LODMesh(detailLevels[i].lod);
			lodMeshes[i].updateCallback += UpdateTerrainChunk;
			if (i == colliderLODIndex)
			{
				lodMeshes[i].updateCallback += UpdateCollisionMesh;
			}
		}

		maxViewDst = detailLevels[detailLevels.Length - 1].visibleDstThreshold;

	}

	public void Load()
	{
		ThreadedDataRequester.RequestData(() => HeightMapGenerator.GenerateHeightMap(meshSettings.numVertsPerLine, meshSettings.numVertsPerLine, heightMapSettings, sampleCentre), OnHeightMapReceived);
	}



	void OnHeightMapReceived(object heightMapObject)
	{
		this.heightMap = (HeightMap)heightMapObject;
		heightMapReceived = true;

		UpdateTerrainChunk();
	}



	// void SpawnTrees() {
	// 	float maxRotation = 4;
	// 	float maxScaleDeviation = .2f;
	// 	float colorVariationFactor = 0.15f;
	// 	float minimumColor = .8f;

	// 	var spawnPrng = new System.Random (seed);
	// 	var treeHolder = new GameObject ("Tree holder").transform;

	// 	for (int y = 0; y < terrainData.size; y++){
	// 	for (int x = 0; x < terrainData.size; x++){
			
	// 		if (prng.NextDouble () < treeProbability){

	// 			float rotationX = Mathf.Lerp (-maxRotation, maxRotation, (float) spawnPrng.NextDouble ());
	// 			float rotationZ = Mathf.Lerp (-maxRotation, maxRotation, (float) spawnPrng.NextDouble ());
	// 			float rotationY = (float) spawnPrng.NextDouble () * 360f;

	// 			Quaternion rotation = Quaternion.Euler (rotationX, rotationY, rotationZ);
	// 			float scale = 1 + ((float) spawnPrng.NextDouble () * 2 - 1) * maxScaleDeviation;

	// 			// Randomize colour 

	// 			float treeColour = Mathf.Lerp (minimumColor, 1, (float) spawnPrng.NextDouble ());
	// 			float r = treeColour + ((float) spawnPrng.NextDouble () * 2 - 1) * colorVariationFactor;
	// 			float g = treeColour + ((float) spawnPrng.NextDouble () * 2 - 1) * colorVariationFactor;
	// 			float b = treeColour + ((float) spawnPrng.NextDouble () * 2 - 1) * colorVariationFactor;

	// 			// Spawn the tree

	// 			MeshRenderer tree = Instantiate (treePrefab, tileCenters[x, y], rotation);
	// 			tree.transform.parent = treeHolder;
	// 			tree.transform.localScale = Vector3.one * scale;
	// 			tree.material.color = new Color (r, g, b);

	// 			// Mark tile as unwalkable?
	// 			}
	// 			else
	// 			{
	// 				Debug.Log("Tree could not be added!");
	// 			}
	// 	}
	// 	}
	// }

	Vector2 viewerPosition
	{
		get
		{
			return new Vector2(viewer.position.x, viewer.position.z);
		}
	}


	public void UpdateTerrainChunk()
	{
		if (heightMapReceived)
		{
			float viewerDstFromNearestEdge = Mathf.Sqrt(bounds.SqrDistance(viewerPosition));

			bool wasVisible = IsVisible();
			bool visible = viewerDstFromNearestEdge <= maxViewDst;

			if (visible)
			{
				int lodIndex = 0;

				for (int i = 0; i < detailLevels.Length - 1; i++)
				{
					if (viewerDstFromNearestEdge > detailLevels[i].visibleDstThreshold)
					{
						lodIndex = i + 1;
					}
					else
					{
						break;
					}
				}

				if (lodIndex != previousLODIndex)
				{
					LODMesh lodMesh = lodMeshes[lodIndex];
					if (lodMesh.hasMesh)
					{
						previousLODIndex = lodIndex;
						meshFilter.mesh = lodMesh.mesh;
					}
					else if (!lodMesh.hasRequestedMesh)
					{
						lodMesh.RequestMesh(heightMap, meshSettings);
					}
				}


			}

			if (wasVisible != visible)
			{

				SetVisible(visible);
				if (onVisibilityChanged != null)
				{
					onVisibilityChanged(this, visible);
				}
			}
		}
	}

	public void UpdateCollisionMesh()
	{
		if (!hasSetCollider)
		{
			float sqrDstFromViewerToEdge = bounds.SqrDistance(viewerPosition);

			if (sqrDstFromViewerToEdge < detailLevels[colliderLODIndex].sqrVisibleDstThreshold)
			{
				if (!lodMeshes[colliderLODIndex].hasRequestedMesh)
				{
					lodMeshes[colliderLODIndex].RequestMesh(heightMap, meshSettings);
				}
			}

			if (sqrDstFromViewerToEdge < colliderGenerationDistanceThreshold * colliderGenerationDistanceThreshold)
			{
				if (lodMeshes[colliderLODIndex].hasMesh)
				{
					meshCollider.sharedMesh = lodMeshes[colliderLODIndex].mesh;
					hasSetCollider = true;
				}
			}
		}
	}

	public void SetVisible(bool visible)
	{
		meshObject.SetActive(visible);
	}

	public bool IsVisible()
	{
		return meshObject.activeSelf;
	}

}

class LODMesh
{

	public Mesh mesh;
	public bool hasRequestedMesh;
	public bool hasMesh;
	int lod;
	public event System.Action updateCallback;

	public LODMesh(int lod)
	{
		this.lod = lod;
	}

	void OnMeshDataReceived(object meshDataObject)
	{
		mesh = ((MeshData)meshDataObject).CreateMesh();
		hasMesh = true;

		updateCallback();
	}

	public void RequestMesh(HeightMap heightMap, MeshSettings meshSettings)
	{
		hasRequestedMesh = true;
		ThreadedDataRequester.RequestData(() => MeshGenerator.GenerateTerrainMesh(heightMap.values, meshSettings, lod), OnMeshDataReceived);
	}

}