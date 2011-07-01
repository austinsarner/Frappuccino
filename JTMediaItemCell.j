/* 
 * Copyright (C) 2010 by Austin Sarner and Mark Davis
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

var SHOW_TITLE = NO;
var TITLE_FIELD_HEIGHT = 25.0;
var SHADOW_SIZE = 7.0;
var animatingFadeIn = NO;
var animatingFadeInInitiator = nil;

@implementation JTMediaItemCell : FPCell
{
	var mediaItemViewsBeingDragged @accessors;
	var blockSelection;
	var inspectorButton;
	var dragClickOffset @accessors;
	var validClick;
	var filteredOut @accessors;
	var beingFilteredIn @accessors;
	var beingFilteredOut @accessors;
	var startingAlphaForFilteringFade @accessors;
	var filteringFadeTimeScale @accessors;
	var uniqueID @accessors;
	
	var displayTitle @accessors;
	var displayBorder @accessors;
	var displayLargeBorder @accessors;
	
	CGRect frame;
	CGRect alphaValue @accessors;
	
	var imageRect @accessors;
	
	var cachedImageData;
	var needsToRedrawImage;
	var containingBrowserBeingZoomed;
	
	var animatingInAfterLoad;
	var redisplayWhileLoading;
	
	var needsToRecalculateImageRect;
	
	BOOL _drawUsedCachedImage;
	BOOL _drawAlpha;
	BOOL shouldIgnoreSelection @accessors;
	
	BOOL loadingThumbnail;
	var imageSize;
	
	CPImage image @accessors;
}

- (id)initWithRepresentedObject:(var)newRepresentedObject
{
	if (self = [super init]) {
				
		[self setRepresentedObject:newRepresentedObject];
		imageSize = [newRepresentedObject mediaSize];


		shouldIgnoreSelection = NO;
		displayBorder = YES;
		displayLargeBorder = NO;
		animatingInAfterLoad = NO;
		redisplayWhileLoading = NO;
		loadingThumbnail = NO;
		image = nil;

		[self setTitle:[representedObject name]];
		_drawAlpha = 1.0;
		alphaValue = 1.0;
		frame = CGRectMakeZero();
		imageRect = CGRectMakeZero();
		
		startingAlphaForFilteringFade = 1.0;
		filteringFadeTimeScale = 1.0;
		
		containingBrowserBeingZoomed = NO;
		needsToRedrawImage = YES;
		filteredOut = NO;
		validClick = NO;
		[self setState:FPOffState];
		blockSelection = NO;
		beingFilteredOut = NO;
		displayTitle = NO;
		needsToRecalculateImageRect = NO;
		
		cachedImageData = nil;
		
		return self;
	}
	
	return nil;
}

- (void)finishedLoadingThumbnailImage:(var)sender
{	
	// image = [representedObject thumbnailImage];
	// needsToRecalculateImageRect = YES;
	// [controlView setNeedsDisplay:YES];
	// return;
	loadingThumbnail = NO;
	_drawAlpha = 0.0;
	
	if (!animatingFadeIn) {
		
		animatingFadeInInitiator = self;
		animatingFadeIn = YES;
		redisplayWhileLoading = YES;
	}
	
	animatingInAfterLoad = YES;
	
	var fadeInAnimation = [[FPAnimation alloc] initWithDuration:0.22 animationCurve:FPAnimationEaseInOut];
	[fadeInAnimation setDelegate:self];
	[fadeInAnimation startAnimation];
}

- (void)sizeCalculated
{
	imageSize = [representedObject mediaSize];
	
	needsToRecalculateImageRect = YES;
	[controlView setNeedsDisplay];
}

- (void)animationFired:(FPAnimation)animation
{	
	_drawAlpha = [animation currentValue];

	if (redisplayWhileLoading)
		[controlView setNeedsDisplay:YES];
}

- (void)animationFinished:(FPAnimation)animation
{
	_drawAlpha = 1.0;
	animatingInAfterLoad = NO;
	redisplayWhileLoading = NO;
	if (animatingFadeIn == YES && animatingFadeInInitiator == self) {
		animationFadeInInitiator = nil;
		animatingFadeIn = NO;
	}
	
	[controlView setNeedsDisplay:YES];
}

- (void)drawWithFrame:(CGRect)drawFrame useCachedImageIfAvailable:(BOOL)useCachedImageIfAvailable alpha:(float)alpha
{
	_drawUsedCachedImage = useCachedImageIfAvailable;
	if (animatingFadeIn)
		_drawAlpha = alpha;
	[self drawWithFrame:drawFrame inView:nil];
}

- (var)proportionallyScaledFrameForSize:(CGSize)size inFrame:(CGRect)containerFrame
{
	var scaledRect = CGRectMake(0.0,0.0,containerFrame.size.width,containerFrame.size.height);

	var width = size.width;
	var height = size.height;

	var targetWidth = containerFrame.size.width;
	var targetHeight = containerFrame.size.height;

	if (displayTitle)
		targetHeight -= 16.0;

	var scaleFactor = 1.0;
	var scaledWidth = targetWidth;
	var scaledHeight = targetHeight;

	var widthFactor = targetWidth / width;
    var heightFactor = targetHeight / height;
	
	var useWidth = (widthFactor < heightFactor);
	
    if (useWidth)
      scaleFactor = widthFactor;
    else
      scaleFactor = heightFactor;

    scaledWidth = width  * scaleFactor;
    scaledHeight = height * scaleFactor;

    if (useWidth)
      scaledRect.origin.y += (targetHeight - scaledHeight) * 0.5;
    else if (widthFactor > heightFactor)
      scaledRect.origin.x += (targetWidth - scaledWidth) * 0.5;

	scaledRect.size.width = scaledWidth;
	scaledRect.size.height = scaledHeight;
	
	return scaledRect;
}

- (void)drawPlaceholderInFrame:(CGRect)drawFrame
{
	[[CPColor colorWithCalibratedWhite:0.15 alpha:1.0] set];
	var adjustedDrawingFrame = CGRectIntegral(CGRectMake(drawFrame.origin.x + imageRect.origin.x,drawFrame.origin.y + imageRect.origin.y,imageRect.size.width,imageRect.size.height));
	[CPBezierPath fillRect:adjustedDrawingFrame];
	[[CPColor colorWithCalibratedWhite:0.30 alpha:1.0] set];
	[CPBezierPath strokeRect:CGRectInset(adjustedDrawingFrame,0.5,0.5)];
}

- (void)drawWithFrame:(CGRect)drawFrame inView:(CPView)view
{
	drawFrame = CGRectInset(drawFrame,SHADOW_SIZE,SHADOW_SIZE);
	
	//CPLog(@"draw %@ with frame",[self title]);
	[CPGraphicsContext saveGraphicsState];
	if ([representedObject thumbnailLoaded] == NO && ![representedObject loadingThumbnail]) {
		[representedObject cacheThumbnailWithDelegate:self];
		loadingThumbnail = YES;
		imageRect = [self proportionallyScaledFrameForSize:imageSize inFrame:drawFrame];
		[self drawPlaceholderInFrame:drawFrame];
		return;
	} else if (image == nil) {
		image = [representedObject thumbnailImage];
		needsToRecalculateImageRect = YES;
	}
	
	if (loadingThumbnail) {
		[self drawPlaceholderInFrame:drawFrame];
		return;
	}
	
	if ([image loadStatus] != CPImageLoadStatusCompleted)
		return;
	
	var ctx = [[CPGraphicsContext currentContext] graphicsPort];

	if (animatingInAfterLoad || containingBrowserBeingZoomed || needsToRedrawImage || !_drawUsedCachedImage) {
		
		if (needsToRecalculateImageRect || containingBrowserBeingZoomed) {
			imageRect = [self proportionallyScaledFrameForSize:imageSize inFrame:drawFrame];
		}

		var adjustedDrawingFrame = CGRectIntegral(CGRectMake(drawFrame.origin.x + imageRect.origin.x,drawFrame.origin.y + imageRect.origin.y,imageRect.size.width,imageRect.size.height));
		
		// If the zoom slider is being dragged ignore all the other fancy stuff and just get it on screen
		if (containingBrowserBeingZoomed || animatingInAfterLoad) {
			[self drawPlaceholderInFrame:drawFrame];
			[image drawInRect:adjustedDrawingFrame fraction:_drawAlpha];
			return;
		}
		
		// Selection highlight
		if ([self state]==FPOnState && !shouldIgnoreSelection) {
			var selectionPath = [CPBezierPath bezierPath];
			[selectionPath appendBezierPathWithRoundedRect:CGRectInset(adjustedDrawingFrame,-3.0,-3.0) xRadius:5.0 yRadius:5.0];
			[[CPColor colorWithCalibratedRed:0.960 green:0.800 blue:0.249 alpha:_drawAlpha] set];
			[selectionPath fill];
		}
	
		// Shadow
		if (!CPBrowserIsEngine(CPGeckoBrowserEngine))
			[[FPShadow shadowWithOffset:CPMakePoint(0,0) blur:SHADOW_SIZE color:[[CPColor blackColor] colorWithAlphaComponent:_drawAlpha]] set];
		else
		{
			//var shadowColor = [CPColor colorWithCalibratedWhite:0.0 alpha:0.5];
			for (var i=0;i<7;i++)
			{
				var shadowRect = CGRectInset(adjustedDrawingFrame,-7+i,-7+i);

				//[[shadowColor colorWithAlphaComponent:0.1+0.05*i] set];
				[[CPColor colorWithCalibratedWhite:0.0 alpha:(0.02*i)*_drawAlpha] set];
				var shadowPath = [CPBezierPath bezierPath];
				[shadowPath appendBezierPathWithRoundedRect:shadowRect xRadius:5.0 yRadius:5.0];
				[shadowPath fill];
			}
		}
		
		// Image + white outline
		[image drawInRect:adjustedDrawingFrame fraction:_drawAlpha];
		
		if (displayBorder) {

			// White outline
			
			if (displayLargeBorder) {
				
				[[[CPColor whiteColor] colorWithAlphaComponent:.875] set];
				var outlinePath = [CPBezierPath bezierPathWithRect:CGRectInset(adjustedDrawingFrame,2.5,2.5)];
				[outlinePath setLineWidth:5.0]
				[outlinePath stroke];
				
			} else {
				[[[CPColor whiteColor] colorWithAlphaComponent:.12 * _drawAlpha] set];
				var outlinePath = [CPBezierPath bezierPathWithRect:CGRectInset(adjustedDrawingFrame,0.5,0.5)];
				[outlinePath setLineWidth:0.5]
				[outlinePath stroke];
	
				[[[CPColor whiteColor] colorWithAlphaComponent:.35 * _drawAlpha] set];
				adjustedDrawingFrame.size.height = 0.5;
				outlinePath = [CPBezierPath bezierPathWithRect:adjustedDrawingFrame];
				[outlinePath fill];
			}	
		}
		
		// Title
		if (displayTitle) {

			var titleRect = CPRectCreateCopy(drawFrame);
			titleRect.origin.y += titleRect.size.height - 16.0;
			titleRect.origin.x += 5.0;
			titleRect.size.width -= 10.0;
			titleRect.size.height = 15.0;
			
			if (displayLargeBorder) {
				[[FPShadow shadowWithOffset:CPMakePoint(0,1) blur:3.0 color:[[CPColor blackColor] colorWithAlphaComponent:1.0]] set];
				
				[[CPColor whiteColor] set];
				[[self title] drawInRect:titleRect withFont:[CPFont boldSystemFontOfSize:13.0] alignment:CPCenterTextAlignment];
				
			} else {
				[[FPShadow shadowWithOffset:CPMakePoint(0,-1) blur:1.0 color:[[CPColor blackColor] colorWithAlphaComponent:1.0]] set];
				
				[[[CPColor whiteColor] colorWithAlphaComponent:0.6] set];
				[[self title] drawInRect:titleRect withFont:[CPFont systemFontOfSize:13.0] alignment:CPCenterTextAlignment];
			}
		}

		// Caching
		if (_drawUsedCachedImage && !animatingInAfterLoad) {
			cachedImageData = FPContextGetImageData(ctx,CGRectInset(drawFrame,-SHADOW_SIZE,-SHADOW_SIZE));
			needsToRedrawImage = NO;
		}
	} else
		ctx.putImageData(cachedImageData,drawFrame.origin.x-SHADOW_SIZE,drawFrame.origin.y-SHADOW_SIZE);
	[CPGraphicsContext restoreGraphicsState];
	
	shouldIgnoreSelection = NO;
	_drawAlpha = 1.0;
	_drawUsedCachedImage = YES;
}

- (var)imageRectWithFrameOffset
{
	return CGRectIntegral(CGRectMake(frame.origin.x + imageRect.origin.x + SHADOW_SIZE,frame.origin.y + imageRect.origin.y + SHADOW_SIZE,imageRect.size.width,imageRect.size.height));
}

- (void)setSelected:(BOOL)isSelected
{
	if ([self isSelected] != isSelected) {
		[self setState:isSelected?FPOnState:FPOffState];
		needsToRedrawImage = YES;
	}
}

- (void)mouseDown:(CPEvent)event
{
	if (![self isSelected])
	{
		var extendSelection = ([event modifierFlags] & CPCommandKeyMask);
		if (!extendSelection)
			[controlView deselectAllMediaItems];

		[self setSelected:YES];
		[controlView setNeedsDisplay:YES];
		[controlView selectionChanged];
	}

	if ([event clickCount] == 2)
	{
		[controlView cell:self doubleClicked:event];
		return;
	}
	
	[controlView cell:self beganDrag:event];
}

- (BOOL)isSelected
{
	return ([self state]==FPOnState);
}

- (CGRect)frame
{
	return frame;
}

- (void)setLayoutFrame:(CGRect)newFrame
{		
	// If the size changed then we need to redraw
	if (containingBrowserBeingZoomed || !CGSizeEqualToSize(newFrame.size,frame.size)) {
		containingBrowserBeingZoomed = NO;
		needsToRedrawImage = YES;
	}
	
	frame = CPRectCreateCopy(newFrame);
}

- (void)setLayoutFrameWithoutRedrawing:(CGRect)newFrame
{	
	if (containingBrowserBeingZoomed == NO) {
		containingBrowserBeingZoomed = YES;
		needsToRedrawImage = NO;
	}
	
	frame = CPRectCreateCopy(newFrame);
}

- (void)setFrameOrigin:(CGPoint)newFrameOrigin
{	
	frame.origin = newFrameOrigin;
}

- (void)inspectorButtonClicked
{
	[[self superview] showInspectorForMediaItem:self];
}

- (BOOL)acceptsFirstResponder
{
	return NO;
}

@end