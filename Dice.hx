
class Dice {
	
	public static inline function roll(min :Int,max:Int  ) : Int {
		var v = Std.random( max - min +1 ) + min;
		return v;
	}
	
	public static inline function percent( thresh : Float ) : Bool 	{
		if ( thresh <= 0.0001 )
			return false;
		else {
			var r = rollF( 1, 100);
			return(r <= thresh);
		}
	}
	
	public static inline function toss() 
		return Dice.roll( 0, 1) == 0;

	public static inline 
	function rollF( min : Float = 0.0, ?max:Float = 1.0) : Float
	{
		var f = Math.random() * (max - min) + min;
		
		
		return  f;
	}
	
	public static inline function angle() 				return rollF(0, Math.PI * 2.0 );
	public static inline function sign() 				return toss()?1.0: -1.0;
}