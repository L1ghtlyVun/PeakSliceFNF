package funkin.ui.freeplay;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.transition.stickers.StickerSubState;
import flixel.FlxState;
import flixel.util.FlxTimer;

class FreeplayLoadingState extends FlxState {
    var assetsToLoad:Array<String>;
    var params:Null<FreeplayState.FreeplayStateParams>;
    var stickers:Null<StickerSubState>;
    var loadedCount:Int = 0;
    
    public function new(?params:FreeplayState.FreeplayStateParams, ?stickers:StickerSubState) {
        this.params = params;
        this.stickers = stickers;
        super();
    }
    
    override function create() {
        assetsToLoad = [
            // Top-level assets
            "freeplay/beatdark.png",
            "freeplay/beatglow.png",
            "freeplay/cardGlow.png",
            "freeplay/clearBox.png",
            "freeplay/dotPulse.png",
            "freeplay/favHeart.png",
            "freeplay/freeplayBGweek1-bf.png",
            "freeplay/freeplayBGweek1-pico.png",
            "freeplay/freeplayerect.png",
            "freeplay/freeplayFlame.png",
            "freeplay/freeplayhard.png",
            "freeplay/freeplaynightmare.png",

            "freeplay/freeplayCapsule/capsule/freeplayCapsule.png",
            "freeplay/freeplayCapsule/capsule/freeplayCapsule_pico.png",
            "freeplay/freeplayCapsule/bpmtext.png",
            "freeplay/freeplayCapsule/difficultytext.png"
        ];
        loadNextAsset();
    }

    function loadNextAsset() {
            FlxG.switchState(FreeplayState.build(params, stickers));
            return;     
    }
}