package ui;

import flash.events.NetStatusEvent;
import flash.events.AsyncErrorEvent;
import flash.events.StageVideoEvent;
import flash.events.SecurityErrorEvent;
import flash.net.NetConnection;
import flash.net.NetStream;

import Agent;

typedef VideoConf = {
	rect:flash.geom.Rectangle,
	smoothing:Bool, 
	autostart:Bool, 
	enableSkip:Bool,
	?forceSoftware:Bool
};
class Video extends Agent {

	var url 	: String;
	var nc 		: flash.net.NetConnection = null;
	var stream 	: flash.net.NetStream = null;
	var sv 		: flash.media.StageVideo = null;
	var vd 		: flash.media.Video = null;
	
	public var onFinished : Signal = new Signal();
	public var onDispose : Signal = new Signal();
	public var onVideoCanStart : Signal = new Signal();
	
	public var conf : VideoConf;
	var rect : flash.geom.Rectangle; function get_rect() return conf.rect;
	
	var sub : AgentList = new AgentList();
	var isStageVideo = false;
	var root : flash.display.Sprite;
	
	public function new(url:String, conf:VideoConf) {
		super();
		this.conf = Reflect.copy(conf);
		rect = conf.rect.clone();
		trace("streaming " + url);
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
			ns.bufferTime = 2.0;
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
			g.buttonMode = g.mouseEnabled = true;
			function a(e) {
				flash.Lib.current.removeChild( g );
				skip();
				g.removeEventListener( flash.events.MouseEvent.CLICK, a);
				Lib.gc();
			}
			g.addEventListener( flash.events.MouseEvent.CLICK, a );
			flash.Lib.current.addChild( g );
		}
		
		if ( conf.autostart ) start();
		else {
			new DelayedAgent(function(){
				onVideoCanStart.trigger();
			}, 100,sub);
		}
		
		
	}
	
	public static function text(txt:String) : flash.text.TextField {
		var t = new flash.text.TextField();
		t.text = txt;
		var tf = new flash.text.TextFormat("arial",32,0xcdcdcd);
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
	
	function error() {
		if ( root == null){
			root = new flash.display.Sprite();
			flash.Lib.current.addChild(root);
		}
			
		var t = text( "Cannot play stream :" + url );
		t.x = rect.x;
		t.y = rect.y;
		root.addChild(t);
	}
	
	public function start() {
		try{
			for ( s in flash.Lib.current.stage.stage3Ds )
				s.visible = false;
			stream.play(url); 
			if ( vd != null)
				flash.Lib.current.addChild(vd);
		}
		catch (d:Dynamic ) {
			error();
		}
	}
	
	public function stop() {
		stream.pause();
		for ( s in flash.Lib.current.stage.stage3Ds )
			s.visible = true;
	}
	
	function netStatusHandler(event:NetStatusEvent)	{ 
		trace("nsh:"+Reflect.fields(event.info));
		trace("nsh.code:" + (event.info.code) );
		switch(event.info.code) {
			default: trace("problem:" + event.info.code);
			case "NetConnection.Connect.Success":
			case "NetStream.Play.StreamNotFound":
				error();
		}
	} 
	
	function securityErrorHandler(event) {
        trace("securityErrorHandler: " + event);	
	}
	
	function asyncErrorHandler(event){ 
		// ignore error 
		trace("aeh:"+event);
	}
	
	function onMetaData(infoObject) trace("onMetaData fired " + infoObject); 
	function onXMPData(infoObject) 	trace("onXMPData Fired" + infoObject); 
	
	function stageVideoStateChange(e) 		trace("svsc:"+e);
	function stageVideoStateChangeUnav(e) 	trace("svscu:"+e);
	function onCuePoint() 					trace("onCuePoint fired "); 
	
    function onImageData() {}
	
	public function skip() 					onFinished.trigger();
    
    function onPlayStatus(event:Dynamic) {
		trace("ops : " + event);
		switch( event.code ) {
			case "NetStream.Play.Complete":
				onFinished.trigger();
		}
	}
    function onTextData(){}

	public override function dispose() {
		trace("disposing");
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
			nc.close();
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
			trace("sv netstream detached");
			sv = null;
		}
		
		if ( vd != null) {
			try {
				vd.attachNetStream(null);
			}
			catch (d:Dynamic) {
				trace("netstream cancel failed "+d);
			}
			trace("vd netstream detached");
			vd = null;
		}
		
		if ( root != null){
			if ( root.parent != null) root.parent.removeChild(root);
			root = null;
		}
		trace("disposed");
	}
	
	public override function update(dt) {
		super.update(dt);
		#if h3d
		var k = App.me.k;
		if( conf.enableSkip)
			if ( k.onDown( Keys.ESCAPE) || k.onDown( Keys.ENTER))  
				onFinished.trigger();
		#end
		sub.update( dt );
	}
}