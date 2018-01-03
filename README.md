# starling


starling 基于ActionScrpit3 GPU 2D渲染引擎，对starling1.3版本BUG修复与理解注释

原版本：

https://github.com/Gamua/Starling-Framework/releases/tag/v1.3

或

Starling-Framework-1.3.tar.gz

修复文件有：

	com/adobe/utils/AGALMiniAssembler.as
	starling/animation/DelayedCall.as
	starling/animation/IAnimatable.as
	starling/animation/Juggler.as
	starling/animation/Transitions.as
	starling/animation/Tween.as
	starling/display/DisplayObject.as
	starling/display/DisplayObjectContainer.as
	starling/display/Image.as
	starling/display/MovieClip.as
	starling/display/Quad.as
	starling/events/EnterFrameEvent.as
	starling/events/Event.as
	starling/events/EventDispatcher.as
	starling/events/ResizeEvent.as
	starling/textures/AtfData.as
	starling/textures/TextureAtlas.as
	starling/utils/VertexData.as
	starling/utils/formatString.as

核心思路与原则：

	1.动画原则：（终点-起始点）*（当前时间/总时间），无误差
	2.事件原则：只要事件触发，如果改变，不会减少收到的事件的对象长度
	3.如果某个时间轴处理方法包含另一个时间轴处理方法，则按照从子类到父类的方式依次调用，例如：动画>人物>地图，可以使用多个时间轴管理器来完成
	原因：如果父类调用的子类改变状态，子类状态清零，这时子类再被调用时，就走了一个帧的时间，导致时间缩短了，虽然这个影响甚微，但是还是得注意
	4.时间轴原则：如果这个时间轴的回调，修改了马上要被回调另一个时间轴，则被修改的时间轴，这次处理会被改变，跟事件原则正好相反
	5.资源的原则：如果加载一个资源组，只有在该资源组的每一个小资源，不被使用的时候，这个资源组才可以被回收
	6.资源的原则：资源组派生出来的资源数组则不同，当资源数组被注销时，里面的每个小资源减1，相应的资源组减n个小资源
	7.每个类，尽量多使用静态的帮助类，已减少垃圾回收。
	8.如果类使用频繁，最好这个类增加对象池，以减少垃圾回收。
	9.如果这个方法返回一个对象，最好把这个方法传入相应的对象，等于空，在创建新对象，不得空则用传进来的对象，这样可以更灵活的
	使用帮助类，来优化程序。