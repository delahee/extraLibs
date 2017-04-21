
class Pair<A,B> {
	public var fst : A;
	public var sec : B;

	public inline function new( a : A,b :B) {
		fst = a;
		sec = b;
	}
	
	public inline function toString() return 'first:$fst second:$sec';
}