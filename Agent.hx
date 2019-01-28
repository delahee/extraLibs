#if (flash&&(d1||d2))
using mt.gx.as.LibEx;
#end

class Agent {
	
	static var _UID : Int = 0;
	public var _id:Int = _UID++;
	
	public var 	name(default, set):String;
	public var  list : AgentList;

	public function new(?list) 				{ 
		if ( list != null ){
			this.list = list;
			list.add(this);
		}
	}
	
	public function update(dt:Float) 	{}
	public function dispose()			{
		if (list != null)
			list.remove(this);
	}
	
	function set_name(str)		{ this.name = str; return str; }//allow override
}

class VizAgent extends Agent{
	public var visible(default,set)	:	Bool = true;
	
	public function new(?list:AgentList) 				{ super(list);  }
	function set_visible(v) {
		return visible = v;
	}
}

class AnonAgent extends Agent {
	var cbk : Float -> Void;
	
	public function new(cbk,?list:AgentList) {
		super(list);
		this.cbk = cbk;
	}
	
	public override function update(dt:Float) {
		super.update(dt);
		if( null != cbk ) cbk( dt );
	}
	
	public override function dispose(){
		super.dispose();
		cbk = null;
	}
}

class DelayedAgent extends Agent {
	public var dur : Float = 0.0;
	var cbk : Void -> Void;
	
	public function new(cbk : Void -> Void, delayMs : Float,?list:AgentList) {
		super(list);
		this.cbk = cbk;
		this.dur = delayMs;
	}
	
	public override function update(dt:Float) {
		super.update(dt);
		if ( dur <= 0 && cbk != null) {
			cbk();
			cbk = null;
			dispose();
		}
		dur -= dt * 1000.0;
	}
	
	public override function dispose(){
		super.dispose();
		cbk = null;
	}
}
#if h3d
class UiAgent extends Agent {
	
	public var x(get,set) : Float;
	public var y(get,set) : Float;
	
	function get_x() 	return root.x;
	function set_x(v) 	return root.x = v;
	
	function get_y() 	return root.y;
	function set_y(v) 	return root.y = v;
	
	public var root : h2d.Sprite; //root is disposable
	
	public function new (?p,?list:AgentList) {
		super(list);
		root = new h2d.Sprite(p);
	}
	
	public function resize() {
		
	}
	
	public override function dispose() {
		super.dispose();
		if( root!=null) root.dispose();
		root = null;
	}
}
#end
#if h3d
class SpriteAgent extends Agent {
	var root : h2d.Sprite; //root is disposable
	public var visible(get, set):Bool; 
	
	inline function get_visible():Bool	 	return root == null ? false : root.visible;
	inline function set_visible(v):Bool 	return root == null ? v : (root.visible = v);
	
	public inline function toFront() root.toFront();
	public inline function toBack() root.toBack();
	public inline function findByName(n) return root.findByName(n);
	
	public inline function getRoot() return root;
	
	public function new( ?p:h2d.Sprite,?list:AgentList ) {
		super(list);
		root = new h2d.Sprite( p );
	}
	
	public override function dispose() { //end of the story 
		super.dispose();
		if( root!=null) root.dispose();
		root = null;
	}
}
#end

#if (flash&&(d1||d2))
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
#end

class AgentList {
	var repo : Stack<Agent>;
	
	public inline function new() 
		repo = new Stack<Agent>();
	
	public
	inline 
	function update(dt) 
		for ( a in repo.backWardIterator() )
			if (a != null) 
				a.update(dt);
			
	public var length(get, null):Int; 	function get_length() return repo.length;
	
	public inline function push(p) 		repo.push(p);
	public inline function add(p) 		repo.push(p);
	
	public 
	inline 
	function dispose() {
		for ( a in repo.backWardIterator() )
			a.dispose();
		repo.hardReset();
	}
	
	public inline function backWardIterator()  {
		return repo.backWardIterator();
	}
	
	public 
	inline 
	function has(v:Agent){
		return repo.indexOf(v) >= 0;
	}
	
	public 
	inline
	function remove(a:Agent) {
		return repo.remove(a);
	}
	
	public 
	inline 
	function clear() {
		repo.hardReset();
	}
	
	public 
	function findByName(name:String) {
		for ( a in repo.backWardIterator() )
			if ( a.name == name )
				return a;
		return null;
	}
	
	public 
	inline 
	function removeByName(name:String) {
		var elem = findByName(name);
		if ( elem == null ) return;
		
		repo.remove(elem);
	}
}

//make something after spin frames
class SpinAgent extends AnonAgent {
	var spinMax = 0;
	var spin = 0;
	public function new( spin,cbk:Float->Void,?dl:AgentList) {
		super(cbk);
		spinMax = spin;
		if(dl!=null) dl.add( this );
	}
	
	override function update(dt)
	{
		if ( spin++> spinMax) {
			super.update(dt);
			spin = 0;
		}
	}
}


//make something after spin_ms ms
class TimeSpinAgent extends AnonAgent {
	public var spinMax = 0.0;
	public var spin = 0.0;
	
	public function new( spin_ms:Float,cbk:Float->Void,?dl:AgentList) {
		super(cbk);
		spinMax = spin_ms;
		if(dl!=null) dl.add( this );
	}
	
	public function unsync() {
		spin = Math.random() * spinMax;
	}
	
	public function trigger(dt) {
		cbk(dt);
	}
	
	override function update(dt:Float) {
		spin += dt * 1000.0;
		if ( spin >= spinMax) {
			super.update(dt);
			spin = 0.0;
		}
	}
	
}

//make something after spin_ms ms
class TimerRatioAgent extends AnonAgent {
	public var duration = 0.0;
	public var current = 0.0;
	
	public var onEnd:Void->Void;
	public var onUpdate:Float->Void;
	
	public function new( duration:Float,cbk:Float->Void,?dl:AgentList) {
		super(cbk);
		this.duration = duration;
		current = 0.0;
		this.onUpdate = cbk;
		if(dl!=null) dl.add( this );
	}
	
	override function update(dt:Float) {
		if ( current > duration ) current = duration;
		onUpdate(current / duration);
		current += dt;
		if ( current > duration ){
			if(onEnd!=null) onEnd();
		}
	}
	
}

class OnceAgent extends AnonAgent {
	
	public var onEnd:Void->Void;
	public var onUpdate:Float->Void;
	
	public function new( cbk:Float->Void,?dl:AgentList) {
		super(cbk);
		this.onUpdate = cbk;
		if(dl!=null) dl.add( this );
	}
	
	override function update(dt:Float) {
		onUpdate(0.5);
		if(onEnd!=null) onEnd();
	}
	
}

