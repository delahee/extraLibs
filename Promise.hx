
#if flash @:native('˹_') #end
class Promise {
	var thens:Array<Dynamic->Dynamic> = [];
	var rejects:Array<Dynamic->Dynamic> = [];
	
	public var _succeeded = false;
	public var _failed = false;
	
	public var curSuccess : Dynamic = null;
	public var curFailure : Dynamic = null;
	
	public function then(f:Dynamic->Dynamic, ?r:Dynamic->Dynamic) : Promise {
		var f = f;
		var r = r;
		if ( _succeeded ) { 
			if ( f != null ) {
				try{
					curSuccess = f( curSuccess );
				}catch (d:Dynamic){
					_succeeded = false;
					_failed = true;
					curFailure = d;
					curFailure = f( curFailure );
				}
			}
		}
		else if ( _failed ){
			if ( r != null ) 
				curFailure = r( curFailure );
		}
		else {
			thens.push( f );
			if ( r != null) rejects.push(r);
		}
		return this;
	}
	
	public function after( f : Dynamic -> Dynamic ) : Promise {
		return then(f, f);
	}
	
	public static function getFailure( d : Dynamic ) : Promise{
		var p = new Promise();
		p.failed(d);
		return p;
	}
	
	public static function getSuccess( d : Dynamic ) : Promise{
		var p = new Promise();
		p.done(d);
		return p;
	}
	
	//what to do in case of failure
	public function reject(f:Dynamic->Dynamic) : Promise {
		if (_failed)
			curFailure = f( curFailure );
 		rejects.push( f );
		return this;
	}
	
	public inline function new() {}
	
	public inline function resolve(?d : Dynamic ) {
		return done(d);
	}
	
	public function done(?d : Dynamic ) : Promise {
		_failed = false;
		_succeeded = true;
		curSuccess = d;
		for (s in thens) {
			try{
				curSuccess = s(curSuccess);
			}
			catch ( d : Dynamic ){
				_failed = true;
				_succeeded = false;
				curFailure = d;
				for (s in rejects)
					curFailure = s(curFailure);
			}
		}
		thens = [];
		rejects = [];
		return this;
	}
	
	/**
	 * declare failure of this one
	 */
	public function failed( ?d : Dynamic ) : Promise {
		_succeeded = false;
		_failed = true;
		curFailure = d;
		for (s in rejects)
			curFailure = s(curFailure);
		thens = [];
		rejects = [];
		return this;
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