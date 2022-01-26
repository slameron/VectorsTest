package;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
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
	var hypotenuse:FlxSprite;
	var Origin:FlxSprite;

	var dirDropDown:FlxUIDropDownMenu;
	var curDir:String = "";
	var directions:Array<String> = ['North', 'East', 'South', 'West'];
	var dirMap:Map<String, Direction> = ['North' => NORTH, 'South' => SOUTH, 'East' => EAST, 'West' => WEST];
	var totals:Map<String, Int> = ['North' => 0, 'East' => 0, 'South' => 0, 'West' => 0];

	var lineLength:FlxUINumericStepper;
	var camZoom:FlxUINumericStepper;
	var pushButton:FlxButton;

	var vectors:Array<Vector> = [];

	var isViewingAllLines:Bool = false;

	var allLinesGroup:FlxTypedGroup<FlxSprite>;
	var differenceGroup:FlxTypedGroup<FlxSprite>;

	var distanceTraveled:Float;
	var totalTraveled:Float = 0;

	var totalsText:FlxText;
	var resultText:FlxText;
	var angleText:FlxText;

	var hypotAngle:Float = 0;

	var scaleFactor:Int = 5;

	var lineCam:FlxCamera;
	var hudCam:FlxCamera;

	override public function create()
	{
		lineCam = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
		hudCam = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
		hudCam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(lineCam, false);
		FlxG.cameras.add(hudCam, true);

		differenceGroup = new FlxTypedGroup(3);
		allLinesGroup = new FlxTypedGroup();
		add(differenceGroup);
		add(allLinesGroup);
		allLinesGroup.visible = isViewingAllLines;

		var horizontal = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.WHITE);
		horizontal.ID = 0;
		var vertical = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.WHITE);
		vertical.ID = 1;
		hypotenuse = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.BLUE);
		hypotenuse.ID = 2;

		Origin = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.RED);
		Origin.screenCenter();

		// Makes the origin look bigger while still maintaining the 1x1 hitbox
		Origin.scale.set(3, 3);

		differenceGroup.add(horizontal);
		differenceGroup.add(vertical);
		differenceGroup.add(hypotenuse);
		add(Origin);

		differenceGroup.cameras = allLinesGroup.cameras = Origin.cameras = [lineCam];

		lineLength = new FlxUINumericStepper(0, 0, 1, 10, 1, 999);
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

			addNewLine(vectors.length - 1);
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

		camZoom = new FlxUINumericStepper(0, all.y + all.height + 2, 0.05, 1, 0.05, 8, 2);
		add(camZoom);
		var camText:FlxText = new FlxText(camZoom.x + camZoom.width + 5, camZoom.y, 0, 'Camera zoom', 8);
		add(camText);

		totalsText = new FlxText(0, 0, 0, 'Totals:\nNorth: ${totals['North']}\nEast: ${totals['East']}\nSouth: ${totals["South"]}\nWest: ${totals["West"]}',
			16);
		totalsText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1, 1);
		totalsText.alignment = RIGHT;
		totalsText.alpha = 0.5;
		add(totalsText);

		resultText = new FlxText(0, 0, 0, 'Distance from Origin: $totalTraveled', 16);
		resultText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1, 1);
		resultText.alignment = RIGHT;
		resultText.alpha = 0.5;
		add(resultText);

		angleText = new FlxText(0, 0, 0, 'Angle: $hypotAngle', 16);
		angleText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1, 1);
		angleText.alignment = RIGHT;
		angleText.alpha = 0.5;
		add(angleText);

		super.create();
	}

	function addNewLine(index:Int)
	{
		var data:Vector = vectors[index];
		var isVertical:Bool = false;
		if (data.direction == NORTH || data.direction == SOUTH)
			isVertical = true;

		var newLine:FlxSprite = new FlxSprite(0, 0).makeGraphic(isVertical?if (lineCam.zoom < 1)
			Math.ceil(1 / lineCam.zoom)
		else
			1:data.value * scaleFactor,
			isVertical ? data.value * scaleFactor : if (lineCam.zoom < 1) Math.ceil(1 / lineCam.zoom) else 1, FlxColor.WHITE);
		newLine.ID = allLinesGroup.length;
		newLine.alpha = 0.6;

		allLinesGroup.add(newLine);

		var scaledValue:Int = Math.floor(data.value * scaleFactor);

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
						case NORTH: newLine.setPosition(prevX, prevY - scaledValue);
						case SOUTH: newLine.setPosition(prevX, prevY - scaledValue);
						case EAST: newLine.setPosition(prevX + (prevW) - Math.ceil(newLine.width / 2), prevY - scaledValue);
						case WEST: newLine.setPosition(prevX, prevY - scaledValue);
					}

				case EAST:
					switch (prevD)
					{
						case NORTH: newLine.setPosition(prevX, prevY);
						case SOUTH: newLine.setPosition(prevX, prevY - newLine.height + Math.ceil(newLine.height / 2));
						case EAST: newLine.setPosition(prevX + prevW - Math.ceil(newLine.height / 2), prevY);
						case WEST: newLine.setPosition(prevX, prevY);
					}

				case SOUTH:
					switch (prevD)
					{
						case NORTH: newLine.setPosition(prevX, prevY);
						case SOUTH: newLine.setPosition(prevX, prevY + prevH - Math.ceil(newLine.width / 2));
						case EAST: newLine.setPosition(prevX + prevW - newLine.width, prevY);
						case WEST: newLine.setPosition(prevX, prevY);
					}

				case WEST:
					switch (prevD)
					{
						case NORTH: newLine.setPosition(prevX - newLine.width + Math.ceil(newLine.height / 2), prevY);
						case SOUTH: newLine.setPosition(prevX - scaledValue + Math.ceil(newLine.height / 2), prevY + prevH - Math.ceil(newLine.height / 2));
						case EAST: newLine.setPosition(prevX + (prevW) - scaledValue - Math.ceil(newLine.height / 2), prevY);
						case WEST: newLine.setPosition(prevX - scaledValue + Math.ceil(newLine.height / 2), prevY);
					}
			}
		}
		else
			newLine.setPosition(if (data.direction != WEST) Origin.x else Origin.x - (scaledValue),
				if (data.direction != NORTH) Origin.y else Origin.y - (scaledValue));

		updateTotals();
	}

	function updateTotals()
	{
		hypotAngle = 0;
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
		var hasH:Bool = false;

		if (totalX < 0)
			western = true;
		if (totalY < 0)
			southern = true;

		var diflength = differenceGroup.members.length;
		for (i in 0...diflength)
		{
			var line = differenceGroup.members[0];
			differenceGroup.remove(line, true);
			line.destroy();
		}
		FlxG.log.add('members length after destruction ${differenceGroup.members.length}');

		if (totalX != 0)
		{
			FlxG.log.add('horizontal line exist wtf');
			var horizontal = new FlxSprite(0,
				0).makeGraphic(Std.int(Math.abs(totalX * scaleFactor)), if (lineCam.zoom < 1) Math.ceil(1 / lineCam.zoom) else 1);
			horizontal.ID = 0;
			differenceGroup.add(horizontal);
			hasH = true;
		}
		else
			hasH = false;

		if (totalY != 0)
		{
			var vertical = new FlxSprite(0, 0).makeGraphic(if (lineCam.zoom < 1) Math.ceil(1 / lineCam.zoom) else 1, Std.int(Math.abs(totalY * scaleFactor)));
			vertical.ID = 1;
			FlxG.log.add('new Vertical');
			differenceGroup.add(vertical);
		}

		var daH = null;
		var daV = null;
		var daHy = null;

		FlxG.log.add('members length ${differenceGroup.members.length}');
		for (line in differenceGroup)
		{
			if (line.ID == 0)
			{
				daH = line;
				FlxG.log.add('detected horizontal line');
			}
			if (line.ID == 1)
			{
				daV = line;
				FlxG.log.add('detected vertical line');
			}
			if (line.ID == 2)
			{
				daHy = line;
				FlxG.log.add('detected hypotenuse');
			}
		}

		if (daH != null)
			daH.updateHitbox();
		if (daV != null)
			daV.updateHitbox();

		if (daH != null)
		{
			if (western)
			{
				daH.setPosition(Origin.x - daH.width + Math.ceil(daH.height / 2), Origin.y);
			}
			else
			{
				daH.setPosition(Origin.x, Origin.y);
			}
		}

		if (daV != null)
		{
			if (daH != null)
				daV.setPosition(western ? daH.x : daH.x + daH.width - Math.ceil(daV.width / 2),
					southern ? daH.y : daH.y - daV.height + Math.ceil(daV.width / 2));
			else
				daV.setPosition(Origin.x, southern ? Origin.y : Origin.y - daV.height + Math.ceil(daV.width / 2));
		}

		// should make a hypotenuse
		if (daV != null && daH != null)
		{
			var hypotLength:Float = Math.sqrt((daV.height * daV.height) + (daH.width * daH.width));
			totalTraveled = hypotLength;
			var hypotenuse:FlxSprite = new FlxSprite(0, 0).makeGraphic(Math.floor(hypotLength), 1, FlxColor.BLUE);
			hypotenuse.antialiasing = true;
			hypotenuse.ID = 2;
			differenceGroup.add(hypotenuse);

			var left:Bool = false;
			var up:Bool = false;

			if (totalX < 0)
				left = true;
			else if (totalX > 0)
				left = false;
			else
				FlxG.log.add('SHOULD NEVER BE SEEING THIS!');

			if (totalY < 0)
				up = true;
			else if (totalY > 0)
				up = false;
			else
				FlxG.log.add('SHOULD NEVER BE SEEING THIS!');

			var pointA:FlxSprite = new FlxSprite(0, 0).makeGraphic(1, 1);
			var pointB:FlxSprite = new FlxSprite(0, 0).makeGraphic(1, 1);

			if (!up)
				pointB.setPosition(daV.x, daV.y);
			else
				pointB.setPosition(daV.x, daV.y + daV.height - Math.ceil(daV.width / 2));

			pointA.setPosition(Origin.x, Origin.y);

			hypotenuse.setPosition((pointA.x + ((pointB.x - pointA.x) / 2))
				- hypotenuse.width / 2,
				pointA.y
				+ ((pointB.y - pointA.y) / 2)
				- hypotenuse.height / 2);

			var radAngle:Float;
			if (western)
				radAngle = Math.asin((daV.height / totalTraveled));
			else
				radAngle = Math.asin((daH.width / totalTraveled));

			radAngle = Math.asin((daV.height / totalTraveled));

			hypotenuse.angle = FlxAngle.asDegrees(radAngle);

			hypotAngle = hypotenuse.angle;
			/*if (hypotAngle < -90)
					hypotAngle = (180 - Math.abs(hypotAngle));
				if (hypotAngle < 0)
					hypotAngle = Math.abs(hypotAngle); */
		}
		else
		{
			if (daV != null)
				totalTraveled = (daV.height);
			else if (daH != null)
				totalTraveled = (daH.width);
			else
				totalTraveled = 0;
		}
	}

	function resetLineScale()
	{
		while (allLinesGroup.members.length != 0)
		{
			var line = allLinesGroup.members[allLinesGroup.members.length - 1];
			allLinesGroup.remove(line, true);
			line.destroy();
		}

		for (i in 0...vectors.length)
		{
			addNewLine(i);
		}
		updateTotals();
	}

	override public function update(elapsed:Float)
	{
		if (lineCam.zoom != camZoom.value)
		{
			lineCam.zoom = camZoom.value;

			resetLineScale();
			FlxG.log.add('new zoom time');
		}

		differenceGroup.cameras = allLinesGroup.cameras = Origin.cameras = [lineCam];

		totalsText.text = 'Totals:\nNorth: ${totals['North']}\nEast: ${totals['East']}\nSouth: ${totals["South"]}\nWest: ${totals["West"]}';
		totalsText.setPosition(FlxG.width - totalsText.width - 2, 0);

		resultText.text = 'Distance from origin: ${totalTraveled / scaleFactor}';
		resultText.setPosition(FlxG.width - resultText.width - 2, totalsText.y + totalsText.height + 20);

		angleText.text = 'Angle: $hypotAngle';
		angleText.setPosition(FlxG.width - angleText.width - 2, resultText.y + resultText.height + 20);

		super.update(elapsed);
	}
}
