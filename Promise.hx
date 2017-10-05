
class Promise {
	var thens:Array<Dynamic->Dynamic> = [];
	var rejects:Array<Dynamic->Dynamic> = [];
	
	public var _succeeded = false;
	public var _failed = false;
	
	public var curSuccess : Dynamic = null;
	public var curFailure : Dynamic = null;
	
	public inline function then(f:Dynamic->Dynamic, ?r:Dynamic->Dynamic){
		if ( _succeeded ) { 
			if ( f != null ) 
				curFailure = f( curFailure );
		}
		else if ( _failed ){
			if ( r != null ) 
				curFailure = r( curFailure );
		}
		else {
			thens.push( f );
			if ( r != null) rejects.push(r);
		}
	}
	
	public inline function reject(f:Dynamic->Dynamic){
		if (_failed){
			curFailure = f( curFailure );
		}
 		rejects.push( f );
	}
	
	public inline function new() {}
	
	public inline function resolve(?d : Dynamic ) {
		done(d);
	}
	
	public function done(?d : Dynamic ) {
		_succeeded = true;
		curSuccess = d;
		for (s in thens) {
			curSuccess = s(curSuccess);
		}
		thens = [];
		rejects = [];
		return curSuccess;
	}
	
	public function failed( ?d : Dynamic ) {
		_failed = true;
		curFailure = d;
		for (s in rejects)
			curFailure = s(curFailure);
		thens = [];
		rejects = [];
		return curFailure;
	}
	
	public function chain( p : Promise ) : Promise{
		p.then( done, failed );
		return this;
	}
	
	public static function test(){
		var p = new Promise();
		
		var otherP = new Promise();
		otherP.then( function(res){
			trace("chained done:"+res);
			return res;
		}, function(res){
			trace("chained err: "+res);
			return res;
		});
		
		otherP.chain( p );//alias p.then( other.done, other.failed )
		
		p.failed("err");
	}
}