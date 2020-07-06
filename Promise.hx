
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
	
	public function isSettled(){
		return _succeeded || _failed;
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
	//public function reject(f:Dynamic->Dynamic) : Promise {
		//if ( !Reflect.isFunction(f)){
			//#if debug
			//trace("ALARM reject process is not a function...");
			//#end
			//return this;
		//}
		//if (_failed)
			//curFailure = f( curFailure );
 		//rejects.push( f );
		//return this;
	//}
	public function reject(e:Dynamic) : Promise {
		return failed(e);
	}
	
	public function catchError(f:Dynamic->Dynamic) : Promise {
		if ( !Reflect.isFunction(f)){
			#if debug
			trace("ALARM catchError process is not a function...");
			#end
			return this;
		}
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
				#if debug
				trace("exception popped in then execution");
				#end
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
	
	public function finally( cbk : Void->Void){
		then(function(res){
			cbk();
			return res;
		}, function(err){
			cbk();
			return err;
		});
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
	
	public static function all( a:Array < Promise >  ) : Promise{
		var res = new Promise();
		var nb = 0;
		var values = [];
		function afterAll(val){
			nb++;
			values.push(val);
			if ( nb == a.length ){
				res.resolve(values);
			}
			return val;
		}
		
		function afterFail(err){
			res.failed( err );
			return err;
		}
		
		for ( p in a ){
			p.then( afterAll, afterFail );
		}
		return res;
	}
}