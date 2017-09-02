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
    import flash.ui.Mouse;
    import flash.ui.MouseCursor;
    import flash.utils.getQualifiedClassName;
    
    import starling.core.RenderSupport;
    import starling.errors.AbstractClassError;
    import starling.errors.AbstractMethodError;
    import starling.events.EventDispatcher;
    import starling.events.TouchEvent;
    import starling.filters.FragmentFilter;
    import starling.utils.MatrixUtil;
    
    /** Dispatched when an object is added to a parent. */
    [Event(name="added", type="starling.events.Event")]
    /** Dispatched when an object is connected to the stage (directly or indirectly). */
    [Event(name="addedToStage", type="starling.events.Event")]
    /** Dispatched when an object is removed from its parent. */
    [Event(name="removed", type="starling.events.Event")]
    /** Dispatched when an object is removed from the stage and won't be rendered any longer. */ 
    [Event(name="removedFromStage", type="starling.events.Event")]
    /** Dispatched once every frame on every object that is connected to the stage. */ 
    [Event(name="enterFrame", type="starling.events.EnterFrameEvent")]
    /** Dispatched when an object is touched. Bubbles. */
    [Event(name="touch", type="starling.events.TouchEvent")]
    
    /**
     *  xp已看完
	 *  1、可以那么定所有的移除，都是调用这个方法removeFromParent(true);
	 *  The DisplayObject class is the base class for all objects that are rendered on the 
     *  screen.
     *  
     *  <p><strong>The Display Tree</strong></p> 
     *  
     *  <p>In Starling, all displayable objects are organized in a display tree. Only objects that
     *  are part of the display tree will be displayed (rendered).</p> 
     *   
     *  <p>The display tree consists of leaf nodes (Image, Quad) that will be rendered directly to
     *  the screen, and of container nodes (subclasses of "DisplayObjectContainer", like "Sprite").
     *  A container is simply a display object that has child nodes - which can, again, be either
     *  leaf nodes or other containers.</p> 
     *  
     *  <p>At the base of the display tree, there is the Stage, which is a container, too. To create
     *  a Starling application, you create a custom Sprite subclass, and Starling will add an
     *  instance of this class to the stage.</p>
     *  
     *  <p>A display object has properties that define its position in relation to its parent
     *  (x, y), as well as its rotation and scaling factors (scaleX, scaleY). Use the 
     *  <code>alpha</code> and <code>visible</code> properties to make an object translucent or 
     *  invisible.</p>
     *  
     *  <p>Every display object may be the target of touch events. If you don't want an object to be
     *  touchable, you can disable the "touchable" property. When it's disabled, neither the object
     *  nor its children will receive any more touch events.</p>
     *    
     *  <strong>Transforming coordinates</strong>
     *  
     *  <p>Within the display tree, each object has its own local coordinate system. If you rotate
     *  a container, you rotate that coordinate system - and thus all the children of the 
     *  container.</p>
     *  
     *  <p>Sometimes you need to know where a certain point lies relative to another coordinate 
     *  system. That's the purpose of the method <code>getTransformationMatrix</code>. It will  
     *  create a matrix that represents the transformation of a point in one coordinate system to 
     *  another.</p> 
     *  
     *  <strong>Subclassing</strong>
     *  
     *  <p>Since DisplayObject is an abstract class, you cannot instantiate it directly, but have 
     *  to use one of its subclasses instead. There are already a lot of them available, and most 
     *  of the time they will suffice.</p> 
     *  
     *  <p>However, you can create custom subclasses as well. That way, you can create an object
     *  with a custom render function. You will need to implement the following methods when you 
     *  subclass DisplayObject:</p>
     *  
     *  <ul>
     *    <li><code>function render(support:RenderSupport, parentAlpha:Number):void</code></li>
     *    <li><code>function getBounds(targetSpace:DisplayObject, 
     *                                 resultRect:Rectangle=null):Rectangle</code></li>
     *  </ul>
     *  
     *  <p>Have a look at the Quad class for a sample implementation of the 'getBounds' method.
     *  For a sample on how to write a custom render function, you can have a look at this
     *  <a href="http://wiki.starling-framework.org/manual/custom_display_objects">article</a>
     *  in the Starling Wiki.</p> 
     * 
     *  <p>When you override the render method, it is important that you call the method
     *  'finishQuadBatch' of the support object. This forces Starling to render all quads that 
     *  were accumulated before by different render methods (for performance reasons). Otherwise, 
     *  the z-ordering will be incorrect.</p> 
     * 
     *  @see DisplayObjectContainer
     *  @see Sprite
     *  @see Stage 
     */
    public class DisplayObject extends EventDispatcher
    {
		private static const TWO_PI:Number = Math.PI * 2.0;
        // members
        
        private var mX:Number;
        private var mY:Number;
        private var mPivotX:Number;
        private var mPivotY:Number;
        private var mScaleX:Number;
        private var mScaleY:Number;
        private var mSkewX:Number;
        private var mSkewY:Number;
        private var mRotation:Number;
        private var mAlpha:Number;
        private var mVisible:Boolean;
        private var mTouchable:Boolean;
        private var mBlendMode:String;
        private var mName:String;
        private var mUseHandCursor:Boolean;
        private var mParent:DisplayObjectContainer;  
        private var mTransformationMatrix:Matrix;
        private var mOrientationChanged:Boolean;
        private var mFilter:FragmentFilter;
        
        /** Helper objects. */
        private static var sAncestors:Vector.<DisplayObject> = new <DisplayObject>[];
		//xp因为是私有的所有，其他的类，是无法使用这个对象，所以没问题
        private static var sHelperRect:Rectangle = new Rectangle();
		//这里需要增加一个，不然我感觉会出问题的（localToGlobal，globalToLocal）和getTransformationMatrix用的是同一个矩阵，肯定会出问题
        private static var sHelperMatrix:Matrix  = new Matrix();
        private static var sHelperMatrix1:Matrix  = new Matrix();
        /** @private */ 
        public function DisplayObject()
        {
            if (Capabilities.isDebugger && 
                getQualifiedClassName(this) == "starling.display::DisplayObject")
            {
                throw new AbstractClassError();
            }
            
            mX = mY = mPivotX = mPivotY = mRotation = mSkewX = mSkewY = 0.0;
            mScaleX = mScaleY = mAlpha = 1.0;            
            mVisible = mTouchable = true;
            mBlendMode = BlendMode.AUTO;
            mTransformationMatrix = new Matrix();
            mOrientationChanged = mUseHandCursor = false;
        }
        
        /** Disposes all resources of the display object. 
          * GPU buffers are released, event listeners are removed, filters are disposed. */
		//这个可以直接调用了
        public function dispose():void
        {
            if (mFilter) mFilter.dispose();
			mFilter = null;
			if (mParent) mParent.removeChild(this);
			mParent = null;
			mTransformationMatrix = null;
            removeEventListeners();
        }
        
        /** Removes the object from its parent, if it has one. */
		//这个也可以直接用了
        public function removeFromParent(dispose:Boolean=false):void
        {
            if (mParent) mParent.removeChild(this, dispose);
			//如果传dispose等于true，也要注销
			else if (dispose) this.dispose();
        }
        
        /** Creates a matrix that represents the transformation from the local coordinate system 
         *  to another. If you pass a 'resultMatrix', the result will be stored in this matrix
         *  instead of creating a new object. */ 
		//只要保证resultMatrix传递过来的不是这个类sHelperMatrix的静态矩阵就没问题
        public function getTransformationMatrix(targetSpace:DisplayObject, 
                                                resultMatrix:Matrix=null):Matrix
        {
            var commonParent:DisplayObject;
            var currentObject:DisplayObject;
            
            if (resultMatrix) resultMatrix.identity();
            else resultMatrix = new Matrix();
            //xp选择相对的目标是自己，返回空
            if (targetSpace == this)
            {
                return resultMatrix;
            }
			//xp选择相对的目标是自己的父类或者目标传的是空并且他没有父类，则返回自己的矩阵
            else if (targetSpace == mParent || (targetSpace == null && mParent == null))
            {
                resultMatrix.copyFrom(transformationMatrix);
                return resultMatrix;
            }
			//xp选择的目标是空或者是最大的父类，
            else if (targetSpace == null || targetSpace == base)
            {
                // targetCoordinateSpace 'null' represents the target space of the base object.
                // -> move up from this to base
                
                currentObject = this;
				//如果targetSpace是空，则计算到最后
				//如果targetSpace是base，则计算到base为止
                while (currentObject != targetSpace)
                {
                    resultMatrix.concat(currentObject.transformationMatrix);
                    currentObject = currentObject.mParent;
                }
                
                return resultMatrix;
            }
			//如果计算的目标的父类是自己，则调用计算目标的方法，然后求的逆矩阵
            else if (targetSpace.mParent == this) // optimization
            {
				//这里走完肯定会调targetSpace == mParent的那个判断
                targetSpace.getTransformationMatrix(this, resultMatrix);
                resultMatrix.invert();
                
                return resultMatrix;
            }
            
            // 1. find a common parent of this and the target space
            
            commonParent = null;
			
			//取this的所有父类，放入数组
            currentObject = this;
            
            while (currentObject)
            {
                sAncestors[sAncestors.length] = currentObject; // avoiding 'push'
                currentObject = currentObject.mParent;
            }
            //取targetSpace，跟this所有父类有关联的父类
            currentObject = targetSpace;
            while (currentObject && sAncestors.indexOf(currentObject) == -1)
                currentObject = currentObject.mParent;
            
            sAncestors.length = 0;
            
			//找到了通用的父类
            if (currentObject) commonParent = currentObject;
            else throw new ArgumentError("Object not connected to target");
            
            // 2. move up from this to common parent
            //把this移动到通用的父类的位置
            currentObject = this;
            while (currentObject != commonParent)
            {
                resultMatrix.concat(currentObject.transformationMatrix);
                currentObject = currentObject.mParent;
            }
            //如果通用的父类本来就是目标，直接返回就可以了
            if (commonParent == targetSpace)
                return resultMatrix;
            
            // 3. now move up from target until we reach the common parent
            
			//把targetSpace移动到通用的父类那
            sHelperMatrix.identity();
            currentObject = targetSpace;
            while (currentObject != commonParent)
            {
                sHelperMatrix.concat(currentObject.transformationMatrix);
                currentObject = currentObject.mParent;
            }
            
            // 4. now combine the two matrices
            //求出逆矩阵，然后再链接，就得到结果了
            sHelperMatrix.invert();
            resultMatrix.concat(sHelperMatrix);
            
            return resultMatrix;
        }        
        
        /** Returns a rectangle that completely encloses the object as it appears in another 
         *  coordinate system. If you pass a 'resultRectangle', the result will be stored in this 
         *  rectangle instead of creating a new object. */ 
		//xp实现这个方法的类，必须注意resultRect的调用方式
		//hittest是自己，其他的宽度，高度而是mParent
        public function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            throw new AbstractMethodError("Method needs to be implemented in subclass");
            //return null;
        }
        
        /** Returns the object that is found topmost beneath a point in local coordinates, or nil if 
         *  the test fails. If "forTouch" is true, untouchable and invisible objects will cause
         *  the test to fail. */
		//xp 碰撞测试
        public function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
        {
            // on a touch test, invisible or untouchable objects cause the test to fail
			//如果是forTouch并且隐藏或者不能触碰，就返回空
            if (forTouch && (!mVisible || !mTouchable)) return null;
            
            // otherwise, check bounding box
            if (getBounds(this, sHelperRect).containsPoint(localPoint)) return this;
            else return null;
        }
        
        /** Transforms a point from the local coordinate system to global (stage) coordinates.
         *  If you pass a 'resultPoint', the result will be stored in this point instead of 
         *  creating a new object. */
		//xp局部转全局
        public function localToGlobal(localPoint:Point, resultPoint:Point=null):Point
        {
            getTransformationMatrix(base, sHelperMatrix1);
            return MatrixUtil.transformCoords(sHelperMatrix1, localPoint.x, localPoint.y, resultPoint);
        }
        
        /** Transforms a point from global (stage) coordinates to the local coordinate system.
         *  If you pass a 'resultPoint', the result will be stored in this point instead of 
         *  creating a new object. */
		//xp全局转局部
        public function globalToLocal(globalPoint:Point, resultPoint:Point=null):Point
        {
            getTransformationMatrix(base, sHelperMatrix1);
			//xp颠倒
            sHelperMatrix1.invert();
            return MatrixUtil.transformCoords(sHelperMatrix1, globalPoint.x, globalPoint.y, resultPoint);
        }
        
        /** Renders the display object with the help of a support object. Never call this method
         *  directly, except from within another render method.
         *  @param support Provides utility functions for rendering.
         *  @param parentAlpha The accumulated alpha value from the object's parent up to the stage. */
		//xp渲染，需要继承
        public function render(support:RenderSupport, parentAlpha:Number):void
        {
            throw new AbstractMethodError("Method needs to be implemented in subclass");
        }
        
        /** Indicates if an object occupies any visible area. (Which is the case when its 'alpha', 
         *  'scaleX' and 'scaleY' values are not zero, and its 'visible' property is enabled.) */
		//xp 透明度不为0并且显示并且x缩放不为0,并且y缩放不为0
        public function get hasVisibleArea():Boolean
        {
            return mAlpha != 0.0 && mVisible && mScaleX != 0.0 && mScaleY != 0.0;
        }
        
        // internal methods
        
        /** @private */
        internal function setParent(value:DisplayObjectContainer):void 
        {
            // check for a recursion
            var ancestor:DisplayObject = value;
			//xp条件是，如果是本身或者不等于空，就继续，只有可能是本身或者为空
            while (ancestor != this && ancestor != null)
                ancestor = ancestor.mParent;
            
            if (ancestor == this)
                throw new ArgumentError("An object cannot be added as a child to itself or one " +
                                        "of its children (or children's children, etc.)");
            else
                mParent = value; 
        }
        
        // helpers
        //等价的，如果相差值在0.0001之内，就说明这两个数字相等
        private final function isEquivalent(a:Number, b:Number, epsilon:Number=0.0001):Boolean
        {
            return (a - epsilon < b) && (a + epsilon > b);
        }
        //格式化角度在-180到180之间
		/*
        private final function normalizeAngle(angle:Number):Number
        {
            // move into range [-180 deg, +180 deg]
            while (angle < -Math.PI) angle += Math.PI * 2.0;
            while (angle >  Math.PI) angle -= Math.PI * 2.0;
            return angle;
        }
		*/
        private final function normalizeAngle(angle:Number):Number
        {
            // move to equivalent value in range [0 deg, 360 deg] without a loop
            angle = angle % TWO_PI;

            // move to [-180 deg, +180 deg]
            if (angle < -Math.PI) angle += TWO_PI;
            if (angle >  Math.PI) angle -= TWO_PI;

            return angle;
        }
        // properties
 
        /** The transformation matrix of the object relative to its parent.
         * 
         *  <p>If you assign a custom transformation matrix, Starling will try to figure out  
         *  suitable values for <code>x, y, scaleX, scaleY,</code> and <code>rotation</code>.
         *  However, if the matrix was created in a different way, this might not be possible. 
         *  In that case, Starling will apply the matrix, but not update the corresponding 
         *  properties.</p>
         * 
         *  @returns CAUTION: not a copy, but the actual object! */
		/*
        public function get transformationMatrix():Matrix
        {
            if (mOrientationChanged)
            {
                mOrientationChanged = false;
                mTransformationMatrix.identity();
                
                if (mScaleX != 1.0 || mScaleY != 1.0) mTransformationMatrix.scale(mScaleX, mScaleY);
                if (mSkewX  != 0.0 || mSkewY  != 0.0) MatrixUtil.skew(mTransformationMatrix, mSkewX, mSkewY);
                if (mRotation != 0.0)                 mTransformationMatrix.rotate(mRotation);
                if (mX != 0.0 || mY != 0.0)           mTransformationMatrix.translate(mX, mY);
                
                if (mPivotX != 0.0 || mPivotY != 0.0)
                {
                    // prepend pivot transformation
                    mTransformationMatrix.tx = mX - mTransformationMatrix.a * mPivotX
                                                  - mTransformationMatrix.c * mPivotY;
                    mTransformationMatrix.ty = mY - mTransformationMatrix.b * mPivotX 
                                                  - mTransformationMatrix.d * mPivotY;
                }
            }
            
            return mTransformationMatrix; 
        }
		*/
        public function get transformationMatrix():Matrix
        {
            if (mOrientationChanged)
            {
                mOrientationChanged = false;
                
                if (mSkewX == 0.0 && mSkewY == 0.0)
                {
                    // optimization: no skewing / rotation simplifies the matrix math
                    
                    if (mRotation == 0.0)
                    {
                        mTransformationMatrix.setTo(mScaleX, 0.0, 0.0, mScaleY, 
                            mX - mPivotX * mScaleX, mY - mPivotY * mScaleY);
                    }
                    else
                    {
                        var cos:Number = Math.cos(mRotation);
                        var sin:Number = Math.sin(mRotation);
                        var a:Number   = mScaleX *  cos;
                        var b:Number   = mScaleX *  sin;
                        var c:Number   = mScaleY * -sin;
                        var d:Number   = mScaleY *  cos;
                        var tx:Number  = mX - mPivotX * a - mPivotY * c;
                        var ty:Number  = mY - mPivotX * b - mPivotY * d;
                        
                        mTransformationMatrix.setTo(a, b, c, d, tx, ty);
                    }
                }
                else
                {
                    mTransformationMatrix.identity();
                    mTransformationMatrix.scale(mScaleX, mScaleY);
                    MatrixUtil.skew(mTransformationMatrix, mSkewX, mSkewY);
                    mTransformationMatrix.rotate(mRotation);
                    mTransformationMatrix.translate(mX, mY);
                    
                    if (mPivotX != 0.0 || mPivotY != 0.0)
                    {
                        // prepend pivot transformation
                        mTransformationMatrix.tx = mX - mTransformationMatrix.a * mPivotX
                                                      - mTransformationMatrix.c * mPivotY;
                        mTransformationMatrix.ty = mY - mTransformationMatrix.b * mPivotX 
                                                      - mTransformationMatrix.d * mPivotY;
                    }
                }
            }
            
            return mTransformationMatrix; 
        }
		/*
        public function set transformationMatrix(matrix:Matrix):void
        {
            mOrientationChanged = false;
            mTransformationMatrix.copyFrom(matrix);
			mPivotX = mPivotY = 0;
            mX = matrix.tx;
            mY = matrix.ty;
            
            mScaleX = Math.sqrt(matrix.a * matrix.a + matrix.b * matrix.b);
            mSkewY  = Math.acos(matrix.a / mScaleX);
            
            if (!isEquivalent(matrix.b, mScaleX * Math.sin(mSkewY)))
            {
                mScaleX *= -1;
                mSkewY = Math.acos(matrix.a / mScaleX);
            }
            
            mScaleY = Math.sqrt(matrix.c * matrix.c + matrix.d * matrix.d);
            mSkewX  = Math.acos(matrix.d / mScaleY);
            
            if (!isEquivalent(matrix.c, -mScaleY * Math.sin(mSkewX)))
            {
                mScaleY *= -1;
                mSkewX = Math.acos(matrix.d / mScaleY);
            }
            
            if (isEquivalent(mSkewX, mSkewY))
            {
                mRotation = mSkewX;
                mSkewX = mSkewY = 0;
            }
            else
            {
                mRotation = 0;
            }
        }
		*/
        public function set transformationMatrix(matrix:Matrix):void
        {
            const PI_Q:Number = Math.PI / 4.0;

            mOrientationChanged = false;
            mTransformationMatrix.copyFrom(matrix);
            mPivotX = mPivotY = 0;
            
            mX = matrix.tx;
            mY = matrix.ty;
            
            mSkewX = Math.atan(-matrix.c / matrix.d);
            mSkewY = Math.atan( matrix.b / matrix.a);

            // NaN check ("isNaN" causes allocation)
            if (mSkewX != mSkewX) mSkewX = 0.0;
            if (mSkewY != mSkewY) mSkewY = 0.0;

            mScaleY = (mSkewX > -PI_Q && mSkewX < PI_Q) ?  matrix.d / Math.cos(mSkewX)
                                                        : -matrix.c / Math.sin(mSkewX);
            mScaleX = (mSkewY > -PI_Q && mSkewY < PI_Q) ?  matrix.a / Math.cos(mSkewY)
                                                        :  matrix.b / Math.sin(mSkewY);

            if (isEquivalent(mSkewX, mSkewY))
            {
                mRotation = mSkewX;
                mSkewX = mSkewY = 0;
            }
            else
            {
                mRotation = 0;
            }
        }
        /** Indicates if the mouse cursor should transform into a hand while it's over the sprite. 
         *  @default false */
        public function get useHandCursor():Boolean { return mUseHandCursor; }
		//是否使用手的光标，如果是就添加一个监听，不是就删除监听
        public function set useHandCursor(value:Boolean):void
        {
            if (value == mUseHandCursor) return;
            mUseHandCursor = value;
            
            if (mUseHandCursor)
                addEventListener(TouchEvent.TOUCH, onTouch);
            else
                removeEventListener(TouchEvent.TOUCH, onTouch);
        }
        
        private function onTouch(event:TouchEvent):void
        {
            Mouse.cursor = event.interactsWith(this) ? MouseCursor.BUTTON : MouseCursor.AUTO;
        }
        
        /** The bounds of the object relative to the local coordinates of the parent. */
        public function get bounds():Rectangle
        {
            return getBounds(mParent);
        }
        
        /** The width of the object in pixels. */
        public function get width():Number { return getBounds(mParent, sHelperRect).width; }
        public function set width(value:Number):void
        {
            // this method calls 'this.scaleX' instead of changing mScaleX directly.
            // that way, subclasses reacting on size changes need to override only the scaleX method.
            
            scaleX = 1.0;
            var actualWidth:Number = width;
            if (actualWidth != 0.0) scaleX = value / actualWidth;
        }
        
        /** The height of the object in pixels. */
        public function get height():Number { return getBounds(mParent, sHelperRect).height; }
        public function set height(value:Number):void
        {
            scaleY = 1.0;
            var actualHeight:Number = height;
			//不得0，才设置
            if (actualHeight != 0.0) scaleY = value / actualHeight;
        }
        
        /** The x coordinate of the object relative to the local coordinates of the parent. */
        public function get x():Number { return mX; }
        public function set x(value:Number):void 
        { 
            if (mX != value)
            {
                mX = value;
                mOrientationChanged = true;
            }
        }
        
        /** The y coordinate of the object relative to the local coordinates of the parent. */
        public function get y():Number { return mY; }
        public function set y(value:Number):void 
        {
            if (mY != value)
            {
                mY = value;
                mOrientationChanged = true;
            }
        }
        
        /** The x coordinate of the object's origin in its own coordinate space (default: 0). */
        public function get pivotX():Number { return mPivotX; }
        public function set pivotX(value:Number):void 
        {
            if (mPivotX != value)
            {
                mPivotX = value;
                mOrientationChanged = true;
            }
        }
        
        /** The y coordinate of the object's origin in its own coordinate space (default: 0). */
        public function get pivotY():Number { return mPivotY; }
        public function set pivotY(value:Number):void 
        { 
            if (mPivotY != value)
            {
                mPivotY = value;
                mOrientationChanged = true;
            }
        }
        
        /** The horizontal scale factor. '1' means no scale, negative values flip the object. */
        public function get scaleX():Number { return mScaleX; }
        public function set scaleX(value:Number):void 
        { 
            if (mScaleX != value)
            {
                mScaleX = value;
                mOrientationChanged = true;
            }
        }
        
        /** The vertical scale factor. '1' means no scale, negative values flip the object. */
        public function get scaleY():Number { return mScaleY; }
        public function set scaleY(value:Number):void 
        { 
            if (mScaleY != value)
            {
                mScaleY = value;
                mOrientationChanged = true;
            }
        }
        
        /** The horizontal skew angle in radians. */
        public function get skewX():Number { return mSkewX; }
        public function set skewX(value:Number):void 
        {
            value = normalizeAngle(value);
            
            if (mSkewX != value)
            {
                mSkewX = value;
                mOrientationChanged = true;
            }
        }
        
        /** The vertical skew angle in radians. */
        public function get skewY():Number { return mSkewY; }
        public function set skewY(value:Number):void 
        {
            value = normalizeAngle(value);
            
            if (mSkewY != value)
            {
                mSkewY = value;
                mOrientationChanged = true;
            }
        }
        
        /** The rotation of the object in radians. (In Starling, all angles are measured 
         *  in radians.) */
        public function get rotation():Number { return mRotation; }
        public function set rotation(value:Number):void 
        {
            value = normalizeAngle(value);

            if (mRotation != value)
            {            
                mRotation = value;
                mOrientationChanged = true;
            }
        }
        
        /** The opacity of the object. 0 = transparent, 1 = opaque. */
        public function get alpha():Number { return mAlpha; }
		//xp 0-1之间
        public function set alpha(value:Number):void 
        { 
            mAlpha = value < 0.0 ? 0.0 : (value > 1.0 ? 1.0 : value); 
        }
        
        /** The visibility of the object. An invisible object will be untouchable. */
        public function get visible():Boolean { return mVisible; }
        public function set visible(value:Boolean):void { mVisible = value; }
        
        /** Indicates if this object (and its children) will receive touch events. */
        public function get touchable():Boolean { return mTouchable; }
        public function set touchable(value:Boolean):void { mTouchable = value; }
        
        /** The blend mode determines how the object is blended with the objects underneath. 
         *   @default auto
         *   @see starling.display.BlendMode */ 
        public function get blendMode():String { return mBlendMode; }
        public function set blendMode(value:String):void { mBlendMode = value; }
        
        /** The name of the display object (default: null). Used by 'getChildByName()' of 
         *  display object containers. */
        public function get name():String { return mName; }
        public function set name(value:String):void { mName = value; }
        
        /** The filter or filter group that is attached to the display object. The starling.filters 
         *  package contains several classes that define specific filters you can use. 
         *  Beware that you should NOT use the same filter on more than one object (for 
         *  performance reasons). */ 
        public function get filter():FragmentFilter { return mFilter; }
        public function set filter(value:FragmentFilter):void { mFilter = value; }
        
        /** The display object container that contains this display object. */
        public function get parent():DisplayObjectContainer { return mParent; }
        
        /** The topmost object in the display tree the object is part of. */
		//最大的父类，也可能是自己
        public function get base():DisplayObject
        {
            var currentObject:DisplayObject = this;
            while (currentObject.mParent) currentObject = currentObject.mParent;
            return currentObject;
        }
        
        /** The root object the display object is connected to (i.e. an instance of the class 
         *  that was passed to the Starling constructor), or null if the object is not connected
         *  to the stage. */
		//根stage的子类
        public function get root():DisplayObject
        {
            var currentObject:DisplayObject = this;
            while (currentObject.mParent)
            {
                if (currentObject.mParent is Stage) return currentObject;
                else currentObject = currentObject.parent;
            }
            
            return null;
        }
        
        /** The stage the display object is connected to, or null if it is not connected 
         *  to the stage. */
		//xp可能是空，因为可能base不是stage
        public function get stage():Stage { return this.base as Stage; }
    }
}