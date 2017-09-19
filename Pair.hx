
class Pair<A,B> {
	public var fst : A;
	public var sec : B;

	public inline function new( a : A,b :B) {
		fst = a;
		sec = b;
	}
	
	public inline function toString() return 'first:$fst second:$sec';
}

@:generic
class Triple<A,B,C> {
	public var fst : A;
	public var sec : B;
	public var thi : C;

	public inline function new( a : A,b :B,c:C) {
		fst = a;
		sec = b;
		thi = c;
	}
}

@:generic
class Quad<A,B,C,D> {
	public var fst : A;
	public var sec : B;
	public var thi : C;
	public var qua : D;

	public inline function new( a : A,b :B,c:C,d:D) {
		fst = a;
		sec = b;
		thi = c;
		qua = d;
	}
}