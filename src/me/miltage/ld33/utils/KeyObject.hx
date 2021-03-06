package me.miltage.ld33.utils;

import openfl.display.Stage;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

class KeyObject {

	private static var stage:Stage;
	private static var keysDown:Dynamic;
	private static var nextStates:Dynamic;

	public static var UP:UInt = Keyboard.UP;
	public static var DOWN:UInt = Keyboard.DOWN;
	public static var LEFT:UInt = Keyboard.LEFT;
	public static var RIGHT:UInt = Keyboard.RIGHT;
	public static var W:UInt = Keyboard.W;
	public static var A:UInt = Keyboard.A;
	public static var S:UInt = Keyboard.S;
	public static var D:UInt = Keyboard.D;
	public static var Z:UInt = Keyboard.Z;
	public static var X:UInt = Keyboard.X;
	public static var C:UInt = Keyboard.C;
	public static var SPACE:UInt = Keyboard.SPACE;

	public function new(stage:Stage) {
		construct(stage);
	}
	
	public function construct(stage:Stage) {
		KeyObject.stage = stage;
		keysDown = new Array();
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
		stage.addEventListener(KeyboardEvent.KEY_UP, keyReleased);
	}

	public function isDown(keyCode:UInt):Bool {
		return keysDown[keyCode];
	}

	private function keyPressed(evt:KeyboardEvent) {
		keysDown[evt.keyCode] = true;
	}
	
	private function keyReleased(evt:KeyboardEvent) {
		keysDown[evt.keyCode] = false;
	}
}