package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

using flixel.util.FlxSpriteUtil;

typedef Vector =
{
	direction:Direction,
	value:Int
}

enum Direction
{
	NORTH;
	EAST;
	SOUTH;
	WEST;
}

class PlayState extends FlxState
{
	var Horizontal:FlxSprite;
	var Vertical:FlxSprite;
	var Origin:FlxSprite;

	var dirDropDown:FlxUIDropDownMenu;
	var curDir:String = "";
	var directions:Array<String> = ['North', 'East', 'South', 'West'];
	var dirMap:Map<String, Direction> = ['North' => NORTH, 'South' => SOUTH, 'East' => EAST, 'West' => WEST];

	var lineLength:FlxUINumericStepper;
	var pushButton:FlxButton;

	var vectors:Array<Vector> = [];

	override public function create()
	{
		Horizontal = new FlxSprite(0, 0).makeGraphic(1, 5, FlxColor.WHITE);
		Vertical = new FlxSprite(0, 0).makeGraphic(5, 1, FlxColor.WHITE);
		Origin = new FlxSprite(0, 0).makeGraphic(10, 10, FlxColor.TRANSPARENT);
		Origin.drawCircle(-1, -1, -1, FlxColor.RED);
		Origin.screenCenter();
		add(Horizontal);
		add(Vertical);
		add(Origin);

		lineLength = new FlxUINumericStepper(0, 0);
		add(lineLength);
		var lengthText:FlxText = new FlxText(lineLength.x + lineLength.width + 5, lineLength.y, 0, 'Length of line', 8);
		add(lengthText);

		dirDropDown = new FlxUIDropDownMenu(0, lineLength.height, FlxUIDropDownMenu.makeStrIdLabelArray(directions, true), function(dir:String)
		{
			curDir = directions[Std.parseInt(dir)];
		});

		add(dirDropDown);

		pushButton = new FlxButton(0, dirDropDown.height + dirDropDown.height, "Add new line", function()
		{
			var directionSel = dirDropDown.selectedLabel;
			FlxG.log.add(directionSel);

			var curLength:Int = Std.int(lineLength.value);
			FlxG.log.add(curLength);

			var data:Vector = {direction: dirMap[directionSel], value: curLength};
			FlxG.log.add(data);

			vectors.push(data);
		});
		add(pushButton);

		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
