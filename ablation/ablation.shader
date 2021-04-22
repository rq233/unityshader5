Shader "Unlit/xr"
{
    Properties
    {
        _Noise ("Noise", 2D) = "white" {}
        _MainTex("MainTex", 2D) = "white"{}
        _MainColor("MainColor", Color) = (1,1,1,1)
        _EdgeColor("Egde color", Color) = (1,1,1,1)
        _rjColor("rj Color", Color) = (1,1,1,1)

        //边缘光强度
        _EdgeLightIins("edge light intensity", float) = 1.0
        //uv流动速度
        _Speed("Speed", Range(0,3.0)) = 2.0
        //边缘光
        _RimNum("RimNum",Range(0,10)) = 5
        //边缘宽度
        _EdgeWi("EdgeWi",Range(-1,10)) = 5
        //消融
        _BurnAmount("BurnAmount", Range(-1,5)) = 1
        //消散点
        _AnyVector("AnyVector", Vector) = (0,1,0)
        //消散边缘
        _EdgeWidth("EdgeWidth", Range(0,1)) = 0.2
        _Smoothness("_Smoothness", Range(0.01,1)) = 0.2
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" "IgnoreProject" = "True"}

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            Cull off
            ZWrite off
            Blend one one
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            #pragma multi_compile_fwdbase

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float3 normal :NORMAL;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldNormal :TEXCOORD1;
                float3 worldPos :TEXCOORD2;
                float4 scrPos:TEXCOORD3;
            };

            sampler2D _Noise;
            float4 _Noise_ST;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _CameraDepthTexture;

            float4 _EdgeColor;
            float4 _MainColor;
            float4 _rjColor;

            float _EdgeLightIins;
            float _Speed;
            float _RimNum;
            float _EdgeWi;
            float _BurnAmount;
            float2 _AnyVector;

            float _EdgeWidth;
            float _Smoothness;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv.xy, _Noise);
                o.uv.zw = TRANSFORM_TEX(v.uv.zw, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                
                o.scrPos = ComputeScreenPos (o.pos); 
                COMPUTE_EYEDEPTH(o.scrPos.z);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldView = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.worldPos));

                //******************************** 法一 ********************************
               /*  fixed mainTex = 0.1 - tex2D(_Noise , i.uv.xy).a;
			    fixed mask = tex2D(_Noise , i.uv + _Time.y * float2(_Speed, _Speed));
                fixed4 col = lerp(_MainColor , _EdgeColor , mainTex);
			    col = lerp(fixed4(0,0,0,1), col, mask);

                //获取深度图和clip space的深度值
			    float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
			    float partZ = i.scrPos.z;
                
                //边缘
                float diff = 1-saturate((sceneZ-i.scrPos.z)*4 - _EdgeWi);
                fixed4 spe = pow(1 - abs(dot(worldNormal, worldView)), _RimNum) * _AlphaScale *_EdgeColor;
                //fixed4 col = albedo *_AlphaScale;

                //向心溶解
                fixed tex = tex2D(_Noise, i.uv.xy).x;
                float dist = distance( _AnyVector, i.uv.xy);
                float dissve = tex + dist - _BurnAmount;
                clip(dissve);

                col = col * spe;

                return col; */


                //******************************** 法二 ********************************
                //albedo
                fixed4 albedo = tex2D(_Noise, i.uv.xy + _Time.y * float2(_Speed, _Speed));
                fixed4 diff = lerp(_MainColor, float4(0,0,0,1), albedo);
                //Specu
                fixed4 spe = pow(1- abs(dot(worldNormal, worldView)),_RimNum) * _EdgeColor * _EdgeLightIins;
                //与地面交接  需要利用深度值计算
                float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
			    float partZ = i.scrPos.z;
                float4 edge = pow(1-saturate((sceneZ - partZ)), _EdgeWi) * _EdgeColor;

                //向心溶解
                /* fixed tex = tex2D(_Noise, i.uv.xy).x;
                float dist = distance( _AnyVector, i.uv.xy);
                float dissve = tex + dist - _BurnAmount;
                clip(dissve);
                if(dissve < _EdgeWidth)
				{
                    return _rjColor ;
                }  */

                //定向溶解
                //Step函数:
                //step(a, x) <=> if(x >= a) return 1; else return 0。
                float3 rootPos = float3(unity_ObjectToWorld[0].w, unity_ObjectToWorld[1].w, unity_ObjectToWorld[2].w);
                float3 pos = i.worldPos.xyz - rootPos;
                float posOffset = dot(normalize(_AnyVector), pos);
                float worldFactor = posOffset;
                fixed dissove = tex2D(_Noise, i.uv).r;
                dissove = (dissove - _BurnAmount) + worldFactor ;
                clip(dissove);

                if(dissove < _EdgeWidth)
				{
                    return _rjColor ;
                }

                fixed4 col = diff + spe + edge;
                return col;
            }
            ENDCG
        }
    }
}
