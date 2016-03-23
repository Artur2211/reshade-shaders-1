/**
 * Copyright (C) 2015 Ganossa (mediehawk@gmail.com)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software with restriction, including without limitation the rights to
 * use and/or sell copies of the Software, and to permit persons to whom the Software 
 * is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and the permission notices (this and below) shall 
 * be included in all copies or substantial portions of the Software.
 *
 * Permission needs to be specifically granted by the author of the software to any
 * person obtaining a copy of this software and associated documentation files 
 * (the "Software"), to deal in the Software without restriction, including without 
 * limitation the rights to copy, modify, merge, publish, distribute, and/or 
 * sublicense the Software, and subject to the following conditions:
 *
 * The above copyright notice and the permission notices (this and above) shall 
 * be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include EFFECT_CONFIG(Ganossa)

#if USE_HISTOGRAM

#pragma message "Histogram by Ganossa\n"


namespace Ganossa
{
texture2D detectIntTex { Width = iResolution; Height = iResolution; Format = RGBA32F; };
sampler2D detectIntColor { Texture = detectIntTex; };

texture2D detectLowTex { Width = 256; Height = 1; Format = RGBA32F; };
sampler2D detectLowColor { Texture = detectLowTex; };

void PS_Histogram_DetectInt(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 detectInt : SV_Target0)
{
	detectInt = tex2D(ReShade::BackBuffer,texcoord);
}

void PS_Histogram_DetectLow(float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 detectLow : SV_Target0)
{
	detectLow = float4(0,0,0,0);
	[loop]
	for (float i = 0.0; i <= 1; i+=1f/iResolution)
	{	[loop]
		for ( float j = 0.0; j <= 1; j+=1f/iResolution )
		{
			float3 level = tex2D(detectIntColor,float2(i,j)).xyz;
			if(trunc(level.x*256f) == trunc(texcoord.x * 256f)) detectLow.x += 1;
			if(trunc(level.y*256f) == trunc(texcoord.x * 256f)) detectLow.y += 1;
			if(trunc(level.z*256f) == trunc(texcoord.x * 256f)) detectLow.z += 1;
		}
	}
	detectLow.xyz /= float(iResolution*iResolution)/iVerticalScale;
}

float4 PS_Histogram_Display(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target0
{
	float3 data = tex2D(detectLowColor,texcoord.x*iHorizontalScale).xyz;
	float4 hg = float4(0,0,0,1);
	if(texcoord.x < (1./iHorizontalScale-BUFFER_RCP_WIDTH)) {
#if HistoMix
	if(texcoord.y > 1-data.x) hg += float4(1,0,0,0);
	if(texcoord.y > 1-data.y) hg += float4(0,1,0,0);
	if(texcoord.y > 1-data.z) hg += float4(0,0,1,0);
#else
	if(texcoord.y+0.66 > 1-data.x && texcoord.y < 0.33) hg += float4(1,0,0,0);
	if(texcoord.y+0.33 > 1-data.y && texcoord.y < 0.66  && texcoord.y > 0.33) hg += float4(0,1,0,0);
	if(texcoord.y > 1-data.z && texcoord.y > 0.66) hg += float4(0,0,1,0);
#endif
	}
	return hg;
}

technique Histogram_Tech <bool enabled = RESHADE_START_ENABLED; int toggle = Histogram_ToggleKey; >
{
	pass Histogram_DetectInt
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_Histogram_DetectInt;
		RenderTarget = detectIntTex;
	}

	pass Histogram_DetectLow
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_Histogram_DetectLow;
		RenderTarget = detectLowTex;
	}

	pass Histogram_Display
	{
		VertexShader = ReShade::VS_PostProcess;
		PixelShader = PS_Histogram_Display;
	}
}

}

#endif

#include EFFECT_CONFIG_UNDEF(Ganossa)