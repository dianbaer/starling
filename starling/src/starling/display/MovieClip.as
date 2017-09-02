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
    import flash.errors.IllegalOperationError;
    import flash.media.Sound;
    
    import starling.animation.IAnimatable;
    import starling.events.Event;
    import starling.textures.Texture;
    
    /** Dispatched whenever the movie has displayed its last frame. */
    [Event(name="complete", type="starling.events.Event")]
    
    /** 1、动画最好帧数别是3的倍数例如3,6,9,12，不然没法除开，整个动画的播放事件会比1秒少一点
	 *  A MovieClip is a simple way to display an animation depicted by a list of textures.
     *  
     *  <p>Pass the frames of the movie in a vector of textures to the constructor. The movie clip 
     *  will have the width and height of the first frame. If you group your frames with the help 
     *  of a texture atlas (which is recommended), use the <code>getTextures</code>-method of the 
     *  atlas to receive the textures in the correct (alphabetic) order.</p> 
     *  
     *  <p>You can specify the desired framerate via the constructor. You can, however, manually 
     *  give each frame a custom duration. You can also play a sound whenever a certain frame 
     *  appears.</p>
     *  
     *  <p>The methods <code>play</code> and <code>pause</code> control playback of the movie. You
     *  will receive an event of type <code>Event.MovieCompleted</code> when the movie finished
     *  playback. If the movie is looping, the event is dispatched once per loop.</p>
     *  
     *  <p>As any animated object, a movie clip has to be added to a juggler (or have its 
     *  <code>advanceTime</code> method called regularly) to run. The movie will dispatch 
     *  an event of type "Event.COMPLETE" whenever it has displayed its last frame.</p>
     *  
     *  @see starling.textures.TextureAtlas
     */    
    public class MovieClip extends Image implements IAnimatable
    {
        private var mTextures:Vector.<Texture>;
        private var mSounds:Vector.<Sound>;
        private var mDurations:Vector.<Number>;
        private var mStartTimes:Vector.<Number>;
        
        private var mDefaultFrameDuration:Number;
        private var mCurrentTime:Number;
        private var mCurrentFrame:int;
        private var mLoop:Boolean;
        private var mPlaying:Boolean;
        
        /** Creates a movie clip from the provided textures and with the specified default framerate.
         *  The movie will have the size of the first frame. */  
        public function MovieClip(textures:Vector.<Texture>, fps:Number=12)
        {
            if (textures.length > 0)
            {
                super(textures[0]);
                init(textures, fps);
            }
            else
            {
                throw new ArgumentError("Empty texture array");
            }
        }
        
        private function init(textures:Vector.<Texture>, fps:Number):void
        {
            if (fps <= 0) throw new ArgumentError("Invalid fps: " + fps);
            var numFrames:int = textures.length;
            
            mDefaultFrameDuration = 1.0 / fps;
            mLoop = true;
            mPlaying = true;
            mCurrentTime = 0.0;
            mCurrentFrame = 0;
			//xp复制一下是有好处的，因为这个数组可能还会传给别人，施放的时候，把这个数组清空了就行，不算外部传来的
            mTextures = textures.concat();
            mSounds = new Vector.<Sound>(numFrames);
            mDurations = new Vector.<Number>(numFrames);
            mStartTimes = new Vector.<Number>(numFrames);
            
            for (var i:int=0; i<numFrames; ++i)
            {
                mDurations[i] = mDefaultFrameDuration;
                mStartTimes[i] = i * mDefaultFrameDuration;
            }
        }
        
        // frame manipulation
        
        /** Adds an additional frame, optionally with a sound and a custom duration. If the 
         *  duration is omitted, the default framerate is used (as specified in the constructor). */   
        public function addFrame(texture:Texture, sound:Sound=null, duration:Number=-1):void
        {
            addFrameAt(numFrames, texture, sound, duration);
        }
        
        /** Adds a frame at a certain index, optionally with a sound and a custom duration. */
		/** xp如果duration传小于0，就说明用默认的间隔值**/
        public function addFrameAt(frameID:int, texture:Texture, sound:Sound=null, 
                                   duration:Number=-1):void
        {
            if (frameID < 0 || frameID > numFrames) throw new ArgumentError("Invalid frame id");
            if (duration < 0) duration = mDefaultFrameDuration;
            
            mTextures.splice(frameID, 0, texture);
            mSounds.splice(frameID, 0, sound);
            mDurations.splice(frameID, 0, duration);
            //xp这里必须大于0，因为-1是没有开始时间和持续时间的
            if (frameID > 0 && frameID == numFrames) 
                mStartTimes[frameID] = mStartTimes[int(frameID-1)] + mDurations[int(frameID-1)];
            else
                updateStartTimes();
        }
        
        /** Removes the frame at a certain ID. The successors will move down. */
        public function removeFrameAt(frameID:int):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            if (numFrames == 1) throw new IllegalOperationError("Movie clip must not be empty");
            
            mTextures.splice(frameID, 1);
            mSounds.splice(frameID, 1);
            mDurations.splice(frameID, 1);
            
            updateStartTimes();
        }
        
        /** Returns the texture of a certain frame. */
        public function getFrameTexture(frameID:int):Texture
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mTextures[frameID];
        }
        
        /** Sets the texture of a certain frame. */
        public function setFrameTexture(frameID:int, texture:Texture):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mTextures[frameID] = texture;
        }
        
        /** Returns the sound of a certain frame. */
        public function getFrameSound(frameID:int):Sound
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mSounds[frameID];
        }
        
        /** Sets the sound of a certain frame. The sound will be played whenever the frame 
         *  is displayed. */
        public function setFrameSound(frameID:int, sound:Sound):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mSounds[frameID] = sound;
        }
        
        /** Returns the duration of a certain frame (in seconds). */
        public function getFrameDuration(frameID:int):Number
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            return mDurations[frameID];
        }
        
        /** Sets the duration of a certain frame (in seconds). */
        public function setFrameDuration(frameID:int, duration:Number):void
        {
            if (frameID < 0 || frameID >= numFrames) throw new ArgumentError("Invalid frame id");
            mDurations[frameID] = duration;
            updateStartTimes();
        }
        
        // playback methods
        
        /** Starts playback. Beware that the clip has to be added to a juggler, too! */
        public function play():void
        {
            mPlaying = true;
        }
        
        /** Pauses playback. */
        public function pause():void
        {
            mPlaying = false;
        }
        
        /** Stops playback, resetting "currentFrame" to zero. */
        public function stop():void
        {
            mPlaying = false;
            currentFrame = 0;
        }
        
        // helpers
        
        private function updateStartTimes():void
        {
            var numFrames:int = this.numFrames;
            
            mStartTimes.length = 0;
            mStartTimes[0] = 0;
            
            for (var i:int=1; i<numFrames; ++i)
                mStartTimes[i] = mStartTimes[int(i-1)] + mDurations[int(i-1)];
        }
        
        // IAnimatable
        
        /** @inheritDoc */
        public function advanceTime(passedTime:Number):void
        {
            if (!mPlaying || passedTime <= 0.0) return;
            
            var finalFrame:int;
            var previousFrame:int = mCurrentFrame;
            var restTime:Number = 0.0;
            var breakAfterFrame:Boolean = false;
            var hasCompleteListener:Boolean = hasEventListener(Event.COMPLETE); 
            var dispatchCompleteEvent:Boolean = false;
            var totalTime:Number = this.totalTime;
			//xp帧是否改变了
			var currentFrameIsChange:Boolean = false;
            //xp这里当前时间肯定不会大于总时间，有点误导，删除
            if (mLoop && mCurrentTime == totalTime)
            { 
                mCurrentTime = 0.0; 
                mCurrentFrame = 0; 
				currentFrameIsChange = true;
            }
            //xp有时间差，才可以播放动画（这个条件肯定是成立，其实没什么用）
            if (mCurrentTime < totalTime)
            {
                mCurrentTime += passedTime;
                finalFrame = mTextures.length - 1;
                
                while (mCurrentTime > mStartTimes[mCurrentFrame] + mDurations[mCurrentFrame])
                {
                    if (mCurrentFrame == finalFrame)
                    {
						
						//xp是loop并且没有完成事件
						//xp这是继续的循环啊，是loop，如果没有完成事件的话，继续走while
						//这是有好处的，不用再调advanceTime了
                        if (mLoop && !hasCompleteListener)
                        {
                            mCurrentTime -= totalTime;
                            mCurrentFrame = 0;
							currentFrameIsChange = true;
                        }
						//xp这里就是1：不是loop，没有完成事件，2：是loop，有完成事件，3：不是loop，有完成事件
						//xp：那就先发个事件再走，1，3：都不用走while了，直接完成就完事儿了
                        else
                        {
                            breakAfterFrame = true;
                            restTime = mCurrentTime - totalTime;
                            dispatchCompleteEvent = hasCompleteListener;
                            mCurrentFrame = finalFrame;
							currentFrameIsChange = true;
                            mCurrentTime = totalTime;
                        }
                    }
					//xp这里可能会到最后一帧，并且时间跟最后一帧的最后时间恰巧相等，所以会下面有判断最后一帧并且时间相等
                    else
                    {
                        mCurrentFrame++;
						currentFrameIsChange = true;
                    }
                    //xp这里可能播放两次音效，到最后一帧开始播放，结束时也可能播放（？）
                    //var sound:Sound = mSounds[mCurrentFrame];
                    //if (sound) sound.play();
                    if (breakAfterFrame) break;
                }
                
                // special case when we reach *exactly* the total time.
				//xp有用，while循环是大于，才走，等于的话，直接发事件就可以了，不用做切换
				//因为这是最后一帧了，不能再往下切换了
                if (mCurrentFrame == finalFrame && mCurrentTime == totalTime)
                    dispatchCompleteEvent = hasCompleteListener;
            }
            
            if (mCurrentFrame != previousFrame){
                texture = mTextures[mCurrentFrame];
			}
            //xp把音效放在这里比较好,如果帧有所变化，就播放音乐
			if(currentFrameIsChange){
				var sound:Sound = mSounds[mCurrentFrame];
				if (sound) sound.play();
			}
            if (dispatchCompleteEvent)
                dispatchEventWith(Event.COMPLETE);
			
			//如果是loop并且有剩余没用的时间，才有意义走动画
			//如果事件回调，改变了loop的值，也就没有必要再走这里了
            if (mLoop && restTime > 0.0)
                advanceTime(restTime);
        }
        
        /** Indicates if a (non-looping) movie has come to its end. */
        public function get isComplete():Boolean 
        {
			//这里的大于条件，根本就不会存在，改成==
            return !mLoop && mCurrentTime == totalTime;
        }
        
        // properties  
        
        /** The total duration of the clip in seconds. */
        public function get totalTime():Number 
        {
            var numFrames:int = mTextures.length;
            return mStartTimes[int(numFrames-1)] + mDurations[int(numFrames-1)];
        }
        
        /** The time that has passed since the clip was started (each loop starts at zero). */
        public function get currentTime():Number { return mCurrentTime; }
        
        /** The total number of frames. */
        public function get numFrames():int { return mTextures.length; }
        
        /** Indicates if the clip should loop. */
        public function get loop():Boolean { return mLoop; }
        public function set loop(value:Boolean):void { mLoop = value; }
        
        /** The index of the frame that is currently displayed. */
        public function get currentFrame():int { return mCurrentFrame; }
        public function set currentFrame(value:int):void
        {
            mCurrentFrame = value;
            mCurrentTime = 0.0;
            
            for (var i:int=0; i<value; ++i)
                mCurrentTime += getFrameDuration(i);
            
            texture = mTextures[mCurrentFrame];
            if (mSounds[mCurrentFrame]) mSounds[mCurrentFrame].play();
        }
        
        /** The default number of frames per second. Individual frames can have different 
         *  durations. If you change the fps, the durations of all frames will be scaled 
         *  relatively to the previous value. */
        public function get fps():Number { return 1.0 / mDefaultFrameDuration; }
        public function set fps(value:Number):void
        {
            if (value <= 0) throw new ArgumentError("Invalid fps: " + value);
            
            var newFrameDuration:Number = 1.0 / value;
            var acceleration:Number = newFrameDuration / mDefaultFrameDuration;
            mCurrentTime *= acceleration;
            mDefaultFrameDuration = newFrameDuration;
            
            for (var i:int=0; i<numFrames; ++i) 
            {
                var duration:Number = mDurations[i] * acceleration;
                mDurations[i] = duration;
            }
            
            updateStartTimes();
        }
        
        /** Indicates if the clip is still playing. Returns <code>false</code> when the end 
         *  is reached. */
        public function get isPlaying():Boolean 
        {
            if (mPlaying)
                return mLoop || mCurrentTime < totalTime;
            else
                return false;
        }
		//xp资源释放
		override public function dispose():void{
			mTextures.length = 0;
			mSounds.length = 0;
			mDurations.length = 0;
			mStartTimes.length = 0;
			mTextures = null;
			mSounds = null;
			mDurations = null;
			mStartTimes = null;
			super.dispose();
		}
    }
}