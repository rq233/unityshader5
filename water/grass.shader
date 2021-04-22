Shader "Unlit/grass"
{
    Properties
    {
        _MainColor ("Main Color", Color) = (1,1,1,1)
        _BottomColor("Bottom Color",Color) = (1,1,1,1)
        _TopColor("TopColor",Color) = (1,1,1,1)
        _Noise("Nosie",2D) = "white"{}
        _TimeScale("TimeScale",Range(0,1)) = 1
        _SS("SS",Range(0,2)) = 0.5
        _SC("SC",Color) =(1,1,1,1)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdbase

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal :NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal :TEXCOORD1;
                SHADOW_COORDS(2)
                float3 worldPos :TEXCOORD3;
            };

            sampler2D _Noise;
            float4 _Noise_ST;
            float4 _MainColor;
            float4 _BottomColor;
            float4 _TopColor;
            float _TimeScale;
            float _SS;
            float4 _SC;

            v2f vert (a2v v)
            {
                v2f o;
                //顶点动画
				v.vertex.x += 0.2*sin(_Time.y * 2) * v.vertex.y;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _Noise);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos =mul(unity_ObjectToWorld,v.vertex).xyz;
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLight= normalize(UnityWorldSpaceLightDir(i.pos));
                fixed3 albedo = lerp(_TopColor, _BottomColor, i.uv.y).rgb ;
                
                //fixed atten = 1;
                //fixed shadow = SHADOW_ATTENUATION(i) * _SS;
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                //atten+0.5 控制阴影区域阴影系数
                fixed shadow = clamp(atten +_SS, atten+0.5, 1); 
                //fixed shadow = atten * _SC;
                fixed3 al = albedo *shadow ;
                //fixed3 c = tex2D(_Noise,i.uv).rgb;
                //这里用半兰伯特光照
                //fixed halfLambert = dot(worldNormal,worldLight)*0.5+0.5;
                //fixed3 diffuse = _LightColor0.rgb * _MainColor.rgb * albedo * halfLambert;
                return fixed4(al, 1.0);
            }
            ENDCG
        }
    }Fallback "Diffuse"
}
