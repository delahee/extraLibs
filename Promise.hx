
class Promise {
	var thens:Array<Dynamic->Dynamic> = [];
	var rejects:Array<Dynamic->Dynamic> = [];
	
	public inline function then(f:Dynamic->Dynamic, ?r:Dynamic->Dynamic){
 		thens.push( f );
		if ( r != null) rejects.push(r);
	}
	
	public inline function reject(f:Dynamic->Dynamic) 		rejects.push( f );
	
	public inline function new() {}
	
	public function done(d : Dynamic ) {
		for (s in thens) {
			d = s(d);
		}
		thens = [];
		rejects = [];
	}
	
	public function failed( d : Dynamic ) {
		for (s in rejects)
			d = s(d);
		thens = [];
		rejects = [];
	}
}