Shader "Unlit/flawer"
{
    Properties
    {
        _MainColor ("Main Color", Color) = (1,1,1,1)
        _MainTex("MainTex",2D) = "white"{}
        _Noise("Nosie",2D) = "white"{}
        _TimeScale("TimeScale",Range(0,1)) = 1
        _SS("SS",Range(0,2)) = 0.5
        _SC("SC",Color) =(1,1,1,1)

    }
    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
        
        cull off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
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
                float4 uv : TEXCOORD0;
                float3 normal :NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 worldNormal :TEXCOORD1;
                SHADOW_COORDS(2)
                float3 worldPos :TEXCOORD3;
            };

            sampler2D _Noise;
            float4 _Noise_ST;
            float4 _MainColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _TimeScale;
            float _SS;
            float4 _SC;

            v2f vert (a2v v)
            {
                v2f o;
                //顶点动画
				v.vertex.x += 0.2*sin(_Time.y * 1) * v.vertex.y;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv.xy, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv.zw, _Noise);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos =mul(unity_ObjectToWorld,v.vertex).xyz;
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLight= normalize(UnityWorldSpaceLightDir(i.pos));
                
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                //atten+0.5 控制阴影区域阴影系数
                fixed4 shadow = clamp(atten +_SS, atten, 1) * _SC; 
                fixed4 albedo = tex2D(_MainTex,i.uv.xy) *shadow;
                //fixed shadow = atten * _SC;
                //clip(albedo.w - 0.4);
                
                return albedo;
            }
            ENDCG
        }
    }Fallback "Diffuse"
}
