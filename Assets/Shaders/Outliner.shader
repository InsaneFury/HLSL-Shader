Shader "Custom/Outliner"
{
    Properties{
        _Color("Tint", Color) = (0, 0, 0, 1)
        _MainTex("Texture", 2D) = "white" {}
        _Smoothness("Smoothness", Range(0, 1)) = 0
        _Metallic("Metalness", Range(0, 1)) = 0
        _Corruption("Corruption",Range(0,1)) = 0
        _Direction("Coverage Direction",Vector) = (0,1,0)
        [HDR] _Emission("Emission", color) = (0,0,0)

        _OutlineColor("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineColorStart("Outline Start Color", Color) = (0, 0, 0, 0)
        _OutlineThickness("Outline Thickness", Range(0,1)) = 1
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
        fixed4 _Color;

        half _Smoothness;
        half _Metallic;
        half _Corruption;
        half3 _Emission;

        //input struct which is automatically filled by unity
        struct Input {
            float2 uv_MainTex;
        };

        //the surface shader function which sets parameters the lighting function then uses
        void surf(Input i, inout SurfaceOutputStandard o) {
            //read albedo color from texture and apply tint
            fixed4 col = tex2D(_MainTex, i.uv_MainTex);

            float2 uv = i.uv_MainTex;
            float corruption = uv.y * _Corruption;

            o.Albedo = lerp(col.rgb, ((col.r+ col.g + col.b))*_Color,corruption);
            //just apply the values for metalness, smoothness and emission
            o.Metallic = _Metallic;
            o.Smoothness = _Smoothness;
            o.Emission = _Emission;
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
            float3 _Direction;

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
                //convert the vertex positions from object space to clip space so they can be rendered
                o.position = UnityObjectToClipPos(v.vertex + normalize(v.normal) * _OutlineThickness);
                return o;
            }

            //the fragment shader
            fixed4 frag(v2f i) : SV_TARGET
            {
                fixed dir = dot(normalize(i.normal),_Direction);
                if (dir < 1)
                {
                    dir = 0;
                }
                
                return lerp(_OutlineColorStart,_OutlineColor, _Corruption * i.uv_Main.y);
            }

            ENDCG

            }
        }
        FallBack "Standard"
}
