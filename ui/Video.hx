package ui;

#if flash
import flash.events.StageVideoEvent;
#end

import flash.events.NetStatusEvent;
import flash.events.AsyncErrorEvent;

import flash.events.SecurityErrorEvent;
import flash.net.NetConnection;
import flash.net.NetStream;

import Agent;

typedef VideoConf = {
	rect:flash.geom.Rectangle,
	smoothing:Bool, 
	autostart:Bool, 
	enableSkip:Bool,
	?forceSoftware:Bool,
	?bufferTimeS:Float,
	?noBuffer:Bool
};

#if !flash
class Video extends Agent {
	public var onUpdate : Signal = new Signal();
	public var onFinished : Signal = new Signal();
	public var onSkip : Signal = new Signal();
	public var onDispose : Signal = new Signal();
	public var onVideoCanStart : Signal = new Signal();
	public var onError : Signal = new Signal();
	
	public function new(url:String, conf:VideoConf) {
		super();
	}
	
	public function skip() 					{
		if ( onSkip.getHandlerCount() == 0)
			onFinished.trigger();
		else {
			onSkip.trigger();
		}
	}
}
#else 
class Video extends Agent {

	public var onUpdate : Signal = new Signal();
	public var onFinished : Signal = new Signal();
	public var onSkip : Signal = new Signal();
	public var onDispose : Signal = new Signal();
	public var onVideoCanStart : Signal = new Signal();
	public var onError : Signal = new Signal();
	
	public var url 	: String;
	var nc 		: flash.net.NetConnection = null;
	var stream 	: flash.net.NetStream = null;
	var sv 		: flash.media.StageVideo = null;
	var vd 		: flash.media.Video = null;
	
	public var conf : VideoConf;
	public var volume(default,set):Float = 1.0;
	var rect : flash.geom.Rectangle; function get_rect() return conf.rect;
	
	var sub : AgentList = new AgentList();
	var isStageVideo = false;
	var root : flash.display.Sprite;
	
	public static var instances = 0;

	var requestedParent : flash.display.DisplayObjectContainer;
	var requestedParentIndex = 0;
	
	public function new(url:String, conf:VideoConf) {
		super();
		this.conf = Reflect.copy(conf);
		rect = conf.rect.clone();
		//trace("streaming " + url);
		this.url = url;
		nc = new NetConnection(); 
		nc.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
		nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
		nc.connect(null);
		
		var ns = stream = new NetStream(nc); 
		ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler); 
		ns.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
		ns.client = this;
		
		var stage = flash.Lib.current.stage;
		if (stage.stageVideos.length <= 0) trace("no hw contexts");
			
		var useClassical = false;
		if ( conf.forceSoftware == true )
			useClassical = true;
			
		if( conf.noBuffer != true ){
			if ( conf.bufferTimeS != null)
				ns.bufferTime = conf.bufferTimeS;
			else 
				ns.bufferTime = 2.0;
		}
				
		if ( useClassical || stage.stageVideos.length == 0) {
			var v = vd = new flash.media.Video( Math.round(conf.rect.width), Math.round(conf.rect.height));
			v.attachNetStream( ns );
			v.smoothing = conf.smoothing;
			vd.x = conf.rect.x;
			vd.y = conf.rect.y;
			isStageVideo = false;
		}
		else {
			if ( sv == null ) {
				sv = stage.stageVideos[0];
				sv.addEventListener(StageVideoEvent.RENDER_STATE, stageVideoStateChange);
				sv.addEventListener(StageVideoEvent.RENDER_STATUS_UNAVAILABLE, stageVideoStateChange);
				sv.viewPort = new flash.geom.Rectangle( conf.rect.x, conf.rect.y, conf.rect.width, conf.rect.height);
			}
			sv.attachNetStream( ns );
			onDispose.addOnce(function() {
				var lsv : flash.media.StageVideo = cast stage.stageVideos[0];
				lsv.removeEventListener(StageVideoEvent.RENDER_STATE, stageVideoStateChange);	
				lsv.removeEventListener(StageVideoEvent.RENDER_STATUS_UNAVAILABLE, stageVideoStateChange);	
			});
			isStageVideo = true;
		}
		
		if ( conf.enableSkip ) {
			var g = new flash.display.Sprite();
			var gfx = g.graphics;
			gfx.beginFill(0, 0);
			gfx.drawRect( 0, 0, flash.Lib.current.stage.stageWidth, flash.Lib.current.stage.stageHeight );
			gfx.endFill;
			g.mouseEnabled = true;
			hxd.System.setCursor( Hide );
			function a(e) {
				flash.Lib.current.removeChild( g );
				skip();
				g.removeEventListener( flash.events.MouseEvent.CLICK, a);
				Lib.gc();
			}
			g.addEventListener( flash.events.MouseEvent.CLICK, a );
			flash.Lib.current.addChild( g );
			onDispose.add( function() {
				if( g == null ) return;
				if( g.parent !=null ) flash.Lib.current.removeChild( g );
				g.removeEventListener( flash.events.MouseEvent.CLICK, a);
				hxd.System.setCursor( Default );
			});
		}
		
		if ( conf.autostart ) start();
		else {
			new DelayedAgent(function(){
				onVideoCanStart.trigger();
			}, 100,sub);
		}
		instances++;
		
		events();
	}
	
	function events() {
		flash.Lib.current.addEventListener( flash.events.Event.RESIZE, onResize );
		onDispose.add( function() flash.Lib.current.removeEventListener( flash.events.Event.RESIZE, onResize ) );
	}
	
	function onResize(e) {
		
	}
	
	public function attachTo( p : flash.display.DisplayObjectContainer ) {
		requestedParent = p;
		requestedParentIndex = p.numChildren;
		
		if ( vd != null) {
			if( vd.parent!=null)
				vd.parent.removeChild( vd );
			p.addChild(vd);
		}
	}
	
	
	public function getTime() : Float {
		return stream.time;
	}
	
	public function getProgress() : Float {
		if ( stream == null ) return 0.0;
		return stream.time / durationS;
	}
	
	
	public static function text(txt:String) : flash.text.TextField {
		var t = new flash.text.TextField();
		t.text = txt;
		var tf = new flash.text.TextFormat("arial",24,0xcdcdcd);
		t.setTextFormat( t.defaultTextFormat = tf );
		
		t.multiline = false;
		t.wordWrap = false;
		t.selectable = false;
		t.mouseEnabled = false;
		t.background = false;
		
		t.width = t.textWidth + 5;
		t.height = t.textHeight + 5;
		return t;
	}
	
	public function defaultOnError(?msg:String="") {
		if ( root == null){
			root = new flash.display.Sprite();
			flash.Lib.current.addChild(root);
		}
			
		var t = text( (msg==null||msg.length==0 ? "": ("Err:"+msg+"\n") )+ "Cannot play stream :" + url );
		t.x = rect.x;
		t.y = rect.y;
		root.addChild(t);
	}
	
	function error(?msg:String="") {
		//trace("vid:err handler");
		if( onError.getHandlerCount() == 0 )
			defaultOnError(msg);
		else 
			onError.trigger();
	}
	
	public function restart() {
		try{
			stream.seek(0); 
		} catch (d:Dynamic ) {
			//trace("err: can' start");
			error();
		}
	}
	
	public function start() {
		if ( disposed ) return;
		
		try{
			for ( s in flash.Lib.current.stage.stage3Ds )
				s.visible = false;
			stream.play(url); 
			if ( vd != null) {
				if( requestedParent == null)
					flash.Lib.current.addChild(vd);
				else 
					requestedParent.addChildAt( vd,requestedParentIndex );
			}
			this.volume = volume;
		}
		catch (d:Dynamic ) {
			//trace("err: can' start");
			error();
		}
	}
	
	public function pause() {
		if( stream!=null) stream.pause();
	}
	
	public function stop() {
		if( stream!=null) stream.pause();
		for ( s in flash.Lib.current.stage.stage3Ds )
			s.visible = true;
	}
	
	function netStatusHandler(event:NetStatusEvent)	{ 
		//trace("nsh:"+Reflect.fields(event.info));
		//trace("nsh.code:" + (event.info.code) );
		switch(event.info.code) {
			default: 
				trace("problem:" + event.info.code);
			case "NetStream.Buffer.Empty":					onFinished.trigger();
			case "NetStream.Buffer.Full":					//good problem!
			case "NetStream.Buffer.Start":					//good problem!
			case "NetConnection.Connect.Success":
			case "NetStream.Play.FileStructureInvalid":		error("Invalid Structure");
			case "NetStream.Play.NoSupportedTrackFound":	error("Invalid Track Structure");
			case "NetStream.Play.StreamNotFound":			error();
		}
	} 
	
	function securityErrorHandler(event) {
        //trace("securityErrorHandler: " + event);	
		error();
	}
	
	function asyncErrorHandler(event){ 
		// ignore error 
		trace("aeh:" + event);
		error();
	}
	
	var durationS:Float;
	function onMetaData(infoObject:Dynamic) {
		//trace("onMetaData fired " + infoObject); 
		durationS = infoObject.duration;
	}
	function onXMPData(infoObject) 	{
		//trace("onXMPData Fired" + infoObject); 
	}
	
	function stageVideoStateChange(e) 		{
		//trace("svsc:"+e);
	}
	function stageVideoStateChangeUnav(e) 	{
		//trace("svscu:"+e);
	}
	function onCuePoint() 					{
		//trace("onCuePoint fired "); 
	}
	
    function onImageData() {}
	
	public function skip() 					{
		if ( onSkip.getHandlerCount() == 0)
			onFinished.trigger();
		else {
			onSkip.trigger();
		}
	}
    
    function onPlayStatus(event:Dynamic) {
		//trace("ops : " + event);
		switch( event.code ) {
			case "NetStream.Play.Complete":
				onFinished.trigger();
		}
	}
    function onTextData(){}

	public var disposed = false;
	public override function dispose() {
		if (disposed)
			return;
		disposed = true;
		
		for ( s in flash.Lib.current.stage.stage3Ds )
			s.visible = true;
			
		//trace("disposing");
		super.dispose();
		
		if ( stream != null) {
			stream.removeEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler); 
			stream.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler); 
			stream.close();
		}
		
		onDispose.trigger();
		
		if ( vd != null) {
			if ( vd.parent != null) vd.parent.removeChild(vd);
		}
		
		if ( nc != null) {
			nc.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			nc.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			try {
				nc.close();
			}catch (d:Dynamic) {
				trace("close failed " + d);
			}
			nc = null;
		}
		
		if ( stream != null) {
			try {
				stream.dispose();
			}
			catch (d:Dynamic) {
				trace("dispose failed " + d);
			}
			stream = null;
		}
		
		if ( sv != null) {
			try {
				sv.attachNetStream(null);
			}
			catch (d:Dynamic) {
				trace("netstream cancel failed "+d);
			}
			//trace("sv netstream detached");
			sv = null;
		}
		
		if ( vd != null) {
			try {
				vd.attachNetStream(null);
			}
			catch (d:Dynamic) {
				trace("netstream cancel failed "+d);
			}
			//trace("vd netstream detached");
			vd = null;
		}
		
		if ( root != null){
			if ( root.parent != null) root.parent.removeChild(root);
			root = null;
		}
		
		instances--;
	}
	
	public var time = 0.0;
	public override function update(dt) {
		super.update(dt);
		
		time += dt;
		
		onUpdate.trigger();
		#if h3d
		var k = App.me.k;
		if( conf.enableSkip)
			if ( k.onDown( Keys.ESCAPE) || k.onDown( Keys.ENTER))  
				onFinished.trigger();
		#end
		sub.update( dt );
	}
	
	public function set_volume(f:Float) {
		volume = f;
		if ( stream != null ) {
			var sf = new flash.media.SoundTransform(f);
			stream.soundTransform = sf;
		}
		return f;
	}
}
#end