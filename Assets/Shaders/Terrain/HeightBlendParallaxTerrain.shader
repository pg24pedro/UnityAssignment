// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "HeightBlendParallaxTerrain"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HideInInspector]_Control("Control", 2D) = "white" {}
		[HideInInspector]_Splat0_ST("Splat0_ST", Vector) = (0,0,0,0)
		[HideInInspector]_Splat2_ST("Splat2_ST", Vector) = (0,0,0,0)
		[HideInInspector]_Splat1_ST("Splat1_ST", Vector) = (0,0,0,0)
		[HideInInspector]_Splat3_ST("Splat3_ST", Vector) = (0,0,0,0)
		[HideInInspector]_Splat0("Splat0", 2D) = "white" {}
		[HideInInspector]_Splat1("Splat1", 2D) = "white" {}
		[HideInInspector]_Splat3("Splat3", 2D) = "white" {}
		[HideInInspector]_Splat2("Splat2", 2D) = "white" {}
		[HideInInspector][Normal]_Normal0("Normal0", 2D) = "bump" {}
		[HideInInspector][Normal]_Normal1("Normal1", 2D) = "bump" {}
		[HideInInspector][Normal]_Normal2("Normal2", 2D) = "bump" {}
		[HideInInspector][Normal]_Normal3("Normal3", 2D) = "bump" {}
		[HideInInspector]_Mask0("Mask0", 2D) = "white" {}
		[HideInInspector]_Mask1("Mask1", 2D) = "white" {}
		[HideInInspector]_Mask2("Mask2", 2D) = "white" {}
		[HideInInspector]_Mask3("Mask3", 2D) = "white" {}
		[HideInInspector]_TerrainHolesTexture("TerrainHolesTexture", 2D) = "white" {}
		[ASEBegin]_HeightBlend1("HeightBlend1", Range( 0.01 , 1)) = 1
		_HeightBlend2("HeightBlend2", Range( 0 , 1)) = 1
		_HeightBlend3("HeightBlend3", Range( 0.01 , 1)) = 0.5
		[Toggle]_Stochastic0("Stochastic0", Float) = 0
		[Toggle]_Stochastic1("Stochastic1", Float) = 0
		[Toggle]_Stochastic2("Stochastic2", Float) = 0
		[Toggle]_Stochastic3("Stochastic3", Float) = 0
		_Parallax0("Parallax0", Range( 0 , 0.1)) = 0
		_Parallax1("Parallax1", Range( 0 , 0.1)) = 0
		_Parallax2("Parallax2", Range( 0 , 0.1)) = 0
		[ASEEnd]_Parallax3("Parallax3", Range( 0 , 0.1)) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

		//_TransmissionShadow( "Transmission Shadow", Range( 0, 1 ) ) = 0.5
		//_TransStrength( "Trans Strength", Range( 0, 50 ) ) = 1
		//_TransNormal( "Trans Normal Distortion", Range( 0, 1 ) ) = 0.5
		//_TransScattering( "Trans Scattering", Range( 1, 50 ) ) = 2
		//_TransDirect( "Trans Direct", Range( 0, 1 ) ) = 0.9
		//_TransAmbient( "Trans Ambient", Range( 0, 1 ) ) = 0.1
		//_TransShadow( "Trans Shadow", Range( 0, 1 ) ) = 0.5
		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		Cull Back
		AlphaToMask Off
		HLSLINCLUDE
		#pragma target 3.0

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}
		
		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		UsePass "Hidden/Nature/Terrain/Utilities/PICKING"
	UsePass "Hidden/Nature/Terrain/Utilities/SELECTION"

		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_FINAL_COLOR_ALPHA_MULTIPLY 1
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 80301
			#define ASE_USING_SAMPLING_MACROS 1

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
			
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_FORWARD

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			
			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

			#if defined(UNITY_INSTANCING_ENABLED) && defined(_TERRAIN_INSTANCED_PERPIXEL_NORMAL)
			    #define ENABLE_TERRAIN_PERPIXEL_NORMAL
			#endif

			#define ASE_NEEDS_VERT_TANGENT
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_TANGENT
			#define ASE_NEEDS_FRAG_WORLD_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_BITANGENT
			#define ASE_NEEDS_FRAG_WORLD_VIEW_DIR
			#define ASE_NEEDS_VERT_POSITION
			#pragma multi_compile_instancing
			#pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap forwardadd


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord : TEXCOORD0;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 lightmapUVOrVertexSH : TEXCOORD0;
				half4 fogFactorAndVertexLight : TEXCOORD1;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord : TEXCOORD2;
				#endif
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 screenPos : TEXCOORD6;
				#endif
				float4 ase_texcoord7 : TEXCOORD7;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Splat0_ST;
			float4 _Mask3_ST;
			float4 _Splat3_ST;
			float4 _Mask2_ST;
			float4 _Control_ST;
			float4 _Mask1_ST;
			float4 _Splat2_ST;
			float4 _Splat1_ST;
			float4 _Mask0_ST;
			float4 _TerrainHolesTexture_ST;
			float _Stochastic1;
			float _HeightBlend1;
			float _HeightBlend3;
			float _Parallax2;
			float _Stochastic0;
			float _Stochastic2;
			float _HeightBlend2;
			float _Parallax3;
			float _Parallax0;
			float _Stochastic3;
			float _Parallax1;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			TEXTURE2D(_Splat0);
			TEXTURE2D(_Mask0);
			SAMPLER(sampler_linear_repeat);
			TEXTURE2D(_Splat1);
			TEXTURE2D(_Mask1);
			TEXTURE2D(_Control);
			SAMPLER(sampler_Control);
			TEXTURE2D(_Splat2);
			TEXTURE2D(_Mask2);
			TEXTURE2D(_Splat3);
			TEXTURE2D(_Mask3);
			TEXTURE2D(_Normal0);
			TEXTURE2D(_Normal1);
			TEXTURE2D(_Normal2);
			TEXTURE2D(_Normal3);
			TEXTURE2D(_TerrainHolesTexture);
			SAMPLER(sampler_TerrainHolesTexture);
			#ifdef UNITY_INSTANCING_ENABLED//ASE Terrain Instancing
				TEXTURE2D(_TerrainHeightmapTexture);//ASE Terrain Instancing
				TEXTURE2D( _TerrainNormalmapTexture);//ASE Terrain Instancing
				SAMPLER(sampler_TerrainNormalmapTexture);//ASE Terrain Instancing
			#endif//ASE Terrain Instancing
			UNITY_INSTANCING_BUFFER_START( Terrain )//ASE Terrain Instancing
				UNITY_DEFINE_INSTANCED_PROP( float4, _TerrainPatchInstanceData )//ASE Terrain Instancing
			UNITY_INSTANCING_BUFFER_END( Terrain)//ASE Terrain Instancing
			CBUFFER_START( UnityTerrain)//ASE Terrain Instancing
				#ifdef UNITY_INSTANCING_ENABLED//ASE Terrain Instancing
					float4 _TerrainHeightmapRecipSize;//ASE Terrain Instancing
					float4 _TerrainHeightmapScale;//ASE Terrain Instancing
				#endif//ASE Terrain Instancing
			CBUFFER_END//ASE Terrain Instancing


			inline float2 POM( TEXTURE2D(heightMap), SAMPLER(samplerheightMap), float2 uvs, float2 dx, float2 dy, float3 normalWorld, float3 viewWorld, float3 viewDirTan, int minSamples, int maxSamples, float parallax, float refPlane, float2 tilling, float2 curv, int index )
			{
				float3 result = 0;
				int stepIndex = 0;
				int numSteps = ( int )lerp( (float)maxSamples, (float)minSamples, saturate( dot( normalWorld, viewWorld ) ) );
				float layerHeight = 1.0 / numSteps;
				float2 plane = parallax * ( viewDirTan.xy / viewDirTan.z );
				uvs.xy += refPlane * plane;
				float2 deltaTex = -plane * layerHeight;
				float2 prevTexOffset = 0;
				float prevRayZ = 1.0f;
				float prevHeight = 0.0f;
				float2 currTexOffset = deltaTex;
				float currRayZ = 1.0f - layerHeight;
				float currHeight = 0.0f;
				float intersection = 0;
				float2 finalTexOffset = 0;
				while ( stepIndex < numSteps + 1 )
				{
				 	currHeight = SAMPLE_TEXTURE2D_GRAD( heightMap, samplerheightMap, uvs + currTexOffset, dx, dy ).b;
				 	if ( currHeight > currRayZ )
				 	{
				 	 	stepIndex = numSteps + 1;
				 	}
				 	else
				 	{
				 	 	stepIndex++;
				 	 	prevTexOffset = currTexOffset;
				 	 	prevRayZ = currRayZ;
				 	 	prevHeight = currHeight;
				 	 	currTexOffset += deltaTex;
				 	 	currRayZ -= layerHeight;
				 	}
				}
				int sectionSteps = 4;
				int sectionIndex = 0;
				float newZ = 0;
				float newHeight = 0;
				while ( sectionIndex < sectionSteps )
				{
				 	intersection = ( prevHeight - prevRayZ ) / ( prevHeight - currHeight + currRayZ - prevRayZ );
				 	finalTexOffset = prevTexOffset + intersection * deltaTex;
				 	newZ = prevRayZ - intersection * layerHeight;
				 	newHeight = SAMPLE_TEXTURE2D_GRAD( heightMap, samplerheightMap, uvs + finalTexOffset, dx, dy ).b;
				 	if ( newHeight > newZ )
				 	{
				 	 	currTexOffset = finalTexOffset;
				 	 	currHeight = newHeight;
				 	 	currRayZ = newZ;
				 	 	deltaTex = intersection * deltaTex;
				 	 	layerHeight = intersection * layerHeight;
				 	}
				 	else
				 	{
				 	 	prevTexOffset = finalTexOffset;
				 	 	prevHeight = newHeight;
				 	 	prevRayZ = newZ;
				 	 	deltaTex = ( 1 - intersection ) * deltaTex;
				 	 	layerHeight = ( 1 - intersection ) * layerHeight;
				 	}
				 	sectionIndex++;
				}
				return uvs.xy + finalTexOffset;
			}
			
			void StochasticTiling( float2 UV, out float2 UV1, out float2 UV2, out float2 UV3, out float W1, out float W2, out float W3 )
			{
				float2 vertex1, vertex2, vertex3;
				// Scaling of the input
				float2 uv = UV * 3.464; // 2 * sqrt (3)
				// Skew input space into simplex triangle grid
				const float2x2 gridToSkewedGrid = float2x2( 1.0, 0.0, -0.57735027, 1.15470054 );
				float2 skewedCoord = mul( gridToSkewedGrid, uv );
				// Compute local triangle vertex IDs and local barycentric coordinates
				int2 baseId = int2( floor( skewedCoord ) );
				float3 temp = float3( frac( skewedCoord ), 0 );
				temp.z = 1.0 - temp.x - temp.y;
				if ( temp.z > 0.0 )
				{
					W1 = temp.z;
					W2 = temp.y;
					W3 = temp.x;
					vertex1 = baseId;
					vertex2 = baseId + int2( 0, 1 );
					vertex3 = baseId + int2( 1, 0 );
				}
				else
				{
					W1 = -temp.z;
					W2 = 1.0 - temp.y;
					W3 = 1.0 - temp.x;
					vertex1 = baseId + int2( 1, 1 );
					vertex2 = baseId + int2( 1, 0 );
					vertex3 = baseId + int2( 0, 1 );
				}
				UV1 = UV + frac( sin( mul( float2x2( 127.1, 311.7, 269.5, 183.3 ), vertex1 ) ) * 43758.5453 );
				UV2 = UV + frac( sin( mul( float2x2( 127.1, 311.7, 269.5, 183.3 ), vertex2 ) ) * 43758.5453 );
				UV3 = UV + frac( sin( mul( float2x2( 127.1, 311.7, 269.5, 183.3 ), vertex3 ) ) * 43758.5453 );
				return;
			}
			
			VertexInput ApplyMeshModification( VertexInput v )
			{
			#ifdef UNITY_INSTANCING_ENABLED
				float2 patchVertex = v.vertex.xy;
				float4 instanceData = UNITY_ACCESS_INSTANCED_PROP( Terrain, _TerrainPatchInstanceData );
				float2 sampleCoords = ( patchVertex.xy + instanceData.xy ) * instanceData.z;
				float height = UnpackHeightmap( _TerrainHeightmapTexture.Load( int3( sampleCoords, 0 ) ) );
				v.vertex.xz = sampleCoords* _TerrainHeightmapScale.xz;
				v.vertex.y = height* _TerrainHeightmapScale.y;
				#ifdef ENABLE_TERRAIN_PERPIXEL_NORMAL
					v.ase_normal = float3(0, 1, 0);
				#else
					v.ase_normal = _TerrainNormalmapTexture.Load(int3(sampleCoords, 0)).rgb* 2 - 1;
				#endif
				v.texcoord.xy = sampleCoords* _TerrainHeightmapRecipSize.zw;
			#endif
				return v;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				v = ApplyMeshModification(v);
				float3 localCalculateTangentsSRP26 = ( ( v.ase_tangent.xyz * v.ase_normal * 0.0 ) );
				{
				v.ase_tangent.xyz = cross ( v.ase_normal, float3( 0, 0, 1 ) );
				v.ase_tangent.w = -1;
				}
				
				o.ase_texcoord7.xy = v.texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord7.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = localCalculateTangentsSRP26;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 positionVS = TransformWorldToView( positionWS );
				float4 positionCS = TransformWorldToHClip( positionWS );

				VertexNormalInputs normalInput = GetVertexNormalInputs( v.ase_normal, v.ase_tangent );

				o.tSpace0 = float4( normalInput.normalWS, positionWS.x);
				o.tSpace1 = float4( normalInput.tangentWS, positionWS.y);
				o.tSpace2 = float4( normalInput.bitangentWS, positionWS.z);

				OUTPUT_LIGHTMAP_UV( v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy );
				OUTPUT_SH( normalInput.normalWS.xyz, o.lightmapUVOrVertexSH.xyz );

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					o.lightmapUVOrVertexSH.zw = v.texcoord;
					o.lightmapUVOrVertexSH.xy = v.texcoord * unity_LightmapST.xy + unity_LightmapST.zw;
				#endif

				half3 vertexLight = VertexLighting( positionWS, normalInput.normalWS );
				#ifdef ASE_FOG
					half fogFactor = ComputeFogFactor( positionCS.z );
				#else
					half fogFactor = 0;
				#endif
				o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
				
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = positionWS;
				vertexInput.positionCS = positionCS;
				o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				
				o.clipPos = positionCS;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				o.screenPos = ComputeScreenPos(positionCS);
				#endif
				return o;
			}
			
			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_tangent = v.ase_tangent;
				o.texcoord = v.texcoord;
				o.texcoord1 = v.texcoord1;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.texcoord = patch[0].texcoord * bary.x + patch[1].texcoord * bary.y + patch[2].texcoord * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual  
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif

			half4 frag ( VertexOutput IN 
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float2 sampleCoords = (IN.lightmapUVOrVertexSH.zw / _TerrainHeightmapRecipSize.zw + 0.5f) * _TerrainHeightmapRecipSize.xy;
					float3 WorldNormal = TransformObjectToWorldNormal(normalize(SAMPLE_TEXTURE2D(_TerrainNormalmapTexture, sampler_TerrainNormalmapTexture, sampleCoords).rgb * 2 - 1));
					float3 WorldTangent = -cross(GetObjectToWorldMatrix()._13_23_33, WorldNormal);
					float3 WorldBiTangent = cross(WorldNormal, -WorldTangent);
				#else
					float3 WorldNormal = normalize( IN.tSpace0.xyz );
					float3 WorldTangent = IN.tSpace1.xyz;
					float3 WorldBiTangent = IN.tSpace2.xyz;
				#endif
				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4( 0, 0, 0, 0 );
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 ScreenPos = IN.screenPos;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#endif
	
				WorldViewDirection = SafeNormalize( WorldViewDirection );

				float4 break18_g460 = _Splat0_ST;
				float2 appendResult16_g460 = (float2(break18_g460.x , break18_g460.y));
				float2 appendResult15_g460 = (float2(break18_g460.z , break18_g460.w));
				float2 texCoord17_g460 = IN.ase_texcoord7.xy * appendResult16_g460 + appendResult15_g460;
				float2 UV29_g460 = texCoord17_g460;
				float3 tanToWorld0 = float3( WorldTangent.x, WorldBiTangent.x, WorldNormal.x );
				float3 tanToWorld1 = float3( WorldTangent.y, WorldBiTangent.y, WorldNormal.y );
				float3 tanToWorld2 = float3( WorldTangent.z, WorldBiTangent.z, WorldNormal.z );
				float3 ase_tanViewDir =  tanToWorld0 * WorldViewDirection.x + tanToWorld1 * WorldViewDirection.y  + tanToWorld2 * WorldViewDirection.z;
				ase_tanViewDir = normalize(ase_tanViewDir);
				float2 OffsetPOM47_g460 = POM( _Mask0, sampler_linear_repeat, UV29_g460, ddx(UV29_g460), ddy(UV29_g460), WorldNormal, WorldViewDirection, ase_tanViewDir, 8, 8, _Parallax0, 0.5, _Mask0_ST.xy, float2(0,0), 0 );
				float2 ParallaxUV51_g460 = OffsetPOM47_g460;
				float localStochasticTiling2_g463 = ( 0.0 );
				float2 Input_UV145_g463 = ParallaxUV51_g460;
				float2 UV2_g463 = Input_UV145_g463;
				float2 UV12_g463 = float2( 0,0 );
				float2 UV22_g463 = float2( 0,0 );
				float2 UV32_g463 = float2( 0,0 );
				float W12_g463 = 0.0;
				float W22_g463 = 0.0;
				float W32_g463 = 0.0;
				StochasticTiling( UV2_g463 , UV12_g463 , UV22_g463 , UV32_g463 , W12_g463 , W22_g463 , W32_g463 );
				float2 temp_output_10_0_g463 = ddx( Input_UV145_g463 );
				float2 temp_output_12_0_g463 = ddy( Input_UV145_g463 );
				float4 Output_2D293_g463 = ( ( SAMPLE_TEXTURE2D_GRAD( _Splat0, sampler_linear_repeat, UV12_g463, temp_output_10_0_g463, temp_output_12_0_g463 ) * W12_g463 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat0, sampler_linear_repeat, UV22_g463, temp_output_10_0_g463, temp_output_12_0_g463 ) * W22_g463 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat0, sampler_linear_repeat, UV32_g463, temp_output_10_0_g463, temp_output_12_0_g463 ) * W32_g463 ) );
				float StochasticAmount43_g460 = _Stochastic0;
				float4 lerpResult26_g460 = lerp( SAMPLE_TEXTURE2D( _Splat0, sampler_linear_repeat, ParallaxUV51_g460 ) , Output_2D293_g463 , StochasticAmount43_g460);
				float4 break18_g464 = _Splat1_ST;
				float2 appendResult16_g464 = (float2(break18_g464.x , break18_g464.y));
				float2 appendResult15_g464 = (float2(break18_g464.z , break18_g464.w));
				float2 texCoord17_g464 = IN.ase_texcoord7.xy * appendResult16_g464 + appendResult15_g464;
				float2 UV29_g464 = texCoord17_g464;
				float2 OffsetPOM47_g464 = POM( _Mask1, sampler_linear_repeat, UV29_g464, ddx(UV29_g464), ddy(UV29_g464), WorldNormal, WorldViewDirection, ase_tanViewDir, 8, 8, _Parallax1, 0.5, _Mask1_ST.xy, float2(0,0), 0 );
				float2 ParallaxUV51_g464 = OffsetPOM47_g464;
				float localStochasticTiling2_g467 = ( 0.0 );
				float2 Input_UV145_g467 = ParallaxUV51_g464;
				float2 UV2_g467 = Input_UV145_g467;
				float2 UV12_g467 = float2( 0,0 );
				float2 UV22_g467 = float2( 0,0 );
				float2 UV32_g467 = float2( 0,0 );
				float W12_g467 = 0.0;
				float W22_g467 = 0.0;
				float W32_g467 = 0.0;
				StochasticTiling( UV2_g467 , UV12_g467 , UV22_g467 , UV32_g467 , W12_g467 , W22_g467 , W32_g467 );
				float2 temp_output_10_0_g467 = ddx( Input_UV145_g467 );
				float2 temp_output_12_0_g467 = ddy( Input_UV145_g467 );
				float4 Output_2D293_g467 = ( ( SAMPLE_TEXTURE2D_GRAD( _Splat1, sampler_linear_repeat, UV12_g467, temp_output_10_0_g467, temp_output_12_0_g467 ) * W12_g467 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat1, sampler_linear_repeat, UV22_g467, temp_output_10_0_g467, temp_output_12_0_g467 ) * W22_g467 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat1, sampler_linear_repeat, UV32_g467, temp_output_10_0_g467, temp_output_12_0_g467 ) * W32_g467 ) );
				float StochasticAmount43_g464 = _Stochastic1;
				float4 lerpResult26_g464 = lerp( SAMPLE_TEXTURE2D( _Splat1, sampler_linear_repeat, ParallaxUV51_g464 ) , Output_2D293_g467 , StochasticAmount43_g464);
				float localStochasticTiling2_g466 = ( 0.0 );
				float2 Input_UV145_g466 = ParallaxUV51_g464;
				float2 UV2_g466 = Input_UV145_g466;
				float2 UV12_g466 = float2( 0,0 );
				float2 UV22_g466 = float2( 0,0 );
				float2 UV32_g466 = float2( 0,0 );
				float W12_g466 = 0.0;
				float W22_g466 = 0.0;
				float W32_g466 = 0.0;
				StochasticTiling( UV2_g466 , UV12_g466 , UV22_g466 , UV32_g466 , W12_g466 , W22_g466 , W32_g466 );
				float2 temp_output_10_0_g466 = ddx( Input_UV145_g466 );
				float2 temp_output_12_0_g466 = ddy( Input_UV145_g466 );
				float4 Output_2D293_g466 = ( ( SAMPLE_TEXTURE2D_GRAD( _Mask1, sampler_linear_repeat, UV12_g466, temp_output_10_0_g466, temp_output_12_0_g466 ) * W12_g466 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask1, sampler_linear_repeat, UV22_g466, temp_output_10_0_g466, temp_output_12_0_g466 ) * W22_g466 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask1, sampler_linear_repeat, UV32_g466, temp_output_10_0_g466, temp_output_12_0_g466 ) * W32_g466 ) );
				float4 lerpResult28_g464 = lerp( SAMPLE_TEXTURE2D( _Mask1, sampler_linear_repeat, ParallaxUV51_g464 ) , Output_2D293_g466 , StochasticAmount43_g464);
				float4 temp_output_15_0_g468 = lerpResult28_g464;
				float2 uv_Control = IN.ase_texcoord7.xy * _Control_ST.xy + _Control_ST.zw;
				float4 tex2DNode7 = SAMPLE_TEXTURE2D( _Control, sampler_Control, uv_Control );
				float SplatWeight161 = tex2DNode7.g;
				float HeightMask39_g468 = saturate(pow((((temp_output_15_0_g468).z*SplatWeight161)*4)+(SplatWeight161*2),( 1.0 / _HeightBlend1 )));
				float4 lerpResult16_g468 = lerp( lerpResult26_g460 , lerpResult26_g464 , HeightMask39_g468);
				float4 break18_g469 = _Splat2_ST;
				float2 appendResult16_g469 = (float2(break18_g469.x , break18_g469.y));
				float2 appendResult15_g469 = (float2(break18_g469.z , break18_g469.w));
				float2 texCoord17_g469 = IN.ase_texcoord7.xy * appendResult16_g469 + appendResult15_g469;
				float2 UV29_g469 = texCoord17_g469;
				float2 OffsetPOM47_g469 = POM( _Mask2, sampler_linear_repeat, UV29_g469, ddx(UV29_g469), ddy(UV29_g469), WorldNormal, WorldViewDirection, ase_tanViewDir, 8, 8, _Parallax2, 0.5, _Mask2_ST.xy, float2(0,0), 0 );
				float2 ParallaxUV51_g469 = OffsetPOM47_g469;
				float localStochasticTiling2_g472 = ( 0.0 );
				float2 Input_UV145_g472 = ParallaxUV51_g469;
				float2 UV2_g472 = Input_UV145_g472;
				float2 UV12_g472 = float2( 0,0 );
				float2 UV22_g472 = float2( 0,0 );
				float2 UV32_g472 = float2( 0,0 );
				float W12_g472 = 0.0;
				float W22_g472 = 0.0;
				float W32_g472 = 0.0;
				StochasticTiling( UV2_g472 , UV12_g472 , UV22_g472 , UV32_g472 , W12_g472 , W22_g472 , W32_g472 );
				float2 temp_output_10_0_g472 = ddx( Input_UV145_g472 );
				float2 temp_output_12_0_g472 = ddy( Input_UV145_g472 );
				float4 Output_2D293_g472 = ( ( SAMPLE_TEXTURE2D_GRAD( _Splat2, sampler_linear_repeat, UV12_g472, temp_output_10_0_g472, temp_output_12_0_g472 ) * W12_g472 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat2, sampler_linear_repeat, UV22_g472, temp_output_10_0_g472, temp_output_12_0_g472 ) * W22_g472 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat2, sampler_linear_repeat, UV32_g472, temp_output_10_0_g472, temp_output_12_0_g472 ) * W32_g472 ) );
				float StochasticAmount43_g469 = _Stochastic2;
				float4 lerpResult26_g469 = lerp( SAMPLE_TEXTURE2D( _Splat2, sampler_linear_repeat, ParallaxUV51_g469 ) , Output_2D293_g472 , StochasticAmount43_g469);
				float localStochasticTiling2_g471 = ( 0.0 );
				float2 Input_UV145_g471 = ParallaxUV51_g469;
				float2 UV2_g471 = Input_UV145_g471;
				float2 UV12_g471 = float2( 0,0 );
				float2 UV22_g471 = float2( 0,0 );
				float2 UV32_g471 = float2( 0,0 );
				float W12_g471 = 0.0;
				float W22_g471 = 0.0;
				float W32_g471 = 0.0;
				StochasticTiling( UV2_g471 , UV12_g471 , UV22_g471 , UV32_g471 , W12_g471 , W22_g471 , W32_g471 );
				float2 temp_output_10_0_g471 = ddx( Input_UV145_g471 );
				float2 temp_output_12_0_g471 = ddy( Input_UV145_g471 );
				float4 Output_2D293_g471 = ( ( SAMPLE_TEXTURE2D_GRAD( _Mask2, sampler_linear_repeat, UV12_g471, temp_output_10_0_g471, temp_output_12_0_g471 ) * W12_g471 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask2, sampler_linear_repeat, UV22_g471, temp_output_10_0_g471, temp_output_12_0_g471 ) * W22_g471 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask2, sampler_linear_repeat, UV32_g471, temp_output_10_0_g471, temp_output_12_0_g471 ) * W32_g471 ) );
				float4 lerpResult28_g469 = lerp( SAMPLE_TEXTURE2D( _Mask2, sampler_linear_repeat, ParallaxUV51_g469 ) , Output_2D293_g471 , StochasticAmount43_g469);
				float4 temp_output_15_0_g473 = lerpResult28_g469;
				float SplatWeight262 = tex2DNode7.b;
				float HeightMask39_g473 = saturate(pow((((temp_output_15_0_g473).z*SplatWeight262)*4)+(SplatWeight262*2),( 1.0 / _HeightBlend2 )));
				float4 lerpResult16_g473 = lerp( lerpResult16_g468 , lerpResult26_g469 , HeightMask39_g473);
				float4 break18_g474 = _Splat3_ST;
				float2 appendResult16_g474 = (float2(break18_g474.x , break18_g474.y));
				float2 appendResult15_g474 = (float2(break18_g474.z , break18_g474.w));
				float2 texCoord17_g474 = IN.ase_texcoord7.xy * appendResult16_g474 + appendResult15_g474;
				float2 UV29_g474 = texCoord17_g474;
				float2 OffsetPOM47_g474 = POM( _Mask3, sampler_linear_repeat, UV29_g474, ddx(UV29_g474), ddy(UV29_g474), WorldNormal, WorldViewDirection, ase_tanViewDir, 8, 8, _Parallax3, 0.5, _Mask3_ST.xy, float2(0,0), 0 );
				float2 ParallaxUV51_g474 = OffsetPOM47_g474;
				float localStochasticTiling2_g477 = ( 0.0 );
				float2 Input_UV145_g477 = ParallaxUV51_g474;
				float2 UV2_g477 = Input_UV145_g477;
				float2 UV12_g477 = float2( 0,0 );
				float2 UV22_g477 = float2( 0,0 );
				float2 UV32_g477 = float2( 0,0 );
				float W12_g477 = 0.0;
				float W22_g477 = 0.0;
				float W32_g477 = 0.0;
				StochasticTiling( UV2_g477 , UV12_g477 , UV22_g477 , UV32_g477 , W12_g477 , W22_g477 , W32_g477 );
				float2 temp_output_10_0_g477 = ddx( Input_UV145_g477 );
				float2 temp_output_12_0_g477 = ddy( Input_UV145_g477 );
				float4 Output_2D293_g477 = ( ( SAMPLE_TEXTURE2D_GRAD( _Splat3, sampler_linear_repeat, UV12_g477, temp_output_10_0_g477, temp_output_12_0_g477 ) * W12_g477 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat3, sampler_linear_repeat, UV22_g477, temp_output_10_0_g477, temp_output_12_0_g477 ) * W22_g477 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat3, sampler_linear_repeat, UV32_g477, temp_output_10_0_g477, temp_output_12_0_g477 ) * W32_g477 ) );
				float StochasticAmount43_g474 = _Stochastic3;
				float4 lerpResult26_g474 = lerp( SAMPLE_TEXTURE2D( _Splat3, sampler_linear_repeat, ParallaxUV51_g474 ) , Output_2D293_g477 , StochasticAmount43_g474);
				float localStochasticTiling2_g476 = ( 0.0 );
				float2 Input_UV145_g476 = ParallaxUV51_g474;
				float2 UV2_g476 = Input_UV145_g476;
				float2 UV12_g476 = float2( 0,0 );
				float2 UV22_g476 = float2( 0,0 );
				float2 UV32_g476 = float2( 0,0 );
				float W12_g476 = 0.0;
				float W22_g476 = 0.0;
				float W32_g476 = 0.0;
				StochasticTiling( UV2_g476 , UV12_g476 , UV22_g476 , UV32_g476 , W12_g476 , W22_g476 , W32_g476 );
				float2 temp_output_10_0_g476 = ddx( Input_UV145_g476 );
				float2 temp_output_12_0_g476 = ddy( Input_UV145_g476 );
				float4 Output_2D293_g476 = ( ( SAMPLE_TEXTURE2D_GRAD( _Mask3, sampler_linear_repeat, UV12_g476, temp_output_10_0_g476, temp_output_12_0_g476 ) * W12_g476 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask3, sampler_linear_repeat, UV22_g476, temp_output_10_0_g476, temp_output_12_0_g476 ) * W22_g476 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask3, sampler_linear_repeat, UV32_g476, temp_output_10_0_g476, temp_output_12_0_g476 ) * W32_g476 ) );
				float4 lerpResult28_g474 = lerp( SAMPLE_TEXTURE2D( _Mask3, sampler_linear_repeat, ParallaxUV51_g474 ) , Output_2D293_g476 , StochasticAmount43_g474);
				float4 temp_output_15_0_g478 = lerpResult28_g474;
				float SplatWeight363 = tex2DNode7.a;
				float HeightMask39_g478 = saturate(pow((((temp_output_15_0_g478).z*SplatWeight363)*4)+(SplatWeight363*2),( 1.0 / _HeightBlend3 )));
				float4 lerpResult16_g478 = lerp( lerpResult16_g473 , lerpResult26_g474 , HeightMask39_g478);
				
				float localStochasticTiling2_g461 = ( 0.0 );
				float2 Input_UV145_g461 = ParallaxUV51_g460;
				float2 UV2_g461 = Input_UV145_g461;
				float2 UV12_g461 = float2( 0,0 );
				float2 UV22_g461 = float2( 0,0 );
				float2 UV32_g461 = float2( 0,0 );
				float W12_g461 = 0.0;
				float W22_g461 = 0.0;
				float W32_g461 = 0.0;
				StochasticTiling( UV2_g461 , UV12_g461 , UV22_g461 , UV32_g461 , W12_g461 , W22_g461 , W32_g461 );
				float2 temp_output_10_0_g461 = ddx( Input_UV145_g461 );
				float2 temp_output_12_0_g461 = ddy( Input_UV145_g461 );
				float4 Output_2D293_g461 = ( ( SAMPLE_TEXTURE2D_GRAD( _Normal0, sampler_linear_repeat, UV12_g461, temp_output_10_0_g461, temp_output_12_0_g461 ) * W12_g461 ) + ( SAMPLE_TEXTURE2D_GRAD( _Normal0, sampler_linear_repeat, UV22_g461, temp_output_10_0_g461, temp_output_12_0_g461 ) * W22_g461 ) + ( SAMPLE_TEXTURE2D_GRAD( _Normal0, sampler_linear_repeat, UV32_g461, temp_output_10_0_g461, temp_output_12_0_g461 ) * W32_g461 ) );
				float3 lerpResult27_g460 = lerp( UnpackNormalScale( SAMPLE_TEXTURE2D( _Normal0, sampler_linear_repeat, ParallaxUV51_g460 ), 1.0f ) , UnpackNormalScale( Output_2D293_g461, 1.0 ) , StochasticAmount43_g460);
				float localStochasticTiling2_g465 = ( 0.0 );
				float2 Input_UV145_g465 = ParallaxUV51_g464;
				float2 UV2_g465 = Input_UV145_g465;
				float2 UV12_g465 = float2( 0,0 );
				float2 UV22_g465 = float2( 0,0 );
				float2 UV32_g465 = float2( 0,0 );
				float W12_g465 = 0.0;
				float W22_g465 = 0.0;
				float W32_g465 = 0.0;
				StochasticTiling( UV2_g465 , UV12_g465 , UV22_g465 , UV32_g465 , W12_g465 , W22_g465 , W32_g465 );
				float2 temp_output_10_0_g465 = ddx( Input_UV145_g465 );
				float2 temp_output_12_0_g465 = ddy( Input_UV145_g465 );
				float4 Output_2D293_g465 = ( ( SAMPLE_TEXTURE2D_GRAD( _Normal1, sampler_linear_repeat, UV12_g465, temp_output_10_0_g465, temp_output_12_0_g465 ) * W12_g465 ) + ( SAMPLE_TEXTURE2D_GRAD( _Normal1, sampler_linear_repeat, UV22_g465, temp_output_10_0_g465, temp_output_12_0_g465 ) * W22_g465 ) + ( SAMPLE_TEXTURE2D_GRAD( _Normal1, sampler_linear_repeat, UV32_g465, temp_output_10_0_g465, temp_output_12_0_g465 ) * W32_g465 ) );
				float3 lerpResult27_g464 = lerp( UnpackNormalScale( SAMPLE_TEXTURE2D( _Normal1, sampler_linear_repeat, ParallaxUV51_g464 ), 1.0f ) , UnpackNormalScale( Output_2D293_g465, 1.0 ) , StochasticAmount43_g464);
				float3 lerpResult17_g468 = lerp( lerpResult27_g460 , lerpResult27_g464 , HeightMask39_g468);
				float localStochasticTiling2_g470 = ( 0.0 );
				float2 Input_UV145_g470 = ParallaxUV51_g469;
				float2 UV2_g470 = Input_UV145_g470;
				float2 UV12_g470 = float2( 0,0 );
				float2 UV22_g470 = float2( 0,0 );
				float2 UV32_g470 = float2( 0,0 );
				float W12_g470 = 0.0;
				float W22_g470 = 0.0;
				float W32_g470 = 0.0;
				StochasticTiling( UV2_g470 , UV12_g470 , UV22_g470 , UV32_g470 , W12_g470 , W22_g470 , W32_g470 );
				float2 temp_output_10_0_g470 = ddx( Input_UV145_g470 );
				float2 temp_output_12_0_g470 = ddy( Input_UV145_g470 );
				float4 Output_2D293_g470 = ( ( SAMPLE_TEXTURE2D_GRAD( _Normal2, sampler_linear_repeat, UV12_g470, temp_output_10_0_g470, temp_output_12_0_g470 ) * W12_g470 ) + ( SAMPLE_TEXTURE2D_GRAD( _Normal2, sampler_linear_repeat, UV22_g470, temp_output_10_0_g470, temp_output_12_0_g470 ) * W22_g470 ) + ( SAMPLE_TEXTURE2D_GRAD( _Normal2, sampler_linear_repeat, UV32_g470, temp_output_10_0_g470, temp_output_12_0_g470 ) * W32_g470 ) );
				float3 lerpResult27_g469 = lerp( UnpackNormalScale( SAMPLE_TEXTURE2D( _Normal2, sampler_linear_repeat, ParallaxUV51_g469 ), 1.0f ) , UnpackNormalScale( Output_2D293_g470, 1.0 ) , StochasticAmount43_g469);
				float3 lerpResult17_g473 = lerp( lerpResult17_g468 , lerpResult27_g469 , HeightMask39_g473);
				float localStochasticTiling2_g475 = ( 0.0 );
				float2 Input_UV145_g475 = ParallaxUV51_g474;
				float2 UV2_g475 = Input_UV145_g475;
				float2 UV12_g475 = float2( 0,0 );
				float2 UV22_g475 = float2( 0,0 );
				float2 UV32_g475 = float2( 0,0 );
				float W12_g475 = 0.0;
				float W22_g475 = 0.0;
				float W32_g475 = 0.0;
				StochasticTiling( UV2_g475 , UV12_g475 , UV22_g475 , UV32_g475 , W12_g475 , W22_g475 , W32_g475 );
				float2 temp_output_10_0_g475 = ddx( Input_UV145_g475 );
				float2 temp_output_12_0_g475 = ddy( Input_UV145_g475 );
				float4 Output_2D293_g475 = ( ( SAMPLE_TEXTURE2D_GRAD( _Normal3, sampler_linear_repeat, UV12_g475, temp_output_10_0_g475, temp_output_12_0_g475 ) * W12_g475 ) + ( SAMPLE_TEXTURE2D_GRAD( _Normal3, sampler_linear_repeat, UV22_g475, temp_output_10_0_g475, temp_output_12_0_g475 ) * W22_g475 ) + ( SAMPLE_TEXTURE2D_GRAD( _Normal3, sampler_linear_repeat, UV32_g475, temp_output_10_0_g475, temp_output_12_0_g475 ) * W32_g475 ) );
				float3 lerpResult27_g474 = lerp( UnpackNormalScale( SAMPLE_TEXTURE2D( _Normal3, sampler_linear_repeat, ParallaxUV51_g474 ), 1.0f ) , UnpackNormalScale( Output_2D293_g475, 1.0 ) , StochasticAmount43_g474);
				float3 lerpResult17_g478 = lerp( lerpResult17_g473 , lerpResult27_g474 , HeightMask39_g478);
				
				float localStochasticTiling2_g462 = ( 0.0 );
				float2 Input_UV145_g462 = ParallaxUV51_g460;
				float2 UV2_g462 = Input_UV145_g462;
				float2 UV12_g462 = float2( 0,0 );
				float2 UV22_g462 = float2( 0,0 );
				float2 UV32_g462 = float2( 0,0 );
				float W12_g462 = 0.0;
				float W22_g462 = 0.0;
				float W32_g462 = 0.0;
				StochasticTiling( UV2_g462 , UV12_g462 , UV22_g462 , UV32_g462 , W12_g462 , W22_g462 , W32_g462 );
				float2 temp_output_10_0_g462 = ddx( Input_UV145_g462 );
				float2 temp_output_12_0_g462 = ddy( Input_UV145_g462 );
				float4 Output_2D293_g462 = ( ( SAMPLE_TEXTURE2D_GRAD( _Mask0, sampler_linear_repeat, UV12_g462, temp_output_10_0_g462, temp_output_12_0_g462 ) * W12_g462 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask0, sampler_linear_repeat, UV22_g462, temp_output_10_0_g462, temp_output_12_0_g462 ) * W22_g462 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask0, sampler_linear_repeat, UV32_g462, temp_output_10_0_g462, temp_output_12_0_g462 ) * W32_g462 ) );
				float4 lerpResult28_g460 = lerp( SAMPLE_TEXTURE2D( _Mask0, sampler_linear_repeat, ParallaxUV51_g460 ) , Output_2D293_g462 , StochasticAmount43_g460);
				float4 lerpResult18_g468 = lerp( lerpResult28_g460 , temp_output_15_0_g468 , HeightMask39_g468);
				float4 lerpResult18_g473 = lerp( lerpResult18_g468 , temp_output_15_0_g473 , HeightMask39_g473);
				float4 lerpResult18_g478 = lerp( lerpResult18_g473 , temp_output_15_0_g478 , HeightMask39_g478);
				float4 break106 = lerpResult18_g478;
				
				float2 uv_TerrainHolesTexture = IN.ase_texcoord7.xy * _TerrainHolesTexture_ST.xy + _TerrainHolesTexture_ST.zw;
				
				float3 Albedo = lerpResult16_g478.xyz;
				float3 Normal = lerpResult17_g478;
				float3 Emission = 0;
				float3 Specular = 0.5;
				float Metallic = break106.x;
				float Smoothness = break106.w;
				float Occlusion = break106.y;
				float Alpha = SAMPLE_TEXTURE2D( _TerrainHolesTexture, sampler_TerrainHolesTexture, uv_TerrainHolesTexture ).r;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;
				#ifdef ASE_DEPTH_WRITE_ON
				float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				InputData inputData;
				inputData.positionWS = WorldPosition;
				inputData.viewDirectionWS = WorldViewDirection;
				inputData.shadowCoord = ShadowCoords;

				#ifdef _NORMALMAP
					#if _NORMAL_DROPOFF_TS
					inputData.normalWS = TransformTangentToWorld(Normal, half3x3( WorldTangent, WorldBiTangent, WorldNormal ));
					#elif _NORMAL_DROPOFF_OS
					inputData.normalWS = TransformObjectToWorldNormal(Normal);
					#elif _NORMAL_DROPOFF_WS
					inputData.normalWS = Normal;
					#endif
					inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
				#else
					inputData.normalWS = WorldNormal;
				#endif

				#ifdef ASE_FOG
					inputData.fogCoord = IN.fogFactorAndVertexLight.x;
				#endif

				inputData.vertexLighting = IN.fogFactorAndVertexLight.yzw;
				#if defined(ENABLE_TERRAIN_PERPIXEL_NORMAL)
					float3 SH = SampleSH(inputData.normalWS.xyz);
				#else
					float3 SH = IN.lightmapUVOrVertexSH.xyz;
				#endif

				inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS );
				#ifdef _ASE_BAKEDGI
					inputData.bakedGI = BakedGI;
				#endif
				half4 color = UniversalFragmentPBR(
					inputData, 
					Albedo, 
					Metallic, 
					Specular, 
					Smoothness, 
					Occlusion, 
					Emission, 
					Alpha);

				#ifdef _TRANSMISSION_ASE
				{
					float shadow = _TransmissionShadow;

					Light mainLight = GetMainLight( inputData.shadowCoord );
					float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
					mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );
					half3 mainTransmission = max(0 , -dot(inputData.normalWS, mainLight.direction)) * mainAtten * Transmission;
					color.rgb += Albedo * mainTransmission;

					#ifdef _ADDITIONAL_LIGHTS
						int transPixelLightCount = GetAdditionalLightsCount();
						for (int i = 0; i < transPixelLightCount; ++i)
						{
							Light light = GetAdditionalLight(i, inputData.positionWS);
							float3 atten = light.color * light.distanceAttenuation;
							atten = lerp( atten, atten * light.shadowAttenuation, shadow );

							half3 transmission = max(0 , -dot(inputData.normalWS, light.direction)) * atten * Transmission;
							color.rgb += Albedo * transmission;
						}
					#endif
				}
				#endif

				#ifdef _TRANSLUCENCY_ASE
				{
					float shadow = _TransShadow;
					float normal = _TransNormal;
					float scattering = _TransScattering;
					float direct = _TransDirect;
					float ambient = _TransAmbient;
					float strength = _TransStrength;

					Light mainLight = GetMainLight( inputData.shadowCoord );
					float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
					mainAtten = lerp( mainAtten, mainAtten * mainLight.shadowAttenuation, shadow );

					half3 mainLightDir = mainLight.direction + inputData.normalWS * normal;
					half mainVdotL = pow( saturate( dot( inputData.viewDirectionWS, -mainLightDir ) ), scattering );
					half3 mainTranslucency = mainAtten * ( mainVdotL * direct + inputData.bakedGI * ambient ) * Translucency;
					color.rgb += Albedo * mainTranslucency * strength;

					#ifdef _ADDITIONAL_LIGHTS
						int transPixelLightCount = GetAdditionalLightsCount();
						for (int i = 0; i < transPixelLightCount; ++i)
						{
							Light light = GetAdditionalLight(i, inputData.positionWS);
							float3 atten = light.color * light.distanceAttenuation;
							atten = lerp( atten, atten * light.shadowAttenuation, shadow );

							half3 lightDir = light.direction + inputData.normalWS * normal;
							half VdotL = pow( saturate( dot( inputData.viewDirectionWS, -lightDir ) ), scattering );
							half3 translucency = atten * ( VdotL * direct + inputData.bakedGI * ambient ) * Translucency;
							color.rgb += Albedo * translucency * strength;
						}
					#endif
				}
				#endif

				#ifdef _REFRACTION_ASE
					float4 projScreenPos = ScreenPos / ScreenPos.w;
					float3 refractionOffset = ( RefractionIndex - 1.0 ) * mul( UNITY_MATRIX_V, WorldNormal ).xyz * ( 1.0 - dot( WorldNormal, WorldViewDirection ) );
					projScreenPos.xy += refractionOffset.xy;
					float3 refraction = SHADERGRAPH_SAMPLE_SCENE_COLOR( projScreenPos ) * RefractionColor;
					color.rgb = lerp( refraction, color.rgb, color.a );
					color.a = 1;
				#endif

				#ifdef ASE_FINAL_COLOR_ALPHA_MULTIPLY
					color.rgb *= color.a;
				#endif

				#ifdef ASE_FOG
					#ifdef TERRAIN_SPLAT_ADDPASS
						color.rgb = MixFogColor(color.rgb, half3( 0, 0, 0 ), IN.fogFactorAndVertexLight.x );
					#else
						color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
					#endif
				#endif
				
				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif

				return color;
			}

			ENDHLSL
		}

		UsePass "Hidden/Nature/Terrain/Utilities/PICKING"
	UsePass "Hidden/Nature/Terrain/Utilities/SELECTION"

		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off

			HLSLPROGRAM
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_FINAL_COLOR_ALPHA_MULTIPLY 1
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 80301
			#define ASE_USING_SAMPLING_MACROS 1

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_SHADOWCASTER

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION
			#pragma multi_compile_instancing
			#pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap forwardadd


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Splat0_ST;
			float4 _Mask3_ST;
			float4 _Splat3_ST;
			float4 _Mask2_ST;
			float4 _Control_ST;
			float4 _Mask1_ST;
			float4 _Splat2_ST;
			float4 _Splat1_ST;
			float4 _Mask0_ST;
			float4 _TerrainHolesTexture_ST;
			float _Stochastic1;
			float _HeightBlend1;
			float _HeightBlend3;
			float _Parallax2;
			float _Stochastic0;
			float _Stochastic2;
			float _HeightBlend2;
			float _Parallax3;
			float _Parallax0;
			float _Stochastic3;
			float _Parallax1;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			TEXTURE2D(_TerrainHolesTexture);
			SAMPLER(sampler_TerrainHolesTexture);
			#ifdef UNITY_INSTANCING_ENABLED//ASE Terrain Instancing
				TEXTURE2D(_TerrainHeightmapTexture);//ASE Terrain Instancing
				TEXTURE2D( _TerrainNormalmapTexture);//ASE Terrain Instancing
				SAMPLER(sampler_TerrainNormalmapTexture);//ASE Terrain Instancing
			#endif//ASE Terrain Instancing
			UNITY_INSTANCING_BUFFER_START( Terrain )//ASE Terrain Instancing
				UNITY_DEFINE_INSTANCED_PROP( float4, _TerrainPatchInstanceData )//ASE Terrain Instancing
			UNITY_INSTANCING_BUFFER_END( Terrain)//ASE Terrain Instancing
			CBUFFER_START( UnityTerrain)//ASE Terrain Instancing
				#ifdef UNITY_INSTANCING_ENABLED//ASE Terrain Instancing
					float4 _TerrainHeightmapRecipSize;//ASE Terrain Instancing
					float4 _TerrainHeightmapScale;//ASE Terrain Instancing
				#endif//ASE Terrain Instancing
			CBUFFER_END//ASE Terrain Instancing


			VertexInput ApplyMeshModification( VertexInput v )
			{
			#ifdef UNITY_INSTANCING_ENABLED
				float2 patchVertex = v.vertex.xy;
				float4 instanceData = UNITY_ACCESS_INSTANCED_PROP( Terrain, _TerrainPatchInstanceData );
				float2 sampleCoords = ( patchVertex.xy + instanceData.xy ) * instanceData.z;
				float height = UnpackHeightmap( _TerrainHeightmapTexture.Load( int3( sampleCoords, 0 ) ) );
				v.vertex.xz = sampleCoords* _TerrainHeightmapScale.xz;
				v.vertex.y = height* _TerrainHeightmapScale.y;
				#ifdef ENABLE_TERRAIN_PERPIXEL_NORMAL
					v.ase_normal = float3(0, 1, 0);
				#else
					v.ase_normal = _TerrainNormalmapTexture.Load(int3(sampleCoords, 0)).rgb* 2 - 1;
				#endif
				v.ase_texcoord.xy = sampleCoords* _TerrainHeightmapRecipSize.zw;
			#endif
				return v;
			}
			

			float3 _LightDirection;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				v = ApplyMeshModification(v);
				float3 localCalculateTangentsSRP26 = ( ( v.ase_tangent.xyz * v.ase_normal * 0.0 ) );
				{
				v.ase_tangent.xyz = cross ( v.ase_normal, float3( 0, 0, 1 ) );
				v.ase_tangent.w = -1;
				}
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = localCalculateTangentsSRP26;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif
				float3 normalWS = TransformObjectToWorldDir(v.ase_normal);

				float4 clipPos = TransformWorldToHClip( ApplyShadowBias( positionWS, normalWS, _LightDirection ) );

				#if UNITY_REVERSED_Z
					clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#else
					clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.clipPos = clipPos;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_tangent = v.ase_tangent;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual  
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif

			half4 frag(	VertexOutput IN 
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );
				
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float2 uv_TerrainHolesTexture = IN.ase_texcoord2.xy * _TerrainHolesTexture_ST.xy + _TerrainHolesTexture_ST.zw;
				
				float Alpha = SAMPLE_TEXTURE2D( _TerrainHolesTexture, sampler_TerrainHolesTexture, uv_TerrainHolesTexture ).r;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				#ifdef ASE_DEPTH_WRITE_ON
				float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				#ifdef ASE_DEPTH_WRITE_ON
					outputDepth = DepthValue;
				#endif
				return 0;
			}

			ENDHLSL
		}

		UsePass "Hidden/Nature/Terrain/Utilities/PICKING"
	UsePass "Hidden/Nature/Terrain/Utilities/SELECTION"

		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_FINAL_COLOR_ALPHA_MULTIPLY 1
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 80301
			#define ASE_USING_SAMPLING_MACROS 1

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION
			#pragma multi_compile_instancing
			#pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap forwardadd


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Splat0_ST;
			float4 _Mask3_ST;
			float4 _Splat3_ST;
			float4 _Mask2_ST;
			float4 _Control_ST;
			float4 _Mask1_ST;
			float4 _Splat2_ST;
			float4 _Splat1_ST;
			float4 _Mask0_ST;
			float4 _TerrainHolesTexture_ST;
			float _Stochastic1;
			float _HeightBlend1;
			float _HeightBlend3;
			float _Parallax2;
			float _Stochastic0;
			float _Stochastic2;
			float _HeightBlend2;
			float _Parallax3;
			float _Parallax0;
			float _Stochastic3;
			float _Parallax1;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			TEXTURE2D(_TerrainHolesTexture);
			SAMPLER(sampler_TerrainHolesTexture);
			#ifdef UNITY_INSTANCING_ENABLED//ASE Terrain Instancing
				TEXTURE2D(_TerrainHeightmapTexture);//ASE Terrain Instancing
				TEXTURE2D( _TerrainNormalmapTexture);//ASE Terrain Instancing
				SAMPLER(sampler_TerrainNormalmapTexture);//ASE Terrain Instancing
			#endif//ASE Terrain Instancing
			UNITY_INSTANCING_BUFFER_START( Terrain )//ASE Terrain Instancing
				UNITY_DEFINE_INSTANCED_PROP( float4, _TerrainPatchInstanceData )//ASE Terrain Instancing
			UNITY_INSTANCING_BUFFER_END( Terrain)//ASE Terrain Instancing
			CBUFFER_START( UnityTerrain)//ASE Terrain Instancing
				#ifdef UNITY_INSTANCING_ENABLED//ASE Terrain Instancing
					float4 _TerrainHeightmapRecipSize;//ASE Terrain Instancing
					float4 _TerrainHeightmapScale;//ASE Terrain Instancing
				#endif//ASE Terrain Instancing
			CBUFFER_END//ASE Terrain Instancing


			VertexInput ApplyMeshModification( VertexInput v )
			{
			#ifdef UNITY_INSTANCING_ENABLED
				float2 patchVertex = v.vertex.xy;
				float4 instanceData = UNITY_ACCESS_INSTANCED_PROP( Terrain, _TerrainPatchInstanceData );
				float2 sampleCoords = ( patchVertex.xy + instanceData.xy ) * instanceData.z;
				float height = UnpackHeightmap( _TerrainHeightmapTexture.Load( int3( sampleCoords, 0 ) ) );
				v.vertex.xz = sampleCoords* _TerrainHeightmapScale.xz;
				v.vertex.y = height* _TerrainHeightmapScale.y;
				#ifdef ENABLE_TERRAIN_PERPIXEL_NORMAL
					v.ase_normal = float3(0, 1, 0);
				#else
					v.ase_normal = _TerrainNormalmapTexture.Load(int3(sampleCoords, 0)).rgb* 2 - 1;
				#endif
				v.ase_texcoord.xy = sampleCoords* _TerrainHeightmapRecipSize.zw;
			#endif
				return v;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				v = ApplyMeshModification(v);
				float3 localCalculateTangentsSRP26 = ( ( v.ase_tangent.xyz * v.ase_normal * 0.0 ) );
				{
				v.ase_tangent.xyz = cross ( v.ase_normal, float3( 0, 0, 1 ) );
				v.ase_tangent.w = -1;
				}
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = localCalculateTangentsSRP26;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;
				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_tangent = v.ase_tangent;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE)
				#define ASE_SV_DEPTH SV_DepthLessEqual  
			#else
				#define ASE_SV_DEPTH SV_Depth
			#endif
			half4 frag(	VertexOutput IN 
						#ifdef ASE_DEPTH_WRITE_ON
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float2 uv_TerrainHolesTexture = IN.ase_texcoord2.xy * _TerrainHolesTexture_ST.xy + _TerrainHolesTexture_ST.zw;
				
				float Alpha = SAMPLE_TEXTURE2D( _TerrainHolesTexture, sampler_TerrainHolesTexture, uv_TerrainHolesTexture ).r;
				float AlphaClipThreshold = 0.5;
				#ifdef ASE_DEPTH_WRITE_ON
				float DepthValue = 0;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				#ifdef ASE_DEPTH_WRITE_ON
				outputDepth = DepthValue;
				#endif
				return 0;
			}
			ENDHLSL
		}

		UsePass "Hidden/Nature/Terrain/Utilities/PICKING"
	UsePass "Hidden/Nature/Terrain/Utilities/SELECTION"

		Pass
		{
			
			Name "Meta"
			Tags { "LightMode"="Meta" }

			Cull Off

			HLSLPROGRAM
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_FINAL_COLOR_ALPHA_MULTIPLY 1
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 80301
			#define ASE_USING_SAMPLING_MACROS 1

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_META

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_VERT_POSITION
			#pragma multi_compile_instancing
			#pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap forwardadd


			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Splat0_ST;
			float4 _Mask3_ST;
			float4 _Splat3_ST;
			float4 _Mask2_ST;
			float4 _Control_ST;
			float4 _Mask1_ST;
			float4 _Splat2_ST;
			float4 _Splat1_ST;
			float4 _Mask0_ST;
			float4 _TerrainHolesTexture_ST;
			float _Stochastic1;
			float _HeightBlend1;
			float _HeightBlend3;
			float _Parallax2;
			float _Stochastic0;
			float _Stochastic2;
			float _HeightBlend2;
			float _Parallax3;
			float _Parallax0;
			float _Stochastic3;
			float _Parallax1;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			TEXTURE2D(_Splat0);
			TEXTURE2D(_Mask0);
			SAMPLER(sampler_linear_repeat);
			TEXTURE2D(_Splat1);
			TEXTURE2D(_Mask1);
			TEXTURE2D(_Control);
			SAMPLER(sampler_Control);
			TEXTURE2D(_Splat2);
			TEXTURE2D(_Mask2);
			TEXTURE2D(_Splat3);
			TEXTURE2D(_Mask3);
			TEXTURE2D(_TerrainHolesTexture);
			SAMPLER(sampler_TerrainHolesTexture);
			#ifdef UNITY_INSTANCING_ENABLED//ASE Terrain Instancing
				TEXTURE2D(_TerrainHeightmapTexture);//ASE Terrain Instancing
				TEXTURE2D( _TerrainNormalmapTexture);//ASE Terrain Instancing
				SAMPLER(sampler_TerrainNormalmapTexture);//ASE Terrain Instancing
			#endif//ASE Terrain Instancing
			UNITY_INSTANCING_BUFFER_START( Terrain )//ASE Terrain Instancing
				UNITY_DEFINE_INSTANCED_PROP( float4, _TerrainPatchInstanceData )//ASE Terrain Instancing
			UNITY_INSTANCING_BUFFER_END( Terrain)//ASE Terrain Instancing
			CBUFFER_START( UnityTerrain)//ASE Terrain Instancing
				#ifdef UNITY_INSTANCING_ENABLED//ASE Terrain Instancing
					float4 _TerrainHeightmapRecipSize;//ASE Terrain Instancing
					float4 _TerrainHeightmapScale;//ASE Terrain Instancing
				#endif//ASE Terrain Instancing
			CBUFFER_END//ASE Terrain Instancing


			inline float2 POM( TEXTURE2D(heightMap), SAMPLER(samplerheightMap), float2 uvs, float2 dx, float2 dy, float3 normalWorld, float3 viewWorld, float3 viewDirTan, int minSamples, int maxSamples, float parallax, float refPlane, float2 tilling, float2 curv, int index )
			{
				float3 result = 0;
				int stepIndex = 0;
				int numSteps = ( int )lerp( (float)maxSamples, (float)minSamples, saturate( dot( normalWorld, viewWorld ) ) );
				float layerHeight = 1.0 / numSteps;
				float2 plane = parallax * ( viewDirTan.xy / viewDirTan.z );
				uvs.xy += refPlane * plane;
				float2 deltaTex = -plane * layerHeight;
				float2 prevTexOffset = 0;
				float prevRayZ = 1.0f;
				float prevHeight = 0.0f;
				float2 currTexOffset = deltaTex;
				float currRayZ = 1.0f - layerHeight;
				float currHeight = 0.0f;
				float intersection = 0;
				float2 finalTexOffset = 0;
				while ( stepIndex < numSteps + 1 )
				{
				 	currHeight = SAMPLE_TEXTURE2D_GRAD( heightMap, samplerheightMap, uvs + currTexOffset, dx, dy ).b;
				 	if ( currHeight > currRayZ )
				 	{
				 	 	stepIndex = numSteps + 1;
				 	}
				 	else
				 	{
				 	 	stepIndex++;
				 	 	prevTexOffset = currTexOffset;
				 	 	prevRayZ = currRayZ;
				 	 	prevHeight = currHeight;
				 	 	currTexOffset += deltaTex;
				 	 	currRayZ -= layerHeight;
				 	}
				}
				int sectionSteps = 4;
				int sectionIndex = 0;
				float newZ = 0;
				float newHeight = 0;
				while ( sectionIndex < sectionSteps )
				{
				 	intersection = ( prevHeight - prevRayZ ) / ( prevHeight - currHeight + currRayZ - prevRayZ );
				 	finalTexOffset = prevTexOffset + intersection * deltaTex;
				 	newZ = prevRayZ - intersection * layerHeight;
				 	newHeight = SAMPLE_TEXTURE2D_GRAD( heightMap, samplerheightMap, uvs + finalTexOffset, dx, dy ).b;
				 	if ( newHeight > newZ )
				 	{
				 	 	currTexOffset = finalTexOffset;
				 	 	currHeight = newHeight;
				 	 	currRayZ = newZ;
				 	 	deltaTex = intersection * deltaTex;
				 	 	layerHeight = intersection * layerHeight;
				 	}
				 	else
				 	{
				 	 	prevTexOffset = finalTexOffset;
				 	 	prevHeight = newHeight;
				 	 	prevRayZ = newZ;
				 	 	deltaTex = ( 1 - intersection ) * deltaTex;
				 	 	layerHeight = ( 1 - intersection ) * layerHeight;
				 	}
				 	sectionIndex++;
				}
				return uvs.xy + finalTexOffset;
			}
			
			void StochasticTiling( float2 UV, out float2 UV1, out float2 UV2, out float2 UV3, out float W1, out float W2, out float W3 )
			{
				float2 vertex1, vertex2, vertex3;
				// Scaling of the input
				float2 uv = UV * 3.464; // 2 * sqrt (3)
				// Skew input space into simplex triangle grid
				const float2x2 gridToSkewedGrid = float2x2( 1.0, 0.0, -0.57735027, 1.15470054 );
				float2 skewedCoord = mul( gridToSkewedGrid, uv );
				// Compute local triangle vertex IDs and local barycentric coordinates
				int2 baseId = int2( floor( skewedCoord ) );
				float3 temp = float3( frac( skewedCoord ), 0 );
				temp.z = 1.0 - temp.x - temp.y;
				if ( temp.z > 0.0 )
				{
					W1 = temp.z;
					W2 = temp.y;
					W3 = temp.x;
					vertex1 = baseId;
					vertex2 = baseId + int2( 0, 1 );
					vertex3 = baseId + int2( 1, 0 );
				}
				else
				{
					W1 = -temp.z;
					W2 = 1.0 - temp.y;
					W3 = 1.0 - temp.x;
					vertex1 = baseId + int2( 1, 1 );
					vertex2 = baseId + int2( 1, 0 );
					vertex3 = baseId + int2( 0, 1 );
				}
				UV1 = UV + frac( sin( mul( float2x2( 127.1, 311.7, 269.5, 183.3 ), vertex1 ) ) * 43758.5453 );
				UV2 = UV + frac( sin( mul( float2x2( 127.1, 311.7, 269.5, 183.3 ), vertex2 ) ) * 43758.5453 );
				UV3 = UV + frac( sin( mul( float2x2( 127.1, 311.7, 269.5, 183.3 ), vertex3 ) ) * 43758.5453 );
				return;
			}
			
			VertexInput ApplyMeshModification( VertexInput v )
			{
			#ifdef UNITY_INSTANCING_ENABLED
				float2 patchVertex = v.vertex.xy;
				float4 instanceData = UNITY_ACCESS_INSTANCED_PROP( Terrain, _TerrainPatchInstanceData );
				float2 sampleCoords = ( patchVertex.xy + instanceData.xy ) * instanceData.z;
				float height = UnpackHeightmap( _TerrainHeightmapTexture.Load( int3( sampleCoords, 0 ) ) );
				v.vertex.xz = sampleCoords* _TerrainHeightmapScale.xz;
				v.vertex.y = height* _TerrainHeightmapScale.y;
				#ifdef ENABLE_TERRAIN_PERPIXEL_NORMAL
					v.ase_normal = float3(0, 1, 0);
				#else
					v.ase_normal = _TerrainNormalmapTexture.Load(int3(sampleCoords, 0)).rgb* 2 - 1;
				#endif
				v.ase_texcoord.xy = sampleCoords* _TerrainHeightmapRecipSize.zw;
			#endif
				return v;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				v = ApplyMeshModification(v);
				float3 localCalculateTangentsSRP26 = ( ( v.ase_tangent.xyz * v.ase_normal * 0.0 ) );
				{
				v.ase_tangent.xyz = cross ( v.ase_normal, float3( 0, 0, 1 ) );
				v.ase_tangent.w = -1;
				}
				
				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord3.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord4.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * unity_WorldTransformParams.w;
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord5.xyz = ase_worldBitangent;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				o.ase_texcoord3.w = 0;
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.w = 0;
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = localCalculateTangentsSRP26;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				o.clipPos = MetaVertexPosition( v.vertex, v.texcoord1.xy, v.texcoord1.xy, unity_LightmapST, unity_DynamicLightmapST );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.texcoord1 = v.texcoord1;
				o.texcoord2 = v.texcoord2;
				o.ase_tangent = v.ase_tangent;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.texcoord1 = patch[0].texcoord1 * bary.x + patch[1].texcoord1 * bary.y + patch[2].texcoord1 * bary.z;
				o.texcoord2 = patch[0].texcoord2 * bary.x + patch[1].texcoord2 * bary.y + patch[2].texcoord2 * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float4 break18_g460 = _Splat0_ST;
				float2 appendResult16_g460 = (float2(break18_g460.x , break18_g460.y));
				float2 appendResult15_g460 = (float2(break18_g460.z , break18_g460.w));
				float2 texCoord17_g460 = IN.ase_texcoord2.xy * appendResult16_g460 + appendResult15_g460;
				float2 UV29_g460 = texCoord17_g460;
				float3 ase_worldTangent = IN.ase_texcoord3.xyz;
				float3 ase_worldNormal = IN.ase_texcoord4.xyz;
				float3 ase_worldBitangent = IN.ase_texcoord5.xyz;
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 ase_tanViewDir =  tanToWorld0 * ase_worldViewDir.x + tanToWorld1 * ase_worldViewDir.y  + tanToWorld2 * ase_worldViewDir.z;
				ase_tanViewDir = normalize(ase_tanViewDir);
				float2 OffsetPOM47_g460 = POM( _Mask0, sampler_linear_repeat, UV29_g460, ddx(UV29_g460), ddy(UV29_g460), ase_worldNormal, ase_worldViewDir, ase_tanViewDir, 8, 8, _Parallax0, 0.5, _Mask0_ST.xy, float2(0,0), 0 );
				float2 ParallaxUV51_g460 = OffsetPOM47_g460;
				float localStochasticTiling2_g463 = ( 0.0 );
				float2 Input_UV145_g463 = ParallaxUV51_g460;
				float2 UV2_g463 = Input_UV145_g463;
				float2 UV12_g463 = float2( 0,0 );
				float2 UV22_g463 = float2( 0,0 );
				float2 UV32_g463 = float2( 0,0 );
				float W12_g463 = 0.0;
				float W22_g463 = 0.0;
				float W32_g463 = 0.0;
				StochasticTiling( UV2_g463 , UV12_g463 , UV22_g463 , UV32_g463 , W12_g463 , W22_g463 , W32_g463 );
				float2 temp_output_10_0_g463 = ddx( Input_UV145_g463 );
				float2 temp_output_12_0_g463 = ddy( Input_UV145_g463 );
				float4 Output_2D293_g463 = ( ( SAMPLE_TEXTURE2D_GRAD( _Splat0, sampler_linear_repeat, UV12_g463, temp_output_10_0_g463, temp_output_12_0_g463 ) * W12_g463 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat0, sampler_linear_repeat, UV22_g463, temp_output_10_0_g463, temp_output_12_0_g463 ) * W22_g463 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat0, sampler_linear_repeat, UV32_g463, temp_output_10_0_g463, temp_output_12_0_g463 ) * W32_g463 ) );
				float StochasticAmount43_g460 = _Stochastic0;
				float4 lerpResult26_g460 = lerp( SAMPLE_TEXTURE2D( _Splat0, sampler_linear_repeat, ParallaxUV51_g460 ) , Output_2D293_g463 , StochasticAmount43_g460);
				float4 break18_g464 = _Splat1_ST;
				float2 appendResult16_g464 = (float2(break18_g464.x , break18_g464.y));
				float2 appendResult15_g464 = (float2(break18_g464.z , break18_g464.w));
				float2 texCoord17_g464 = IN.ase_texcoord2.xy * appendResult16_g464 + appendResult15_g464;
				float2 UV29_g464 = texCoord17_g464;
				float2 OffsetPOM47_g464 = POM( _Mask1, sampler_linear_repeat, UV29_g464, ddx(UV29_g464), ddy(UV29_g464), ase_worldNormal, ase_worldViewDir, ase_tanViewDir, 8, 8, _Parallax1, 0.5, _Mask1_ST.xy, float2(0,0), 0 );
				float2 ParallaxUV51_g464 = OffsetPOM47_g464;
				float localStochasticTiling2_g467 = ( 0.0 );
				float2 Input_UV145_g467 = ParallaxUV51_g464;
				float2 UV2_g467 = Input_UV145_g467;
				float2 UV12_g467 = float2( 0,0 );
				float2 UV22_g467 = float2( 0,0 );
				float2 UV32_g467 = float2( 0,0 );
				float W12_g467 = 0.0;
				float W22_g467 = 0.0;
				float W32_g467 = 0.0;
				StochasticTiling( UV2_g467 , UV12_g467 , UV22_g467 , UV32_g467 , W12_g467 , W22_g467 , W32_g467 );
				float2 temp_output_10_0_g467 = ddx( Input_UV145_g467 );
				float2 temp_output_12_0_g467 = ddy( Input_UV145_g467 );
				float4 Output_2D293_g467 = ( ( SAMPLE_TEXTURE2D_GRAD( _Splat1, sampler_linear_repeat, UV12_g467, temp_output_10_0_g467, temp_output_12_0_g467 ) * W12_g467 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat1, sampler_linear_repeat, UV22_g467, temp_output_10_0_g467, temp_output_12_0_g467 ) * W22_g467 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat1, sampler_linear_repeat, UV32_g467, temp_output_10_0_g467, temp_output_12_0_g467 ) * W32_g467 ) );
				float StochasticAmount43_g464 = _Stochastic1;
				float4 lerpResult26_g464 = lerp( SAMPLE_TEXTURE2D( _Splat1, sampler_linear_repeat, ParallaxUV51_g464 ) , Output_2D293_g467 , StochasticAmount43_g464);
				float localStochasticTiling2_g466 = ( 0.0 );
				float2 Input_UV145_g466 = ParallaxUV51_g464;
				float2 UV2_g466 = Input_UV145_g466;
				float2 UV12_g466 = float2( 0,0 );
				float2 UV22_g466 = float2( 0,0 );
				float2 UV32_g466 = float2( 0,0 );
				float W12_g466 = 0.0;
				float W22_g466 = 0.0;
				float W32_g466 = 0.0;
				StochasticTiling( UV2_g466 , UV12_g466 , UV22_g466 , UV32_g466 , W12_g466 , W22_g466 , W32_g466 );
				float2 temp_output_10_0_g466 = ddx( Input_UV145_g466 );
				float2 temp_output_12_0_g466 = ddy( Input_UV145_g466 );
				float4 Output_2D293_g466 = ( ( SAMPLE_TEXTURE2D_GRAD( _Mask1, sampler_linear_repeat, UV12_g466, temp_output_10_0_g466, temp_output_12_0_g466 ) * W12_g466 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask1, sampler_linear_repeat, UV22_g466, temp_output_10_0_g466, temp_output_12_0_g466 ) * W22_g466 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask1, sampler_linear_repeat, UV32_g466, temp_output_10_0_g466, temp_output_12_0_g466 ) * W32_g466 ) );
				float4 lerpResult28_g464 = lerp( SAMPLE_TEXTURE2D( _Mask1, sampler_linear_repeat, ParallaxUV51_g464 ) , Output_2D293_g466 , StochasticAmount43_g464);
				float4 temp_output_15_0_g468 = lerpResult28_g464;
				float2 uv_Control = IN.ase_texcoord2.xy * _Control_ST.xy + _Control_ST.zw;
				float4 tex2DNode7 = SAMPLE_TEXTURE2D( _Control, sampler_Control, uv_Control );
				float SplatWeight161 = tex2DNode7.g;
				float HeightMask39_g468 = saturate(pow((((temp_output_15_0_g468).z*SplatWeight161)*4)+(SplatWeight161*2),( 1.0 / _HeightBlend1 )));
				float4 lerpResult16_g468 = lerp( lerpResult26_g460 , lerpResult26_g464 , HeightMask39_g468);
				float4 break18_g469 = _Splat2_ST;
				float2 appendResult16_g469 = (float2(break18_g469.x , break18_g469.y));
				float2 appendResult15_g469 = (float2(break18_g469.z , break18_g469.w));
				float2 texCoord17_g469 = IN.ase_texcoord2.xy * appendResult16_g469 + appendResult15_g469;
				float2 UV29_g469 = texCoord17_g469;
				float2 OffsetPOM47_g469 = POM( _Mask2, sampler_linear_repeat, UV29_g469, ddx(UV29_g469), ddy(UV29_g469), ase_worldNormal, ase_worldViewDir, ase_tanViewDir, 8, 8, _Parallax2, 0.5, _Mask2_ST.xy, float2(0,0), 0 );
				float2 ParallaxUV51_g469 = OffsetPOM47_g469;
				float localStochasticTiling2_g472 = ( 0.0 );
				float2 Input_UV145_g472 = ParallaxUV51_g469;
				float2 UV2_g472 = Input_UV145_g472;
				float2 UV12_g472 = float2( 0,0 );
				float2 UV22_g472 = float2( 0,0 );
				float2 UV32_g472 = float2( 0,0 );
				float W12_g472 = 0.0;
				float W22_g472 = 0.0;
				float W32_g472 = 0.0;
				StochasticTiling( UV2_g472 , UV12_g472 , UV22_g472 , UV32_g472 , W12_g472 , W22_g472 , W32_g472 );
				float2 temp_output_10_0_g472 = ddx( Input_UV145_g472 );
				float2 temp_output_12_0_g472 = ddy( Input_UV145_g472 );
				float4 Output_2D293_g472 = ( ( SAMPLE_TEXTURE2D_GRAD( _Splat2, sampler_linear_repeat, UV12_g472, temp_output_10_0_g472, temp_output_12_0_g472 ) * W12_g472 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat2, sampler_linear_repeat, UV22_g472, temp_output_10_0_g472, temp_output_12_0_g472 ) * W22_g472 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat2, sampler_linear_repeat, UV32_g472, temp_output_10_0_g472, temp_output_12_0_g472 ) * W32_g472 ) );
				float StochasticAmount43_g469 = _Stochastic2;
				float4 lerpResult26_g469 = lerp( SAMPLE_TEXTURE2D( _Splat2, sampler_linear_repeat, ParallaxUV51_g469 ) , Output_2D293_g472 , StochasticAmount43_g469);
				float localStochasticTiling2_g471 = ( 0.0 );
				float2 Input_UV145_g471 = ParallaxUV51_g469;
				float2 UV2_g471 = Input_UV145_g471;
				float2 UV12_g471 = float2( 0,0 );
				float2 UV22_g471 = float2( 0,0 );
				float2 UV32_g471 = float2( 0,0 );
				float W12_g471 = 0.0;
				float W22_g471 = 0.0;
				float W32_g471 = 0.0;
				StochasticTiling( UV2_g471 , UV12_g471 , UV22_g471 , UV32_g471 , W12_g471 , W22_g471 , W32_g471 );
				float2 temp_output_10_0_g471 = ddx( Input_UV145_g471 );
				float2 temp_output_12_0_g471 = ddy( Input_UV145_g471 );
				float4 Output_2D293_g471 = ( ( SAMPLE_TEXTURE2D_GRAD( _Mask2, sampler_linear_repeat, UV12_g471, temp_output_10_0_g471, temp_output_12_0_g471 ) * W12_g471 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask2, sampler_linear_repeat, UV22_g471, temp_output_10_0_g471, temp_output_12_0_g471 ) * W22_g471 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask2, sampler_linear_repeat, UV32_g471, temp_output_10_0_g471, temp_output_12_0_g471 ) * W32_g471 ) );
				float4 lerpResult28_g469 = lerp( SAMPLE_TEXTURE2D( _Mask2, sampler_linear_repeat, ParallaxUV51_g469 ) , Output_2D293_g471 , StochasticAmount43_g469);
				float4 temp_output_15_0_g473 = lerpResult28_g469;
				float SplatWeight262 = tex2DNode7.b;
				float HeightMask39_g473 = saturate(pow((((temp_output_15_0_g473).z*SplatWeight262)*4)+(SplatWeight262*2),( 1.0 / _HeightBlend2 )));
				float4 lerpResult16_g473 = lerp( lerpResult16_g468 , lerpResult26_g469 , HeightMask39_g473);
				float4 break18_g474 = _Splat3_ST;
				float2 appendResult16_g474 = (float2(break18_g474.x , break18_g474.y));
				float2 appendResult15_g474 = (float2(break18_g474.z , break18_g474.w));
				float2 texCoord17_g474 = IN.ase_texcoord2.xy * appendResult16_g474 + appendResult15_g474;
				float2 UV29_g474 = texCoord17_g474;
				float2 OffsetPOM47_g474 = POM( _Mask3, sampler_linear_repeat, UV29_g474, ddx(UV29_g474), ddy(UV29_g474), ase_worldNormal, ase_worldViewDir, ase_tanViewDir, 8, 8, _Parallax3, 0.5, _Mask3_ST.xy, float2(0,0), 0 );
				float2 ParallaxUV51_g474 = OffsetPOM47_g474;
				float localStochasticTiling2_g477 = ( 0.0 );
				float2 Input_UV145_g477 = ParallaxUV51_g474;
				float2 UV2_g477 = Input_UV145_g477;
				float2 UV12_g477 = float2( 0,0 );
				float2 UV22_g477 = float2( 0,0 );
				float2 UV32_g477 = float2( 0,0 );
				float W12_g477 = 0.0;
				float W22_g477 = 0.0;
				float W32_g477 = 0.0;
				StochasticTiling( UV2_g477 , UV12_g477 , UV22_g477 , UV32_g477 , W12_g477 , W22_g477 , W32_g477 );
				float2 temp_output_10_0_g477 = ddx( Input_UV145_g477 );
				float2 temp_output_12_0_g477 = ddy( Input_UV145_g477 );
				float4 Output_2D293_g477 = ( ( SAMPLE_TEXTURE2D_GRAD( _Splat3, sampler_linear_repeat, UV12_g477, temp_output_10_0_g477, temp_output_12_0_g477 ) * W12_g477 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat3, sampler_linear_repeat, UV22_g477, temp_output_10_0_g477, temp_output_12_0_g477 ) * W22_g477 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat3, sampler_linear_repeat, UV32_g477, temp_output_10_0_g477, temp_output_12_0_g477 ) * W32_g477 ) );
				float StochasticAmount43_g474 = _Stochastic3;
				float4 lerpResult26_g474 = lerp( SAMPLE_TEXTURE2D( _Splat3, sampler_linear_repeat, ParallaxUV51_g474 ) , Output_2D293_g477 , StochasticAmount43_g474);
				float localStochasticTiling2_g476 = ( 0.0 );
				float2 Input_UV145_g476 = ParallaxUV51_g474;
				float2 UV2_g476 = Input_UV145_g476;
				float2 UV12_g476 = float2( 0,0 );
				float2 UV22_g476 = float2( 0,0 );
				float2 UV32_g476 = float2( 0,0 );
				float W12_g476 = 0.0;
				float W22_g476 = 0.0;
				float W32_g476 = 0.0;
				StochasticTiling( UV2_g476 , UV12_g476 , UV22_g476 , UV32_g476 , W12_g476 , W22_g476 , W32_g476 );
				float2 temp_output_10_0_g476 = ddx( Input_UV145_g476 );
				float2 temp_output_12_0_g476 = ddy( Input_UV145_g476 );
				float4 Output_2D293_g476 = ( ( SAMPLE_TEXTURE2D_GRAD( _Mask3, sampler_linear_repeat, UV12_g476, temp_output_10_0_g476, temp_output_12_0_g476 ) * W12_g476 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask3, sampler_linear_repeat, UV22_g476, temp_output_10_0_g476, temp_output_12_0_g476 ) * W22_g476 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask3, sampler_linear_repeat, UV32_g476, temp_output_10_0_g476, temp_output_12_0_g476 ) * W32_g476 ) );
				float4 lerpResult28_g474 = lerp( SAMPLE_TEXTURE2D( _Mask3, sampler_linear_repeat, ParallaxUV51_g474 ) , Output_2D293_g476 , StochasticAmount43_g474);
				float4 temp_output_15_0_g478 = lerpResult28_g474;
				float SplatWeight363 = tex2DNode7.a;
				float HeightMask39_g478 = saturate(pow((((temp_output_15_0_g478).z*SplatWeight363)*4)+(SplatWeight363*2),( 1.0 / _HeightBlend3 )));
				float4 lerpResult16_g478 = lerp( lerpResult16_g473 , lerpResult26_g474 , HeightMask39_g478);
				
				float2 uv_TerrainHolesTexture = IN.ase_texcoord2.xy * _TerrainHolesTexture_ST.xy + _TerrainHolesTexture_ST.zw;
				
				
				float3 Albedo = lerpResult16_g478.xyz;
				float3 Emission = 0;
				float Alpha = SAMPLE_TEXTURE2D( _TerrainHolesTexture, sampler_TerrainHolesTexture, uv_TerrainHolesTexture ).r;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				MetaInput metaInput = (MetaInput)0;
				metaInput.Albedo = Albedo;
				metaInput.Emission = Emission;
				
				return MetaFragment(metaInput);
			}
			ENDHLSL
		}

		UsePass "Hidden/Nature/Terrain/Utilities/PICKING"
	UsePass "Hidden/Nature/Terrain/Utilities/SELECTION"

		Pass
		{
			
			Name "Universal2D"
			Tags { "LightMode"="Universal2D" }

			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			HLSLPROGRAM
			#define _NORMAL_DROPOFF_TS 1
			#pragma multi_compile_instancing
			#pragma multi_compile _ LOD_FADE_CROSSFADE
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_FINAL_COLOR_ALPHA_MULTIPLY 1
			#define _ALPHATEST_ON 1
			#define _NORMALMAP 1
			#define ASE_SRP_VERSION 80301
			#define ASE_USING_SAMPLING_MACROS 1

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS_2D

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_VERT_POSITION
			#pragma multi_compile_instancing
			#pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap forwardadd


			#pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Splat0_ST;
			float4 _Mask3_ST;
			float4 _Splat3_ST;
			float4 _Mask2_ST;
			float4 _Control_ST;
			float4 _Mask1_ST;
			float4 _Splat2_ST;
			float4 _Splat1_ST;
			float4 _Mask0_ST;
			float4 _TerrainHolesTexture_ST;
			float _Stochastic1;
			float _HeightBlend1;
			float _HeightBlend3;
			float _Parallax2;
			float _Stochastic0;
			float _Stochastic2;
			float _HeightBlend2;
			float _Parallax3;
			float _Parallax0;
			float _Stochastic3;
			float _Parallax1;
			#ifdef _TRANSMISSION_ASE
				float _TransmissionShadow;
			#endif
			#ifdef _TRANSLUCENCY_ASE
				float _TransStrength;
				float _TransNormal;
				float _TransScattering;
				float _TransDirect;
				float _TransAmbient;
				float _TransShadow;
			#endif
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			TEXTURE2D(_Splat0);
			TEXTURE2D(_Mask0);
			SAMPLER(sampler_linear_repeat);
			TEXTURE2D(_Splat1);
			TEXTURE2D(_Mask1);
			TEXTURE2D(_Control);
			SAMPLER(sampler_Control);
			TEXTURE2D(_Splat2);
			TEXTURE2D(_Mask2);
			TEXTURE2D(_Splat3);
			TEXTURE2D(_Mask3);
			TEXTURE2D(_TerrainHolesTexture);
			SAMPLER(sampler_TerrainHolesTexture);
			#ifdef UNITY_INSTANCING_ENABLED//ASE Terrain Instancing
				TEXTURE2D(_TerrainHeightmapTexture);//ASE Terrain Instancing
				TEXTURE2D( _TerrainNormalmapTexture);//ASE Terrain Instancing
				SAMPLER(sampler_TerrainNormalmapTexture);//ASE Terrain Instancing
			#endif//ASE Terrain Instancing
			UNITY_INSTANCING_BUFFER_START( Terrain )//ASE Terrain Instancing
				UNITY_DEFINE_INSTANCED_PROP( float4, _TerrainPatchInstanceData )//ASE Terrain Instancing
			UNITY_INSTANCING_BUFFER_END( Terrain)//ASE Terrain Instancing
			CBUFFER_START( UnityTerrain)//ASE Terrain Instancing
				#ifdef UNITY_INSTANCING_ENABLED//ASE Terrain Instancing
					float4 _TerrainHeightmapRecipSize;//ASE Terrain Instancing
					float4 _TerrainHeightmapScale;//ASE Terrain Instancing
				#endif//ASE Terrain Instancing
			CBUFFER_END//ASE Terrain Instancing


			inline float2 POM( TEXTURE2D(heightMap), SAMPLER(samplerheightMap), float2 uvs, float2 dx, float2 dy, float3 normalWorld, float3 viewWorld, float3 viewDirTan, int minSamples, int maxSamples, float parallax, float refPlane, float2 tilling, float2 curv, int index )
			{
				float3 result = 0;
				int stepIndex = 0;
				int numSteps = ( int )lerp( (float)maxSamples, (float)minSamples, saturate( dot( normalWorld, viewWorld ) ) );
				float layerHeight = 1.0 / numSteps;
				float2 plane = parallax * ( viewDirTan.xy / viewDirTan.z );
				uvs.xy += refPlane * plane;
				float2 deltaTex = -plane * layerHeight;
				float2 prevTexOffset = 0;
				float prevRayZ = 1.0f;
				float prevHeight = 0.0f;
				float2 currTexOffset = deltaTex;
				float currRayZ = 1.0f - layerHeight;
				float currHeight = 0.0f;
				float intersection = 0;
				float2 finalTexOffset = 0;
				while ( stepIndex < numSteps + 1 )
				{
				 	currHeight = SAMPLE_TEXTURE2D_GRAD( heightMap, samplerheightMap, uvs + currTexOffset, dx, dy ).b;
				 	if ( currHeight > currRayZ )
				 	{
				 	 	stepIndex = numSteps + 1;
				 	}
				 	else
				 	{
				 	 	stepIndex++;
				 	 	prevTexOffset = currTexOffset;
				 	 	prevRayZ = currRayZ;
				 	 	prevHeight = currHeight;
				 	 	currTexOffset += deltaTex;
				 	 	currRayZ -= layerHeight;
				 	}
				}
				int sectionSteps = 4;
				int sectionIndex = 0;
				float newZ = 0;
				float newHeight = 0;
				while ( sectionIndex < sectionSteps )
				{
				 	intersection = ( prevHeight - prevRayZ ) / ( prevHeight - currHeight + currRayZ - prevRayZ );
				 	finalTexOffset = prevTexOffset + intersection * deltaTex;
				 	newZ = prevRayZ - intersection * layerHeight;
				 	newHeight = SAMPLE_TEXTURE2D_GRAD( heightMap, samplerheightMap, uvs + finalTexOffset, dx, dy ).b;
				 	if ( newHeight > newZ )
				 	{
				 	 	currTexOffset = finalTexOffset;
				 	 	currHeight = newHeight;
				 	 	currRayZ = newZ;
				 	 	deltaTex = intersection * deltaTex;
				 	 	layerHeight = intersection * layerHeight;
				 	}
				 	else
				 	{
				 	 	prevTexOffset = finalTexOffset;
				 	 	prevHeight = newHeight;
				 	 	prevRayZ = newZ;
				 	 	deltaTex = ( 1 - intersection ) * deltaTex;
				 	 	layerHeight = ( 1 - intersection ) * layerHeight;
				 	}
				 	sectionIndex++;
				}
				return uvs.xy + finalTexOffset;
			}
			
			void StochasticTiling( float2 UV, out float2 UV1, out float2 UV2, out float2 UV3, out float W1, out float W2, out float W3 )
			{
				float2 vertex1, vertex2, vertex3;
				// Scaling of the input
				float2 uv = UV * 3.464; // 2 * sqrt (3)
				// Skew input space into simplex triangle grid
				const float2x2 gridToSkewedGrid = float2x2( 1.0, 0.0, -0.57735027, 1.15470054 );
				float2 skewedCoord = mul( gridToSkewedGrid, uv );
				// Compute local triangle vertex IDs and local barycentric coordinates
				int2 baseId = int2( floor( skewedCoord ) );
				float3 temp = float3( frac( skewedCoord ), 0 );
				temp.z = 1.0 - temp.x - temp.y;
				if ( temp.z > 0.0 )
				{
					W1 = temp.z;
					W2 = temp.y;
					W3 = temp.x;
					vertex1 = baseId;
					vertex2 = baseId + int2( 0, 1 );
					vertex3 = baseId + int2( 1, 0 );
				}
				else
				{
					W1 = -temp.z;
					W2 = 1.0 - temp.y;
					W3 = 1.0 - temp.x;
					vertex1 = baseId + int2( 1, 1 );
					vertex2 = baseId + int2( 1, 0 );
					vertex3 = baseId + int2( 0, 1 );
				}
				UV1 = UV + frac( sin( mul( float2x2( 127.1, 311.7, 269.5, 183.3 ), vertex1 ) ) * 43758.5453 );
				UV2 = UV + frac( sin( mul( float2x2( 127.1, 311.7, 269.5, 183.3 ), vertex2 ) ) * 43758.5453 );
				UV3 = UV + frac( sin( mul( float2x2( 127.1, 311.7, 269.5, 183.3 ), vertex3 ) ) * 43758.5453 );
				return;
			}
			
			VertexInput ApplyMeshModification( VertexInput v )
			{
			#ifdef UNITY_INSTANCING_ENABLED
				float2 patchVertex = v.vertex.xy;
				float4 instanceData = UNITY_ACCESS_INSTANCED_PROP( Terrain, _TerrainPatchInstanceData );
				float2 sampleCoords = ( patchVertex.xy + instanceData.xy ) * instanceData.z;
				float height = UnpackHeightmap( _TerrainHeightmapTexture.Load( int3( sampleCoords, 0 ) ) );
				v.vertex.xz = sampleCoords* _TerrainHeightmapScale.xz;
				v.vertex.y = height* _TerrainHeightmapScale.y;
				#ifdef ENABLE_TERRAIN_PERPIXEL_NORMAL
					v.ase_normal = float3(0, 1, 0);
				#else
					v.ase_normal = _TerrainNormalmapTexture.Load(int3(sampleCoords, 0)).rgb* 2 - 1;
				#endif
				v.ase_texcoord.xy = sampleCoords* _TerrainHeightmapRecipSize.zw;
			#endif
				return v;
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				v = ApplyMeshModification(v);
				float3 localCalculateTangentsSRP26 = ( ( v.ase_tangent.xyz * v.ase_normal * 0.0 ) );
				{
				v.ase_tangent.xyz = cross ( v.ase_normal, float3( 0, 0, 1 ) );
				v.ase_tangent.w = -1;
				}
				
				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord3.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord4.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * unity_WorldTransformParams.w;
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord5.xyz = ase_worldBitangent;
				
				o.ase_texcoord2.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.zw = 0;
				o.ase_texcoord3.w = 0;
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.w = 0;
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = localCalculateTangentsSRP26;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_tangent = v.ase_tangent;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float4 break18_g460 = _Splat0_ST;
				float2 appendResult16_g460 = (float2(break18_g460.x , break18_g460.y));
				float2 appendResult15_g460 = (float2(break18_g460.z , break18_g460.w));
				float2 texCoord17_g460 = IN.ase_texcoord2.xy * appendResult16_g460 + appendResult15_g460;
				float2 UV29_g460 = texCoord17_g460;
				float3 ase_worldTangent = IN.ase_texcoord3.xyz;
				float3 ase_worldNormal = IN.ase_texcoord4.xyz;
				float3 ase_worldBitangent = IN.ase_texcoord5.xyz;
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float3 ase_tanViewDir =  tanToWorld0 * ase_worldViewDir.x + tanToWorld1 * ase_worldViewDir.y  + tanToWorld2 * ase_worldViewDir.z;
				ase_tanViewDir = normalize(ase_tanViewDir);
				float2 OffsetPOM47_g460 = POM( _Mask0, sampler_linear_repeat, UV29_g460, ddx(UV29_g460), ddy(UV29_g460), ase_worldNormal, ase_worldViewDir, ase_tanViewDir, 8, 8, _Parallax0, 0.5, _Mask0_ST.xy, float2(0,0), 0 );
				float2 ParallaxUV51_g460 = OffsetPOM47_g460;
				float localStochasticTiling2_g463 = ( 0.0 );
				float2 Input_UV145_g463 = ParallaxUV51_g460;
				float2 UV2_g463 = Input_UV145_g463;
				float2 UV12_g463 = float2( 0,0 );
				float2 UV22_g463 = float2( 0,0 );
				float2 UV32_g463 = float2( 0,0 );
				float W12_g463 = 0.0;
				float W22_g463 = 0.0;
				float W32_g463 = 0.0;
				StochasticTiling( UV2_g463 , UV12_g463 , UV22_g463 , UV32_g463 , W12_g463 , W22_g463 , W32_g463 );
				float2 temp_output_10_0_g463 = ddx( Input_UV145_g463 );
				float2 temp_output_12_0_g463 = ddy( Input_UV145_g463 );
				float4 Output_2D293_g463 = ( ( SAMPLE_TEXTURE2D_GRAD( _Splat0, sampler_linear_repeat, UV12_g463, temp_output_10_0_g463, temp_output_12_0_g463 ) * W12_g463 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat0, sampler_linear_repeat, UV22_g463, temp_output_10_0_g463, temp_output_12_0_g463 ) * W22_g463 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat0, sampler_linear_repeat, UV32_g463, temp_output_10_0_g463, temp_output_12_0_g463 ) * W32_g463 ) );
				float StochasticAmount43_g460 = _Stochastic0;
				float4 lerpResult26_g460 = lerp( SAMPLE_TEXTURE2D( _Splat0, sampler_linear_repeat, ParallaxUV51_g460 ) , Output_2D293_g463 , StochasticAmount43_g460);
				float4 break18_g464 = _Splat1_ST;
				float2 appendResult16_g464 = (float2(break18_g464.x , break18_g464.y));
				float2 appendResult15_g464 = (float2(break18_g464.z , break18_g464.w));
				float2 texCoord17_g464 = IN.ase_texcoord2.xy * appendResult16_g464 + appendResult15_g464;
				float2 UV29_g464 = texCoord17_g464;
				float2 OffsetPOM47_g464 = POM( _Mask1, sampler_linear_repeat, UV29_g464, ddx(UV29_g464), ddy(UV29_g464), ase_worldNormal, ase_worldViewDir, ase_tanViewDir, 8, 8, _Parallax1, 0.5, _Mask1_ST.xy, float2(0,0), 0 );
				float2 ParallaxUV51_g464 = OffsetPOM47_g464;
				float localStochasticTiling2_g467 = ( 0.0 );
				float2 Input_UV145_g467 = ParallaxUV51_g464;
				float2 UV2_g467 = Input_UV145_g467;
				float2 UV12_g467 = float2( 0,0 );
				float2 UV22_g467 = float2( 0,0 );
				float2 UV32_g467 = float2( 0,0 );
				float W12_g467 = 0.0;
				float W22_g467 = 0.0;
				float W32_g467 = 0.0;
				StochasticTiling( UV2_g467 , UV12_g467 , UV22_g467 , UV32_g467 , W12_g467 , W22_g467 , W32_g467 );
				float2 temp_output_10_0_g467 = ddx( Input_UV145_g467 );
				float2 temp_output_12_0_g467 = ddy( Input_UV145_g467 );
				float4 Output_2D293_g467 = ( ( SAMPLE_TEXTURE2D_GRAD( _Splat1, sampler_linear_repeat, UV12_g467, temp_output_10_0_g467, temp_output_12_0_g467 ) * W12_g467 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat1, sampler_linear_repeat, UV22_g467, temp_output_10_0_g467, temp_output_12_0_g467 ) * W22_g467 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat1, sampler_linear_repeat, UV32_g467, temp_output_10_0_g467, temp_output_12_0_g467 ) * W32_g467 ) );
				float StochasticAmount43_g464 = _Stochastic1;
				float4 lerpResult26_g464 = lerp( SAMPLE_TEXTURE2D( _Splat1, sampler_linear_repeat, ParallaxUV51_g464 ) , Output_2D293_g467 , StochasticAmount43_g464);
				float localStochasticTiling2_g466 = ( 0.0 );
				float2 Input_UV145_g466 = ParallaxUV51_g464;
				float2 UV2_g466 = Input_UV145_g466;
				float2 UV12_g466 = float2( 0,0 );
				float2 UV22_g466 = float2( 0,0 );
				float2 UV32_g466 = float2( 0,0 );
				float W12_g466 = 0.0;
				float W22_g466 = 0.0;
				float W32_g466 = 0.0;
				StochasticTiling( UV2_g466 , UV12_g466 , UV22_g466 , UV32_g466 , W12_g466 , W22_g466 , W32_g466 );
				float2 temp_output_10_0_g466 = ddx( Input_UV145_g466 );
				float2 temp_output_12_0_g466 = ddy( Input_UV145_g466 );
				float4 Output_2D293_g466 = ( ( SAMPLE_TEXTURE2D_GRAD( _Mask1, sampler_linear_repeat, UV12_g466, temp_output_10_0_g466, temp_output_12_0_g466 ) * W12_g466 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask1, sampler_linear_repeat, UV22_g466, temp_output_10_0_g466, temp_output_12_0_g466 ) * W22_g466 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask1, sampler_linear_repeat, UV32_g466, temp_output_10_0_g466, temp_output_12_0_g466 ) * W32_g466 ) );
				float4 lerpResult28_g464 = lerp( SAMPLE_TEXTURE2D( _Mask1, sampler_linear_repeat, ParallaxUV51_g464 ) , Output_2D293_g466 , StochasticAmount43_g464);
				float4 temp_output_15_0_g468 = lerpResult28_g464;
				float2 uv_Control = IN.ase_texcoord2.xy * _Control_ST.xy + _Control_ST.zw;
				float4 tex2DNode7 = SAMPLE_TEXTURE2D( _Control, sampler_Control, uv_Control );
				float SplatWeight161 = tex2DNode7.g;
				float HeightMask39_g468 = saturate(pow((((temp_output_15_0_g468).z*SplatWeight161)*4)+(SplatWeight161*2),( 1.0 / _HeightBlend1 )));
				float4 lerpResult16_g468 = lerp( lerpResult26_g460 , lerpResult26_g464 , HeightMask39_g468);
				float4 break18_g469 = _Splat2_ST;
				float2 appendResult16_g469 = (float2(break18_g469.x , break18_g469.y));
				float2 appendResult15_g469 = (float2(break18_g469.z , break18_g469.w));
				float2 texCoord17_g469 = IN.ase_texcoord2.xy * appendResult16_g469 + appendResult15_g469;
				float2 UV29_g469 = texCoord17_g469;
				float2 OffsetPOM47_g469 = POM( _Mask2, sampler_linear_repeat, UV29_g469, ddx(UV29_g469), ddy(UV29_g469), ase_worldNormal, ase_worldViewDir, ase_tanViewDir, 8, 8, _Parallax2, 0.5, _Mask2_ST.xy, float2(0,0), 0 );
				float2 ParallaxUV51_g469 = OffsetPOM47_g469;
				float localStochasticTiling2_g472 = ( 0.0 );
				float2 Input_UV145_g472 = ParallaxUV51_g469;
				float2 UV2_g472 = Input_UV145_g472;
				float2 UV12_g472 = float2( 0,0 );
				float2 UV22_g472 = float2( 0,0 );
				float2 UV32_g472 = float2( 0,0 );
				float W12_g472 = 0.0;
				float W22_g472 = 0.0;
				float W32_g472 = 0.0;
				StochasticTiling( UV2_g472 , UV12_g472 , UV22_g472 , UV32_g472 , W12_g472 , W22_g472 , W32_g472 );
				float2 temp_output_10_0_g472 = ddx( Input_UV145_g472 );
				float2 temp_output_12_0_g472 = ddy( Input_UV145_g472 );
				float4 Output_2D293_g472 = ( ( SAMPLE_TEXTURE2D_GRAD( _Splat2, sampler_linear_repeat, UV12_g472, temp_output_10_0_g472, temp_output_12_0_g472 ) * W12_g472 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat2, sampler_linear_repeat, UV22_g472, temp_output_10_0_g472, temp_output_12_0_g472 ) * W22_g472 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat2, sampler_linear_repeat, UV32_g472, temp_output_10_0_g472, temp_output_12_0_g472 ) * W32_g472 ) );
				float StochasticAmount43_g469 = _Stochastic2;
				float4 lerpResult26_g469 = lerp( SAMPLE_TEXTURE2D( _Splat2, sampler_linear_repeat, ParallaxUV51_g469 ) , Output_2D293_g472 , StochasticAmount43_g469);
				float localStochasticTiling2_g471 = ( 0.0 );
				float2 Input_UV145_g471 = ParallaxUV51_g469;
				float2 UV2_g471 = Input_UV145_g471;
				float2 UV12_g471 = float2( 0,0 );
				float2 UV22_g471 = float2( 0,0 );
				float2 UV32_g471 = float2( 0,0 );
				float W12_g471 = 0.0;
				float W22_g471 = 0.0;
				float W32_g471 = 0.0;
				StochasticTiling( UV2_g471 , UV12_g471 , UV22_g471 , UV32_g471 , W12_g471 , W22_g471 , W32_g471 );
				float2 temp_output_10_0_g471 = ddx( Input_UV145_g471 );
				float2 temp_output_12_0_g471 = ddy( Input_UV145_g471 );
				float4 Output_2D293_g471 = ( ( SAMPLE_TEXTURE2D_GRAD( _Mask2, sampler_linear_repeat, UV12_g471, temp_output_10_0_g471, temp_output_12_0_g471 ) * W12_g471 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask2, sampler_linear_repeat, UV22_g471, temp_output_10_0_g471, temp_output_12_0_g471 ) * W22_g471 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask2, sampler_linear_repeat, UV32_g471, temp_output_10_0_g471, temp_output_12_0_g471 ) * W32_g471 ) );
				float4 lerpResult28_g469 = lerp( SAMPLE_TEXTURE2D( _Mask2, sampler_linear_repeat, ParallaxUV51_g469 ) , Output_2D293_g471 , StochasticAmount43_g469);
				float4 temp_output_15_0_g473 = lerpResult28_g469;
				float SplatWeight262 = tex2DNode7.b;
				float HeightMask39_g473 = saturate(pow((((temp_output_15_0_g473).z*SplatWeight262)*4)+(SplatWeight262*2),( 1.0 / _HeightBlend2 )));
				float4 lerpResult16_g473 = lerp( lerpResult16_g468 , lerpResult26_g469 , HeightMask39_g473);
				float4 break18_g474 = _Splat3_ST;
				float2 appendResult16_g474 = (float2(break18_g474.x , break18_g474.y));
				float2 appendResult15_g474 = (float2(break18_g474.z , break18_g474.w));
				float2 texCoord17_g474 = IN.ase_texcoord2.xy * appendResult16_g474 + appendResult15_g474;
				float2 UV29_g474 = texCoord17_g474;
				float2 OffsetPOM47_g474 = POM( _Mask3, sampler_linear_repeat, UV29_g474, ddx(UV29_g474), ddy(UV29_g474), ase_worldNormal, ase_worldViewDir, ase_tanViewDir, 8, 8, _Parallax3, 0.5, _Mask3_ST.xy, float2(0,0), 0 );
				float2 ParallaxUV51_g474 = OffsetPOM47_g474;
				float localStochasticTiling2_g477 = ( 0.0 );
				float2 Input_UV145_g477 = ParallaxUV51_g474;
				float2 UV2_g477 = Input_UV145_g477;
				float2 UV12_g477 = float2( 0,0 );
				float2 UV22_g477 = float2( 0,0 );
				float2 UV32_g477 = float2( 0,0 );
				float W12_g477 = 0.0;
				float W22_g477 = 0.0;
				float W32_g477 = 0.0;
				StochasticTiling( UV2_g477 , UV12_g477 , UV22_g477 , UV32_g477 , W12_g477 , W22_g477 , W32_g477 );
				float2 temp_output_10_0_g477 = ddx( Input_UV145_g477 );
				float2 temp_output_12_0_g477 = ddy( Input_UV145_g477 );
				float4 Output_2D293_g477 = ( ( SAMPLE_TEXTURE2D_GRAD( _Splat3, sampler_linear_repeat, UV12_g477, temp_output_10_0_g477, temp_output_12_0_g477 ) * W12_g477 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat3, sampler_linear_repeat, UV22_g477, temp_output_10_0_g477, temp_output_12_0_g477 ) * W22_g477 ) + ( SAMPLE_TEXTURE2D_GRAD( _Splat3, sampler_linear_repeat, UV32_g477, temp_output_10_0_g477, temp_output_12_0_g477 ) * W32_g477 ) );
				float StochasticAmount43_g474 = _Stochastic3;
				float4 lerpResult26_g474 = lerp( SAMPLE_TEXTURE2D( _Splat3, sampler_linear_repeat, ParallaxUV51_g474 ) , Output_2D293_g477 , StochasticAmount43_g474);
				float localStochasticTiling2_g476 = ( 0.0 );
				float2 Input_UV145_g476 = ParallaxUV51_g474;
				float2 UV2_g476 = Input_UV145_g476;
				float2 UV12_g476 = float2( 0,0 );
				float2 UV22_g476 = float2( 0,0 );
				float2 UV32_g476 = float2( 0,0 );
				float W12_g476 = 0.0;
				float W22_g476 = 0.0;
				float W32_g476 = 0.0;
				StochasticTiling( UV2_g476 , UV12_g476 , UV22_g476 , UV32_g476 , W12_g476 , W22_g476 , W32_g476 );
				float2 temp_output_10_0_g476 = ddx( Input_UV145_g476 );
				float2 temp_output_12_0_g476 = ddy( Input_UV145_g476 );
				float4 Output_2D293_g476 = ( ( SAMPLE_TEXTURE2D_GRAD( _Mask3, sampler_linear_repeat, UV12_g476, temp_output_10_0_g476, temp_output_12_0_g476 ) * W12_g476 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask3, sampler_linear_repeat, UV22_g476, temp_output_10_0_g476, temp_output_12_0_g476 ) * W22_g476 ) + ( SAMPLE_TEXTURE2D_GRAD( _Mask3, sampler_linear_repeat, UV32_g476, temp_output_10_0_g476, temp_output_12_0_g476 ) * W32_g476 ) );
				float4 lerpResult28_g474 = lerp( SAMPLE_TEXTURE2D( _Mask3, sampler_linear_repeat, ParallaxUV51_g474 ) , Output_2D293_g476 , StochasticAmount43_g474);
				float4 temp_output_15_0_g478 = lerpResult28_g474;
				float SplatWeight363 = tex2DNode7.a;
				float HeightMask39_g478 = saturate(pow((((temp_output_15_0_g478).z*SplatWeight363)*4)+(SplatWeight363*2),( 1.0 / _HeightBlend3 )));
				float4 lerpResult16_g478 = lerp( lerpResult16_g473 , lerpResult26_g474 , HeightMask39_g478);
				
				float2 uv_TerrainHolesTexture = IN.ase_texcoord2.xy * _TerrainHolesTexture_ST.xy + _TerrainHolesTexture_ST.zw;
				
				
				float3 Albedo = lerpResult16_g478.xyz;
				float Alpha = SAMPLE_TEXTURE2D( _TerrainHolesTexture, sampler_TerrainHolesTexture, uv_TerrainHolesTexture ).r;
				float AlphaClipThreshold = 0.5;

				half4 color = half4( Albedo, Alpha );

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				return color;
			}
			ENDHLSL
		}
		
	}
	/*ase_lod*/
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=18909
0;73.6;2048;1009;2112.781;-2739.186;1;True;False
Node;AmplifyShaderEditor.SamplerNode;7;-279.3584,2608.543;Inherit;True;Property;_Control;Control;0;1;[HideInInspector];Create;False;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexturePropertyNode;47;-1735.506,2194.034;Inherit;True;Property;_Normal1;Normal1;10;2;[HideInInspector];[Normal];Create;True;0;0;0;False;0;False;None;None;False;bump;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RangedFloatNode;228;-1277.797,2338.947;Inherit;False;Property;_Stochastic1;Stochastic1;22;1;[Toggle];Create;True;0;0;0;True;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;45;-1504.78,1821.061;Inherit;True;Property;_Mask0;Mask0;13;1;[HideInInspector];Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.Vector4Node;11;-2115.295,1586.145;Inherit;False;Property;_Splat0_ST;Splat0_ST;1;1;[HideInInspector];Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;269;-1278.502,2424.172;Inherit;False;Property;_Parallax1;Parallax1;26;0;Create;True;0;0;0;False;0;False;0;0.01;0;0.1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;227;-1270.275,1893.639;Inherit;False;Property;_Stochastic0;Stochastic0;21;1;[Toggle];Create;True;0;0;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;264;-1271.67,1970.62;Inherit;False;Property;_Parallax0;Parallax0;25;0;Create;True;0;0;0;False;0;False;0;0;0;0.1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;43;-1950.713,1663;Inherit;True;Property;_Splat0;Splat0;5;1;[HideInInspector];Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;44;-1725.089,1741.223;Inherit;True;Property;_Normal0;Normal0;9;2;[HideInInspector];[Normal];Create;True;0;0;0;False;0;False;None;None;False;bump;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RegisterLocalVarNode;61;67.28233,2664.679;Inherit;False;SplatWeight1;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;49;-1512.652,2265.046;Inherit;True;Property;_Mask1;Mask1;14;1;[HideInInspector];Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;48;-1958.659,2115.082;Inherit;True;Property;_Splat1;Splat1;6;1;[HideInInspector];Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.Vector4Node;50;-2129.169,2050.456;Inherit;False;Property;_Splat1_ST;Splat1_ST;3;1;[HideInInspector];Create;True;0;0;0;False;0;False;0,0,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;62;68.28233,2737.679;Inherit;False;SplatWeight2;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;75;-1944.645,2560.521;Inherit;True;Property;_Splat2;Splat2;8;1;[HideInInspector];Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.FunctionNode;292;-1005.224,2052.973;Inherit;False;SampleSplat;-1;;464;e2e9abda534a6d846b3f4cae57f47947;0;6;11;FLOAT4;0,0,0,0;False;8;SAMPLER2D;0,0,0,0;False;9;SAMPLER2D;0,0,0,0;False;10;SAMPLER2D;0,0,0,0;False;25;FLOAT;0;False;55;FLOAT;0;False;3;COLOR;0;FLOAT3;1;COLOR;2
Node;AmplifyShaderEditor.RangedFloatNode;171;-986.3636,2327.879;Inherit;False;Property;_HeightBlend1;HeightBlend1;18;0;Create;True;0;0;0;True;0;False;1;0.5;0.01;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;270;-1269.502,2873.172;Inherit;False;Property;_Parallax2;Parallax2;27;0;Create;True;0;0;0;False;0;False;0;0.02;0;0.1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;88;-907.9341,2233.051;Inherit;False;61;SplatWeight1;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;76;-2115.154,2495.893;Inherit;False;Property;_Splat2_ST;Splat2_ST;2;1;[HideInInspector];Create;True;0;0;0;False;0;False;0,0,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;229;-1268.631,2783.911;Inherit;False;Property;_Stochastic2;Stochastic2;23;1;[Toggle];Create;True;0;0;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;293;-1007.591,1591.898;Inherit;False;SampleSplat;-1;;460;e2e9abda534a6d846b3f4cae57f47947;0;6;11;FLOAT4;0,0,0,0;False;8;SAMPLER2D;0,0,0,0;False;9;SAMPLER2D;0,0,0,0;False;10;SAMPLER2D;0,0,0,0;False;25;FLOAT;0;False;55;FLOAT;0;False;3;COLOR;0;FLOAT3;1;COLOR;2
Node;AmplifyShaderEditor.TexturePropertyNode;74;-1721.49,2639.474;Inherit;True;Property;_Normal2;Normal2;11;2;[HideInInspector];[Normal];Create;True;0;0;0;False;0;False;None;None;False;bump;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;73;-1498.636,2710.486;Inherit;True;Property;_Mask2;Mask2;15;1;[HideInInspector];Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RangedFloatNode;21;-690.8824,3841.399;Float;False;Constant;_Float5;Float 5;17;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;80;-1938.098,3109.671;Inherit;True;Property;_Splat3;Splat3;7;1;[HideInInspector];Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;79;-1714.945,3191.682;Inherit;True;Property;_Normal3;Normal3;12;2;[HideInInspector];[Normal];Create;True;0;0;0;False;0;False;None;None;False;bump;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RegisterLocalVarNode;63;67.28233,2809.679;Inherit;False;SplatWeight3;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;172;-973.6595,2763.934;Inherit;False;Property;_HeightBlend2;HeightBlend2;19;0;Create;True;0;0;0;True;0;False;1;0.2;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;294;-991.2082,2498.41;Inherit;False;SampleSplat;-1;;469;e2e9abda534a6d846b3f4cae57f47947;0;6;11;FLOAT4;0,0,0,0;False;8;SAMPLER2D;0,0,0,0;False;9;SAMPLER2D;0,0,0,0;False;10;SAMPLER2D;0,0,0,0;False;25;FLOAT;0;False;55;FLOAT;0;False;3;COLOR;0;FLOAT3;1;COLOR;2
Node;AmplifyShaderEditor.NormalVertexDataNode;25;-730.1924,3693.99;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;271;-1247.502,3418.172;Inherit;False;Property;_Parallax3;Parallax3;28;0;Create;True;0;0;0;False;0;False;0;0.05;0;0.1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;78;-1492.091,3262.692;Inherit;True;Property;_Mask3;Mask3;16;1;[HideInInspector];Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TangentVertexDataNode;23;-738.1314,3553.704;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector4Node;81;-2108.606,3046.574;Inherit;False;Property;_Splat3_ST;Splat3_ST;4;1;[HideInInspector];Create;True;0;0;0;False;0;False;0,0,0,0;1,1,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;256;-633.0502,2002.122;Inherit;False;LerpSplat;-1;;468;231ff8f02fffc3849907f9c49dc8ecc8;0;8;3;FLOAT4;0,0,0,0;False;10;FLOAT3;0,0,0;False;11;FLOAT4;0,0,0,0;False;13;FLOAT4;0,0,0,0;False;14;FLOAT3;0,0,0;False;15;FLOAT4;0,0,0,0;False;9;FLOAT;0;False;40;FLOAT;0;False;3;FLOAT4;0;FLOAT3;1;FLOAT4;2
Node;AmplifyShaderEditor.GetLocalVarNode;91;-896.6619,2673.422;Inherit;False;62;SplatWeight2;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;230;-1247.073,3326.922;Inherit;False;Property;_Stochastic3;Stochastic3;24;1;[Toggle];Create;True;0;0;0;True;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;231;-890.6452,3232.585;Inherit;False;63;SplatWeight3;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;24;-511.6362,3634.575;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;257;-621.9538,2451.177;Inherit;False;LerpSplat;-1;;473;231ff8f02fffc3849907f9c49dc8ecc8;0;8;3;FLOAT4;0,0,0,0;False;10;FLOAT3;0,0,0;False;11;FLOAT4;0,0,0,0;False;13;FLOAT4;0,0,0,0;False;14;FLOAT3;0,0,0;False;15;FLOAT4;0,0,0,0;False;9;FLOAT;0;False;40;FLOAT;0;False;3;FLOAT4;0;FLOAT3;1;FLOAT4;2
Node;AmplifyShaderEditor.RangedFloatNode;215;-967.3254,3323.548;Inherit;False;Property;_HeightBlend3;HeightBlend3;20;0;Create;True;0;0;0;True;0;False;0.5;0.5;0.01;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;295;-984.6617,3049.091;Inherit;False;SampleSplat;-1;;474;e2e9abda534a6d846b3f4cae57f47947;0;6;11;FLOAT4;0,0,0,0;False;8;SAMPLER2D;0,0,0,0;False;9;SAMPLER2D;0,0,0,0;False;10;SAMPLER2D;0,0,0,0;False;25;FLOAT;0;False;55;FLOAT;0;False;3;COLOR;0;FLOAT3;1;COLOR;2
Node;AmplifyShaderEditor.FunctionNode;258;-618.9734,3002.862;Inherit;False;LerpSplat;-1;;478;231ff8f02fffc3849907f9c49dc8ecc8;0;8;3;FLOAT4;0,0,0,0;False;10;FLOAT3;0,0,0;False;11;FLOAT4;0,0,0,0;False;13;FLOAT4;0,0,0,0;False;14;FLOAT3;0,0,0;False;15;FLOAT4;0,0,0,0;False;9;FLOAT;0;False;40;FLOAT;0;False;3;FLOAT4;0;FLOAT3;1;FLOAT4;2
Node;AmplifyShaderEditor.RegisterLocalVarNode;54;67.28233,2590.678;Inherit;False;SplatWeight0;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;142;-299.6787,3521.836;Inherit;False;Constant;_Float0;Float 0;18;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;150;-450.5046,3295.799;Inherit;True;Property;_TerrainHolesTexture;TerrainHolesTexture;17;1;[HideInInspector];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CustomExpressionNode;26;-334.5067,3632.458;Float;False;v.ase_tangent.xyz = cross ( v.ase_normal, float3( 0, 0, 1 ) )@$v.ase_tangent.w = -1@;1;Call;0;CalculateTangentsSRP;True;False;0;;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;106;-288.0164,3124.092;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;13.53281,3003.57;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;HeightBlendParallaxTerrain;94348b07e5e8bab40bd6c8a1e3df54cd;True;Forward;0;1;Forward;18;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;2;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;0;Hidden/InternalErrorShader;0;0;Standard;38;Workflow;1;Surface;0;  Refraction Model;0;  Blend;0;Two Sided;1;Fragment Normal Space,InvertActionOnDeselection;0;Transmission;0;  Transmission Shadow;0.5,False,-1;Translucency;0;  Translucency Strength;1,False,-1;  Normal Distortion;0.5,False,-1;  Scattering;2,False,-1;  Direct;0.9,False,-1;  Ambient;0.1,False,-1;  Shadow;0.5,False,-1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;1;Built-in Fog;1;_FinalColorxAlpha;1;Meta Pass;1;Override Baked GI;0;Extra Pre Pass;0;DOTS Instancing;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;2,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Write Depth;0;  Early Z;0;Vertex Position,InvertActionOnDeselection;1;0;6;False;True;True;True;True;True;True;;True;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;0;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;6;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=Universal2D;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;5;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;2;New Amplify Shader;94348b07e5e8bab40bd6c8a1e3df54cd;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;61;0;7;2
WireConnection;62;0;7;3
WireConnection;292;11;50;0
WireConnection;292;8;48;0
WireConnection;292;9;47;0
WireConnection;292;10;49;0
WireConnection;292;25;228;0
WireConnection;292;55;269;0
WireConnection;293;11;11;0
WireConnection;293;8;43;0
WireConnection;293;9;44;0
WireConnection;293;10;45;0
WireConnection;293;25;227;0
WireConnection;293;55;264;0
WireConnection;63;0;7;4
WireConnection;294;11;76;0
WireConnection;294;8;75;0
WireConnection;294;9;74;0
WireConnection;294;10;73;0
WireConnection;294;25;229;0
WireConnection;294;55;270;0
WireConnection;256;3;293;0
WireConnection;256;10;293;1
WireConnection;256;11;293;2
WireConnection;256;13;292;0
WireConnection;256;14;292;1
WireConnection;256;15;292;2
WireConnection;256;9;88;0
WireConnection;256;40;171;0
WireConnection;24;0;23;0
WireConnection;24;1;25;0
WireConnection;24;2;21;0
WireConnection;257;3;256;0
WireConnection;257;10;256;1
WireConnection;257;11;256;2
WireConnection;257;13;294;0
WireConnection;257;14;294;1
WireConnection;257;15;294;2
WireConnection;257;9;91;0
WireConnection;257;40;172;0
WireConnection;295;11;81;0
WireConnection;295;8;80;0
WireConnection;295;9;79;0
WireConnection;295;10;78;0
WireConnection;295;25;230;0
WireConnection;295;55;271;0
WireConnection;258;3;257;0
WireConnection;258;10;257;1
WireConnection;258;11;257;2
WireConnection;258;13;295;0
WireConnection;258;14;295;1
WireConnection;258;15;295;2
WireConnection;258;9;231;0
WireConnection;258;40;215;0
WireConnection;54;0;7;1
WireConnection;26;0;24;0
WireConnection;106;0;258;2
WireConnection;2;0;258;0
WireConnection;2;1;258;1
WireConnection;2;3;106;0
WireConnection;2;4;106;3
WireConnection;2;5;106;1
WireConnection;2;6;150;1
WireConnection;2;7;142;0
WireConnection;2;8;26;0
ASEEND*/
//CHKSM=1931F4B2D507F225F46571358712ABA0BD63439B