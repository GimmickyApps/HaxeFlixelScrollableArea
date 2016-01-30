package flixel.addons;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

/**
 * Simple scrollbar.  Draws itself and also handles dragging.  (It's up to you to use the provided data to update whatever you're scrolling.)
 * @author Gimmicky Apps
 */
class FlxScrollbar extends FlxSpriteGroup
{
	private var _orientation:FlxScrollbarOrientation;
	private var _colour:FlxColor;
	private var _minProportion:Float = 0.1; // smallest barProportion of the track that the bar can be
	private var _track:FlxSprite;
	private var _bar:FlxSprite;
	private var _stale:Bool = true;
	private var _camera:FlxScrollableArea;
	private var _dragStartedAt:FlxPoint = null; // null signifying that we are not currently dragging, this is the mousedown spot
	private var _dragStartedAtBar:Float; // the x or y (depending on orientation) of the bar at drag start
	/**
	 * Create a new scrollbar graphic.  You'll have to hide it yourself when needed.
	 * 
	 * @param	X					As with any sprite.
	 * @param	Y					"
	 * @param	Width				"
	 * @param	Height				"
	 * @param	Orientation			Whether it's meant to operate vertically or horizontally.  (This is not assumed from the width/height.)
	 * @param	Colour				The colour of the draggable part of the scrollbar.  The rest of it will be the same colour added to FlxColor.GRAY.
	 * @param	InitiallyVisible	Bool to set .visible to.
	 */
	public function new( X:Float, Y:Float, Width:Float, Height:Float, Orientation:FlxScrollbarOrientation, Colour:FlxColor, Camera:FlxScrollableArea, ?InitiallyVisible:Bool=false ) 
	{
		super( X, Y );
		_orientation = Orientation;
		_colour = Colour;
		_camera = Camera;
		
		_track = new FlxSprite();
		_track.makeGraphic( Std.int( Width ), Std.int( Height ), FlxColor.add( FlxColor.GRAY, _colour ), true );
		add( _track );
		
		_bar = new FlxSprite();
		_bar.makeGraphic( Std.int( Width ), Std.int( Height ), _colour, true );
		add( _bar );
		
		visible = InitiallyVisible;
	}
	override public function draw() {
		if (_stale) {
			var barProportion:Float;
			var scrolledProportion:Float;
			if (_orientation == HORIZONTAL) {
				barProportion = FlxMath.bound( _track.width / _camera.content.width, _minProportion );
				_bar.makeGraphic( Std.int( _track.width * barProportion ), Std.int( _track.height ), _colour, true );
				if (_camera.content.width == _track.width)
					scrolledProportion = 0;
				else
					scrolledProportion = FlxMath.bound( _camera.scroll.x / ( _camera.content.width - _track.width ), 0, 1 );
				_bar.x = scrolledProportion * (_track.width * (1 - barProportion));
			} else {
				barProportion = FlxMath.bound( _track.height / _camera.content.height, _minProportion );
				_bar.makeGraphic( Std.int( _track.width ), Std.int( _track.height * barProportion ), _colour, true );
				if (_camera.content.height == _track.height)
					scrolledProportion = 0;
				else
					scrolledProportion = FlxMath.bound( _camera.scroll.y / ( _camera.content.height - _track.height ), 0, 1 );
				_bar.y = scrolledProportion * (_track.height * (1 - barProportion));
			}
			_stale = false;
		}
		super.draw();
	}
	override public function update(elapsed:Float)
	{
		var mousePosition = FlxG.mouse.getWorldPosition();
		if (FlxG.mouse.justPressed) {
			if (_bar.overlapsPoint( mousePosition )) {
				_dragStartedAt = mousePosition;
				if (_orientation == HORIZONTAL) {
					_dragStartedAtBar = _bar.x;
				} else {
					_dragStartedAtBar = _bar.y;					
				}
			} else if (_track.overlapsPoint( mousePosition )) {
				// TODO: track/paging case
			}
		}
		if (_dragStartedAt != null) {
			if (_orientation == HORIZONTAL) {
				if (mousePosition.y < (_camera.y + _camera.height / 2)) // allow 50% of height away before jumping back to original position
					mousePosition.x = _dragStartedAt.x;
				_bar.x = FlxMath.bound( _dragStartedAtBar + (mousePosition.x - _dragStartedAt.x), _track.x, _track.x + _track.width - _bar.width );
				updateScrollX();
			} else { // VERTICAL
				if (mousePosition.x < (_camera.x + _camera.width / 2)) // allow 50% of width away before jumping back to original position
					mousePosition.y = _dragStartedAt.y;
				_bar.y = FlxMath.bound( _dragStartedAtBar + (mousePosition.y - _dragStartedAt.y), _track.y, _track.y + _track.height - _bar.height );
				updateScrollY();
			}
		}
		if (FlxG.mouse.justReleased)
			_dragStartedAt = null;
		super.update(elapsed);
	}
	/**
	 * Updates the view's horizontal scroll.  Should be done from the outside if there's a resize.
	 */
	public function updateScrollX() {
		_camera.scroll.x = _camera.content.x + (_camera.content.width - _track.width) * FlxMath.bound( _bar.x / (_track.width - _bar.width), 0, 1 );
	}
	/**
	 * Updates the view's vertical scroll.  Should be done from the outside if there's a resize.
	 */
	public function updateScrollY() {
		_camera.scroll.y = _camera.content.y + (_camera.content.height - _track.height) * FlxMath.bound( _bar.y / (_track.height - _bar.height), 0, 1 );
	}
	/**
	 * Use this instead of setting .width, in order to ensure the scrollbar is redrawn.
	 * @param	value	The new width.
	 * @return			The new width.
	 */
	public function resizeWidth(value:Float):Float 
	{
		if (_track.width != value) {
			_track.makeGraphic( Std.int( value ), Std.int( height ), FlxColor.add( FlxColor.GRAY, _colour ), true );
			_stale = true;
		}
		return value;
	}
	/**
	 * Use this instead of setting .height, in order to ensure the scrollbar is redrawn.
	 * @param	value	The new height.
	 * @return			The new height.
	 */
	public function resizeHeight(value:Float):Float 
	{
		if (_track.height != value) {
			_track.makeGraphic( Std.int( width ), Std.int( value ), FlxColor.add( FlxColor.GRAY, _colour ), true );
			_stale = true;
		}
		return value;
	}	
}
enum FlxScrollbarOrientation {
	VERTICAL;
	HORIZONTAL;
}