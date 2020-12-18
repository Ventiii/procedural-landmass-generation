using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]// making sure that the gameobject has a MeshFilter component
[RequireComponent(typeof(MeshRenderer))]	// making sure that the gameobject has a MeshRenderer component
public class WaterController : MonoBehaviour {
    /* This class creates a custom mesh that resembles a water (or other fluid) surface. The surface consists of 
        a grid of points that extends along the X and Z axes. Those points have a fixed X and Z position, but their 
        Y-value can be animated through time, using sinusoidal functions and thus create the effect of waves.
        The Waves are created in relation to the position of any scene object which is tagged as "wavesource".
        You can alter the number of wavesources and their position and see the effect that it has on the waves. */

    List<GameObject> waterSources; // All wave sources collected by tag

    // Variables

    float waterLevelY; // the water - surface's level (along the Y - axis)
    float surfaceActualWidth; // surface - dimension along the X-axis
    float surfaceActualLength;  // surface - dimension along the Z-axis
    int surfaceWidthPoints;  // number of points on the X-axis
    int surfaceLengthPoints;  // number of points on the Z-axis
    float localTime; // The current time which is used for animating the waves 
    float localTimeScale; // Local Time Scale - Makes animation go faster or slower


    // Initialisation
    void Awake()
    {
        waterLevelY = 0.0f;
        surfaceActualWidth = 10;
        surfaceActualLength = 10;
        surfaceWidthPoints = 100;
        surfaceLengthPoints = 100;
        localTime = 0.0f;
        localTimeScale = 2.0f;

        CreateMesh();  // Create the initial geometry of the water mesh 

        waterSources = new List<GameObject> ();
        waterSources = GameObject.FindGameObjectsWithTag ("watersource").ToList(); // Find all the wave sources 
    }

    void Update()
    {
        localTime += Time.deltaTime * localTimeScale; // Advance local time...
        UpdateWaterMesh(); // Update the geometry of the created mesh (which is where the animation happens)
    }


    private void UpdateWaterMesh()
    {
        /*
            This function updates the water mesh by recalculating each points 
            y - value using the CalculateWaterY() function
        */

        Mesh waterMesh = GetComponent<MeshFilter>().mesh; // Gets the current mesh filter 
        Vector3[] vertices = waterMesh.vertices; //get the mesh's vertices

        for (int i = 0; i < vertices.Length; i++) //cycle through all the vertices of the mesh
        { 
            float x = vertices [i].x; // value of X stays the same
            float y = RecalculatePointY (vertices[i]); // calculate the new Y-value for the mesh, using the calculateWaterY() function
            float z = vertices [i].z; // value of Z stays the same
            Vector3 p = new Vector3 (x, y, z); //create a new point (with updated Y - value)
            vertices [i] = p; //replace the vertice
        }

        waterMesh.vertices = vertices; //pass the updated vertices array to the existing mesh
        waterMesh.RecalculateNormals(); //recalculate the normals of the surface inorder to have correct shading
    }

    /*
        This function recalculates the Y - value of each point of the water - surface
		by applying a sinusoidal function on the point, for each of the wave - sources
		that there are in the scene.
    */

    private float RecalculatePointY (Vector3 point)
    {
        float y = 0.0f; // Initialize the y value (Set as zero)
        for (int i = 0; i < waterSources.Count; i++){
            // Cycle through all the wave sources 
            Vector2 p1 = new Vector2 (point.x, point.z); // 2D - Version of the incoming 3d position.
            Vector2 p2 = new Vector2 (waterSources[i].transform.position.x, waterSources[i].transform.position.z); // the wave-source's 2d-position
            float distance = Vector2.Distance (p1, p2); //the distance between the water-point and the current wave source
            y += Mathf.Sin (distance * 12.0f - localTime) / (distance * 20.0f + 10.0f); // // apply the first wave    
        }

        y += waterLevelY;
        return y;
    }

    /* 
        This function creates the mesh object - triangle by triangle - 
        and then applies it to the Mesh Filter's mesh.
    */
    private void CreateMesh()
    {
        Mesh newMesh = new Mesh();
        List<Vector3> verticesList = new List<Vector3> (); // list that will hold the mesh vertices
        List<Vector2> uvsList = new List<Vector2> (); // list that will hold the mesh UVs
        List<int> trianglesList = new List<int> (); // list that will hold the mesh triangles

        // Mesh - data creation double loop

        for (int i = 0; i < surfaceWidthPoints; i++){
        for (int j = 0; j < surfaceLengthPoints; j++){
            
            float x = MapValue (i, 0.0f, surfaceWidthPoints, -surfaceActualWidth / 2.0f, surfaceActualWidth / 2.0f);
            float z = MapValue (j, 0.0f, surfaceLengthPoints, -surfaceActualLength / 2.0f, surfaceActualLength / 2.0f);

            verticesList.Add(new Vector3 (x, 0f, z));
            uvsList.Add(new Vector2 (x, z));
            // Skip if a new square on the plane hasnt been formed.
            if (i == 0 || j == 0)
                continue;
            //Adds the index of the three vertices in order to make up each of the two triangles
            trianglesList.Add (surfaceLengthPoints * i + j); // Top right
            trianglesList.Add (surfaceLengthPoints * i + j - 1); // Bottom Right
            trianglesList.Add (surfaceLengthPoints * (i - 1) + j - 1); // Bottom left - First triangle
            trianglesList.Add (surfaceLengthPoints * (i - 1) + j - 1); // Bottom Left
            trianglesList.Add (surfaceLengthPoints * (i - 1) + j); // Top left
            trianglesList.Add (surfaceLengthPoints * i + j); // Top right second triangle
        }
        }


        // Creating the mesh with the data that has been generated 
        newMesh.vertices = verticesList.ToArray(); // Pass vertices to mesh 
        newMesh.uv = uvsList.ToArray(); // Pass uvs list to mesh 
        newMesh.triangles = trianglesList.ToArray(); // Pass triangles to mesh 
        newMesh.RecalculateNormals (); // Recalculate mesh normals 
        GetComponent<MeshFilter>().mesh = newMesh; // Pass the created mesh to the mesh filter.
    }

/*
        This function converts the value of a variable (reference value) from one range 
        (reference range) to another (target range) in this example it is used to convert 
        the x and z value to the correct range, while creating the mesh, in the CreateMesh() 
        function
*/
    private float MapValue (float referenceValue, float referenceMinimum, float referenceMaximum, float targetMinimum, float targetMaximum)
    {
        return targetMinimum + (referenceValue - referenceMinimum) * (targetMaximum - targetMinimum) / (referenceMaximum - referenceMinimum);
    } 
}