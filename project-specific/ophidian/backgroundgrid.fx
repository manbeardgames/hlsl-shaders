//--------------------------------------------------------
//	Background Grid
//	
//	Draws the background grid for ophidian based on two
//	colors.  The colors used fror the cells are based
//	on _basecolor and _secondarycolor. Every cell is color
//	_basecolor, except for those that are on an odd row
//	and column paring.
//
//	Note:
//	In the game, to draw this grid, I render a 1x1 pixel
//	texture that is then stretched to the size of the viewport
//	The shader is applied to this stretched texture.
//--------------------------------------------------------
#if OPENGL
#define SV_POSITION POSITION
#define VS_SHADERMODEL vs_3_0
#define PS_SHADERMODEL ps_3_0
#else
#define VS_SHADERMODEL vs_4_0_level_9_1
#define PS_SHADERMODEL ps_4_0_level_9_1
#endif

//-----------------------------------------
//	External Variables
//-----------------------------------------
//	The base color to use for cells
extern float4 _basecolor = float4(0.0, 0.0, 0.0, 1.0);

//	The secondary color to use for every cell that is on an odd row & column paring.
extern float4 _secondarycolor = float4(1.0, 0.0, 0.0, 1.0);

//	The color to draw the grid lines
extern float4 _linecolor = float4(1.0, 1.0, 1.0, 1.0);

//	How thick a grid line is.  0 to 1 realtive to the size of the cell if the
//	cell was measured 0 to 1
extern float _linethickness = 0.03125;

//	The width in pixels of the viewport
extern float _viewport_width = 1280.0;

//	The height in pixels of the viewport
extern float _viewport_height = 704.0;

//	The width in pixels of a singe cell
extern float _cell_width = 32.0;

//	The height in pixels of single cell
extern float _cell_height = 32.0;

//-----------------------------------------
//	Structs
//-----------------------------------------
//	Input for the pixel shader
struct psInput
{
	float2 texcoord : TEXCOORD0;
};



//-----------------------------------------
//	Pixel shader function
//-----------------------------------------

float4 PSFunction(psInput input) : COLOR0
{
	//  Get the number of cells we can tile wide and tall
	float tileCountWide = _viewport_width / _cell_width;
	float tileCountTall = _viewport_height / _cell_height;

	//  Translate the size of each cell from the viewport width/height
	//  to a (0,0) to (1,1) width/height
	float translated_cell_width = 1.0 / tileCountWide;
	float translated_cell_height = 1.0 / tileCountTall;



	//  Divide the pixel's x position by the translated cell width, but we only care
	//  about the remainder, so we use the frac() function.  Doing this means
	//  we're mapping every pixel to a value from 0 to 1.
	//  Check to see if that value is less than the line thickness value. If it is
	//  return the grid line color. If not, return the color of the grid cell.
	//  Do the same thing for the pixel's y position
	if (frac(input.texcoord.x / translated_cell_width) < _linethickness || frac(input.texcoord.y / translated_cell_height) < _linethickness)
	{
		return _linecolor;
	}
	else
	{
		if (fmod(floor(input.texcoord.x / translated_cell_width) , 2.0) == 0.0 && fmod(floor(input.texcoord.y / translated_cell_height), 2.0) == 0.0)
		{
			return _secondarycolor;
		}
		else
		{

			return _basecolor;
		}
	}
}


technique DrawGrid
{
	pass Grid
	{
		PixelShader = compile PS_SHADERMODEL PSFunction();
	}
};