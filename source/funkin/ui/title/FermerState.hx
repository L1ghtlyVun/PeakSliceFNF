package funkin.ui.title;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import openfl.Lib;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinSprite;

class FermerState extends FlxState
{
    override public function create():Void
    {
        super.create();
        if (FlxG.sound.music != null) {
            FlxG.sound.music.stop();
        }
        FunkinSound.playOnce(Paths.sound('secretSound'), 1.0);
        var fermer = new FlxSprite();
        fermer.loadGraphic(Paths.image('fermer'));
        fermer.setGraphicSize(FlxG.width, FlxG.height);
        fermer.updateHitbox();
        fermer.screenCenter();
        add(fermer);
        new FlxTimer().start(3, function(tmr:FlxTimer) {
            Sys.exit(0);
        });
    }
}