// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display
{
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;
    import flash.utils.getQualifiedClassName;
    
    import starling.core.RenderSupport;
    import starling.core.starling_internal;
    import starling.errors.AbstractClassError;
    import starling.events.Event;
    import starling.filters.FragmentFilter;
    import starling.utils.MatrixUtil;
    
    use namespace starling_internal;
    
    /**
     *  A DisplayObjectContainer represents a collection of display objects.
     *  It is the base class of all display objects that act as a container for other objects. By 
     *  maintaining an ordered list of children, it defines the back-to-front positioning of the 
     *  children within the display tree.
     *  
     *  <p>A container does not a have size in itself. The width and height properties represent the 
     *  extents of its children. Changing those properties will scale all children accordingly.</p>
     *  
     *  <p>As this is an abstract class, you can't instantiate it directly, but have to 
     *  use a subclass instead. The most lightweight container class is "Sprite".</p>
     *  
     *  <strong>Adding and removing children</strong>
     *  
     *  <p>The class defines methods that allow you to add or remove children. When you add a child, 
     *  it will be added at the frontmost position, possibly occluding a child that was added 
     *  before. You can access the children via an index. The first child will have index 0, the 
     *  second child index 1, etc.</p> 
     *  
     *  Adding and removing objects from a container triggers non-bubbling events.
     *  
     *  <ul>
     *   <li><code>Event.ADDED</code>: the object was added to a parent.</li>
     *   <li><code>Event.ADDED_TO_STAGE</code>: the object was added to a parent that is 
     *       connected to the stage, thus becoming visible now.</li>
     *   <li><code>Event.REMOVED</code>: the object was removed from a parent.</li>
     *   <li><code>Event.REMOVED_FROM_STAGE</code>: the object was removed from a parent that 
     *       is connected to the stage, thus becoming invisible now.</li>
     *  </ul>
     *  
     *  Especially the <code>ADDED_TO_STAGE</code> event is very helpful, as it allows you to 
     *  automatically execute some logic (e.g. start an animation) when an object is rendered the 
     *  first time.
     *  
     *  @see Sprite
     *  @see DisplayObject
     */
    public class DisplayObjectContainer extends DisplayObject
    {
        // members
        
        private var mChildren:Vector.<DisplayObject>;
        
        /** Helper objects. */
        private static var sHelperMatrix:Matrix = new Matrix();
        private static var sHelperPoint:Point = new Point();
        private static var sBroadcastListeners:Vector.<DisplayObject> = new <DisplayObject>[];
        
        // construction
        
        /** @private */
        public function DisplayObjectContainer()
        {
            if (Capabilities.isDebugger && 
                getQualifiedClassName(this) == "starling.display::DisplayObjectContainer")
            {
                throw new AbstractClassError();
            }
            
            mChildren = new <DisplayObject>[];
        }
        
        /** Disposes the resources of all children. */
		//xp注销,可能注销的时候，就不需要再发那些离开事件了吧
        public override function dispose():void
        {
			if(mChildren){
				 for (var i:int=mChildren.length-1; i>=0; --i)
					mChildren[i].dispose();
				//xp应该把这个数组清空
				mChildren.length = 0;
				mChildren = null;
			}
            super.dispose();
        }
        
        // child management
        
        /** Adds a child to the container. It will be at the frontmost position. */
        public function addChild(child:DisplayObject):DisplayObject
        {
            addChildAt(child, numChildren);
            return child;
        }
        
        /** Adds a child to the container at a certain index. */
		/*
        public function addChildAt(child:DisplayObject, index:int):DisplayObject
        {
            var numChildren:int = mChildren.length; 
            
            if (index >= 0 && index <= numChildren)
            {
                child.removeFromParent();
                
                // 'splice' creates a temporary object, so we avoid it if it's not necessary
                if (index == numChildren) mChildren.push(child);
                else                      mChildren.splice(index, 0, child);
                
                child.setParent(this);
                child.dispatchEventWith(Event.ADDED, true);
                
                if (stage)
                {
                    var container:DisplayObjectContainer = child as DisplayObjectContainer;
                    if (container) container.broadcastEventWith(Event.ADDED_TO_STAGE);
                    else           child.dispatchEventWith(Event.ADDED_TO_STAGE);
                }
                
                return child;
            }
            else
            {
                throw new RangeError("Invalid child index");
            }
        }
		*/
        public function addChildAt(child:DisplayObject, index:int):DisplayObject
        {
            var numChildren:int = mChildren.length; 
            
            if (index >= 0 && index <= numChildren)
            {
                if (child.parent == this)
                {
                    setChildIndex(child, index); // avoids dispatching events
                }
                else
                {
                    child.removeFromParent();
                    
                    // 'splice' creates a temporary object, so we avoid it if it's not necessary
                    if (index == numChildren) mChildren[numChildren] = child;
                    else                      mChildren.splice(index, 0, child);
                    
                    child.setParent(this);
                    child.dispatchEventWith(Event.ADDED, true);
                    
                    if (stage)
                    {
                        var container:DisplayObjectContainer = child as DisplayObjectContainer;
                        if (container) container.broadcastEventWith(Event.ADDED_TO_STAGE);
                        else           child.dispatchEventWith(Event.ADDED_TO_STAGE);
                    }
                }
                
                return child;
            }
            else
            {
                throw new RangeError("Invalid child index");
            }
        }
        /** Removes a child from the container. If the object is not a child, nothing happens. 
         *  If requested, the child will be disposed right away. */
        public function removeChild(child:DisplayObject, dispose:Boolean=false):DisplayObject
        {
            var childIndex:int = getChildIndex(child);
            if (childIndex != -1) removeChildAt(childIndex, dispose);
            return child;
        }
        
        /** Removes a child at a certain index. Children above the child will move down. If
         *  requested, the child will be disposed right away. */
        public function removeChildAt(index:int, dispose:Boolean=false):DisplayObject
        {
            if (index >= 0 && index < numChildren)
            {
                var child:DisplayObject = mChildren[index];
                child.dispatchEventWith(Event.REMOVED, true);
                
                if (stage)
                {
                    var container:DisplayObjectContainer = child as DisplayObjectContainer;
                    if (container) container.broadcastEventWith(Event.REMOVED_FROM_STAGE);
                    else           child.dispatchEventWith(Event.REMOVED_FROM_STAGE);
                }
                
                child.setParent(null);
				//可能这个子对象已经被移除了，也有可能，所以这里得判断
                index = mChildren.indexOf(child); // index might have changed by event handler
                if (index >= 0) mChildren.splice(index, 1); 
                if (dispose) child.dispose();
                
                return child;
            }
            else
            {
                throw new RangeError("Invalid child index");
            }
        }
        
        /** Removes a range of children from the container (endIndex included). 
         *  If no arguments are given, all children will be removed. */
		//如果endIndex小于0或者大于等于最大长度，则移除全部
        public function removeChildren(beginIndex:int=0, endIndex:int=-1, dispose:Boolean=false):void
        {
            if (endIndex < 0 || endIndex >= numChildren) 
                endIndex = numChildren - 1;
            //这块是一直删除开始那个，删某个长度，删除那每次都有判断没问题的
            for (var i:int=beginIndex; i<=endIndex; ++i)
                removeChildAt(beginIndex, dispose);
        }
        
        /** Returns a child object at a certain index. */
        public function getChildAt(index:int):DisplayObject
        {
            if (index >= 0 && index < numChildren)
                return mChildren[index];
            else
                throw new RangeError("Invalid child index");
        }
        
        /** Returns a child object with a certain name (non-recursively). */
        public function getChildByName(name:String):DisplayObject
        {
            var numChildren:int = mChildren.length;
            for (var i:int=0; i<numChildren; ++i)
                if (mChildren[i].name == name) return mChildren[i];

            return null;
        }
        
        /** Returns the index of a child within the container, or "-1" if it is not found. */
        public function getChildIndex(child:DisplayObject):int
        {
            return mChildren.indexOf(child);
        }
        
        /** Moves a child to a certain index. Children at and after the replaced position move up.*/
        public function setChildIndex(child:DisplayObject, index:int):void
        {
            var oldIndex:int = getChildIndex(child);
			if (oldIndex == index) return;
            if (oldIndex == -1) throw new ArgumentError("Not a child of this container");
            mChildren.splice(oldIndex, 1);
            mChildren.splice(index, 0, child);
        }
        
        /** Swaps the indexes of two children. */
        public function swapChildren(child1:DisplayObject, child2:DisplayObject):void
        {
            var index1:int = getChildIndex(child1);
            var index2:int = getChildIndex(child2);
            if (index1 == -1 || index2 == -1) throw new ArgumentError("Not a child of this container");
            swapChildrenAt(index1, index2);
        }
        
        /** Swaps the indexes of two children. */
        public function swapChildrenAt(index1:int, index2:int):void
        {
            var child1:DisplayObject = getChildAt(index1);
            var child2:DisplayObject = getChildAt(index2);
            mChildren[index1] = child2;
            mChildren[index2] = child1;
        }
        
        /** Sorts the children according to a given function (that works just like the sort function
         *  of the Vector class). */
        public function sortChildren(compareFunction:Function):void
        {
            mChildren = mChildren.sort(compareFunction);
        }
        
        /** Determines if a certain object is a child of the container (recursively). */
		//这个是包含，儿子的儿子也算
        public function contains(child:DisplayObject):Boolean
        {
            while (child)
            {
                if (child == this) return true;
                else child = child.parent;
            }
            return false;
        }
        
        /** @inheritDoc */ 
		//resultRect只参与最后的赋值，所以很安全的，sHelperMatrix也是很安全的
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            
            var numChildren:int = mChildren.length;
            
            if (numChildren == 0)
            {
                getTransformationMatrix(targetSpace, sHelperMatrix);
				//xp这个很安全，不牵扯到传参
                MatrixUtil.transformCoords(sHelperMatrix, 0.0, 0.0, sHelperPoint);
                resultRect.setTo(sHelperPoint.x, sHelperPoint.y, 0, 0);
                //return resultRect;
            }
            else if (numChildren == 1)
            {
                //return mChildren[0].getBounds(targetSpace, resultRect);
				resultRect = mChildren[0].getBounds(targetSpace, resultRect);
            }
            else
            {
                var minX:Number = Number.MAX_VALUE, maxX:Number = -Number.MAX_VALUE;
                var minY:Number = Number.MAX_VALUE, maxY:Number = -Number.MAX_VALUE;
                
                for (var i:int=0; i<numChildren; ++i)
                {
                    mChildren[i].getBounds(targetSpace, resultRect);
                    minX = minX < resultRect.x ? minX : resultRect.x;
                    maxX = maxX > resultRect.right ? maxX : resultRect.right;
                    minY = minY < resultRect.y ? minY : resultRect.y;
                    maxY = maxY > resultRect.bottom ? maxY : resultRect.bottom;
                }
                
                resultRect.setTo(minX, minY, maxX - minX, maxY - minY);
                //return resultRect;
            }
			return resultRect;			
        }
        
        /** @inheritDoc */
		//这个一点问题都没有，因为localPoint传进来之后，就不会再被利用了
        public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            if (forTouch && (!visible || !touchable))
                return null;
            //xp这里是很重要的，因为localPoint一般都会变化
            var localX:Number = localPoint.x;
            var localY:Number = localPoint.y;
            
            var numChildren:int = mChildren.length;
			//xp碰撞测试需要从前往后
            for (var i:int=numChildren-1; i>=0; --i) // front to back!
            {
                var child:DisplayObject = mChildren[i];
				//计算这个孩子相对于父类的矩阵（这里扯皮了两次，父类调子类，子类又调父类）
                getTransformationMatrix(child, sHelperMatrix);
                //根据子类相对于父类的矩阵，算出另一个坐标
                MatrixUtil.transformCoords(sHelperMatrix, localX, localY, sHelperPoint);
				//去计算子类的hitTest(最终是找到最底层的子类)（递归）（再到下一层的时候，用到的还是这个sHelperPoint，所以上面开始写好了localX，localY）
                var target:DisplayObject = child.hitTest(sHelperPoint, forTouch);
                
                if (target) return target;
            }
            
            return null;
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            var alpha:Number = parentAlpha * this.alpha;
            var numChildren:int = mChildren.length;
            var blendMode:String = support.blendMode;
            
            for (var i:int=0; i<numChildren; ++i)
            {
                var child:DisplayObject = mChildren[i];
                
                if (child.hasVisibleArea)
                {
                    var filter:FragmentFilter = child.filter;
					//一进一出
                    support.pushMatrix();
                    support.transformMatrix(child);
                    support.blendMode = child.blendMode;
                    
                    if (filter) filter.render(child, support, alpha);
                    else        child.render(support, alpha);
                    //这块在还原回来
                    support.blendMode = blendMode;
                    support.popMatrix();
                }
            }
        }
        
        /** Dispatches an event on all children (recursively). The event must not bubble. */
        public function broadcastEvent(event:Event):void
        {
            if (event.bubbles)
                throw new ArgumentError("Broadcast of bubbling events is prohibited");
            
            // The event listeners might modify the display tree, which could make the loop crash. 
            // Thus, we collect them in a list and iterate over that list instead.
            // And since another listener could call this method internally, we have to take 
            // care that the static helper vector does not get currupted.
            
			//这个是非常重要的，这个方法可能在发事件的时候，还会调用，还会往sBroadcastListeners放东西
			//当然了再次调用的肯定是先完成，所以他加入多少，之后就清理多少，然后再继续回来一次调用的地方
			//通过派发事件，删除子对象时，不会导致这个子对象，这次的监听删除，还会收到的
            var fromIndex:int = sBroadcastListeners.length;
            getChildEventListeners(this, event.type, sBroadcastListeners);
            var toIndex:int = sBroadcastListeners.length;
            
            for (var i:int=fromIndex; i<toIndex; ++i)
                sBroadcastListeners[i].dispatchEvent(event);
            
            sBroadcastListeners.length = fromIndex;
        }
        
        /** Dispatches an event with the given parameters on all children (recursively). 
         *  The method uses an internal pool of event objects to avoid allocations. */
		//广播是不能冒泡的
        public function broadcastEventWith(type:String, data:Object=null):void
        {
            var event:Event = Event.fromPool(type, false, data);
            broadcastEvent(event);
            Event.toPool(event);
        }
        //递归去所有子对象，按树型结构，遍历
        private function getChildEventListeners(object:DisplayObject, eventType:String, 
                                                listeners:Vector.<DisplayObject>):void
        {
            var container:DisplayObjectContainer = object as DisplayObjectContainer;
            
            if (object.hasEventListener(eventType))
                listeners[listeners.length] = object; // avoiding 'push'
            
            if (container)
            {
                var children:Vector.<DisplayObject> = container.mChildren;
                var numChildren:int = children.length;
                
                for (var i:int=0; i<numChildren; ++i)
                    getChildEventListeners(children[i], eventType, listeners);
            }
        }
        
        /** The number of children of this container. */
        public function get numChildren():int { return mChildren.length; }        
    }
}
