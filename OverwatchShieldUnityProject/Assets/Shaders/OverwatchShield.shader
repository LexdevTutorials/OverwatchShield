Shader "Lexdev/CaseStudies/OverwatchShield"
{
	Properties
	{
		//General properties
		_Color("Color", COLOR) = (0,0,0,0)
		_MainTex("Hex Texture", 2D) = "white" {}
		
		//Hex pulse properties
		_PulseIntensity("Hex Pulse Intensity", float) = 3.0
		_PulseTimeScale("Hex Pulse Time Scale", float) = 2.0
		_PulsePosScale("Hex Pulse Position Scale", float) = 50.0
		_PulseTexOffsetScale("Hex Pulse Texture Offset Scale", float) = 1.5

		//Hex edge pulse properties
		_HexEdgeIntensity("Hex Edge Intensity", float) = 2.0
		_HexEdgeColor("Hex Edge Color", COLOR) = (0,0,0,0)
		_HexEdgeTimeScale("Hex Edge Time Scale", float) = 2.0
		_HexEdgeWidthModifier("Hex Edge Width Modifier", Range(0,1)) = 0.8
		_HexEdgePosScale("Hex Edge Position Scale", float) = 80.0

		//Outer edge properties
		_EdgeIntensity("Edge Intensity", float) = 10.0
		_EdgeExponent("Edge Falloff Exponent", float) = 6.0

		//Intersection properties - if the values are close to the outer edge ones the two effects will blend properly
		_IntersectIntensity("Intersection Intensity", float) = 10.0
		_IntersectExponent("Intersection Falloff Exponent", float) = 6.0
	}
	SubShader
	{
		Tags {"RenderType" = "Transparent" "Queue" = "Transparent"} //Make sure the object is rendered after the opaque objects
		Cull Off //Disable backface culling
		Blend SrcAlpha One //Somewhat additive blend mode, you should choose whatever mode you think looks best

		Pass
		{
			HLSLPROGRAM

			#pragma vertex vert //Our vertex function is called vert ...
			#pragma fragment frag //... our fragment function frag
			
			#include "UnityCG.cginc" //Provides lots of helper functions

			//Input values we need from the vertices of the mesh
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			//Data we have to pass from the vertex to the fragment function 
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 vertexObjPos : TEXCOORD1; //Needed for pulse animations
				float4 screenPos : TEXCOORD2; //Needed for sampling the depth texture
				float depth : TEXCOORD3; 
			};

			//General variables
			float4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;

			//Hex pulse variables
			float _PulseIntensity;
			float _PulseTimeScale;
			float _PulsePosScale;
			float _PulseTexOffsetScale;

			//Hex edge pulse variables
			float _HexEdgeIntensity;
			float4 _HexEdgeColor;
			float _HexEdgeTimeScale;
			float _HexEdgeWidthModifier;
			float _HexEdgePosScale;

			//Outer edge variables
			float _EdgeIntensity;
			float _EdgeExponent;

			//Intersection variables
			sampler2D _CameraDepthNormalsTexture; //Automatically filled by Unity
			float _IntersectIntensity;
			float _IntersectExponent;

			//Vertex function
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.vertexObjPos = v.vertex;
				o.screenPos = ComputeScreenPos(o.vertex);
				o.depth = -mul(UNITY_MATRIX_MV, v.vertex).z * _ProjectionParams.w; //ProjectionParams.w is the far plane distance
				return o;
			}
			
			//Fragment function
			fixed4 frag (v2f i) : SV_Target
			{
				//Store the distance of the vertex to the object center
				float horizontalDist = abs(i.vertexObjPos.x);
				float verticalDist = abs(i.vertexObjPos.z);

				//Sample the combined texture
				fixed4 tex = tex2D(_MainTex, i.uv);

				//Hex pulse logic
				fixed4 pulseTex = tex.g;
				fixed4 pulseTerm = pulseTex * _Color * _PulseIntensity *
					abs(sin(_Time.y * _PulseTimeScale - horizontalDist * _PulsePosScale + pulseTex.r * _PulseTexOffsetScale));
				
				//Hex edge pulse logic
				fixed4 hexEdgeTex = tex.r;
				fixed4 hexEdgeTerm = hexEdgeTex * _HexEdgeColor * _HexEdgeIntensity *
					max(sin((horizontalDist + verticalDist) * _HexEdgePosScale - _Time.y * _HexEdgeTimeScale) - _HexEdgeWidthModifier, 0.0f) *
					(1 / (1 - _HexEdgeWidthModifier));

				//Outer edge logic
				fixed4 edgeTex = tex.b;
				fixed4 edgeTerm = pow(edgeTex.a, _EdgeExponent) * _Color * _EdgeIntensity;

				//Intersection logic
				float diff = DecodeFloatRG(tex2D(_CameraDepthNormalsTexture, i.screenPos.xy / i.screenPos.w).zw) - i.depth;
				float intersectGradient = 1 - min(diff / _ProjectionParams.w, 1.0f);
				fixed4 intersectTerm = _Color * pow(intersectGradient, _IntersectExponent) * _IntersectIntensity;

				//Final colour
				return fixed4(_Color.rgb + pulseTerm.rgb + hexEdgeTerm.rgb + edgeTerm + intersectTerm, _Color.a);
			}

			ENDHLSL
		}
	}
}