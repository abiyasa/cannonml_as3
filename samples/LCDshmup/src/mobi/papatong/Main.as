package mobi.papatong
{
	import flash.display.*;
	import flash.geom.*;
	import flash.filters.*;
	import flash.events.*;
	import flash.media.*;
	import flash.utils.*;
	
	/**
	 * Main app.
	 * Copyright keim_at_Si ( http://wonderfl.net/user/keim_at_Si )
	 * MIT License ( http://www.opensource.org/licenses/mit-license.php )
	 * Downloaded from: http://wonderfl.net/c/7lZE
	 *
	 * @author Abiyasa
	 */
	public class Main extends Sprite
	{
		const FIBER:int = 0;
		const BULLET:int = 1;
		const SHOT:int = 2;
		const ENEMY:int = 3;
		const PARTICLE:int = 4;
		const EXPLOSION:int = 5;

		var sin:Vector.<Number> = new Vector.<Number>(5120, true);
		var _lcd:LCDRender;
		var _key:KeyMapper;
		var _beep:Beep;
		var _sceneManager:SceneManager = new SceneManager();
		var _playerManager:ActorManager = new ActorManager(Player).pat("7820782f782078", 7);
		var _actorManager:Vector.<ActorManager> = new Vector.<ActorManager>(6, true);
		var _player:Player;
		var frameCount:int;
		var score:int;
		var phase:int;

		var shotScript:Vector.<String> = Vector.<String>([
			"&c1[99999ha180f40{&p0}f{&p1v20w1ha190vd40}f{&p1v-20w1ha170vd40}w2f40{&p0}40w2f40f{&p1v20w1ha200vd40}f{&p1v-20w1ha160vd40}w2f40{&p0}w2]",
			"&c1[99999ha180f40{&p0}f{&p1v20w1v0,-40}f{&p1v-20w1v0,-40}w2]"
		]);
		
		public function Main():void
		{
            // key mapping
            _key = new KeyMapper(stage);
            _key.map(0,37,65).map(1,38,87).map(2,39,68).map(3,40,83).map(4,17,90,78).map(5,16,88,77);

            // lcd render
            _lcd = new LCDRender();
            _lcd.charMap[65] = LCDRender.hex2bmp("70607c6070");
            addChild(_lcd);
            addEventListener("enterFrame", _onEnterFrame);

            // beep
            _beep = new Beep();

            _actorManager[FIBER]     = new ActorManager(Fiber);
            _actorManager[BULLET]    = new ActorManager(Actor).pat("070507", 3).pat("0e1b111b0e", 5);
            _actorManager[SHOT]      = new ActorManager(Actor).pat("3f0000003f", 6).pat("3f", 6);
            _actorManager[ENEMY]     = new ActorManager(Actor, _actorManager[SHOT]);
            _actorManager[PARTICLE]  = new ActorManager(Actor).pat("01", 1);
            _actorManager[EXPLOSION] = new ActorManager(Explosion);
            _actorManager[ENEMY].pat("583c563f3f563c58", 7, 6).pat("2b7e353c3c357e2b", 14, 20).pat("2b7e353c3c357e2b", 21, 20).pat("01", 1);
            _actorManager[EXPLOSION].pat("0000060909060000").pat("1669b9c644463d02").pat("1285324884844a30");
            _actorManager[EXPLOSION].pat("0002000060905021").pat("0000000000000080");
            for (var i:int=0, p:Number=0; i<5120; i++, p+=0.0015339807878856411) sin[i] = Math.sin(p);
            _player = Player(_playerManager.alloc());
            _player.changeStatus(0);
            _player.life = 3;
            score = 0;
            _sceneManager.changeScene(0);
		}
		
        private function _onEnterFrame(e:Event):void
		{
            frameCount++;
            _lcd.cls();
            if (frameCount & 1) _actorManager[PARTICLE].alloc().init(Math.random()*96, 0, 0, int(Math.random()*3)+1);
            if (_sceneManager.update()) _player.update(_actorManager[BULLET]);
            for (var i:int = 0; i<6; i++) _actorManager[i].updateAll();
            _lcd.render();
        }
		
	}
	
}