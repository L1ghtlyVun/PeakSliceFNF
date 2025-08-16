package funkin.ui.options;

import flixel.FlxState;
import flixel.FlxG;
import flixel.input.mouse.FlxMouseButton;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxSave;
import funkin.save.Save;
import polymod.Polymod.ModMetadata;
import openfl.display.BlendMode;
import flixel.util.FlxAxes;
import flixel.addons.display.FlxBackdrop;
import funkin.modding.PolymodHandler;
import funkin.mobile.ui.FunkinBackButton;
import funkin.util.TouchUtil;
import funkin.util.SwipeUtil;

class ModMenuItem extends FlxText
{
  public var modEnabled:Bool = false;
  public var modId:String;
  public var modMetadata:ModMetadata;
  public var defaultColor:FlxColor = FlxColor.WHITE;

  public function new(x:Float, y:Float, w:Float, str:String, size:Int, metadata:ModMetadata)
  {
    super(x, y, w, str, size);
    modId = metadata.id;
    modMetadata = metadata;
    modEnabled = false;
    setModState(false);
  }

  public function setModState(enabled:Bool):Void
  {
    modEnabled = enabled;
    if (enabled)
    {
      color = FlxColor.LIME;
      alpha = 1.0;
      text = modMetadata.title + " (Enabled)";
      defaultColor = FlxColor.LIME;
    }
    else
    {
      color = FlxColor.WHITE;
      alpha = 0.5;
      text = modMetadata.title;
      defaultColor = FlxColor.WHITE;
    }
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);
  }
}

/**
 * This is a Mod Manager for PeakSlice
 */
class ModMenuState extends FlxState
{
  var grpMods:FlxTypedGroup<ModMenuItem>;
  var enabledMods:Array<ModMetadata> = [];
  var detectedMods:Array<ModMetadata> = [];

  var curSelected:Int = 0;
  var lastTapTime:Float = 0;
  var lastTapIndex:Int = -1;
  var DOUBLE_TAP_THRESHOLD:Float = 0.3; // 300ms

  var statusText:FlxText;
  var restartPromptVisible:Bool = false;

  var checker:FlxBackdrop;
  var bgMetadata:FlxSprite;
  var title:FlxText;
  var instructions:FlxText;
  var textMetadata:FlxText;
  var scrollOffset:Float = 0;
  var scrollOF:Float = 0;
  var SCROLL_STEP:Float = 40; // Amount to scroll per wheel tick or key press
  #if mobile
  var lastTouchY:Float = 0;
  var isTouching:Bool = false;
  #end

  override public function create():Void
  {
    super.create();

    var bg:FlxSprite = new FlxSprite(Paths.image('menuDesat'));
    bg.color = 0x575757;
    bg.scrollFactor.x = #if !mobile 0 #else 0.17 #end;
    bg.scrollFactor.y = 0.17;
    bg.setGraphicSize(Std.int(FlxG.width * 1.2));
    bg.updateHitbox();
    bg.screenCenter();
    add(bg);

    checker = new FlxBackdrop(Paths.image('checker', 'preload'), FlxAxes.XY);
    checker.scale.set(4, 4);
    checker.blend = BlendMode.LAYER;
    add(checker);
    checker.scrollFactor.set(0, 0.07);
    checker.alpha = 0.5;
    checker.updateHitbox();

    title = new FlxText(-40, 40, 0, "Mod Manager", 32);
    title.color = 0xFFFFFFFF;
    title.setFormat(Paths.font('vcr.ttf'), 64);
    add(title);

    instructions = new FlxText(-40, 110, FlxG.width - 80, "Tap to select a mod\nDouble-tap to enable/disable\nPress BACK to return", 16);
    instructions.color = 0xFFAAAAAA;
    instructions.setFormat(Paths.font('vcr.ttf'), 30);
    add(instructions);

    statusText = new FlxText(-40, FlxG.height - 100, 0, "Ready", 20);
    statusText.color = 0xFFAAAAAA;
    statusText.setFormat(Paths.font('vcr.ttf'), 45);
    add(statusText);

    grpMods = new FlxTypedGroup<ModMenuItem>();
    add(grpMods);

    FlxTween.tween(title, {x: 40}, 2,
    {
      ease: FlxEase.cubeOut,
      onStart: function(twn:FlxTween) {
        FlxTween.tween(instructions, {x: 40}, 1.9,
        {
          ease: FlxEase.cubeOut,
          onStart: function(twn:FlxTween) {
            FlxTween.tween(statusText, {x: 40}, 1.8, {ease: FlxEase.cubeOut});
          }
        });
      }
    });

    bgMetadata = new FlxSprite(1130).makeGraphic(740, 940, FlxColor.BLACK);
    bgMetadata.alpha = 0.50;
    add(bgMetadata);
    textMetadata = new FlxText(bgMetadata.x + 80, bgMetadata.y + 200, 340, "", 26);
    add(textMetadata);

    var backButton:FunkinBackButton = new FunkinBackButton(FlxG.width - 230, FlxG.height - 200, FlxColor.WHITE, exitState, 0.8);
    add(backButton);

    refreshModList();
    organizeByY();
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (SwipeUtil.justSwipedDown)
    {
      FlxTween.num(scrollOF, scrollOF - 64, 0.05, function(num) { scrollOF = num; });
    }
    if (SwipeUtil.justSwipedUp)
    {
      FlxTween.num(scrollOF, scrollOF + 64, 0.05, function(num) { scrollOF = num; });
    }
    organizeByY();

    checker.x += 0.45;
    checker.y += 0.16;

    // Mouse wheel scroll (desktop only)
    #if !mobile
    if (FlxG.mouse.wheel != 0)
    {
      scrollOffset -= FlxG.mouse.wheel * SCROLL_STEP;
    }
    // Arrow key scroll (PageUp/PageDown for faster)
    if (FlxG.keys.pressed.UP)
    {
      scrollOffset += SCROLL_STEP * elapsed * 5;
    }
    if (FlxG.keys.pressed.DOWN)
    {
      scrollOffset -= SCROLL_STEP * elapsed * 5;
    }
    if (FlxG.keys.justPressed.PAGEUP)
    {
      scrollOffset += SCROLL_STEP * 5;
    }
    if (FlxG.keys.justPressed.PAGEDOWN)
    {
      scrollOffset -= SCROLL_STEP * 5;
    }
    #end

    #if mobile
    var touch = FlxG.touches.getFirst();
    if (touch != null)
    {
      if (!isTouching)
      {
        isTouching = true;
        lastTouchY = touch.screenY;
      }
      else
      {
        var dy = touch.screenY - lastTouchY;
        scrollOffset += dy;
        lastTouchY = touch.screenY;
      }
    }
    else
    {
      isTouching = false;
    }
    #end

    if (FlxG.mouse.justPressed)
    {
      var currentTime = Sys.time();
      var tappedIndex = -1;

      for (i in 0...grpMods.length)
      {
        var item = grpMods.members[i];
        if (FlxG.mouse.overlaps(item))
        {
          tappedIndex = i;
          break;
        }
      }

      if (tappedIndex >= 0)
      {
        if (tappedIndex == lastTapIndex && (currentTime - lastTapTime) < DOUBLE_TAP_THRESHOLD)
        {
          toggleModState(tappedIndex);
        }
        else
        {
          curSelected = tappedIndex;
          selections(0); // Just update selection visuals
        }

        lastTapTime = currentTime;
        lastTapIndex = tappedIndex;
      }
    }

    if (FlxG.keys.justPressed.UP)
    {
      selections(-1);
    }
    else if (FlxG.keys.justPressed.DOWN)
    {
      selections(1);
    }
    else if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
    {
      toggleModState(curSelected);
    }
  }

  function selections(change:Int = 0):Void
  {
    curSelected += change;
    if (curSelected >= detectedMods.length) curSelected = 0;
    if (curSelected < 0) curSelected = detectedMods.length - 1;

    for (i in 0...grpMods.length)
    {
      if (i == curSelected)
      {
        if (grpMods.members[i].color != FlxColor.YELLOW)
        {
          FlxTween.color(grpMods.members[i], 0.3, grpMods.members[i].color, FlxColor.YELLOW);
        }
        textMetadata.text = grpMods.members[i].modMetadata.description;
      }
      else
      {
        if (grpMods.members[i].color != grpMods.members[i].defaultColor)
        {
          FlxTween.color(grpMods.members[i], 0.3, grpMods.members[i].color, grpMods.members[i].defaultColor);
        }
        grpMods.members[i].setModState(grpMods.members[i].modEnabled);
      }
    }

    organizeByY();
  }

  function toggleModState(index:Int):Void
  {
    if (index < 0 || index >= detectedMods.length) return;

    var modMetadata = detectedMods[index];
    var modItem = grpMods.members[index];
    var isEnabled = Save.instance.enabledModIds.indexOf(modMetadata.id) != -1;

    if (isEnabled)
    {
      // Disable mod
      var newIds = Save.instance.enabledModIds.copy();
      newIds.remove(modMetadata.id);
      Save.instance.enabledModIds = newIds; // Use setter
      modItem.setModState(false);
      statusText.text = "$modMetadata.title disabled";
    }
    else
    {
      // Enable mod
      var newIds = Save.instance.enabledModIds.copy();
      if (newIds.indexOf(modMetadata.id) == -1) newIds.push(modMetadata.id);
      Save.instance.enabledModIds = newIds; // Use setter
      modItem.setModState(true);
      statusText.text = "$modMetadata.title enabled";
    }
    Save.instance.debug_dumpSave();
    // Show restart prompt
    statusText.text = "Changes saved!";
  }

  function refreshModList():Void
  {
    while (grpMods.members.length > 0)
    {
      grpMods.remove(grpMods.members[0], true);
    }

    #if sys
    detectedMods = PolymodHandler.getAllMods();
    statusText.text = "Detected" + detectedMods.length + "mods";

    for (index in 0...detectedMods.length)
    {
      var modMetadata = detectedMods[index];
      var modItem = new ModMenuItem(-40, 40 + (50 * index), 0, modMetadata.title, 32, modMetadata);
      modItem.setFormat(Paths.font('vcr.ttf'), 58);

      var delay:Float = index * 0.05;
      FlxTween.tween(modItem, {x: 40}, 1, {startDelay: delay, ease: FlxEase.cubeOut});

      modItem.modEnabled = Save.instance.enabledModIds.indexOf(modMetadata.id) != -1;
      modItem.setModState(modItem.modEnabled);

      grpMods.add(modItem);
    }

    if (detectedMods.length == 0)
    {
      statusText.text = "No mods found. Place ZIPs in the data folder!";
    }
    #else
    statusText.text = "Modding not available on this platform";
    #end
  }

  function organizeByY():Void
  {
    for (i in 0...grpMods.length)
    {
      grpMods.members[i].y = 210 + (50 * i) + scrollOF;
      grpMods.members[i].x = 40;
    }
    title.y = 40 + scrollOF;
    instructions.y = 110 + scrollOF;
  }

  /**
   * Exit State function!
   */
  public function exitState():Void
  {
    PolymodHandler.forceReloadAssets();
    FlxG.switchState(new OptionsState());
  }
}
