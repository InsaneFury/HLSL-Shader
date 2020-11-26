Shader "Custom/Outliner"
{
    Properties{
        _Smoothness("Smoothness", Range(0, 1)) = 0
        _Metallic("Metalness", Range(0, 1)) = 0

        _Color("Tint", Color) = (0, 0, 0, 1)
        _MainTex("Main Texture", 2D) = "white" {}
        _OverlayTex("Overlay Texture", 2D) = "black" {}
        
        _Corruption("Corruption",Range(0,1)) = 0

        _OutlineColor("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineColorStart("Outline Start Color", Color) = (0, 0, 0, 0)
        _OutlineThickness("Outline Thickness", Range(0,1)) = 1

        _NoiseTex("Noise", 2D) = "white" {}
        _EdgeWidth("Edge Width", Range(0, 1)) = 0.05
        [HDR] _EdgeColor("Edge Color", Color) = (1,1,1,1)

        _DisplacementTexture("Displacement Texture",2D) = "white"{}
        _Displacement("Displacement", Range(0,1)) = 0.1
        _DisplacementPower("Displacement Power",Range(0,4)) = 0.1
    }
    SubShader{
        //the material is completely non-transparent and is rendered at the same time as the other opaque geometry
        Tags{ "RenderType" = "Opaque" "Queue" = "Geometry"}

        CGPROGRAM
        //the shader is a surface shader, meaning that it will be extended by unity in the background
        //to have fancy lighting and other features
        //our surface shader function is called surf and we use our custom lighting model
        //fullforwardshadows makes sure unity adds the shadow passes the shader might need
        //vertex:vert makes the shader use vert as a vertex shader function
        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _OverlayTex;
        fixed4 _Color;

        half _Smoothness;
        half _Metallic;
        half _Corruption;
        half3 _Emission;

        sampler2D _NoiseTex;
        half _EdgeWidth;
        fixed4 _EdgeColor;

        fixed4 noisePixel, pixel;
        half cutoff;

        //input struct which is automatically filled by unity
        struct Input {
            float2 uv_MainTex;
            float2 uv_OverlayTex;
            float2 uv_NoiseTex;
        };

        //the surface shader function which sets parameters the lighting function then uses
        void surf(Input i, inout SurfaceOutputStandard o) {
            float2 uv = i.uv_MainTex;
            fixed4 tex1 = tex2D(_MainTex, i.uv_MainTex);
            fixed4 tex2 = tex2D(_OverlayTex, i.uv_OverlayTex) * _Color;

            float4 blend = lerp(tex1, tex2 , _Corruption);
            o.Albedo = blend >= (_Corruption * (_EdgeWidth + 1.0)) ? blend : blend * _EdgeColor;

            o.Metallic = _Metallic;
            o.Smoothness = _Smoothness;

            noisePixel = tex2D(_NoiseTex, i.uv_NoiseTex);

            o.Emission = noisePixel.r >= (_Corruption * (_EdgeWidth + 1.0)) ? 0 : blend;
        }
        ENDCG

        //The second pass where we render the outlines
        Pass
        {
            Cull Front

            CGPROGRAM

            //include useful shader functions
            #include "UnityCG.cginc"

            //define vertex and fragment shader
            #pragma vertex vert
            #pragma fragment frag

            //tint of the texture
            fixed4 _OutlineColor;
            fixed4 _OutlineColorStart;
            float _OutlineThickness;

            half _Corruption;
            float _Displacement;
            float _DisplacementPower;
            sampler2D _DisplacementTexture;

            //the data that's used to generate fragments and can be read by the fragment shader
            struct v2f 
            {
                float4 position : SV_POSITION;
                float4 normal : NORMAL;
                float2 uv_Main : TEXCOORD0;
                float2 uv_Overlay : TEXCOORD1;
            };

            //the vertex shader
            v2f vert(appdata_full v) 
            {
                v2f o;
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                half4 d = tex2Dlod(_DisplacementTexture, float4(worldPos.x,worldPos.y + _Time.y * _DisplacementPower,0,0));

                v.vertex.xyz += (_Displacement * v.normal * d) * _Corruption;
                o.position = UnityObjectToClipPos(v.vertex + (normalize(v.normal) * _OutlineThickness));
                return o;
            }

            //the fragment shader
            fixed4 frag(v2f i) : SV_TARGET
            {
                return lerp(_OutlineColorStart,_OutlineColor, _Corruption);
            }

            ENDCG

            }
        }
        FallBack "Standard"
}
