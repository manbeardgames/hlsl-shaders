//--------------------------------------------------------
//	Background Color
//	
//	Colors the background texture.  Takes the initial
//	texture color sample, and adjusts the hue value of
//	it based on the external hue value given.
//
//	There is also a _isGray, and a few external variables
//	related to a circle definition. These are used in game
//	to switch between grayscaling the final color or
//	not grayscalling it.  When it is switch in game, 
//	the radius value is incrementally increased which creates
//	an expanding circle effect for the change in coloring.
//	
//	Additionaly a soft vignette is applied and scanlines.
//
//	Note:
//	In ophdiain, the background is first rendered as the
//	grid using the grid shader to a render target, then this
//	shader is applied to the rendertarget when it renders
//--------------------------------------------------------
#if OPENGL
#define SV_POSITION POSITION
#define PS_SHADERMODEL ps_3_0
#else
#define PS_SHADERMODEL ps_4_0_level_9_1
#endif

//-----------------------------------------
//	Variables
//-----------------------------------------
//	The texture to apply this to
sampler2D _mainTex;

//	The amount to adjust the hue of the color by
extern float _hue = 0;

//	Determines if using grayscale or now
extern float _isGray = 0.0;

//	The center of the expanding circle
extern float2 _center = float2(0.5, 0.5);

//	The radius of the circle
extern float _rad = 0.1;

//	The width in pixels of the viewport
extern float _width = 1280.0;

//	The height in pixels of the viewports
extern float _height = 704.0;

//	Epsilon
#define EPSILON 1.0e-4;

//-----------------------------------------
//	Structs
//-----------------------------------------
struct psInput
{
	float2 texcoord : TEXCOORD0;
};


//-----------------------------------------
//	User defined functions
//-----------------------------------------

//	------------------------------------------------
//	Draw a circle at the given position, with the given
//	radius, using the given color
//	Based on https://www.shadertoy.com/view/XsjGDt
//	------------------------------------------------
float4 Circle(float2 uv, float2 pos, float rad, float3 color) {
	float d = length(pos - uv) - rad;
	float t = clamp(d, 0.0, 1.0);
	return float4(color, 1.0 - t);
}

//	------------------------------------------------
//	Converts the given color from RGB colorspace to
//	HSV colorspace
//	Based on: http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
//	------------------------------------------------
float3 RgbToHsv(float3 c)
{
	float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
	float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = EPSILON;
	return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

//	------------------------------------------------
//	Converts the given color from HSV colorspace to
//	RGB colorspace
//	Based on http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
//	------------------------------------------------
float3 HsvToRgb(float3 c)
{
	float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}


//	------------------------------------------------
//	Rotates the value given. Basically if it goes 
//	above the hi value, it rotates back around to low
//	and if it goes below low, it rotates backe around
//	to hi
//	------------------------------------------------
float RotateValue(float value, float low, float hi)
{
	
	return (value < low) ? value + hi
		: (value > hi)
		? value - hi
		: value;
}

//	------------------------------------------------
//	Shifts the hue of the given color by the given amount
//	------------------------------------------------
float3 ShiftHue(float3 color, float amount)
{
	//	Translate the rgb color space to HSV
	float3 hsv = RgbToHsv(color);

	//	Increment the hue
	hsv.x = RotateValue(hsv.x + (amount / 360), 0.0, 1.0);

	//	Return back as rgb
	return HsvToRgb(hsv);

}

//	------------------------------------------------
//	Grayscales the given color
//	------------------------------------------------
float3 GrayScale(float3 color)
{
	float d = dot(color.rgb, float3(0.3, 0.59, 0.11));
	return float3(d, d, d);
}


//-----------------------------------------
//	Pixel shader function
//-----------------------------------------

float4 PSFunction(psInput input) : COLOR0
{
	//	Define the vignette
	float2 uv = input.texcoord * (1.0 - input.texcoord.yx);
	float vig = uv.x*uv.y * 15.0;

	//	Adjust the value here, higher is stronger vignette effect
	vig = pow(vig, 0.25);

	//	Convert the texcoords from 0 to 1 to actual pixels
	uv = float2(input.texcoord.x * _width, input.texcoord.y * _height);

	//	Sample the color
	float4 texcol = tex2D(_mainTex, input.texcoord);

	//	Adjust the hue
	float3 hueAdjusted = ShiftHue(texcol.rgb, _hue);

	//	Get the grayscale color
	float3 gray = GrayScale(hueAdjusted);

	//	Set the center of the screen
	float2 center = float2(_width, _height) * 0.5;

	//	Get the circle if it was gray scaled
	float4 graycircle = Circle(uv, center, _rad, gray);
	
	//	Get the circle if ti was colored
	float4 colorcircle = Circle(uv, center, _rad, hueAdjusted);
	
	//	Use a fancy nested lerp to decide if we are grayscaling or coloring the circle
	float4 col = lerp(lerp(float4(gray, 1.0), colorcircle, colorcircle.a), lerp(float4(hueAdjusted, 1.0), graycircle, graycircle.a), _isGray);


	//	Create the scanelines
	float scanline = sin(input.texcoord.y*800.0)*0.04;
	col -= scanline;

	//	Multily the final color by the vignette color and return it
	return col*vig;
}


technique ColorBackground
{
	pass Color
	{
		PixelShader = compile PS_SHADERMODEL PSFunction();
	}
};