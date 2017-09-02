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
    
    import starling.core.RenderSupport;
    import starling.utils.VertexData;
    
    /** xp已看完
	 *  A Quad represents a rectangle with a uniform color or a color gradient.
     *  
     *  <p>You can set one color per vertex. The colors will smoothly fade into each other over the area
     *  of the quad. To display a simple linear color gradient, assign one color to vertices 0 and 1 and 
     *  another color to vertices 2 and 3. </p> 
     *
     *  <p>The indices of the vertices are arranged like this:</p>
     *  
     *  <pre>
     *  0 - 1
     *  | / |
     *  2 - 3
     *  </pre>
     * 
     *  @see Image
     */
    public class Quad extends DisplayObject
    {
        private var mTinted:Boolean;
        
        /** The raw vertex data of the quad. */
        protected var mVertexData:VertexData;
        
        /** Helper objects. */
        private static var sHelperPoint:Point = new Point();
        private static var sHelperMatrix:Matrix = new Matrix();
        
        /** Creates a quad with a certain size and color. The last parameter controls if the 
         *  alpha value should be premultiplied into the color values on rendering, which can
         *  influence blending output. You can use the default value in most cases.  */
        public function Quad(width:Number, height:Number, color:uint=0xffffff,
                             premultipliedAlpha:Boolean=true)
        {
            mTinted = color != 0xffffff;
            
            mVertexData = new VertexData(4, premultipliedAlpha);
            mVertexData.setPosition(0, 0.0, 0.0);
            mVertexData.setPosition(1, width, 0.0);
            mVertexData.setPosition(2, 0.0, height);
            mVertexData.setPosition(3, width, height);            
            mVertexData.setUniformColor(color);
            
            onVertexDataChanged();
        }
        
        /** Call this method after manually changing the contents of 'mVertexData'. */
        protected function onVertexDataChanged():void
        {
            // override in subclasses, if necessary
        }
        
        /** @inheritDoc */
        public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
        {
            if (resultRect == null) resultRect = new Rectangle();
            //如果是自己，则取第三个点，就可以了
            if (targetSpace == this) // optimization
            {
                mVertexData.getPosition(3, sHelperPoint);
                resultRect.setTo(0.0, 0.0, sHelperPoint.x, sHelperPoint.y);
            }
			//如果目标parent，并且旋转角度为0
            else if (targetSpace == parent && rotation == 0.0) // optimization
            {
                var scaleX:Number = this.scaleX;
                var scaleY:Number = this.scaleY;
                mVertexData.getPosition(3, sHelperPoint);
                resultRect.setTo(x - pivotX * scaleX,      y - pivotY * scaleY,
                                 sHelperPoint.x * scaleX, sHelperPoint.y * scaleY);
				//如果缩放比小于0，则宽度高度乘以-1，并且x，y减去宽度，高度。宽度，高度是负，x,y想左上角移动
                if (scaleX < 0) { resultRect.width  *= -1; resultRect.x -= resultRect.width;  }
                if (scaleY < 0) { resultRect.height *= -1; resultRect.y -= resultRect.height; }
            }
            else
            {
                getTransformationMatrix(targetSpace, sHelperMatrix);
                mVertexData.getBounds(sHelperMatrix, 0, 4, resultRect);
            }
            
            return resultRect;
        }
        
        /** Returns the color of a vertex at a certain index. */
        public function getVertexColor(vertexID:int):uint
        {
            return mVertexData.getColor(vertexID);
        }
        
        /** Sets the color of a vertex at a certain index. */
        public function setVertexColor(vertexID:int, color:uint):void
        {
            mVertexData.setColor(vertexID, color);
            onVertexDataChanged();
            
			//每次都要考虑displayobject的透明度
            if (color != 0xffffff || this.alpha != 1.0) mTinted = true;
            //else mTinted = mVertexData.tinted;
        }
        
        /** Returns the alpha value of a vertex at a certain index. */
        public function getVertexAlpha(vertexID:int):Number
        {
            return mVertexData.getAlpha(vertexID);
        }
        
        /** Sets the alpha value of a vertex at a certain index. */
        public function setVertexAlpha(vertexID:int, alpha:Number):void
        {
            mVertexData.setAlpha(vertexID, alpha);
            onVertexDataChanged();
            
			//每次都要考虑displayobject的透明度
            if (alpha != 1.0 || this.alpha != 1.0) mTinted = true;
            //else mTinted = mVertexData.tinted;
        }
        
        /** Returns the color of the quad, or of vertex 0 if vertices have different colors. */
        public function get color():uint 
        { 
            return mVertexData.getColor(0); 
        }
        
        /** Sets the colors of all vertices to a certain value. */
        public function set color(value:uint):void 
        {
            for (var i:int=0; i<4; ++i)
                setVertexColor(i, value);
            
			//每次都要考虑displayobject的透明度
            if (value != 0xffffff || this.alpha != 1.0) mTinted = true;
            //else mTinted = mVertexData.tinted;
        }
        
        /** @inheritDoc **/
		//如果是整体透明度的话，就不更新所有点的透明，应该是最后一块计算
        public override function set alpha(value:Number):void
        {
            super.alpha = value;
            //每次都要考虑displayobject的透明度
            if (this.alpha != 1.0) mTinted = true;
            //else mTinted = mVertexData.tinted;
        }
        
        /** Copies the raw vertex data to a VertexData instance. */
		//把这个对象的顶点都copy到目标对象里
        public function copyVertexDataTo(targetData:VertexData, targetVertexID:int=0):void
        {
			//copy之后的mTinted还没有写入呢（？），可能copy的数据，是mTinted的
            mVertexData.copyTo(targetData, targetVertexID);
			//这之后要处理，targetData的所对应的对象的mTinted问题
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            support.batchQuad(this, parentAlpha);
        }
        
        /** Returns true if the quad (or any of its vertices) is non-white or non-opaque. */
        public function get tinted():Boolean { return mTinted; }
		public override function dispose():void{
			mVertexData.dispose();
			mVertexData = null;
			super.dispose();
		}
    }
}