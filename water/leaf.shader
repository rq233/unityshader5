Shader "Unlit/leaf"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Normal("Normal",2D) = "white"{}
        _Color ("Color",Color) = (1,1,1,1)
        _BumpScale("Bump Scale",float)=20.0
        _Noise("Noise", 2D) = "white"{}
        _Speed("Speed", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
        LOD 100
        cull off
        //ZWrite Off
		//Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float3 normal :NORMAL;
                float4 tangent :TANGENT;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                SHADOW_COORDS(2)
                float4 pos : SV_POSITION;
                float3 worldPos :TEXCOORD3;
                
                float3 lightDir :TEXCOORD1;
                float3 viewDir :TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            sampler2D _Normal;
            float4 _Normal_ST;
            float _BumpScale;
            sampler2D _Noise;
            float4 _Noise_ST;
            float _Speed;

            v2f vert (appdata v)
            {
                v2f o;
                v.vertex.x += 0.005*sin(_Time.y * 1) * v.vertex.y;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_SHADOW(o);
                TANGENT_SPACE_ROTATION;
                //v.uv.x += 0.1*sin(_Time.y * 2) ;
                o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv.zw,_Normal);
                o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 tangentLightDir =normalize(i.lightDir);
                fixed3 tangentViewDir =normalize(i.viewDir);
                
                //得到切线空间法线并进行映射
                //tex2D 对法线纹理 BumpMap 进行采样,注意这个采样值暂时还不能用，需要映射
                fixed4 packedNormal =tex2D(_Normal,i.uv.zw);
                //使用法线纹理中的法线值来代替模型原来的法线参与光照计算
                fixed3 tangentNormal;
                tangentNormal = UnpackNormal(packedNormal);
                //作法线映射
                tangentNormal.xy *= _BumpScale;
                //计算法线的z分量,保证z方向的为正
                tangentNormal.z = sqrt(1.0 - saturate( dot(tangentNormal.xy,tangentNormal.xy)));
                
                //光照模型计算照旧
                fixed4 albedo = tex2D(_MainTex,i.uv.xy) * _Color;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 lan = tangentLightDir * tangentViewDir ;
                fixed halflambert = dot(tangentNormal,lan)*0.5 + 0.9;
                fixed4 diffuse =  albedo * halflambert;
                //UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                fixed atten = 1;
                fixed shadow = SHADOW_ATTENUATION(i);

                //树叶抖动
                //fixed2 speed = _Intensity * _Time.y * float2(_Xspeed, _Yspeed);
                //float4 Noicol = tex2D(_Noise, i.uv.zw + _Time.y*float2(_Speed, _Speed));


                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv) *_Color;
                clip(diffuse.w - 0.4);
                //fixed sha = _Color * atten;
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                return diffuse;
            }
            ENDCG
        }
    }Fallback "Diffuse"
}
