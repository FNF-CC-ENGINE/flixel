package flixel;

import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.math.FlxRect;

/**
 * A very basic rendering component which uses `drawTriangles()`.
 * You have access to `vertices`, `indices` and `uvtData` vectors which are used as data storages for rendering.
 * The whole `FlxGraphic` object is used as a texture for this sprite.
 * Use these links for more info about `drawTriangles()`:
 * @see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/display/Graphics.html#drawTriangles%28%29
 * @see http://help.adobe.com/en_US/as3/dev/WS84753F1C-5ABE-40b1-A2E4-07D7349976C4.html
 * @see https://web.archive.org/web/20170620062159/http://www.flashandmath.com/advanced/p10triangles/index.html
 *
 * WARNING: This class is EXTREMELY slow on Flash!
 */
class FlxStrip extends FlxSprite
{
	/**
	 * A `Vector` of floats where each pair of numbers is treated as a coordinate location (an x, y pair).
	 */
	public var vertices:DrawData<Float> = new DrawData<Float>();

	/**
	 * A `Vector` of integers or indexes, where every three indexes define a triangle.
	 */
	public var indices:DrawData<Int> = new DrawData<Int>();

	/**
	 * A `Vector` of normalized coordinates used to apply texture mapping.
	 */
	public var uvtData:DrawData<Float> = new DrawData<Float>();

	public var colors:DrawData<Int> = new DrawData<Int>();

	public var repeat:Bool = false;

	override public function destroy():Void
	{
		vertices = null;
		indices = null;
		uvtData = null;
		colors = null;

		super.destroy();
	}

	override public function draw():Void
	{
		if (alpha == 0 || graphic == null || vertices == null)
			return;

		final cameras = getCamerasLegacy();
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
    			continue;

			getScreenPosition(_point, camera);
			
			_point.subtractPoint(offset); 
			camera.drawTriangles(graphic, vertices, indices, uvtData, colors, _point, blend, repeat, antialiasing, colorTransform, shader);
		}
	}

	override public function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect
	{
		if (newRect == null)
			newRect = FlxRect.get();
		
		if (camera == null)
			camera = getDefaultCamera();

		var minX:Float = Math.POSITIVE_INFINITY;
		var minY:Float = Math.POSITIVE_INFINITY;
		var maxX:Float = Math.NEGATIVE_INFINITY;
		var maxY:Float = Math.NEGATIVE_INFINITY;

		if (vertices != null && vertices.length >= 2)
		{
			var i:Int = 0;
			while (i < vertices.length)
			{
				var vx:Float = vertices[i];
				var vy:Float = vertices[i + 1];
				if (vx < minX) minX = vx;
				if (vx > maxX) maxX = vx;
				if (vy < minY) minY = vy;
				if (vy > maxY) maxY = vy;
				i += 2;
			}
		}
		else
		{
			minX = 0; minY = 0; maxX = frameWidth; maxY = frameHeight;
		}

		newRect.setPosition(x, y);

		if (pixelPerfectPosition)
			newRect.round();

		_scaledOrigin.set(origin.x * scale.x, origin.y * scale.y);
		
		newRect.x += -Std.int(camera.scroll.x * scrollFactor.x) - offset.x + origin.x - _scaledOrigin.x;
		newRect.y += -Std.int(camera.scroll.y * scrollFactor.y) - offset.y + origin.y - _scaledOrigin.y;

		if (isPixelPerfectRender(camera))
			newRect.round();

		newRect.x += minX * Math.abs(scale.x);
		newRect.y += minY * Math.abs(scale.y);
		newRect.setSize((maxX - minX) * Math.abs(scale.x), (maxY - minY) * Math.abs(scale.y));

		return newRect.getRotatedBounds(angle, _scaledOrigin, newRect);
	}
}
