package flixel.graphics.tile;

import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import openfl.display.Graphics;
import openfl.display.ShaderParameter;
import openfl.display.TriangleCulling;
import openfl.geom.ColorTransform;

typedef DrawData<T> = openfl.Vector<T>;

/**
 * @author Zaphod
 */
class FlxDrawTrianglesItem extends FlxDrawBaseItem<FlxDrawTrianglesItem>
{
	static inline final INDICES_PER_QUAD = 6;
	static var point:FlxPoint = FlxPoint.get();
	static var rect:FlxRect = FlxRect.get();

	public var shader:FlxShader;
	var alphas:Array<Float>;
	var colorMultipliers:Array<Float>;
	var colorOffsets:Array<Float>;

	public var vertices:DrawData<Float> = new DrawData<Float>();
	public var indices:DrawData<Int> = new DrawData<Int>();
	public var uvtData:DrawData<Float> = new DrawData<Float>();
	
	@:deprecated("colors is deprecated, use colorMultipliers and colorOffsets")
	public var colors:DrawData<Int> = new DrawData<Int>();

	public var verticesPosition:Int = 0;
	public var indicesPosition:Int = 0;

	@:deprecated("colorsPosition is deprecated")
	public var colorsPosition:Int = 0;
	
	var alphasPosition:Int = 0;
	var colorMultipliersPosition:Int = 0;
	var colorOffsetsPosition:Int = 0;

	var bounds:FlxRect = FlxRect.get();

	public function new()
	{
		super();
		type = FlxDrawItemType.TRIANGLES;
		alphas = [];
	}

	override public function render(camera:FlxCamera):Void
	{
		if (numTriangles <= 0)
			return;
			
		vertices.length = verticesPosition;
		indices.length = indicesPosition;
		uvtData.length = verticesPosition;

		#if (cpp || hl)
		alphas.resize(alphasPosition);
		if (colorMultipliers != null) colorMultipliers.resize(colorMultipliersPosition);
		if (colorOffsets != null) colorOffsets.resize(colorOffsetsPosition);
		#else
		if (alphas.length > alphasPosition) alphas.splice(alphasPosition, alphas.length - alphasPosition);
		if (colorMultipliers != null && colorMultipliers.length > colorMultipliersPosition) colorMultipliers.splice(colorMultipliersPosition, colorMultipliers.length - colorMultipliersPosition);
		if (colorOffsets != null && colorOffsets.length > colorOffsetsPosition) colorOffsets.splice(colorOffsetsPosition, colorOffsets.length - colorOffsetsPosition);
		#end

		#if !flash
		var shader = shader != null ? shader : graphics.shader;
		shader.bitmap.input = graphics.bitmap;
		shader.bitmap.filter = (camera.antialiasing || antialiasing) ? LINEAR : NEAREST;
		shader.bitmap.wrap = REPEAT; // in order to prevent breaking tiling behaviour in classes that use drawTriangles
		shader.alpha.value = alphas;

		if (colored || hasColorOffsets)
		{
			shader.colorMultiplier.value = colorMultipliers;
			shader.colorOffset.value = colorOffsets;
		}
		else
		{
			shader.colorMultiplier.value = null;
			shader.colorOffset.value = null;
		}

		setParameterValue(shader.hasTransform, true);
		setParameterValue(shader.hasColorTransform, colored || hasColorOffsets);

		camera.canvas.graphics.overrideBlendMode(blend);

		camera.canvas.graphics.beginShaderFill(shader);
		#else
		camera.canvas.graphics.beginBitmapFill(graphics.bitmap, null, true, (camera.antialiasing || antialiasing));
		#end

		camera.canvas.graphics.drawTriangles(vertices, indices, uvtData, TriangleCulling.NONE);
		camera.canvas.graphics.endFill();

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
		{
			var gfx:Graphics = camera.debugLayer.graphics;
			gfx.lineStyle(1, FlxColor.BLUE, 0.5);
			gfx.drawTriangles(vertices, indices, uvtData);
		}
		#end

		super.render(camera);
	}

	override public function reset():Void
	{
		super.reset();
		verticesPosition = 0;
		indicesPosition = 0;
		alphasPosition = 0;
		colorMultipliersPosition = 0;
		colorOffsetsPosition = 0;
	}

	override public function dispose():Void
	{
		super.dispose();

		vertices = null;
		indices = null;
		uvtData = null;
		bounds = null;
		alphas = null;
		colorMultipliers = null;
		colorOffsets = null;
	}

	public function addTriangles(vertices:DrawData<Float>, indices:DrawData<Int>, uvtData:DrawData<Float>, ?colors:DrawData<Int>, ?position:FlxPoint,
			?cameraBounds:FlxRect, ?transform:ColorTransform):Void
	{
		if (position == null)
			position = point.zero();

		if (cameraBounds == null)
			cameraBounds = rect.set(0, 0, FlxG.width, FlxG.height);

		var verticesLength:Int = vertices.length;
		var numberOfVertices:Int = Std.int(verticesLength / 2);
		
		var tempX:Float, tempY:Float;
		var i:Int = 0;
		var currentVertexPosition:Int = verticesPosition;
		
		if (this.vertices.length < currentVertexPosition + verticesLength) 
			this.vertices.length = currentVertexPosition + verticesLength + 512;

		while (i < verticesLength)
		{
			tempX = position.x + vertices[i];
			tempY = position.y + vertices[i + 1];

			this.vertices[currentVertexPosition++] = tempX;
			this.vertices[currentVertexPosition++] = tempY;

			if (i == 0)
			{
				bounds.set(tempX, tempY, 0, 0);
			}
			else
			{
				inflateBounds(bounds, tempX, tempY);
			}

			i += 2;
		}

		var indicesLength:Int = indices.length;
		
		if (cameraBounds.overlaps(bounds))
		{
			var uvtDataLength:Int = uvtData.length;
			
			if (this.uvtData.length < verticesPosition + uvtDataLength) 
				this.uvtData.length = verticesPosition + uvtDataLength + 512;
				
			for (i in 0...uvtDataLength)
			{
				this.uvtData[verticesPosition + i] = uvtData[i];
			}

			if (this.indices.length < indicesPosition + indicesLength) 
				this.indices.length = indicesPosition + indicesLength + 512;

			var prevNumberOfVertices:Int = Std.int(verticesPosition / 2);
			for (i in 0...indicesLength)
			{
				this.indices[indicesPosition + i] = indices[i] + prevNumberOfVertices;
			}
			
			final alphaMultiplier = transform != null ? transform.alphaMultiplier : 1.0;
			var aPos = alphasPosition;
			
			for (_ in 0...indicesLength)
				alphas[aPos++] = alphaMultiplier;
				
			alphasPosition = aPos;
			
			if (colored || hasColorOffsets)
			{
				if (colorMultipliers == null) colorMultipliers = [];
				if (colorOffsets == null) colorOffsets = [];
				
				var cmPos = colorMultipliersPosition;
				var coPos = colorOffsetsPosition;
				
				for (_ in 0...indicesLength)
				{
					if (transform != null)
					{
						colorMultipliers[cmPos++] = transform.redMultiplier;
						colorMultipliers[cmPos++] = transform.greenMultiplier;
						colorMultipliers[cmPos++] = transform.blueMultiplier;
						colorMultipliers[cmPos++] = 1;
						
						colorOffsets[coPos++] = transform.redOffset;
						colorOffsets[coPos++] = transform.greenOffset;
						colorOffsets[coPos++] = transform.blueOffset;
						colorOffsets[coPos++] = transform.alphaOffset;
					}
					else
					{
						colorMultipliers[cmPos++] = 1;
						colorMultipliers[cmPos++] = 1;
						colorMultipliers[cmPos++] = 1;
						colorMultipliers[cmPos++] = 1;
						
						colorOffsets[coPos++] = 0;
						colorOffsets[coPos++] = 0;
						colorOffsets[coPos++] = 0;
						colorOffsets[coPos++] = 0;
					}
				}
				
				colorMultipliersPosition = cmPos;
				colorOffsetsPosition = coPos;
			}
			
			verticesPosition += verticesLength;
			indicesPosition += indicesLength;
		}

		position.putWeak();
		cameraBounds.putWeak();
	}

	inline function setParameterValue(parameter:ShaderParameter<Bool>, value:Bool):Void
	{
		if (parameter.value == null)
			parameter.value = [];
		parameter.value[0] = value;
	}

	public static inline function inflateBounds(bounds:FlxRect, x:Float, y:Float):FlxRect
	{
		if (x < bounds.x)
		{
			bounds.width += bounds.x - x;
			bounds.x = x;
		}

		if (y < bounds.y)
		{
			bounds.height += bounds.y - y;
			bounds.y = y;
		}

		if (x > bounds.x + bounds.width)
		{
			bounds.width = x - bounds.x;
		}

		if (y > bounds.y + bounds.height)
		{
			bounds.height = y - bounds.y;
		}

		return bounds;
	}

	override public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform):Void
	{
		final prevVerticesPos = verticesPosition;
		final prevNumberOfVertices = Std.int(verticesPosition / 2);
		
		if (vertices.length < prevVerticesPos + 8) vertices.length = prevVerticesPos + 8 + 256;
		if (uvtData.length < prevVerticesPos + 8) uvtData.length = prevVerticesPos + 8 + 256;
		
		final w = frame.frame.width;
		final h = frame.frame.height;
		vertices[prevVerticesPos + 0] = matrix.transformX(0, 0); // left
		vertices[prevVerticesPos + 1] = matrix.transformY(0, 0); // top
		vertices[prevVerticesPos + 2] = matrix.transformX(w, 0); // right
		vertices[prevVerticesPos + 3] = matrix.transformY(w, 0); // top
		vertices[prevVerticesPos + 4] = matrix.transformX(0, h); // left
		vertices[prevVerticesPos + 5] = matrix.transformY(0, h); // bottom
		vertices[prevVerticesPos + 6] = matrix.transformX(w, h); // right
		vertices[prevVerticesPos + 7] = matrix.transformY(w, h); // bottom
		
		uvtData[prevVerticesPos + 0] = frame.uv.left;
		uvtData[prevVerticesPos + 1] = frame.uv.top;
		uvtData[prevVerticesPos + 2] = frame.uv.right;
		uvtData[prevVerticesPos + 3] = frame.uv.top;
		uvtData[prevVerticesPos + 4] = frame.uv.left;
		uvtData[prevVerticesPos + 5] = frame.uv.bottom;
		uvtData[prevVerticesPos + 6] = frame.uv.right;
		uvtData[prevVerticesPos + 7] = frame.uv.bottom;
		
		final prevIndicesPos = indicesPosition;
		
		if (indices.length < prevIndicesPos + 6) indices.length = prevIndicesPos + 6 + 256;
		
		indices[prevIndicesPos + 0] = prevNumberOfVertices + 0; // TL
		indices[prevIndicesPos + 1] = prevNumberOfVertices + 1; // TR
		indices[prevIndicesPos + 2] = prevNumberOfVertices + 2; // BL
		indices[prevIndicesPos + 3] = prevNumberOfVertices + 1; // TR
		indices[prevIndicesPos + 4] = prevNumberOfVertices + 2; // BL
		indices[prevIndicesPos + 5] = prevNumberOfVertices + 3; // BR

		final alphaMultiplier = transform != null ? transform.alphaMultiplier : 1.0;
		var aPos = alphasPosition;
		
		for (i in 0...INDICES_PER_QUAD)
			alphas[aPos++] = alphaMultiplier;
			
		alphasPosition = aPos;
			
		if (colored || hasColorOffsets)
		{
			if (colorMultipliers == null) colorMultipliers = [];
			if (colorOffsets == null) colorOffsets = [];
				
			var cmPos = colorMultipliersPosition;
			var coPos = colorOffsetsPosition;
				
			for (i in 0...INDICES_PER_QUAD)
			{
				if (transform != null)
				{
					colorMultipliers[cmPos++] = transform.redMultiplier;
					colorMultipliers[cmPos++] = transform.greenMultiplier;
					colorMultipliers[cmPos++] = transform.blueMultiplier;
					colorMultipliers[cmPos++] = 1;
					
					colorOffsets[coPos++] = transform.redOffset;
					colorOffsets[coPos++] = transform.greenOffset;
					colorOffsets[coPos++] = transform.blueOffset;
					colorOffsets[coPos++] = transform.alphaOffset;
				}
				else
				{
					colorMultipliers[cmPos++] = 1;
					colorMultipliers[cmPos++] = 1;
					colorMultipliers[cmPos++] = 1;
					colorMultipliers[cmPos++] = 1;
					
					colorOffsets[coPos++] = 0;
					colorOffsets[coPos++] = 0;
					colorOffsets[coPos++] = 0;
					colorOffsets[coPos++] = 0;
				}
			}
			
			colorMultipliersPosition = cmPos;
			colorOffsetsPosition = coPos;
		}

		verticesPosition += 8;
		indicesPosition += 6;
	}

	override function get_numVertices():Int
	{
		return Std.int(verticesPosition / 2);
	}

	override function get_numTriangles():Int
	{
		return Std.int(indicesPosition / 3);
	}
}