
class Signal {
	var signals:Array<Void->Void> = [];
	var signalsOnce:Array<Void->Void> = [];
	
	public var isTriggerring = false; 
	
	public inline function add(f:Void->Void) 		signals.push( f );
	public inline function addOnce(f:Void->Void) 	signalsOnce.push( f );
	
	public inline function new() {}
	public function trigger() {
		isTriggerring = true;
		for (s in signals) s();
		
		if( signalsOnce.length > 0 ){
			for (s in signalsOnce) s();
			signalsOnce = [];
		}
		isTriggerring = false;
	}
	
	public inline function remove(f) {
		signals.remove(f);
		signalsOnce.remove(f);
	}
	
	public inline function dispose() { 
		signals = [];
		signalsOnce = [];
	}
	
	public inline function reset() { 
		signals = [];
		signalsOnce = [];
	}
	
	public function getHandlerCount() return signals.length + signalsOnce.length;
	
	public inline function clone(){
		var ns = new Signal();
		for ( s in signals) ns.add(s);
		for ( s in signalsOnce) ns.addOnce(s);
		return ns;
	}
	
	public inline function inject(e:Signal){
		for ( s in e.signals) add(s);
		for ( s in e.signalsOnce) addOnce(s);
	}
}