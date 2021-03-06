package me.miltage.ld33;

import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.Assets;
import openfl.geom.Rectangle;
import openfl.geom.Point;

import me.miltage.ld33.math.BB;
import me.miltage.ld33.math.Vec2;
import me.miltage.ld33.utils.KeyObject;
import me.miltage.ld33.utils.GraphicsUtil;

class Game extends Sprite {

	public static var instance:Game;
	public static var started:Bool = false;
	public static var finished:Bool = false;
	public static var runCounter:Int = 0;

	public var entities:Array<Entity>;
	public var teens:Array<Teen>;
	public var extras:Array<Entity>;
	public var blood:Array<Blood>;
	public var rain:Array<Rain>;
	public var hidingPlaces:Array<Vec2>;
	public var windows:Array<Vec2>;
	public var order:Array<Teen>;
	public var navMesh:NavMesh;

	var bg:BitmapData;
	var data:BitmapData;
	var effect:BitmapData;
	var hud:BitmapData;
	var weather:BitmapData;
	var holder:Sprite;

	var keys:KeyObject;
	var ui:BitmapData;
	var car:Car;
	var roof:Bitmap;

	var rainDelay:Int;

	var worldBBs:Array<BB>;

	public var killer:Killer;
	
	public function new(){
		super();
		instance = this;

		entities = [];
		extras = [];
		teens = [];
		blood = [];
		hidingPlaces = [];
		windows = [];
		order = [];
		rain = [];

		keys = new KeyObject(Lib.current.stage);
		holder = new Sprite();

		bg = new BitmapData(Std.int(Lib.application.window.width/Main.scale), Std.int(Lib.application.window.height/Main.scale), false, 0x353d31);
		var b:Bitmap = new Bitmap(bg);
		addChild(b);

		worldBBs = new Array<BB>();
		// world boundaries
		worldBBs.push(new BB(null, 0, 0, Lib.application.window.width/Main.scale, 2));
		worldBBs.push(new BB(null, 0, 0, 2, Lib.application.window.height/Main.scale));
		worldBBs.push(new BB(null, 0, Lib.application.window.height/Main.scale-2, Lib.application.window.width/Main.scale, 2));
		worldBBs.push(new BB(null, Lib.application.window.width/Main.scale-2, 0, 2, Lib.application.window.height/Main.scale));

		// cabin walls		
		worldBBs.push(new BB(null, 91, 65, 320, 67));
		worldBBs.push(new BB(null, 190, 116, 288, 119));
		worldBBs.push(new BB(null, 306, 116, 320, 119));
		worldBBs.push(new BB(null, 92, 135, 161, 137));
		worldBBs.push(new BB(null, 92, 212, 281, 215));
		worldBBs.push(new BB(null, 299, 212, 320, 215));

		worldBBs.push(new BB(null, 91, 66, 95, 214));
		worldBBs.push(new BB(null, 160, 66, 164, 82));
		worldBBs.push(new BB(null, 160, 97, 164, 169));
		worldBBs.push(new BB(null, 160, 184, 164, 213));
		worldBBs.push(new BB(null, 186, 66, 190, 82));
		worldBBs.push(new BB(null, 186, 97, 190, 169));
		worldBBs.push(new BB(null, 186, 184, 190, 213));
		worldBBs.push(new BB(null, 241, 66, 245, 117));
		worldBBs.push(new BB(null, 320, 65, 324, 215));

		worldBBs.push(new BB(null, 260, 238, 263, 241));
		worldBBs.push(new BB(null, 319, 238, 322, 241));

		navMesh = new NavMesh();

		var bmd = Assets.getBitmapData("assets/cabin_floor.png");
		addChild(new Bitmap(bmd));
		ui = Assets.getBitmapData("assets/ui.png");

		loadExtra();

		addEventListener(Event.ENTER_FRAME, update);

		effect = new BitmapData(Std.int(Lib.application.window.width/Main.scale), Std.int(Lib.application.window.height/Main.scale), true, 0x00000000);
		b = new Bitmap(effect);
		addChild(b);

		data = new BitmapData(Std.int(Lib.application.window.width/Main.scale), Std.int(Lib.application.window.height/Main.scale), true, 0x00000000);
		b = new Bitmap(data);
		addChild(b);
		addChild(holder);

		for(bb in getBBs(new BB(null, 0, 0, 400, 300))){
			GraphicsUtil.drawLine(data, bb.x0, bb.y0, bb.x1, bb.y0, 0xffff0000);
			GraphicsUtil.drawLine(data, bb.x0, bb.y0, bb.x0, bb.y1, 0xffff0000);
			GraphicsUtil.drawLine(data, bb.x0, bb.y1, bb.x1, bb.y1, 0xffff0000);
			GraphicsUtil.drawLine(data, bb.x1, bb.y0, bb.x1, bb.y1, 0xffff0000);
		}
		for(node in navMesh.nodes){
			/*data.setPixel32(Std.int(node.x), Std.int(node.y), 0xffff0000);
			for(n in node.neighbours)
				GraphicsUtil.drawLine(data, node.x, node.y, n.x, n.y, 0xffff0000);*/
		}

		roof = new Bitmap(Assets.getBitmapData("assets/roof.png"));
		addChild(roof);

		weather = new BitmapData(Std.int(Lib.application.window.width/Main.scale), Std.int(Lib.application.window.height/Main.scale), true, 0x00000000);
		b = new Bitmap(weather);
		addChild(b);

		hud = new BitmapData(Std.int(Lib.application.window.width/Main.scale), Std.int(Lib.application.window.height/Main.scale), true, 0x00000000);
		b = new Bitmap(hud);
		addChild(b);

		for(i in 0...100){
			rain.push(new Rain());
		}


	}

	public function update(e:Event){
		data.fillRect(data.rect, 0x00000000);
		weather.fillRect(data.rect, 0x00000000);

		if(Game.started) runCounter++;

		if(runCounter == 300){
			addKiller();
			rainDelay = 9;
		}

		// sort
		updateOrder();

		// input
		if(keys.isDown(KeyObject.SPACE) && !Game.started){
			Game.started = true;
			Main.instance.titleScreen.visible = false;
		}
		else if(keys.isDown(KeyObject.SPACE) && Game.finished){
			Main.instance.restart();
		}

		if(Game.finished) return;

		if(killer != null){
			if(keys.isDown(KeyObject.RIGHT) || keys.isDown(KeyObject.D))
				killer.move(2, 0);
			if(keys.isDown(KeyObject.LEFT) || keys.isDown(KeyObject.A))
				killer.move(-2, 0);
			if(keys.isDown(KeyObject.UP) || keys.isDown(KeyObject.W))
				killer.move(0, -2);
			if(keys.isDown(KeyObject.DOWN) || keys.isDown(KeyObject.S))
				killer.move(0, 2);

			if(keys.isDown(KeyObject.RIGHT) || keys.isDown(KeyObject.D) || keys.isDown(KeyObject.LEFT) || keys.isDown(KeyObject.A)
				|| keys.isDown(KeyObject.UP) || keys.isDown(KeyObject.W) || keys.isDown(KeyObject.DOWN) || keys.isDown(KeyObject.S))
				killer.moveCount++;
			else
				killer.moveCount = 0;

			if(keys.isDown(KeyObject.X)){
				if(!killer.hiding) killer.slash();
			}

			if(keys.isDown(KeyObject.C)){
				if(killer.canHide() && killer.hideDelay == 0){
					killer.hiding = !killer.hiding;
					killer.hideDelay = 10;
				}
				else if(killer.canWindow() && killer.hideDelay == 0){
					var d = killer.pos.sub(windows[0]);
					if(d.y > 0 && d.y < 8) d.y = 8;
					killer.pos.y += d.y*-2;
					killer.hideDelay = 10;
					updateOrder();
				}
			}
		}

		for(e in entities)
			e.update();

		for(b in blood){
			b.update();
			if(b.remove){
				blood.remove(b);
				entities.remove(b);
				holder.removeChild(b);
				GraphicsUtil.drawCircle(effect, b.x, b.y, Std.int(Math.random()*2), 0xffcc0000, true);
			}
		}

		for(teen in teens){
			if(killer == null) break;
			if(teen.state == Teen.SCARED) continue;
			if(LOS.canSee(teen.pos, killer.pos, 1) && teen.facing.dot(killer.pos.sub(teen.pos)) > 0.7 && !killer.hiding){
				GraphicsUtil.drawStaggeredLine(data, killer.pos.x, killer.pos.y, teen.pos.x, teen.pos.y, 0xffff0000);
				teen.thought = "!";
				teen.setState(Teen.SUSPICIOUS);
				if(teen.suspTime < 100) teen.suspTime = 200;
				teen.suspTime+=2;
			}else if(teen.thought == "!"){
				teen.thought = "";
			}
		}

		// hud elements
		for(i in 0...order.length){
			hud.copyPixels(ui, new Rectangle(order[i].portrait*16, 32+(order[i].health>0?0:16), 16, 16), new Point(i*16+5, Std.int(Lib.application.window.height/Main.scale)-21));
		}

		hud.copyPixels(ui, new Rectangle(16*(Main.mute?1:0), 16, 16, 16), new Point(Std.int(Lib.application.window.width/Main.scale)-18, 4));

		if(runCounter > 150) roof.alpha -= 0.015;

		if(rainDelay == 9) Main.instance.thunderStruck();
		if(rainDelay > 0) rainDelay--;
		if(rainDelay < 10 && rainDelay % 3 == 0) lightning();
		drawRain();

	}

	private function updateOrder(){		
		for(i in 0...entities.length-1){
			if(entities[i].y+entities[i].register > entities[i+1].y+entities[i+1].register){
				var t = entities[i];
				entities[i] = entities[i+1];
				entities[i+1] = t;
				holder.swapChildren(entities[i], entities[i+1]);
			}
		}
	}

	public function getBBs(bounds:BB, includeFurni:Bool=false):Array<BB> {
		var list:Array<BB> = new Array<BB>();
		bounds = bounds.grow(5);		

		for(bb in worldBBs){
			if(bounds.intersectsBB(bb))
				list.push(bb);
		}

		if(!includeFurni) return list;

		for(e in extras){
			if(bounds.intersectsBB(e.getBB()))
				list.push(e.getBB());
		}

		return list;
	}

	private function addKiller(){
		killer = new Killer(this, 130, 250);
		entities.push(killer);
		holder.addChild(killer);
	}

	private function loadExtra(){
		car = new Car();
		entities.push(car);
		extras.push(car);
		holder.addChild(car);

		var walls = new Extra(this, 0, 0, 400, 300, "cabin_walls");
		walls.register = 40;
		entities.push(walls);
		holder.addChild(walls);

		var deer = new Extra(this, 162, 32, 24, 32, "furniture", 70, 0);
		deer.register = 11;
		entities.push(deer);
		holder.addChild(deer);

		var shower = new Extra(this, 188, 32, 24, 64, "furniture", 95, 0);
		shower.register = 11;
		shower.bb = new BB(shower, 193, 69, 208, 79);
		entities.push(shower);
		extras.push(shower);
		holder.addChild(shower);

		var toilet = new Extra(this, 218, 32, 24, 64, "furniture", 125, 0);
		toilet.register = 11;
		toilet.bb = new BB(toilet, 230, 68, 239, 77);
		entities.push(toilet);
		extras.push(toilet);
		holder.addChild(toilet);

		var kitchen = new Extra(this, 247, 32, 78, 64, "furniture", 155, 0);
		kitchen.register = 11;
		kitchen.bb = new BB(kitchen, 247, 67, 318, 78);
		entities.push(kitchen);
		extras.push(kitchen);
		holder.addChild(kitchen);

		var wardrobe = new Extra(this, 92, 32, 48, 64, "furniture", 0, 0);
		wardrobe.register = 11;		
		wardrobe.bb = new BB(wardrobe, 97, 70, 124, 78);
		entities.push(wardrobe);
		extras.push(wardrobe);
		holder.addChild(wardrobe);

		var bed = new Extra(this, 116, 104, 48, 32, "furniture", 24, 72);
		bed.register = 0;		
		bed.bb = new BB(bed, 119, 125, 155, 132);
		entities.push(bed);
		extras.push(bed);
		holder.addChild(bed);

		var bed2 = new Extra(this, 95, 125, 48, 32, "furniture", 24, 72);
		bed2.register = 1;
		bed2.bb = new BB(bed2, 98, 140, 133, 152);
		entities.push(bed2);
		extras.push(bed2);
		holder.addChild(bed2);

		var wardrobe2 = new Extra(this, 92, 162, 48, 64, "furniture", 0, 130);
		wardrobe2.register = 18;
		wardrobe2.bb = new BB(wardrobe2, 97, 200, 123, 209);
		entities.push(wardrobe2);
		extras.push(wardrobe2);
		holder.addChild(wardrobe2);

		var tv = new Extra(this, 172, 100, 48, 36, "furniture", 80, 70);
		tv.register = 5;		
		tv.bb = new BB(tv, 193, 121, 211, 133);
		entities.push(tv);
		extras.push(tv);
		holder.addChild(tv);

		var record = new Extra(this, 172, 186, 48, 36, "furniture", 80, 154);
		record.register = 3;
		record.bb = new BB(record, 194, 200, 207, 209);
		entities.push(record);
		extras.push(record);
		holder.addChild(record);

		var couch = new Extra(this, 220, 100, 48, 36, "furniture", 125, 70);
		couch.register = 5;
		couch.bb = new BB(couch, 233, 123, 264, 135);
		entities.push(couch);
		extras.push(couch);
		holder.addChild(couch);

		var couch1 = new Extra(this, 260, 142, 48, 48, "furniture", 170, 111);
		couch1.register = 5;
		couch1.bb = new BB(couch1, 270, 153, 284, 180);
		entities.push(couch1);
		extras.push(couch1);
		holder.addChild(couch1);

		hidingPlaces.push(new Vec2(112, 75));
		hidingPlaces.push(new Vec2(112, 200));
		hidingPlaces.push(new Vec2(310, 75));
		hidingPlaces.push(new Vec2(115, 150));
		hidingPlaces.push(new Vec2(138, 120));

		windows.push(new Vec2(145, 68));
		windows.push(new Vec2(222, 67));
	}

	public function addTeens(){
		var t0 = new Teen(this, 165, 285, "token");
		t0.portrait = 0;
		entities.push(t0);
		teens.push(t0);
		holder.addChild(t0);

		var t1 = new Teen(this, 170, 260, "todd");
		t1.portrait = 1;
		entities.push(t1);
		teens.push(t1);
		holder.addChild(t1);

		var t2 = new Teen(this, 170, 285, "roxanne");
		t2.portrait = 2;
		entities.push(t2);
		teens.push(t2);
		holder.addChild(t2);

		var t3 = new Teen(this, 165, 260, "jessica");
		t3.portrait = 3;
		entities.push(t3);
		teens.push(t3);
		holder.addChild(t3);

		order.push(t1);
		order.push(t2);
		order.push(t3);
		order.sort( function(a:Teen, b:Teen):Int
			{
			    return Std.int(Math.round(Math.random()*2-1));
			} );
		order.insert(0, t0);
	}

	public function addBlood(b:Blood){
		blood.push(b);
		entities.push(b);
		holder.addChild(b);
	}

	public function checkOrder(){
		var alive = false;
		var scared = true;
		for(teen in order){
			if(alive && teen.state == Teen.SCARED)
				return false;

			if(teen.health <= 0 && alive)
				return false;
			else if(teen.health > 0)
				alive = true;
		}

		if(alive == false) Main.instance.showScreen(Main.instance.winScreen);

		return true;
	}

	public function dump(){
		entities = [];
		extras = [];
		teens = [];
		blood = [];
		hidingPlaces = [];
		windows = [];
		order = [];
		rain = [];		
		removeEventListener(Event.ENTER_FRAME, update);

	}

	private function lightning(){
		weather.fillRect(weather.rect, 0xffffffff);
		if(rainDelay == 0) rainDelay = Std.int(200+Math.random()*400);
	}

	private function drawRain(){
		for(drop in rain){
			drop.update();
			GraphicsUtil.drawLine(weather, drop.x, drop.y, drop.x-3, drop.y+8, 0xff475b71);
		}
	}

}