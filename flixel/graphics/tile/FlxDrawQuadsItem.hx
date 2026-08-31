package flixel.graphics.tile;

import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType;
import flixel.math.FlxMatrix;
import flixel.system.FlxAssets.FlxShader;
import openfl.Vector;
import openfl.display.ShaderParameter;
import openfl.geom.ColorTransform;

class FlxDrawQuadsItem extends FlxDrawBaseItem<FlxDrawQuadsItem>
{
	static inline var VERTICES_PER_QUAD = 4;

	public var shader:FlxShader;

	var rects:Vector<Float>;
	var transforms:Vector<Float>;
	var alphas:Array<Float>;
	var colorMultipliers:Array<Float>;
	var colorOffsets:Array<Float>;

	var rectsPosition:Int = 0;
	var transformsPosition:Int = 0;
	var alphasPosition:Int = 0;
	var colorMultipliersPosition:Int = 0;
	var colorOffsetsPosition:Int = 0;

	public function new()
	{
		super();
		type = FlxDrawItemType.TILES;
		rects = new Vector<Float>();
		transforms = new Vector<Float>();
		alphas = [];
	}

	override public function reset():Void
	{
		super.reset();
		rectsPosition = 0;
		transformsPosition = 0;
		alphasPosition = 0;
		colorMultipliersPosition = 0;
		colorOffsetsPosition = 0;
	}

	override public function dispose():Void
	{
		super.dispose();
		rects = null;
		transforms = null;
		alphas = null;
		colorMultipliers = null;
		colorOffsets = null;
	}

	override public function addQuad(frame:FlxFrame, matrix:FlxMatrix, ?transform:ColorTransform):Void
	{
		var rect = frame.frame;
		
		if (rects.length < rectsPosition + 4) rects.length = rectsPosition + 4 + 256;
		
		rects[rectsPosition++] = rect.x;
		rects[rectsPosition++] = rect.y;
		rects[rectsPosition++] = rect.width;
		rects[rectsPosition++] = rect.height;

		if (transforms.length < transformsPosition + 6) transforms.length = transformsPosition + 6 + 256;
		
		transforms[transformsPosition++] = matrix.a;
		transforms[transformsPosition++] = matrix.b;
		transforms[transformsPosition++] = matrix.c;
		transforms[transformsPosition++] = matrix.d;
		transforms[transformsPosition++] = matrix.tx;
		transforms[transformsPosition++] = matrix.ty;

		var alphaMultiplier = transform != null ? transform.alphaMultiplier : 1.0;
		var aPos = alphasPosition;
		for (i in 0...VERTICES_PER_QUAD)
			alphas[aPos++] = alphaMultiplier;
		alphasPosition = aPos;

		if (colored || hasColorOffsets)
		{
			if (colorMultipliers == null) colorMultipliers = [];
			if (colorOffsets == null) colorOffsets = [];

			var cmPos = colorMultipliersPosition;
			var coPos = colorOffsetsPosition;

			for (i in 0...VERTICES_PER_QUAD)
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
	}

	#if !flash
	override public function render(camera:FlxCamera):Void
	{
		if (rectsPosition == 0)
			return;
		
		rects.length = rectsPosition;
		transforms.length = transformsPosition;
		
		#if (cpp || hl)
		alphas.resize(alphasPosition);
		if (colorMultipliers != null) colorMultipliers.resize(colorMultipliersPosition);
		if (colorOffsets != null) colorOffsets.resize(colorOffsetsPosition);
		#else
		if (alphas.length > alphasPosition) alphas.splice(alphasPosition, alphas.length - alphasPosition);
		if (colorMultipliers != null && colorMultipliers.length > colorMultipliersPosition) colorMultipliers.splice(colorMultipliersPosition, colorMultipliers.length - colorMultipliersPosition);
		if (colorOffsets != null && colorOffsets.length > colorOffsetsPosition) colorOffsets.splice(colorOffsetsPosition, colorOffsets.length - colorOffsetsPosition);
		#end
		
		// TODO: catch this error when the dev actually messes up, not in the draw phase
		if (shader == null && graphics.isDestroyed)
			throw 'Attempted to render an invalid FlxDrawItem, did you destroy a cached sprite?';
		
		final shader = shader != null ? shader : graphics.shader;
		shader.bitmap.input = graphics.bitmap;
		shader.bitmap.filter = (camera.antialiasing || antialiasing) ? LINEAR : NEAREST;
		shader.alpha.value = alphas;

		if (colored || hasColorOffsets)
		{
			shader.colorMultiplier.value = colorMultipliers;
			shader.colorOffset.value = colorOffsets;
		}

		setParameterValue(shader.hasTransform, true);
		setParameterValue(shader.hasColorTransform, colored || hasColorOffsets);

		camera.canvas.graphics.overrideBlendMode(blend);
		camera.canvas.graphics.beginShaderFill(shader);
		camera.canvas.graphics.drawQuads(rects, null, transforms);
		camera.canvas.graphics.endFill();
		super.render(camera);
	}

	inline function setParameterValue(parameter:ShaderParameter<Bool>, value:Bool):Void
	{
		if (parameter.value == null)
			parameter.value = [];
		parameter.value[0] = value;
	}
	#end
}