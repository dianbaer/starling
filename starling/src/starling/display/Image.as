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
    import flash.display.Bitmap;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import starling.core.RenderSupport;
    import starling.textures.Texture;
    import starling.textures.TextureSmoothing;
    import starling.utils.VertexData;
    
    /** xp已看完
	 *  An Image is a quad with a texture mapped onto it.
     *  
     *  <p>The Image class is the Starling equivalent of Flash's Bitmap class. Instead of 
     *  BitmapData, Starling uses textures to represent the pixels of an image. To display a 
     *  texture, you have to map it onto a quad - and that's what the Image class is for.</p>
     *  
     *  <p>As "Image" inherits from "Quad", you can give it a color. For each pixel, the resulting  
     *  color will be the result of the multiplication of the color of the texture with the color of 
     *  the quad. That way, you can easily tint textures with a certain color. Furthermore, images 
     *  allow the manipulation of texture coordinates. That way, you can move a texture inside an 
     *  image without changing any vertex coordinates of the quad. You can also use this feature
     *  as a very efficient way to create a rectangular mask.</p> 
     *  
     *  @see starling.textures.Texture
     *  @see Quad
     */ 
    public class Image extends Quad
    {
        private var mTexture:Texture;
        private var mSmoothing:String;
        
        private var mVertexDataCache:VertexData;
        private var mVertexDataCacheInvalid:Boolean;
        
        /** Creates a quad with a texture mapped onto it. */
        public function Image(texture:Texture)
        {
            if (texture)
            {
				//读取纹理的宽高和是否支持透明，优先读取纹理的frame
                var frame:Rectangle = texture.frame;
                var width:Number  = frame ? frame.width  : texture.width;
                var height:Number = frame ? frame.height : texture.height;
                var pma:Boolean = texture.premultipliedAlpha;
                
                super(width, height, 0xffffff, pma);
                
                mVertexData.setTexCoords(0, 0.0, 0.0);
                mVertexData.setTexCoords(1, 1.0, 0.0);
                mVertexData.setTexCoords(2, 0.0, 1.0);
                mVertexData.setTexCoords(3, 1.0, 1.0);
                
                mTexture = texture;
                mSmoothing = TextureSmoothing.BILINEAR;
				//顶点缓存
                mVertexDataCache = new VertexData(4, pma);
                mVertexDataCacheInvalid = true;
            }
            else
            {
                throw new ArgumentError("Texture cannot be null");
            }
        }
        
        /** Creates an Image with a texture that is created from a bitmap object. */
        public static function fromBitmap(bitmap:Bitmap, generateMipMaps:Boolean=true, 
                                          scale:Number=1):Image
        {
            return new Image(Texture.fromBitmap(bitmap, generateMipMaps, false, scale));
        }
        
        /** @inheritDoc */
        protected override function onVertexDataChanged():void
        {
            mVertexDataCacheInvalid = true;
        }
        
        /** Readjusts the dimensions of the image according to its current texture. Call this method 
         *  to synchronize image and texture size after assigning a texture with a different size.*/
		//读取正确的尺寸(应该是在，重新设置纹理后，想改变大小时，调用)
        public function readjustSize():void
        {
            var frame:Rectangle = texture.frame;
            var width:Number  = frame ? frame.width  : texture.width;
            var height:Number = frame ? frame.height : texture.height;
            
            mVertexData.setPosition(0, 0.0, 0.0);
            mVertexData.setPosition(1, width, 0.0);
            mVertexData.setPosition(2, 0.0, height);
            mVertexData.setPosition(3, width, height); 
            
            onVertexDataChanged();
        }
        
        /** Sets the texture coordinates of a vertex. Coordinates are in the range [0, 1]. */
		//设置纹理的位置
        public function setTexCoords(vertexID:int, coords:Point):void
        {
            mVertexData.setTexCoords(vertexID, coords.x, coords.y);
            onVertexDataChanged();
        }
        
        /** Gets the texture coordinates of a vertex. Coordinates are in the range [0, 1]. 
         *  If you pass a 'resultPoint', the result will be stored in this point instead of 
         *  creating a new object.*/
        public function getTexCoords(vertexID:int, resultPoint:Point=null):Point
        {
            if (resultPoint == null) resultPoint = new Point();
            mVertexData.getTexCoords(vertexID, resultPoint);
            return resultPoint;
        }
        
        /** Copies the raw vertex data to a VertexData instance.
         *  The texture coordinates are already in the format required for rendering. */ 
        public override function copyVertexDataTo(targetData:VertexData, targetVertexID:int=0):void
        {
			//这个顶点缓存，可能是保存比较原始的数据包括（颜色，透明度，纹理位置，纹理本身，显示对象的位置）
			//就是增加效率的。因为会调用 mTexture.adjustVertexData，可能比较消耗效率，所以做一个缓存，不用总调用这个
            if (mVertexDataCacheInvalid)
            {
                mVertexDataCacheInvalid = false;
                mVertexData.copyTo(mVertexDataCache);
				
                mTexture.adjustVertexData(mVertexDataCache, 0, 4);
            }
            //如果定点缓存，没改变的话，直接copy就可以了
            mVertexDataCache.copyTo(targetData, targetVertexID);
			//这之后要处理，targetData的所对应的对象的mTinted问题
        }
        
        /** The texture that is displayed on the quad. */
        public function get texture():Texture { return mTexture; }
        public function set texture(value:Texture):void 
        { 
            if (value == null)
            {
                throw new ArgumentError("Texture cannot be null");
            }
            else if (value != mTexture)
            {
                mTexture = value;
				//替换纹理的时候怎么只是，设置一下是否支持透明度呢，其他的都不设置呢（？）
				//重设纹理的时候，保持原来的属性（确实不应该重置别的属性，如果想重置，可以按照纹理，去设置相应的属性）
                mVertexData.setPremultipliedAlpha(mTexture.premultipliedAlpha);
				//更改纹理缓存，但是并不更新那些顶点数据，因为下次用到时会更新的（这是没问题的，因为mVertexDataCache里面的数据库下次调用，不会使用的）
				mVertexDataCache.setPremultipliedAlpha(mTexture.premultipliedAlpha, false);
                onVertexDataChanged();
            }
        }
        
        /** The smoothing filter that is used for the texture. 
        *   @default bilinear
        *   @see starling.textures.TextureSmoothing */ 
        public function get smoothing():String { return mSmoothing; }
        public function set smoothing(value:String):void 
        {
            if (TextureSmoothing.isValid(value))
                mSmoothing = value;
            else
                throw new ArgumentError("Invalid smoothing mode: " + value);
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
            support.batchQuad(this, parentAlpha, mTexture, mSmoothing);
        }
		public override function dispose():void{
			mVertexDataCache.dispose();
			mVertexDataCache = null;
			mTexture = null;
			super.dispose();
		}
    }
}