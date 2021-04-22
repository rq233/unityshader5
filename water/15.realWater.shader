// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//实现的效果
//效果：1.反射
      //2.折射
      //3.菲涅尔效果  近岸透明，远岸不透明
      //4.浪花
      //5.uv顶点动画
      //6.阳光反射闪闪发光
Shader "Unlit/15.realWater"
{
    Properties{
        _Color("Color",Color) = (1,1,1,1)
        //纹理
        _MainTex("Main Tex",2D) = "white"{}
        
        //一个由噪声纹理生成的法线纹理，实现流动效果
        _WaveMap("Wave Map",2D) = "Bump"{}
        //流动强度
        _Intensity("Instensity",float) = 1
        //流动速度
        _Xspeed("Xspeed",Range(0,4)) = 2
        _Yspeed("Yspeed",Range(0,4)) = 2
        //波浪
        _Amount("Amount",Range(0,4)) = 1
        _High("High",Range(0,0.15)) = 0.1
        _Speed("Speed",Range(0,4)) = 1

        //水的反射
        _ReflectAmount("Reflect Amount",Range(0,1)) = 1
        _ReflectColor("Reflect Color",Color) = (1,1,1,1)
        _Cube("CubeMap",Cube) = "skybox"{}
        //菲涅尔
        _FresnelScale("Fresnel Scale", Range(0,1)) = 0.5
        //折射
        _DistortionFactor("DistortionFactor",Range(0,5)) = 2
        _EdgeColor("EdgeColor",Color) = (1,1,1,1)
        
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(0,30)) = 0.5 

        /* _destion("destion",Range(0,4)) = 2
        _Shinese("Shinese",float) = 20 */
    }

    SubShader{
        Tags{"RanderType" = "Opaque" "Queue" = "Transparent"}

        GrabPass{}

        pass{
            Tags {"LightMode" = "ForwardBase"}
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            
            sampler2D _WaveMap;
            //float4 _WaveMap_;
            float _Xspeed;
            float _Yspeed;
            float _Intensity;
            float _High;
            float _Amount;
            //波浪速度
            float _Speed;

            float _ReflectAmount;
            float4 _ReflectColor;
            samplerCUBE _Cube;
            fixed _FresnelScale;
            float _DistortionFactor;
            float4 _EdgeColor;
            sampler2D _CameraDepthTexture, _GrabTexture;//unity内置变量，无需在Properties中声明
			float4 _GrabTexture_TexelSize;
            
            float _Specular;
            float _Gloss; 

            /* float _destion;  
            float _Shinese; */

            //先实现流动效果
            struct a2v{
                float4 vertex :POSITION;
                float4 texcoord :TEXCOORD;
                float3 normal :NORMAL;
            };

            struct v2f{
                float4 pos :SV_POSITION;
                float3 worldPos :TEXCOORD0;
                float3 worldNormal :TEXCOORD2;
                float3 worldView :TEXCOORD3;
                float3 worldRefl :TEXCOORD4;
                float2 uv :TEXCOORD5;
                //相机深度信息
                float4 screenPos : TEXCOORD6;
                float2 depthtex : TEXCOORD7;
                float4 grabtex : TEXCOORD8;
                SHADOW_COORDS(9)
            };

            //顶点着色器
            v2f vert (a2v v){
                v2f o;
                v.vertex.y += sin(_Time.z * _Speed + (v.vertex.x * v.vertex.z * _Amount)) *_High;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(o.worldPos);
                o.worldView = UnityWorldSpaceViewDir(o.worldPos);
                o.worldRefl = reflect(-normalize(o.worldView), normalize(o.worldNormal));
                TRANSFER_SHADOW(o);
                //这里时采样的uv是x得输入
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.screenPos = ComputeScreenPos(o.pos);
                o.grabtex = ComputeGrabScreenPos(o.pos);
                return o;
            }

            fixed4 frag (v2f i ):SV_TARGET{
                float3 worldNormal = normalize(i.worldNormal);
                float3 worldView = normalize(i.worldView);
                float3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //*******************************************水的波动******************************************//
                fixed2 speed = _Intensity * _Time.y * float2(_Xspeed, _Yspeed);
                //这里陈慧呈现成流动的原因是噪点图uv随时间变化而改变，所以看起来像流动
                
                fixed4 color1 = tex2D(_WaveMap, i.uv + speed);
                float4 color2 = tex2D(_WaveMap, i.uv - speed);
                float4 color = color1 + color2;
                //给于两层是为了体现上下波动的效果
                
                /* fixed uM = color.r;
                fixed vM = color.r;
                float4 Maincol = tex2D(_MainTex, i.uv + float2(uM, vM)); */
                //这里我们用给经处理过的噪点，将其处理，让它成为maintex采样的uv

                //折射
                float2 offset = (_DistortionFactor * 10) * _GrabTexture_TexelSize.xy * 10;
                i.grabtex.xy = offset + i.grabtex.xy;
                float4 dis = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(i.grabtex)) * _EdgeColor;

                float3 albedo = tex2D(_MainTex,color.xy).rgb;
                fixed3 diffuse = max(0,dot(worldNormal ,worldLightDir));
                
                fixed3 reflection = texCUBE(_Cube,i.worldRefl + color.xyz).rgb * _ReflectColor.rgb;
                fixed fresnel = _FresnelScale + (1 - _FresnelScale )*pow(1-dot(worldView, worldNormal  ),5);

                float3 specular =  pow(max(0,dot(worldNormal  ,worldView)), _Gloss);
                
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                
                float3 final =  lerp(diffuse,reflection,saturate(fresnel))  + ambient + specular*atten + dis;
                return fixed4(final, 1.0) +_Color;
            }ENDCG
        }
    }Fallback "Diffuse"
}