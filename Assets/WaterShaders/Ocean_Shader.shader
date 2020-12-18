// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Ocean_Shader"
{
	Properties
	{
		_WaveSpeed("Wave Speed", Float) = 1
		_WaveTile("Wave Tile", Float) = 1
		_WaveHeight("Wave Height", Float) = 1
		_WaterColor("Water Color", Color) = (0.1415984,0.6083747,0.8113208,0)
		_TopColor("Top Color", Color) = (0.123754,0.9439473,0.9716981,0)
		_EdgeDistance("Edge Distance", Float) = 1
		_EdgePower("Edge Power", Range( 0 , 1)) = 1
		_NormalSpeed("Normal Speed", Float) = 1
		_NormalStrength("Normal Strength", Range( 0 , 1)) = 1
		_NormalTile("Normal Tile", Float) = 1
		_NormalMap("Normal Map", 2D) = "bump" {}
		_SeaFoam("Sea Foam", 2D) = "white" {}
		_EdgeFoamTile("Edge Foam Tile", Float) = 1
		_SeaFoamTile("Sea Foam Tile", Float) = 1
		_RefractAmount("Refract Amount", Float) = 0.1
		_Depth("Depth", Float) = -4
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Off
		GrabPass{ }
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#include "UnityStandardUtils.cginc"
		#include "UnityCG.cginc"
		#include "Tessellation.cginc"
		#pragma target 4.6
		#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
		#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex);
		#else
		#define ASE_DECLARE_SCREENSPACE_TEXTURE(tex) UNITY_DECLARE_SCREENSPACE_TEXTURE(tex)
		#endif
		#pragma surface surf Standard keepalpha noshadow vertex:vertexDataFunc tessellate:tessFunction 
		struct Input
		{
			float3 worldPos;
			float4 screenPos;
		};

		uniform float _WaveHeight;
		uniform float _WaveSpeed;
		uniform float _WaveTile;
		uniform sampler2D _NormalMap;
		uniform float _NormalSpeed;
		uniform float _NormalTile;
		uniform float _NormalStrength;
		uniform float4 _WaterColor;
		uniform float4 _TopColor;
		uniform sampler2D _SeaFoam;
		uniform float _SeaFoamTile;
		ASE_DECLARE_SCREENSPACE_TEXTURE( _GrabTexture )
		uniform float _RefractAmount;
		UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
		uniform float4 _CameraDepthTexture_TexelSize;
		uniform float _Depth;
		uniform float _EdgeDistance;
		uniform float _EdgeFoamTile;
		uniform float _EdgePower;


		float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }

		float snoise( float2 v )
		{
			const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
			float2 i = floor( v + dot( v, C.yy ) );
			float2 x0 = v - i + dot( i, C.xx );
			float2 i1;
			i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
			float4 x12 = x0.xyxy + C.xxzz;
			x12.xy -= i1;
			i = mod2D289( i );
			float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
			float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
			m = m * m;
			m = m * m;
			float3 x = 2.0 * frac( p * C.www ) - 1.0;
			float3 h = abs( x ) - 0.5;
			float3 ox = floor( x + 0.5 );
			float3 a0 = x - ox;
			m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
			float3 g;
			g.x = a0.x * x0.x + h.x * x0.y;
			g.yz = a0.yz * x12.xz + h.yz * x12.yw;
			return 130.0 * dot( m, g );
		}


		inline float4 ASE_ComputeGrabScreenPos( float4 pos )
		{
			#if UNITY_UV_STARTS_AT_TOP
			float scale = -1.0;
			#else
			float scale = 1.0;
			#endif
			float4 o = pos;
			o.y = pos.w * 0.5f;
			o.y = ( pos.y - o.y ) * _ProjectionParams.x * scale + o.y;
			return o;
		}


		float4 tessFunction( appdata_full v0, appdata_full v1, appdata_full v2 )
		{
			float4 Tessellation135 = UnityDistanceBasedTess( v0.vertex, v1.vertex, v2.vertex, 0.0,80.0,( _WaveHeight * 8.0 ));
			return Tessellation135;
		}

		void vertexDataFunc( inout appdata_full v )
		{
			float temp_output_8_0 = ( _Time.y * _WaveSpeed );
			float2 _WaveDirection = float2(-1,0);
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			float4 appendResult11 = (float4(ase_worldPos.x , ase_worldPos.z , 0.0 , 0.0));
			float4 worldSpaceTile12 = appendResult11;
			float4 WaveTileUV22 = ( ( worldSpaceTile12 * float4( float2( 0.15,0.02 ), 0.0 , 0.0 ) ) * _WaveTile );
			float2 panner3 = ( temp_output_8_0 * _WaveDirection + WaveTileUV22.xy);
			float simplePerlin2D1 = snoise( panner3 );
			simplePerlin2D1 = simplePerlin2D1*0.5 + 0.5;
			float2 panner26 = ( temp_output_8_0 * _WaveDirection + ( WaveTileUV22 * float4( 0.1,0.1,0,0 ) ).xy);
			float simplePerlin2D27 = snoise( panner26 );
			simplePerlin2D27 = simplePerlin2D27*0.5 + 0.5;
			float temp_output_29_0 = ( simplePerlin2D1 * simplePerlin2D27 );
			float3 WaveHeight35 = ( ( float3(0,1,0) * _WaveHeight ) * temp_output_29_0 );
			v.vertex.xyz += WaveHeight35;
			v.vertex.w = 1;
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float3 ase_worldPos = i.worldPos;
			float4 appendResult11 = (float4(ase_worldPos.x , ase_worldPos.z , 0.0 , 0.0));
			float4 worldSpaceTile12 = appendResult11;
			float4 temp_output_82_0 = ( worldSpaceTile12 / 10.0 );
			float2 panner68 = ( 1.0 * _Time.y * ( float2( 1,0 ) * _NormalSpeed ) + ( temp_output_82_0 * _NormalTile ).xy);
			float2 panner69 = ( 1.0 * _Time.y * ( float2( -1,0 ) * ( _NormalSpeed * 3.0 ) ) + ( temp_output_82_0 * ( _NormalTile * 5.0 ) ).xy);
			float3 Normals79 = BlendNormals( UnpackScaleNormal( tex2D( _NormalMap, panner68 ), _NormalStrength ) , UnpackScaleNormal( tex2D( _NormalMap, panner69 ), _NormalStrength ) );
			o.Normal = Normals79;
			float2 panner103 = ( 1.0 * _Time.y * float2( 0.04,-0.03 ) + ( worldSpaceTile12 * 0.3 ).xy);
			float simplePerlin2D102 = snoise( panner103 );
			float clampResult109 = clamp( ( tex2D( _SeaFoam, ( ( worldSpaceTile12 / 10.0 ) * _SeaFoamTile ).xy ).r * simplePerlin2D102 ) , 0.0 , 1.0 );
			float SeaFoam99 = clampResult109;
			float temp_output_8_0 = ( _Time.y * _WaveSpeed );
			float2 _WaveDirection = float2(-1,0);
			float4 WaveTileUV22 = ( ( worldSpaceTile12 * float4( float2( 0.15,0.02 ), 0.0 , 0.0 ) ) * _WaveTile );
			float2 panner3 = ( temp_output_8_0 * _WaveDirection + WaveTileUV22.xy);
			float simplePerlin2D1 = snoise( panner3 );
			simplePerlin2D1 = simplePerlin2D1*0.5 + 0.5;
			float2 panner26 = ( temp_output_8_0 * _WaveDirection + ( WaveTileUV22 * float4( 0.1,0.1,0,0 ) ).xy);
			float simplePerlin2D27 = snoise( panner26 );
			simplePerlin2D27 = simplePerlin2D27*0.5 + 0.5;
			float temp_output_29_0 = ( simplePerlin2D1 * simplePerlin2D27 );
			float WavePattern32 = temp_output_29_0;
			float clampResult46 = clamp( WavePattern32 , 0.0 , 1.0 );
			float4 lerpResult43 = lerp( _WaterColor , ( _TopColor + SeaFoam99 ) , clampResult46);
			float4 Albedo49 = lerpResult43;
			float4 ase_screenPos = float4( i.screenPos.xyz , i.screenPos.w + 0.00000000001 );
			float4 ase_grabScreenPos = ASE_ComputeGrabScreenPos( ase_screenPos );
			float4 ase_grabScreenPosNorm = ase_grabScreenPos / ase_grabScreenPos.w;
			float4 screenColor117 = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture,( float3( (ase_grabScreenPosNorm).xy ,  0.0 ) + ( _RefractAmount * Normals79 ) ).xy);
			float4 clampResult118 = clamp( screenColor117 , float4( 0,0,0,0 ) , float4( 1,1,1,0 ) );
			float4 Refraction119 = clampResult118;
			float4 ase_screenPosNorm = ase_screenPos / ase_screenPos.w;
			ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
			float screenDepth123 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy ));
			float distanceDepth123 = abs( ( screenDepth123 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( _Depth ) );
			float clampResult124 = clamp( ( 1.0 - distanceDepth123 ) , 0.0 , 1.0 );
			float depth125 = clampResult124;
			float4 lerpResult127 = lerp( Albedo49 , Refraction119 , depth125);
			o.Albedo = lerpResult127.rgb;
			float screenDepth51 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE( _CameraDepthTexture, ase_screenPosNorm.xy ));
			float distanceDepth51 = abs( ( screenDepth51 - LinearEyeDepth( ase_screenPosNorm.z ) ) / ( _EdgeDistance ) );
			float4 clampResult58 = clamp( ( ( ( 1.0 - distanceDepth51 ) + tex2D( _SeaFoam, ( ( worldSpaceTile12 / 10.0 ) * _EdgeFoamTile ).xy ) ) * _EdgePower ) , float4( 0,0,0,0 ) , float4( 1,1,1,0 ) );
			float4 Edge56 = clampResult58;
			o.Emission = Edge56.rgb;
			o.Smoothness = 0.9;
			o.Alpha = 1;
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18712
0;73;1326;655;3000.886;603.9667;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;13;-6440.11,-955.86;Inherit;False;1022.327;314.4494;Comment;3;10;11;12;World Space UV's;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldPosInputsNode;10;-6390.11,-889.8757;Inherit;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;11;-6008.196,-894.4108;Inherit;True;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CommentaryNode;37;-5032.567,-1720.948;Inherit;False;2406.307;648.5331;Comment;11;16;14;15;18;17;22;20;33;21;34;35;Wave UV's & Height;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;12;-5664.783,-905.8601;Float;True;worldSpaceTile;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.Vector2Node;16;-4881.142,-1376.416;Float;True;Constant;_WaveStretch;Wave Stretch;2;0;Create;True;0;0;0;False;0;False;0.15,0.02;0.23,0.01;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.CommentaryNode;80;390.6244,-1705.157;Inherit;False;3769.275;1436.293;Comment;21;62;64;65;66;63;67;61;68;72;70;73;74;71;75;69;60;76;78;79;82;83;Normal Maps;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;14;-4982.567,-1649.521;Inherit;True;12;worldSpaceTile;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;63;454.9862,-1599.604;Inherit;True;12;worldSpaceTile;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;73;1574.297,-1234.97;Float;True;Property;_NormalSpeed;Normal Speed;7;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;65;740.074,-1639.103;Float;True;Property;_NormalTile;Normal Tile;9;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;18;-4626.906,-1384.591;Float;True;Property;_WaveTile;Wave Tile;1;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;15;-4687.474,-1653.863;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;83;424.5117,-1322.601;Float;True;Constant;_Float0;Float 0;11;0;Create;True;0;0;0;False;0;False;10;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;17;-4426.427,-1660.664;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;82;660.4513,-1270.009;Inherit;True;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CommentaryNode;110;-3901.291,-2804.613;Inherit;False;2131.378;965.6641;Comment;13;97;94;105;98;104;95;96;103;93;102;108;109;99;Sea Foam;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector2Node;71;1795.402,-544.9352;Float;True;Constant;_PanDirection2;PanDirection2;8;0;Create;True;0;0;0;False;0;False;-1,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;74;1840.848,-926.4;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;3;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;70;1551.784,-1555.314;Float;True;Constant;_PanDirection;Pan Direction;8;0;Create;True;0;0;0;False;0;False;1,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;66;969.1079,-803.2443;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;105;-3810.083,-2096.949;Float;True;Constant;_FoamMask;Foam Mask;14;0;Create;True;0;0;0;False;0;False;0.3;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;75;2173.284,-521.8662;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;1079.286,-1495.555;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CommentaryNode;38;-4995.282,-849.5501;Inherit;False;1989.728;1165.434;Comment;13;30;31;6;7;9;8;23;26;3;27;1;29;32;Wave Pattern;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;22;-4122.139,-1670.948;Float;True;WaveTileUV;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;94;-3851.291,-2738.955;Inherit;True;12;worldSpaceTile;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;67;1266.876,-989.9604;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;97;-3764.514,-2404.784;Float;True;Constant;_Float2;Float 1;12;0;Create;True;0;0;0;False;0;False;10;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;72;1808.391,-1512.886;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;92;-3663.069,-3903.944;Inherit;False;1497.489;843.5886;Comment;8;84;86;85;89;90;87;88;91;Ocean Edge Foam;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleTimeNode;6;-4925.849,-247.3969;Inherit;True;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;30;-4643.859,85.88324;Inherit;True;22;WaveTileUV;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.PannerNode;68;2143.711,-1655.157;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;7;-4924.54,8.394463;Float;True;Property;_WaveSpeed;Wave Speed;0;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;95;-3503.091,-2754.613;Inherit;True;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TexturePropertyNode;62;524.9111,-1016.625;Inherit;True;Property;_NormalMap;Normal Map;10;0;Create;True;0;0;0;False;0;False;74423cbef99ad234e9191594e6c27a06;74423cbef99ad234e9191594e6c27a06;True;bump;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RangedFloatNode;98;-3439.165,-2428.639;Float;True;Property;_SeaFoamTile;Sea Foam Tile;13;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;78;2623.664,-1236.045;Float;True;Property;_NormalStrength;Normal Strength;8;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;104;-3591.699,-2118.166;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.PannerNode;69;2525.161,-651.6586;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TexturePropertyNode;84;-3109.065,-3848.069;Inherit;True;Property;_SeaFoam;Sea Foam;11;0;Create;True;0;0;0;False;0;False;36f8a71993fe8084dbe1085834a1c819;36f8a71993fe8084dbe1085834a1c819;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.GetLocalVarNode;23;-4945.282,-799.5502;Inherit;True;22;WaveTileUV;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.Vector2Node;9;-4936.9,-563.1871;Float;True;Constant;_WaveDirection;Wave Direction;0;0;Create;True;0;0;0;False;0;False;-1,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;31;-4346.403,60.37044;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0.1,0.1,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;8;-4592.321,-249.6302;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;96;-3167.458,-2603.24;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SamplerNode;60;2978.406,-1431.325;Inherit;True;Property;_TextureSample0;Texture Sample 0;8;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;61;2958.461,-1091.484;Inherit;True;Property;_TextureSample1;Texture Sample 1;8;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;103;-3264.336,-2145.19;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0.04,-0.03;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BlendNormalsNode;76;3560.08,-1259.664;Inherit;True;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PannerNode;3;-4226.13,-622.011;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;26;-4216.846,-327.1164;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;93;-2897.483,-2583.702;Inherit;True;Property;_TextureSample3;Texture Sample 3;13;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NoiseGeneratorNode;102;-2908.274,-2166.921;Inherit;True;Simplex2D;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;1;-3911.82,-622.063;Inherit;True;Simplex2D;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;27;-3909.78,-324.4131;Inherit;True;Simplex2D;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;59;-3502.379,-4621.029;Inherit;False;2247.399;527.8149;Comment;7;52;51;53;56;58;54;55;Edge;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;121;-414.7478,-4429.095;Inherit;False;1895.634;757.3679;Comment;9;111;113;114;115;112;116;117;118;119;Refraction;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;79;3915.9,-1253.015;Float;True;Normals;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;86;-3613.069,-3596.027;Inherit;True;12;worldSpaceTile;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;108;-2581.504,-2375.122;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;90;-3572.716,-3354.674;Float;True;Constant;_Float1;Float 1;12;0;Create;True;0;0;0;False;0;False;10;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;-3547.884,-568.8239;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;113;-341.5576,-4169.837;Float;True;Property;_RefractAmount;Refract Amount;14;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;52;-3447.548,-4509.67;Float;True;Property;_EdgeDistance;Edge Distance;5;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GrabScreenPosition;111;-364.7478,-4379.095;Inherit;False;0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;88;-3330.034,-3318.355;Float;True;Property;_EdgeFoamTile;Edge Foam Tile;12;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;109;-2291.307,-2377.074;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;114;-340.5965,-3901.727;Inherit;True;79;Normals;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;131;-334.5759,-4872.407;Inherit;False;1436.425;435.4585;Comment;5;125;124;130;123;122;Depth;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;89;-3353.405,-3586.312;Inherit;True;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CommentaryNode;50;-1117.5,-3272.561;Inherit;False;1896.987;1373.13;Comment;8;46;49;43;42;41;44;100;101;Albedo (Color);1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;122;-293.0647,-4749.886;Float;True;Property;_Depth;Depth;15;0;Create;True;0;0;0;False;0;False;-4;-4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;87;-3056.406,-3597.949;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;115;-2.729519,-4132.299;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;99;-2013.912,-2484.85;Inherit;True;SeaFoam;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;112;-10.12719,-4369.891;Inherit;True;True;True;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;32;-3249.556,-553.5939;Float;True;WavePattern;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DepthFade;51;-3199.766,-4519.679;Inherit;False;True;False;True;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;85;-2772.269,-3708.777;Inherit;True;Property;_TextureSample2;Texture Sample 2;12;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DepthFade;123;-77.12749,-4700.897;Inherit;False;True;False;True;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;53;-2857.756,-4517.885;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;116;349.2797,-4199.171;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;138;-2858.229,-814.2621;Inherit;False;925.4338;858.8726;Comment;6;133;134;137;132;135;19;Tessellation;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;101;-976.6768,-2751.42;Inherit;True;99;SeaFoam;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;44;-1001.973,-2282.105;Inherit;True;32;WavePattern;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;42;-1067.5,-3020.251;Inherit;False;Property;_TopColor;Top Color;4;0;Create;True;0;0;0;False;0;False;0.123754,0.9439473,0.9716981,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;91;-2400.58,-3806.482;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;41;-1061.003,-3222.561;Inherit;False;Property;_WaterColor;Water Color;3;0;Create;True;0;0;0;False;0;False;0.1415984,0.6083747,0.8113208,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;55;-2457.944,-4510.993;Float;True;Property;_EdgePower;Edge Power;6;0;Create;True;0;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenColorNode;117;672.1985,-4140.79;Inherit;False;Global;_GrabScreen0;Grab Screen 0;15;0;Create;True;0;0;0;False;0;False;Object;-1;False;False;1;0;FLOAT2;0,0;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ClampOpNode;46;-659.231,-2360.844;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;130;246.1986,-4712.074;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;33;-3761.085,-1357.141;Float;True;Property;_WaveHeight;Wave Height;2;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;20;-3820.784,-1658.869;Float;True;Constant;_Waveup;Wave up;2;0;Create;True;0;0;0;False;0;False;0,1,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;100;-559.2882,-2835.563;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;19;-2808.229,-693.7049;Float;True;Constant;_tesselation;tesselation;2;0;Create;True;0;0;0;False;0;False;8;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;21;-3476.431,-1595.092;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;54;-2082.119,-4531.317;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;43;-191.4694,-3101.481;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;118;942.4161,-4108.363;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,1,1,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;124;525.8364,-4715.283;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;137;-2523.73,-764.2621;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;134;-2764.977,-213.3893;Float;True;Constant;_Float4;Float 4;17;0;Create;True;0;0;0;False;0;False;80;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;133;-2784.851,-462.4747;Float;True;Constant;_Float3;Float 3;17;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;125;843.6575,-4713.575;Float;True;depth;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;58;-1828.759,-4528.444;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,1,1,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;49;138.5647,-3099.231;Float;True;Albedo;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;34;-3181.567,-1576.27;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DistanceBasedTessNode;132;-2514.067,-445.3955;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;119;1236.886,-4105.325;Float;True;Refraction;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;135;-2176.795,-387.0886;Float;False;Tessellation;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;56;-1555.915,-4524.062;Float;True;Edge;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;35;-2870.261,-1575.587;Float;True;WaveHeight;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;48;-776.9774,-864.179;Inherit;True;49;Albedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;129;-763.6533,-457.1212;Inherit;True;125;depth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;128;-781.8604,-662.4271;Inherit;True;119;Refraction;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;36;-595.2932,347.1767;Inherit;True;35;WaveHeight;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;39;-586.1582,109.5641;Float;True;Constant;_Smoothness;Smoothness;3;0;Create;True;0;0;0;False;0;False;0.9;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;57;-610.0356,-78.99065;Inherit;True;56;Edge;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;127;-492.2646,-673.1964;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;136;-594.9444,552.4301;Inherit;True;135;Tessellation;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;81;-619.7731,-269.182;Inherit;True;79;Normals;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;0,0;Float;False;True;-1;6;ASEMaterialInspector;0;0;Standard;Ocean_Shader;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Off;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;False;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;True;2;15;10;25;False;0.5;False;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;11;0;10;1
WireConnection;11;1;10;3
WireConnection;12;0;11;0
WireConnection;15;0;14;0
WireConnection;15;1;16;0
WireConnection;17;0;15;0
WireConnection;17;1;18;0
WireConnection;82;0;63;0
WireConnection;82;1;83;0
WireConnection;74;0;73;0
WireConnection;66;0;65;0
WireConnection;75;0;71;0
WireConnection;75;1;74;0
WireConnection;64;0;82;0
WireConnection;64;1;65;0
WireConnection;22;0;17;0
WireConnection;67;0;82;0
WireConnection;67;1;66;0
WireConnection;72;0;70;0
WireConnection;72;1;73;0
WireConnection;68;0;64;0
WireConnection;68;2;72;0
WireConnection;95;0;94;0
WireConnection;95;1;97;0
WireConnection;104;0;94;0
WireConnection;104;1;105;0
WireConnection;69;0;67;0
WireConnection;69;2;75;0
WireConnection;31;0;30;0
WireConnection;8;0;6;0
WireConnection;8;1;7;0
WireConnection;96;0;95;0
WireConnection;96;1;98;0
WireConnection;60;0;62;0
WireConnection;60;1;68;0
WireConnection;60;5;78;0
WireConnection;61;0;62;0
WireConnection;61;1;69;0
WireConnection;61;5;78;0
WireConnection;103;0;104;0
WireConnection;76;0;60;0
WireConnection;76;1;61;0
WireConnection;3;0;23;0
WireConnection;3;2;9;0
WireConnection;3;1;8;0
WireConnection;26;0;31;0
WireConnection;26;2;9;0
WireConnection;26;1;8;0
WireConnection;93;0;84;0
WireConnection;93;1;96;0
WireConnection;102;0;103;0
WireConnection;1;0;3;0
WireConnection;27;0;26;0
WireConnection;79;0;76;0
WireConnection;108;0;93;1
WireConnection;108;1;102;0
WireConnection;29;0;1;0
WireConnection;29;1;27;0
WireConnection;109;0;108;0
WireConnection;89;0;86;0
WireConnection;89;1;90;0
WireConnection;87;0;89;0
WireConnection;87;1;88;0
WireConnection;115;0;113;0
WireConnection;115;1;114;0
WireConnection;99;0;109;0
WireConnection;112;0;111;0
WireConnection;32;0;29;0
WireConnection;51;0;52;0
WireConnection;85;0;84;0
WireConnection;85;1;87;0
WireConnection;123;0;122;0
WireConnection;53;0;51;0
WireConnection;116;0;112;0
WireConnection;116;1;115;0
WireConnection;91;0;53;0
WireConnection;91;1;85;0
WireConnection;117;0;116;0
WireConnection;46;0;44;0
WireConnection;130;0;123;0
WireConnection;100;0;42;0
WireConnection;100;1;101;0
WireConnection;21;0;20;0
WireConnection;21;1;33;0
WireConnection;54;0;91;0
WireConnection;54;1;55;0
WireConnection;43;0;41;0
WireConnection;43;1;100;0
WireConnection;43;2;46;0
WireConnection;118;0;117;0
WireConnection;124;0;130;0
WireConnection;137;0;33;0
WireConnection;137;1;19;0
WireConnection;125;0;124;0
WireConnection;58;0;54;0
WireConnection;49;0;43;0
WireConnection;34;0;21;0
WireConnection;34;1;29;0
WireConnection;132;0;137;0
WireConnection;132;1;133;0
WireConnection;132;2;134;0
WireConnection;119;0;118;0
WireConnection;135;0;132;0
WireConnection;56;0;58;0
WireConnection;35;0;34;0
WireConnection;127;0;48;0
WireConnection;127;1;128;0
WireConnection;127;2;129;0
WireConnection;0;0;127;0
WireConnection;0;1;81;0
WireConnection;0;2;57;0
WireConnection;0;4;39;0
WireConnection;0;11;36;0
WireConnection;0;14;136;0
ASEEND*/
//CHKSM=0386FA75540A13400EC2A282C105AE996964CC53