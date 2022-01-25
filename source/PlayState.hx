package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.ui.FlxButtonPlus;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import lime.utils.AssetLibrary;

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
	var horizontal:FlxSprite;
	var vertical:FlxSprite;
	var hypotenuse:FlxSprite;
	var Origin:FlxSprite;

	var dirDropDown:FlxUIDropDownMenu;
	var curDir:String = "";
	var directions:Array<String> = ['North', 'East', 'South', 'West'];
	var dirMap:Map<String, Direction> = ['North' => NORTH, 'South' => SOUTH, 'East' => EAST, 'West' => WEST];
	var totals:Map<String, Int> = ['North' => 0, 'East' => 0, 'South' => 0, 'West' => 0];

	var lineLength:FlxUINumericStepper;
	var pushButton:FlxButton;

	var vectors:Array<Vector> = [];

	var isViewingAllLines:Bool = false;

	var allLinesGroup:FlxTypedGroup<FlxSprite>;
	var differenceGroup:FlxTypedGroup<FlxSprite>;

	override public function create()
	{
		differenceGroup = new FlxTypedGroup(3);
		allLinesGroup = new FlxTypedGroup();
		add(differenceGroup);
		add(allLinesGroup);
		allLinesGroup.visible = isViewingAllLines;

		horizontal = new FlxSprite(0, 0).makeGraphic(1, 5, FlxColor.WHITE);
		horizontal.ID = 0;
		vertical = new FlxSprite(0, 0).makeGraphic(5, 1, FlxColor.WHITE);
		vertical.ID = 1;
		hypotenuse = new FlxSprite(0, 0).makeGraphic(5, 1, FlxColor.BLUE);
		hypotenuse.ID = 2;

		Origin = new FlxSprite(0, 0).makeGraphic(15, 15, FlxColor.TRANSPARENT);
		Origin.drawCircle(-1, -1, -1, FlxColor.RED);
		Origin.screenCenter();

		differenceGroup.add(horizontal);
		differenceGroup.add(vertical);
		differenceGroup.add(hypotenuse);
		add(Origin);

		lineLength = new FlxUINumericStepper(0, 0, 1, 0, 0, 999);
		add(lineLength);
		var lengthText:FlxText = new FlxText(lineLength.x + lineLength.width + 5, lineLength.y, 0, 'Length of line', 8);
		add(lengthText);

		dirDropDown = new FlxUIDropDownMenu(0, lineLength.height, FlxUIDropDownMenu.makeStrIdLabelArray(directions, true), function(dir:String)
		{
			curDir = directions[Std.parseInt(dir)];
		});

		add(dirDropDown);

		pushButton = new FlxButton(0, dirDropDown.y + dirDropDown.height, "Add new line", function()
		{
			var data:Vector = {direction: dirMap[dirDropDown.selectedLabel], value: Std.int(lineLength.value)};
			if (data.value <= 0)
				return;
			vectors.push(data);

			var isVertical:Bool = false;
			if (data.direction == NORTH || data.direction == SOUTH)
				isVertical = true;

			var newLine:FlxSprite = new FlxSprite(0, 0).makeGraphic(isVertical ? 5 : data.value, isVertical ? data.value : 5, FlxColor.WHITE);
			newLine.ID = allLinesGroup.length;
			allLinesGroup.add(newLine);

			if (allLinesGroup.members[newLine.ID - 1] != null)
			{
				var prevX = allLinesGroup.members[newLine.ID - 1].x;
				var prevY = allLinesGroup.members[newLine.ID - 1].y;
				var prevW = allLinesGroup.members[newLine.ID - 1].width;
				var prevH = allLinesGroup.members[newLine.ID - 1].height;
				var prevD = vectors[newLine.ID - 1].direction;
				switch (data.direction)
				{
					case NORTH:
						switch (prevD)
						{
							case NORTH: newLine.setPosition(prevX, prevY - data.value);
							case SOUTH: newLine.setPosition(prevX, prevY - data.value + prevH);
							case EAST: newLine.setPosition(prevX + prevW - newLine.width, prevY - data.value);
							case WEST: newLine.setPosition(prevX, prevY - data.value);
						}

					case EAST:
						switch (prevD)
						{
							case NORTH: newLine.setPosition(prevX + prevW, prevY);
							case SOUTH: newLine.setPosition(prevX + prevW, prevY + prevH - newLine.height);
							case EAST: newLine.setPosition(prevX + prevW, prevY);
							case WEST: newLine.setPosition(prevX, prevY);
						}

					case SOUTH:
						switch (prevD)
						{
							case NORTH: newLine.setPosition(prevX, prevY);
							case SOUTH: newLine.setPosition(prevX, prevY + prevH);
							case EAST: newLine.setPosition(prevX + prevW - newLine.width, prevY + prevH);
							case WEST: newLine.setPosition(prevX, prevY + prevH);
						}

					case WEST:
						switch (prevD)
						{
							case NORTH: newLine.setPosition(prevX - newLine.width, prevY);
							case SOUTH: newLine.setPosition(prevX - data.value, prevY + prevH - newLine.height);
							case EAST: newLine.setPosition(prevX + prevW - data.value, prevY);
							case WEST: newLine.setPosition(prevX - data.value, prevY);
						}
				}
			}
			else
				newLine.setPosition(if (data.direction != WEST) Origin.x + 5 else Origin.x + 5 - data.value,
					if (data.direction != NORTH) Origin.y + 5 else Origin.y + 5 - data.value);

			updateTotals();
		});
		add(pushButton);
		var resetButton = new FlxButton(0, pushButton.y + pushButton.height + 2, "Reset lines", function()
		{
			vectors = [];

			while (allLinesGroup.members.length != 0)
			{
				var line = allLinesGroup.members[allLinesGroup.members.length - 1];
				allLinesGroup.remove(line, true);
				line.destroy();
			}

			updateTotals();
		});
		add(resetButton);
		var undoButton = new FlxButton(0, resetButton.y + resetButton.height + 2, "Undo last line", function()
		{
			vectors.remove(vectors[vectors.length - 1]);

			var line = allLinesGroup.members[allLinesGroup.members.length - 1];
			allLinesGroup.remove(line, true);
			line.destroy();

			updateTotals();
		});
		add(undoButton);

		var all:FlxButton = new FlxButton();
		all = new FlxButton(0, undoButton.y + undoButton.height + 2, "View All Lines", function()
		{
			all.text = isViewingAllLines ? "View All Lines" : "View Total";
			isViewingAllLines = !isViewingAllLines;

			differenceGroup.visible = isViewingAllLines ? false : true;
			allLinesGroup.visible = isViewingAllLines ? true : false;
		});

		add(all);

		super.create();
	}

	function updateTotals()
	{
		for (direction in directions)
		{
			var total:Int = 0;
			for (data in vectors)
			{
				if (data.direction == dirMap[direction])
					total += data.value;
			}
			totals[direction] = total;
		}

		var totalY:Int = 0;
		var totalX:Int = 0;

		totalX = totals['East'] - totals['West'];
		totalY = totals['North'] - totals['South'];

		var western:Bool = false;
		var southern:Bool = false;

		if (totalX < 0)
			western = true;
		if (totalY < 0)
			southern = true;

		horizontal.visible = vertical.visible = true;

		for (line in differenceGroup)
		{
			differenceGroup.remove(line, true);
			line.destroy();
		}

		if (totalX != 0)
		{
			horizontal = new FlxSprite(0, 0).makeGraphic(Std.int(Math.abs(totalX)), 10);
			horizontal.ID = 0;
			differenceGroup.add(horizontal);
		}
		else
		{
			horizontal.visible = false;
			// horizontal.width = 10;
		}

		if (totalY != 0)
		{
			vertical = new FlxSprite(0, 0).makeGraphic(10, Std.int(Math.abs(totalY)));
			vertical.ID = 1;
			differenceGroup.add(vertical);
		}
		else
		{
			// vertical.height = 10;
			vertical.visible = false;
		}

		var daH = null;
		var daV = null;
		var daHy = null;

		for (line in differenceGroup)
		{
			if (line.ID == 0)
				daH = line;
			if (line.ID == 1)
				daV = line;
			if (line.ID == 2)
				daHy = line;
		}

		daH.updateHitbox();
		daV.updateHitbox();

		if (western)
			daH.setPosition(Origin.x + 5 - daH.width, Origin.y);
		else
			daH.setPosition(Origin.x + 5, Origin.y);

		// if (daH != null)
		daV.setPosition(western ? daH.x : daH.x + daH.width - daV.width, southern ? daH.y + daH.height : daH.y - daV.height);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}
