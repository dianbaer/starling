// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.events
{
    import flash.utils.Dictionary;
    
    import starling.core.starling_internal;
    import starling.display.DisplayObject;
    
    use namespace starling_internal;
    
    /** xp已看完，这个类重中之重就是回调之后，不能影响这次循环的调用，一切都有一个衡量点，就是如果注册了这个时间，并且触发时，除非是被阻止冒泡，不能阻止事件触发
	 * 比较重要的几点，如果事件触发了，接受这个事件的对象无法改变自身这一次的监听状态例如 a对象监听函数有b和c，b先收到，在这一次b里面移除c的监听，并不能阻止c收到这次事件
	 * 如果想阻止，可以再b里面把stopsImmediatePropagation设置为true
	 * 接受这个事件的对象可以移除他的上一级的监听，使之无法收到事件（这种做法不合理，本来就不能做）
	 * 如果接受这个事件对象，离开了自己的父类，也不能阻止父类这一次收到这个事件
	 * The EventDispatcher class is the base class for all classes that dispatch events. 
     *  This is the Starling version of the Flash class with the same name. 
     *  
     *  <p>The event mechanism is a key feature of Starling's architecture. Objects can communicate 
     *  with each other through events. Compared the the Flash event system, Starling's event system
     *  was simplified. The main difference is that Starling events have no "Capture" phase.
     *  They are simply dispatched at the target and may optionally bubble up. They cannot move 
     *  in the opposite direction.</p>  
     *  
     *  <p>As in the conventional Flash classes, display objects inherit from EventDispatcher 
     *  and can thus dispatch events. Beware, though, that the Starling event classes are 
     *  <em>not compatible with Flash events:</em> Starling display objects dispatch 
     *  Starling events, which will bubble along Starling display objects - but they cannot 
     *  dispatch Flash events or bubble along Flash display objects.</p>
     *  
     *  @see Event
     *  @see starling.display.DisplayObject DisplayObject
     */
    public class EventDispatcher
    {
        private var mEventListeners:Dictionary;
        
        /** Helper object. */
        private static var sBubbleChains:Array = [];
        
        /** Creates an EventDispatcher. */
        public function EventDispatcher()
        {  }
        
        /** Registers an event listener at a certain object. */
		/** xp添加监听,同一个函数只能添加一种类型的监听，多余的忽略，在监听的时候动态的创建，节省资源（无回调） **/
        public function addEventListener(type:String, listener:Function):void
        {
            if (mEventListeners == null)
                mEventListeners = new Dictionary();
            
            var listeners:Vector.<Function> = mEventListeners[type] as Vector.<Function>;
            if (listeners == null)
                mEventListeners[type] = new <Function>[listener];
            else if (listeners.indexOf(listener) == -1) // check for duplicates
                listeners.push(listener);
        }
        
        /** Removes an event listener from the object. */
		/** xp移除监听，这里面临时创建了一个数组，存还需要在监听的函数，这里能创建大量的临时数组，这是有意义的，因为回调的时候可能会删除事件，这个删除事件，不能影响这一次的遍历（无回调）**/
		/*
        public function removeEventListener(type:String, listener:Function):void
        {
            if (mEventListeners)
            {
                var listeners:Vector.<Function> = mEventListeners[type] as Vector.<Function>;
                if (listeners)
                {
                    var numListeners:int = listeners.length;
                    var remainingListeners:Vector.<Function> = new <Function>[];
                    
                    for (var i:int=0; i<numListeners; ++i)
					{
                        var otherListener:Function = listeners[i];
                        if (otherListener != listener) remainingListeners.push(otherListener);
                    }
                    
                    mEventListeners[type] = remainingListeners;
                }
            }
        }
		*/
        public function removeEventListener(type:String, listener:Function):void
        {
            if (mEventListeners)
            {
                var listeners:Vector.<Function> = mEventListeners[type] as Vector.<Function>;
                var numListeners:int = listeners ? listeners.length : 0;

                if (numListeners > 0)
                {
                    // we must not modify the original vector, but work on a copy.
                    // (see comment in 'invokeEvent')

                    var index:int = 0;
                    var restListeners:Vector.<Function> = new Vector.<Function>(numListeners-1);

                    for (var i:int=0; i<numListeners; ++i)
                    {
                        var otherListener:Function = listeners[i];
                        if (otherListener != listener) restListeners[int(index++)] = otherListener;
                    }

                    mEventListeners[type] = restListeners;
                }
            }
        }
        /** Removes all event listeners with a certain type, or all of them if type is null. 
         *  Be careful when removing all event listeners: you never know who else was listening. */
		/** xp移除这个类型的所有监听，如果不传类型，就移除所有类型的监听（无回调）**/
        public function removeEventListeners(type:String=null):void
        {
            if (type && mEventListeners)
                delete mEventListeners[type];
            else
                mEventListeners = null;
        }
        
        /** Dispatches an event to all objects that have registered listeners for its type. 
         *  If an event with enabled 'bubble' property is dispatched to a display object, it will 
         *  travel up along the line of parents, until it either hits the root object or someone
         *  stops its propagation manually. */
		/** xp如果不冒泡并且 （事件字典为空或者字典里没有这个事件）就不发事件，这样提高效率
		 * **/
        public function dispatchEvent(event:Event):void
        {
            var bubbles:Boolean = event.bubbles;
            
            if (!bubbles && (mEventListeners == null || !(event.type in mEventListeners)))
                return; // no need to do anything
            
            // we save the current target and restore it later;
            // this allows users to re-dispatch events without creating a clone.
            
			//xp存这个事件最开始设定的目标，执行完毕之后在还原，一般情况下这个目标肯定是空，除非用户自己设定了目标
            var previousTarget:EventDispatcher = event.target;
			//xp设置目标
            event.setTarget(this);
            //xp只有设置冒泡，并且这个目标是显示对象，才去走冒泡逻辑，不然不走，提高效率
            if (bubbles && this is DisplayObject) bubbleEvent(event);
            else                                  invokeEvent(event);
            
            if (previousTarget) event.setTarget(previousTarget);
        }
        
        /** @private
         *  Invokes an event on the current object. This method does not do any bubbling, nor
         *  does it back-up and restore the previous target on the event. The 'dispatchEvent' 
         *  method uses this method internally. */
		/**xp 这里的回调，可能增加事件无所谓，因为加的事件在长度之外，也可能删除事件，删除事件已经解决了这个问题，创建新的数组**/
        internal function invokeEvent(event:Event):Boolean
        {
            var listeners:Vector.<Function> = mEventListeners ?
                mEventListeners[event.type] as Vector.<Function> : null;
            var numListeners:int = listeners == null ? 0 : listeners.length;
            
            if (numListeners)
            {
				//xp这个this，并不是发事件的那个显示对象，谁调的，就是谁
                event.setCurrentTarget(this);
                
                // we can enumerate directly over the vector, because:
                // when somebody modifies the list while we're looping, "addEventListener" is not
                // problematic, and "removeEventListener" will create a new Vector, anyway.
                
                for (var i:int=0; i<numListeners; ++i)
                {
                    var listener:Function = listeners[i] as Function;
                    var numArgs:int = listener.length;
                    
                    if (numArgs == 0) listener();
                    else if (numArgs == 1) listener(event);
                    else listener(event, event.data);
                    
                    if (event.stopsImmediatePropagation){
						//xp如果这个数组被换掉了，就把这个数组置空把，没用了（回来测试下）
						if(!mEventListeners || listeners !== mEventListeners[event.type]){
							listeners.length = 0;
						}
                        return true;
					}
                }
				//xp如果这个数组被换掉了，就把这个数组置空把，没用了（回来测试下）
                if(!mEventListeners || listeners !== mEventListeners[event.type]){
					listeners.length = 0;
				}
                return event.stopsPropagation;
            }
            else
            {
                return false;
            }
        }
        
        /** @private */
		/** xp把全部监听的对象到头放到一个数组里，防止回调给他们删除，然后执行事件冒泡，这个冒泡的数据组池，提高效率而且必须是数组，因为回调之后再发布事件，还需要创建新的**/
        internal function bubbleEvent(event:Event):void
        {
            // we determine the bubble chain before starting to invoke the listeners.
            // that way, changes done by the listeners won't affect the bubble chain.
            
            var chain:Vector.<EventDispatcher>;
            var element:DisplayObject = this as DisplayObject;
            var length:int = 1;
            
            if (sBubbleChains.length > 0) { chain = sBubbleChains.pop(); chain[0] = element; }
            else chain = new <EventDispatcher>[element];
            
            while ((element = element.parent) != null)
                chain[int(length++)] = element;

            for (var i:int=0; i<length; ++i)
            {
                var stopPropagation:Boolean = chain[i].invokeEvent(event);
                if (stopPropagation) break;
            }
            
            chain.length = 0;
            sBubbleChains.push(chain);
        }
        
        /** Dispatches an event with the given parameters to all objects that have registered 
         *  listeners for the given type. The method uses an internal pool of event objects to 
         *  avoid allocations. */
		/** xp发布事件用内部的事件池，执行事件发布之后，然后再放入事件池，如果是冒泡或者自己有这个事件 才去发布事件，这个判断增加效率，**/
        public function dispatchEventWith(type:String, bubbles:Boolean=false, data:Object=null):void
        {
            if (bubbles || hasEventListener(type)) 
            {
                var event:Event = Event.fromPool(type, bubbles, data);
                dispatchEvent(event);
                Event.toPool(event);
            }
        }
        
        /** Returns if there are listeners registered for a certain event type. */
		/** xp返回是否有这种类型的监听（无回调）**/
        public function hasEventListener(type:String):Boolean
        {
            var listeners:Vector.<Function> = mEventListeners ?
                mEventListeners[type] as Vector.<Function> : null;
            return listeners ? listeners.length != 0 : false;
        }
    }
}