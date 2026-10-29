package flixel.sound;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxTween;
import flixel.util.FlxStringUtil;
import lime.media.AudioBuffer;
import lime.media.AudioSource;
import openfl.media.Sound;
import openfl.utils.ByteArray;

/**
 * This is the universal flixel sound object, used for streaming, music, and sound effects.
 */
@:access(openfl.media.Sound)
class FlxSound extends FlxBasic
{
	/**
	 * The x position of this sound in world coordinates.
	 * Only really matters if you are doing proximity/panning stuff.
	 */
	public var x:Float;
	
	/**
	 * The y position of this sound in world coordinates.
	 * Only really matters if you are doing proximity/panning stuff.
	 */
	public var y:Float;
	
	/**
	 * Whether or not this sound should be automatically destroyed when you switch states.
	 */
	public var persist:Bool;
	
	/**
	 * The ID3 song name. Defaults to null. Currently only works for streamed sounds.
	 */
	public var name(default, null):String;
	
	/**
	 * The ID3 artist name. Defaults to null. Currently only works for streamed sounds.
	 */
	public var artist(default, null):String;
	
	/**
	 * Whether to call `destroy()` when the sound has finished playing.
	 */
	public var autoDestroy:Bool;
	
	/**
	 * Tracker for sound complete callback. If assigned, will be called
	 * each time when sound reaches its end.
	 */
	public var onComplete:Null<()->Void> = null;
	
	/**
	 * Pan amount. -1 = full left, 1 = full right. Proximity based panning overrides this.
	 * 
	 * Note: On desktop targets this only works with mono sounds, due to limitations of OpenAL.
	 * More info: [OpenFL Forums - SoundTransform.pan does not work](https://community.openfl.org/t/windows-legacy-soundtransform-pan-does-not-work/6616/2?u=geokureli)
	 */
	public var pan(get, set):Float;
	
	/**
	 * Whether or not the sound is currently playing.
	 */
	public var playing(get, never):Bool;
	
	/**
	 * A number between 0 and 1 indicating how loud this sound is.
	 * 
	 * **NOTE:** This value is automatically clamped to 0 <= a <= 1
	 */
	public var volume(get, set):Float;
	
	/**
	 * Set pitch, which also alters the playback speed. Default is 1.
	 */
	public var pitch(get, set):Float;
	
	/**
	 * The position in runtime of the music playback in milliseconds.
	 * If set while paused, changes only come into effect after a `resume()` call.
	 */
	public var time(get, set):Float;
	
	/**
	 * The length of the sound in milliseconds.
	 * @since 4.2.0
	 */
	public var length(get, never):Float;
	
	/**
	 * The sound group this sound belongs to, can only be in one group.
	 * NOTE: This setter is deprecated, use `group.add(sound)` or `group.remove(sound)`.
	 */
	public var group(default, set):FlxSoundGroup;
	
	/**
	 * Whether or not this sound should loop.
	 * 
	 * **NOTE:** If `loopUntil` is 0 or more, than the sound will only loop until
	 * `loopCount` reaches `loopUntil`
	 */
	public var looped:Bool;
	
	/**
	 * The number of times this sound was restarted, via the `looped` flag.
	 * Automatically incremented on loops, and reset to 0 when restarted
	 * @since 6.2.0
	 */
	public var loopCount(default, null):Int = 0;
	
	/**
	 * The number of times this sound should loop, where `-1` loops forever, and `1` is
	 * repeated once. This field is ignored if `looped` is `false`
	 * @since 6.2.0
	 */
	public var loopUntil:Int = -1;
	
	/**
	 * The time (in milliseconds) from where to restart the sound when it loops back
	 * @since 4.1.0
	 */
	public var loopTime:Float = 0;
	
	/**
	 * At which point to stop playing the sound, in milliseconds.
	 * If not set / `null`, the sound completes normally.
	 * @since 4.2.0
	 */
	public var endTime:Null<Float>;
	
	/**
	 * The tween used to fade this sound's volume in and out (set via `fadeIn()` and `fadeOut()`)
	 * @since 4.1.0
	 */
	public var fadeTween:FlxTween;
	
	/**
	 * Internal tracker for a Flash sound object.
	 */
	var _sound:Null<Sound> = null;
	
	/**
	 * Internal tracker for a Lime audio buffer object.
	 */
	var _buffer:Null<AudioBuffer> = null;
	
	/**
	 * Internal tracker for a Lime audio source object.
	 */
	var _source:Null<AudioSource> = null;
	
	/**
	 * Internal tracker for stereo panning (-1 = full left, 1 = full right).
	 */
	var _pan:Float = 0;
	
	/**
	 * Internal tracker for whether the sound is paused or not (not the same as stopped).
	 */
	var _paused:Bool;
	
	/**
	 * Internal tracker for volume.
	 */
	var _volume:Float;
	
	/**
	 * Internal tracker for pitch.
	 */
	var _pitch:Float = 1.0;
	
	/**
	 * Internal tracker for total volume adjustment.
	 */
	var _volumeAdjust:Float = 1.0;
	
	/**
	 * Internal tracker for the sound's "target" (for proximity and panning).
	 */
	var _target:FlxObject;
	
	/**
	 * Internal tracker for the maximum effective radius of this sound (for proximity and panning).
	 */
	var _radius:Float;
	
	/**
	 * Internal tracker for whether to pan the sound left and right.  Default is false.
	 */
	var _proximityPan:Bool;
	
	/**
	 * Helper var to prevent the sound from playing after focus was regained when it was already paused.
	 */
	var _resumeOnFocus:Bool = false;
	
	/**
	 * The FlxSound constructor gets all the variables initialized, but NOT ready to play a sound yet.
	 */
	public function new()
	{
		super();
		reset();
	}
	
	/**
	 * An internal function for clearing all the variables used by sounds.
	 */
	function reset():Void
	{
		destroy();
		
		x = 0;
		y = 0;
		
		_paused = false;
		_volume = 1.0;
		_volumeAdjust = 1.0;
		looped = false;
		loopTime = 0.0;
		loopCount = 0;
		loopUntil = -1;
		endTime = 0.0;
		_target = null;
		_radius = 0;
		_proximityPan = false;
		visible = false;
		autoDestroy = false;
		_pan = 0;
	}
	
	override public function destroy():Void
	{
		// Prevents double destroy
		if (group != null)
			group.remove(this);
		
		exists = false;
		active = false;
		_target = null;
		name = null;
		artist = null;
		
		if (_source != null)
		{
			_source.onComplete.remove(stopped);
			_source.stop();
			_source.dispose();
			_source = null;
		}
		
		_buffer = null;
		_sound = null;
		
		if (fadeTween != null)
		{
			fadeTween.cancel();
			fadeTween = null;
		}
		
		onComplete = null;
		
		super.destroy();
	}
	
	/**
	 * Handles fade out, fade in, panning, and proximity operations each frame.
	 */
	override public function update(elapsed:Float):Void
	{
		if (!playing)
			return;
			
		updateProximity();
		
		if (endTime != null && endTime > 0 && time >= endTime)
			stopped();
	}
	
	function updateProximity()
	{
		_volumeAdjust = 1.0;
		
		// Distance-based volume control
		if (_target != null)
		{
			final targetPosition = _target.getPosition();
			final distRatio = targetPosition.distanceTo(FlxPoint.weak(x, y)) / _radius;
			targetPosition.put();
			_volumeAdjust = 1 - FlxMath.bound(distRatio, 0, 1);
			
			if (_proximityPan)
			{
				final xDiff = (x - _target.x) / _radius;
				_pan = FlxMath.bound(xDiff, -1, 1);
			}
		}
		
		updateTransform();
	}
	
	override public function kill():Void
	{
		super.kill();
		cleanup(false);
	}
	
	/**
	 * Loads a sound from the provided sound asset.
	 * The asset can be an OpenFL Sound instance, an asset ID or byte array.
	 * 
	 * @param   sound       The sound asset to load. For asset IDs the extention can be omitted
	 * @param   allowCache  If `sound` is an asset ID, it will see a sound already exists
	 * @return  This FlxSound instance (nice for chaining stuff together, if you're into that).
	 * 
	 * @since 6.2.0
	 */
	public function load(asset:FlxSoundAsset, allowCache = true):FlxSound
	{
		if (asset == null)
			FlxG.log.error("Expected sound asset, got null");

		#if FLX_STREAM_SOUND
		if (Std.isOfType(asset, String) && FlxG.sound.useStreamingForAll)
		{
			return loadStreamed(cast asset);
		}
		#end

		return loadHelper(asset, true, allowCache, true).init(false, false, null);
	}
	
	function loadHelper(asset:FlxSoundAsset, destroy = false, allowCache = true, addExt = false):FlxSound
	{
		cleanup(destroy);
		
		_sound = asset.resolveSound(allowCache, addExt);
		if (_sound != null)
		{
			_buffer = _sound.__buffer;
			onSoundSet();
		}
		
		return this;
	}

	#if FLX_STREAM_SOUND
	/**
	 * Streams a sound from the given file path. Unlike the `load` method, this will load and
	 * unload chunks of data as the sound plays, keeping memory usage low. This is recommended for
	 * longer sounds, like music tracks. For shorter sounds like sound effects, it is better to
	 * use the `load` method, which loads the entire sound into memory before playing it.
	 * 
	 * Due to a backend limitation, audio streaming is currently only available on native targets 
	 * and OGG/Vorbis audio files.
	 * 
	 * This does not load sounds from web locations. Use `loadFromURL()` for that, instead.
	 * 
	 * @param   assetId  The ID or asset path to the sound asset. You may omit the file extension
	 * @return  This FlxSound instance (nice for chaining stuff together, if you're into that).
	 * 
	 * @since 6.2.0
	 */
	public function loadStreamed(assetId:String):FlxSound
	{
		return loadStreamedHelper(assetId, true).init(false, false, null);
	}
	
	function loadStreamedHelper(assetId:String, destroy:Bool):FlxSound
	{
		cleanup(destroy);
		
		final fullAssetId = FlxG.assets.addSoundExt(assetId);

		if (FlxG.assets.exists(fullAssetId, SOUND))
		{
			if (FlxG.assets.canStreamSound(fullAssetId))
			{
				_sound = FlxG.assets.streamSoundUnsafe(fullAssetId);
				if (_sound != null)
				{
					_buffer = _sound.__buffer;
					onSoundSet();
				}
				
				// NOTE: can't pull ID3 info from embedded sound currently
				return init(false, false, null);
			}
			
			FlxG.log.error('Unable to stream SOUND asset with ID "$fullAssetId". Expected a .OGG/Vorbis file');
		}
		else
			FlxG.log.error('Could not find a Sound asset with an ID of \'$assetId\'.');
		
		return this;
	}
	#end

	/**
	 * Loads a sound from the provided URL.
	 * 
	 * @param   soundURL     A string representing the URL of the sound you want to play.
	 * @param   onLoad       Called when the sound finishes loading.
	 * @return  This FlxSound instance (nice for chaining stuff together, if you're into that).
	 * 
	 * @since 6.2.0
	 */
	public function loadFromURL(soundURL:String, ?onLoad:()->Void):FlxSound
	{
		return loadFromUrlHelper(soundURL, onLoad).init(false, false, null);
	}
	
	function loadFromUrlHelper(soundURL:String, ?onLoad:()->Void):FlxSound
	{
		cleanup(true);
		
		#if FLX_UNIT_TEST
		// Don't actually load enternal on unit tests
		if (onLoad != null)
			onLoad();
		#else
		AudioBuffer.loadFromFile(soundURL).onComplete(function(buffer:AudioBuffer)
		{
			if (!exists || buffer == null)
				return;
				
			_buffer = buffer;
			_sound = Sound.fromAudioBuffer(buffer);
			onSoundSet();
			
			if (onLoad != null)
				onLoad();
		});
		#end
		
		return this;
	}

	/**
	 * One of the main setup functions for sounds, this function loads a sound from an embedded MP3.
	 * 
	 * **Note:** If the `FLX_DEFAULT_SOUND_EXT` flag is enabled, you may omit the file extension
	 * 
	 * @param   embeddedSound  An embedded Class object representing an MP3 file.
	 * @param   looped         Whether or not this sound should loop endlessly.
	 * @param   autoDestroy    Whether or not this FlxSound instance should be destroyed when the sound finishes playing.
	 *                         Default value is false, but `FlxG.sound.play()` and `FlxG.sound.playFromURL()` will set it to true by default.
	 * @param   onComplete     Called when the sound finished playing
	 * @return  This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	@:deprecated("loadEmbedded() is deprecated, use load() instead.") // 6.2.0
	public function loadEmbedded(embeddedSound:FlxSoundAsset, looped = false, autoDestroy = false, ?onComplete:()->Void):FlxSound
	{
		if (embeddedSound == null)
			return this;
		
		return loadHelper(embeddedSound, true).init(looped, autoDestroy, onComplete);
	}
	
	/**
	 * One of the main setup functions for sounds, this function loads a sound from a URL.
	 * 
	 * @param   soundURL     A string representing the URL of the MP3 file you want to play.
	 * @param   looped       Whether or not this sound should loop endlessly.
	 * @param   autoDestroy  Whether or not this FlxSound instance should be destroyed when the sound finishes playing.
	 *                       Default value is false, but `FlxG.sound.play()` and `FlxG.sound.loadFromURL()` will set it to true by default.
	 * @param   onComplete   Called when the sound finished playing
	 * @param   onLoad       Called when the sound finished loading.
	 * @return  This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	@:deprecated("loadStream() is deprecated, use loadFromURL() instead.") // 6.2.0
	public function loadStream(soundURL:String, looped = false, autoDestroy = false, ?onComplete:()->Void, ?onLoad:()->Void):FlxSound
	{
		return loadFromUrlHelper(soundURL, onLoad).init(looped, autoDestroy, onComplete);
	}
	
	/**
	 * One of the main setup functions for sounds, this function loads a sound from a ByteArray.
	 * 
	 * @param   bytes        A ByteArray object.
	 * @param   looped       Whether or not this sound should loop endlessly.
	 * @param   autoDestroy  Whether or not this FlxSound instance should be destroyed when the sound finishes playing.
	 *                       Default value is false, but `FlxG.sound.play()` and `FlxG.sound.loadFromURL()` will set it to true by default.
	 * @return  This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	@:deprecated("loadByteArray() is deprecated, use load() instead.") // 6.2.0
	public function loadByteArray(bytes:ByteArray, looped:Bool = false, autoDestroy = false, ?onComplete:()->Void):FlxSound
	{
		if (bytes == null)
			return this;
		
		return loadHelper(bytes, true).init(looped, autoDestroy, onComplete);
	}
	
	/**
	 * Handy method to set up all playing fields at once
	 * 
	 * @param volume       How loud this sound will play (0 to 1)
	 * @param looped       Whether this sound will loop on completion or not
	 * @param loopUntil    The number of times this sound will restart
	 * @param autoDestroy  Whether this sound will be destroyed upon completion
	 * @param onComplete   Called upon completion
	 * @since 6.2.0
	 */
	public inline function setup(volume = 1.0, ?looped = false, ?loopUntil:Int = -1, autoDestroy = false, ?onComplete:()->Void):FlxSound
	{
		this.volume = volume;
		this.loopUntil = loopUntil;
		return init(looped, autoDestroy, onComplete);
	}
	
	function init(looped:Bool, autoDestroy:Bool, onComplete:Null<()->Void>):FlxSound
	{
		this.looped = looped;
		this.autoDestroy = autoDestroy;
		this.onComplete = onComplete;
		updateTransform();
		exists = true;
		pitch = 1;
		return this;
	}
	
	/**
	 * Call this function if you want this sound's volume to change
	 * based on distance from a particular FlxObject.
	 *
	 * @param	X			The X position of the sound.
	 * @param	Y			The Y position of the sound.
	 * @param	TargetObject		The object you want to track.
	 * @param	Radius			The maximum distance this sound can travel.
	 * @param	Pan			Whether panning should be used in addition to the volume changes.
	 * @return	This FlxSound instance (nice for chaining stuff together, if you're into that).
	 */
	public function proximity(X:Float, Y:Float, TargetObject:FlxObject, Radius:Float, Pan:Bool = true):FlxSound
	{
		x = X;
		y = Y;
		_target = TargetObject;
		_radius = Radius;
		_proximityPan = Pan;
		updateProximity();
		return this;
	}
	
	/**
	 * Call this function to play the sound - also works on paused sounds.
	 *
	 * @param   ForceRestart   Whether to start the sound over or not.
	 *                         Default value is false, meaning if the sound is already playing or was
	 *                         paused when you call play(), it will continue playing from its current
	 *                         position, NOT start again from the beginning.
	 * @param   StartTime      At which point to start playing the sound, in milliseconds.
	 * @param   EndTime        At which point to stop playing the sound, in milliseconds.
	 *                         If not set / `null`, the sound completes normally.
	 */
	public function play(forceRestart = false, startTime = 0.0, ?endTime:Float):FlxSound
	{
		if (!exists)
			return this;
		
		if (forceRestart)
			cleanup(false, true);
		else if (playing) // Already playing sound
			return this;
			
		if (_paused)
			resume();
		else
		{
			loopCount = 0;
			startSound(startTime);
		}
			
		this.endTime = endTime;
		return this;
	}
	
	/**
	 * Unpause a sound. Only works on sounds that have been paused.
	 */
	public function resume():FlxSound
	{
		if (_paused)
		{
			if (_source != null)
			{
				_paused = false;
				_source.play();
				active = true;
			}
			else
			{
				startSound(0);
			}
		}
		return this;
	}
	
	/**
	 * Call this function to pause this sound.
	 */
	public function pause():FlxSound
	{
		if (!playing)
			return this;
			
		_paused = true;
		_source.pause();
		active = false;
		return this;
	}
	
	/**
	 * Call this function to stop this sound.
	 */
	public inline function stop():FlxSound
	{
		cleanup(autoDestroy, true);
		return this;
	}
	
	/**
	 * Helper function that tweens this sound's volume.
	 *
	 * @param	Duration	The amount of time the fade-out operation should take.
	 * @param	To			The volume to tween to, 0 by default.
	 */
	public inline function fadeOut(Duration:Float = 1, ?To:Float = 0, ?onComplete:FlxTween->Void):FlxSound
	{
		if (fadeTween != null)
			fadeTween.cancel();
		fadeTween = FlxTween.num(volume, To, Duration, {onComplete: onComplete}, volumeTween);
		
		return this;
	}
	
	/**
	 * Helper function that tweens this sound's volume.
	 *
	 * @param	Duration	The amount of time the fade-in operation should take.
	 * @param	From		The volume to tween from, 0 by default.
	 * @param	To			The volume to tween to, 1 by default.
	 */
	public inline function fadeIn(Duration:Float = 1, From:Float = 0, To:Float = 1, ?onComplete:FlxTween->Void):FlxSound
	{
		if (!playing)
			play();
			
		if (fadeTween != null)
			fadeTween.cancel();
			
		fadeTween = FlxTween.num(From, To, Duration, {onComplete: onComplete}, volumeTween);
		return this;
	}
	
	function volumeTween(f:Float):Void
	{
		volume = f;
	}
	
	/**
	 * Returns the currently selected "real" volume of the sound (takes fades and proximity into account).
	 *
	 * @return	The adjusted volume of the sound.
	 */
	public inline function getActualVolume():Float
	{
		return _volume * _volumeAdjust;
	}
	
	/**
	 * Helper function to set the coordinates of this object.
	 * Sound positioning is used in conjunction with proximity/panning.
	 *
	 * @param        X        The new x position
	 * @param        Y        The new y position
	 */
	public inline function setPosition(X:Float = 0, Y:Float = 0):Void
	{
		x = X;
		y = Y;
		updateProximity();
	}
	
	/**
	 * Call after adjusting the volume to update the sound channel's settings.
	 */
	@:allow(flixel.sound.FlxSoundGroup)
	function updateTransform():Void
	{
		final gain = calcTransformVolume();
		
		if (_source != null)
		{
			_source.gain = gain;
			_source.pan = _pan;
		}
	}
	
	function calcTransformVolume():Float
	{
		final volume = (group != null ? group.getVolume() : 1.0) * _volume * _volumeAdjust;
		
		#if FLX_SOUND_SYSTEM
		if (FlxG.sound.muted)
			return 0.0;
		
		return FlxG.sound.applySoundCurve(FlxG.sound.volume * volume);
		#else
		return volume;
		#end
	}
	
	/**
	 * An internal helper function used to attempt to start playing
	 * the sound and populate the _source variable.
	 */
	function startSound(StartTime:Float):Void
	{
		if (_buffer == null && _sound != null)
			_buffer = _sound.__buffer;
			
		if (_buffer == null)
			return;
			
		_paused = false;
		
		if (_source == null)
		{
			_source = new AudioSource(_buffer);
		}
		else
		{
			_source.onComplete.remove(stopped);
			_source.stop();
		}
		
		_source.currentTime = StartTime;
		_source.loops = 0;
		updateTransform();
		
		_source.pitch = _pitch;
		
		_source.onComplete.add(stopped);
		_source.play();
		
		if (_source.playing)
		{
			active = true;
		}
		else
		{
			exists = false;
			active = false;
		}
	}
	
	/**
	 * An internal helper function used to help Flash
	 * clean up finished sounds or restart looped sounds.
	 */
	function stopped():Void
	{
		if (onComplete != null)
			onComplete();
		
		if (looped && (loopUntil == -1 || loopCount < loopUntil))
		{
			loopCount++;
			
			if (_source != null)
			{
				_source.currentTime = loopTime;
				_source.play();
				active = true;
			}
			else
			{
				startSound(loopTime);
			}
		}
		else
		{
			cleanup(autoDestroy, false);
		}
	}
	
	/**
	 * An internal helper function used to help Flash clean up (and potentially re-use) finished sounds.
	 * Will stop the current sound and destroy the associated AudioSource, plus,
	 * any other commands ordered by the passed in parameters.
	 *
	 * @param  destroySound    Whether or not to destroy the sound. If this is true,
	 *                         the position and fading will be reset as well.
	 * @param  resetPosition   Whether or not to reset the position of the sound.
	 */
	function cleanup(destroySound:Bool, resetPosition:Bool = true):Void
	{
		if (destroySound)
		{
			reset();
			return;
		}
		
		if (_source != null)
		{
			_source.onComplete.remove(stopped);
			_source.stop();
			_source.dispose();
			_source = null;
		}
		
		active = false;
		
		if (resetPosition)
		{
			_paused = false;
			loopCount = 0;
		}
	}
	
	function onSoundSet()
	{
		if (_source != null)
		{
			_source.onComplete.remove(stopped);
			_source.stop();
			_source.dispose();
			_source = null;
		}
		
		if (_buffer != null)
		{
			_source = new AudioSource(_buffer);
		}

		if (_sound != null && _sound.id3 != null)
		{
			name = _sound.id3.songName;
			artist = _sound.id3.artist;
		}
		
		endTime = length;
	}
	
	#if FLX_SOUND_SYSTEM
	function onFocus():Void
	{
		if (_resumeOnFocus)
		{
			_resumeOnFocus = false;
			resume();
		}
	}
	
	function onFocusLost():Void
	{
		_resumeOnFocus = !_paused;
		pause();
	}
	#end
	
	@:deprecated("sound.group = myGroup is deprecated, use myGroup.add(sound)") // 5.7.0
	function set_group(value:FlxSoundGroup):FlxSoundGroup
	{
		if (value != null)
		{
			// add to new group, also removes from prev and calls updateTransform
			value.add(this);
		}
		else
		{
			// remove from prev group, also calls updateTransform
			group.remove(this);
		}
		return value;
	}
	
	inline function get_playing():Bool
	{
		return _source != null && _source.playing;
	}
	
	inline function get_volume():Float
	{
		return _volume;
	}
	
	function set_volume(Volume:Float):Float
	{
		_volume = FlxMath.bound(Volume, 0, 1);
		updateTransform();
		return Volume;
	}
	
	inline function get_pitch():Float
	{
		return _pitch;
	}
	
	function set_pitch(v:Float):Float
	{
		if (_source != null)
			_source.pitch = v;
			
		return _pitch = v;
	}
	
	inline function get_pan():Float
	{
		return _pan;
	}
	
	inline function set_pan(pan:Float):Float
	{
		_pan = pan;
		updateTransform();
		return pan;
	}
	
	inline function get_time():Float
	{
		return _source != null ? _source.currentTime : 0;
	}
	
	function set_time(time:Float):Float
	{
		if (_source != null)
		{
			return _source.currentTime = time;
		}
		return time;
	}
	
	inline function get_length():Float
	{
		return _source != null ? _source.length : 0;
	}
	
	override public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("playing", playing),
			LabelValuePair.weak("time", time),
			LabelValuePair.weak("length", length),
			LabelValuePair.weak("volume", volume)
		]);
	}
}