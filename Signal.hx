
class Signal {
	var signals:Array<Void->Void> = [];
	var signalsOnce:Array<Void->Void> = [];
	public inline function add(f:Void->Void) 		signals.push( f );
	public inline function addOnce(f:Void->Void) 	signalsOnce.push( f );
	public inline function new() {}
	public function trigger() {
		for (s in signals) s();
		for (s in signalsOnce) s();
		signalsOnce = [];
	}
}