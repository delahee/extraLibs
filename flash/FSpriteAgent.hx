using mt.gx.as.LibEx;

class FSpriteAgent extends Agent {
	var root : flash.display.Sprite; //root is disposable
	var visible(get, set):Bool; 
	
	inline function get_visible():Bool	 	return root.visible;
	inline function set_visible(v):Bool 	return root.visible = v;
	
	public inline function toFront() 			root.toFront();
	public inline function toBack() 			root.toBack();
	public inline function getChildByName(n) 	return root.getChildByName(n);
	
	public inline function getRoot() return root;
	
	public function new( ?p:flash.display.Sprite ) {
		super();
		root = new flash.display.Sprite();
		if ( p != null) p.addChild(root);
	}
	
	public inline function addChild(c) 			root.addChild(c);
	
	public override function dispose() { //end of the story 
		super.dispose();
		root = null;
	}
}
