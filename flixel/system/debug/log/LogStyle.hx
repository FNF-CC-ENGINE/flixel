package flixel.system.debug.log;

import flixel.system.debug.log.FlxLogStyle;
import flixel.util.FlxColor;
import haxe.PosInfos;

/**
 * A class that allows you to create a custom style for `FlxG.log.advanced()`.
 * Also used internally for the pre-defined styles.
 */
@:forward
@:deprecated("LogStyle is deprecated, use FlxLogStyle, instead")
abstract LogStyle(FlxLogStyle) from FlxLogStyle to FlxLogStyle
{
	@:deprecated("LogStyle.NORMAL is deprecated, use FlxG.log.styles.NORMAL, instead")
	public static var NORMAL(get, set):LogStyle;
	static function get_NORMAL():LogStyle return cast StaticHolder.NORMAL;
	static function set_NORMAL(style:LogStyle):LogStyle {
		StaticHolder.NORMAL = style;
		return style;
	}
	
	@:deprecated("LogStyle.WARNING is deprecated, use FlxG.log.styles.WARNING, instead")
	public static var WARNING(get, set):LogStyle;
	static function get_WARNING():LogStyle return cast StaticHolder.WARNING;
	static function set_WARNING(style:LogStyle):LogStyle {
		StaticHolder.WARNING = style;
		return style;
	}
	
	@:deprecated("LogStyle.ERROR is deprecated, use FlxG.log.styles.ERROR, instead")
	public static var ERROR(get, set):LogStyle;
	static function get_ERROR():LogStyle return cast StaticHolder.ERROR;
	static function set_ERROR(style:LogStyle):LogStyle {
		StaticHolder.ERROR = style;
		return style;
	}
	
	@:deprecated("LogStyle.NOTICE is deprecated, use FlxG.log.styles.NOTICE, instead")
	public static var NOTICE(get, set):LogStyle;
	static function get_NOTICE():LogStyle return cast StaticHolder.NOTICE;
	static function set_NOTICE(style:LogStyle):LogStyle {
		StaticHolder.NOTICE = style;
		return style;
	}
	
	@:deprecated("LogStyle.CONSOLE is deprecated, use FlxG.log.styles.CONSOLE, instead")
	public static var CONSOLE(get, set):LogStyle;
	static function get_CONSOLE():LogStyle return cast StaticHolder.CONSOLE;
	static function set_CONSOLE(style:LogStyle):LogStyle {
		StaticHolder.CONSOLE = style;
		return style;
	}
	
	public var color(get, set):String;
	inline function get_color() return this.format.getColorString();
	inline function set_color(value:String) return this.format.setColorString(value);
	
	public var size(get, set):Int;
	inline function get_size() return this.format.size;
	inline function set_size(value:Int) return this.format.size = value;
	
	public var bold(get, set):Bool;
	inline function get_bold() return this.format.bold;
	inline function set_bold(value:Bool) return this.format.bold = value;
	
	public var italic(get, set):Bool;
	inline function get_italic() return this.format.italic;
	inline function set_italic(value:Bool) return this.format.italic = value;
	
	public var underlined(get, set):Bool;
	inline function get_underlined() return this.format.underlined;
	inline function set_underlined(value:Bool) return this.format.underlined = value;
	
	
	@:deprecated("LogStyle is deprecated, use FlxLogStyle, instead")
	public function new(prefix = "", color = "FFFFFF", size = 12, bold = false, italic = false, underlined = false,
			?errorSound:String, openConsole = false, ?callbackFunction:()->Void, ?callback:(Any, ?PosInfos)->Void, throwException = false)
	{
		final format = new FlxLogFormat(FlxColor.fromString('#$color'), size, bold, italic, underlined);
		this = new FlxLogStyle(prefix, format, errorSound, openConsole, throwException);
		
		this.callbackFunction = callbackFunction;
		if (callback != null)
			this.onLog.add(callback);
	}
}

private class StaticHolder {
	public static var NORMAL:FlxLogStyle;
	public static var WARNING:FlxLogStyle;
	public static var ERROR:FlxLogStyle;
	public static var NOTICE:FlxLogStyle;
	public static var CONSOLE:FlxLogStyle;
	
	static function __init__() {
		NORMAL = new FlxLogStyle();
		WARNING = new FlxLogStyle();
		ERROR = new FlxLogStyle();
		NOTICE = new FlxLogStyle();
		CONSOLE = new FlxLogStyle();
	}
}