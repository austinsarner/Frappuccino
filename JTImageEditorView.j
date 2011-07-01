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

var MAXIMUM_GUIDE_ALPHA = 0.7;
var	GUIDE_FADE_DURATION = 0.18;

@implementation JTImageEditorView : CPView
{
	CPImage 	image @accessors;
	CGRect		imageRect;
	CGRect 		croppingRect;
	
	BOOL		drawingCropBox;
	CGPoint		drawnCropBoxOrigin;
	
	BOOL 		cropped;
	BOOL		cropping @accessors;
	CGPoint		clickOffset @accessors;
	BOOL		draggingCropBox @accessors;
	BOOL		dragResizingCropBox;
	var			draggingCorner;
	
	FPAnimation	guidesAnimation;
	var			guidesAlpha;
	BOOL		fadingOutGuides;
	
	var drawRect;
}

- (void)setImage:(CPImage)aImage
{
	drawingCropBox = NO;
	draggingCorner = -1;
	fadingOutGuides = NO;
	draggingCropBox = NO;
	dragResizingCropBox = NO;
	cropped = NO;
	image = aImage;
	imageRect = [self proportionallyScaledFrameForSize:[image size] inFrame:[self frame]];
	
	var defaultCropAmount = 0.35;
	var width = Math.floor([image size].width * defaultCropAmount);
	var height = Math.floor([image size].height * defaultCropAmount);
	
	croppingRect = CGRectMake(1.0,1.0,width,height);

	[self setNeedsDisplay:YES];
}

- (void)setCropping:(BOOL)isCropping
{
	if (cropping) {
		imageRect = [self proportionallyScaledFrameForSize:[image size] inFrame:[self frame]];
		cropped = NO;
	}
	
	cropping = isCropping;
	[self valueForKey:@"_DOMElement"].style.cursor = /*isCropping?"crosshair":*/"default";
	[self setNeedsDisplay:YES];
}

- (void)crop
{
	if (!cropping)
		return;
		
	cropping = NO;
	cropped = YES;
	imageRect = [self proportionallyScaledFrameForSize:croppingRect.size inFrame:[self frame]];
	
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(CPRect)aRect
{
	if (cropping) {
		[image drawInRect:imageRect fraction:1.0];
		drawRect = CPRectCreateCopy(croppingRect);

		var widthFactor = (imageRect.size.width / [image size].width);
		var heightFactor = (imageRect.size.height / [image size].height);
		
		drawRect.origin.x *= widthFactor;
		drawRect.origin.y *= heightFactor;
		drawRect.origin.x += imageRect.origin.x;
		drawRect.origin.y += imageRect.origin.y;
		drawRect.size.width *= widthFactor;
		drawRect.size.height *= heightFactor;

		drawRect.size.width = Math.floor(drawRect.size.width);
		drawRect.size.height = Math.floor(drawRect.size.height);
		drawRect.origin.x = Math.floor(drawRect.origin.x);
		drawRect.origin.y = Math.floor(drawRect.origin.y);
				
		[[CPColor whiteColor] set];
		[CPBezierPath strokeRect:CGRectInset(drawRect,-0.5,-0.5)];
		
		[[CPColor colorWithCalibratedWhite:0.0 alpha:0.7] set];
		var borderPath = [CPBezierPath bezierPath];
		
		[borderPath appendBezierPathWithRect:CGRectMake(imageRect.origin.x,imageRect.origin.y,imageRect.size.width,(drawRect.origin.y - imageRect.origin.y) - 1.0)];
		[borderPath appendBezierPathWithRect:CGRectMake(imageRect.origin.x,imageRect.origin.y,(drawRect.origin.x - imageRect.origin.x) - 1.0,imageRect.size.height)];
		[borderPath appendBezierPathWithRect:CGRectMake(drawRect.origin.x + drawRect.size.width + 1.0,imageRect.origin.y,imageRect.size.width - (drawRect.size.width + (drawRect.origin.x - imageRect.origin.x)),imageRect.size.height)];
		[borderPath appendBezierPathWithRect:CGRectMake(imageRect.origin.x,drawRect.origin.y + drawRect.size.height + 1.0,imageRect.size.width,imageRect.size.height - (drawRect.size.height + (drawRect.origin.y - imageRect.origin.y)))];
	
		[borderPath fill];
		
		// debug -- draw actual crop image cutout:
		//[image drawInRect:drawRect fromRect:croppingRect operation:CPCompositeSourceOver fraction:1.0];
		
		var smallCropBox = (drawRect.size.width < 35.0 || drawRect.size.height < 35.0);
		
		if (!smallCropBox && (draggingCropBox || dragResizingCropBox || fadingOutGuides || drawingCropBox)) {
			
			[[CPColor colorWithCalibratedWhite:1.0 alpha:guidesAlpha] set];
			
			var ySpacing = drawRect.size.height / 3.0;
			[CPBezierPath fillRect:CGRectMake(drawRect.origin.x,Math.floor(drawRect.origin.y + ySpacing),drawRect.size.width,1.0)];
			[CPBezierPath fillRect:CGRectMake(drawRect.origin.x,Math.floor(drawRect.origin.y + ySpacing * 2.0),drawRect.size.width,1.0)];
			
			var xSpacing = drawRect.size.width / 3.0;
			[CPBezierPath fillRect:CGRectMake(Math.floor(drawRect.origin.x + xSpacing),drawRect.origin.y,1.0,drawRect.size.height)];
			[CPBezierPath fillRect:CGRectMake(Math.floor(drawRect.origin.x + xSpacing * 2.0),drawRect.origin.y,1.0,drawRect.size.height)];
		}
		
		[[CPColor colorWithCalibratedWhite:0.85 alpha:1.0] set];
		
		var handleThickness = smallCropBox ? 3.0 : 4.0;
		var handleSize = smallCropBox ? 8.0 : 20.0;
		
		[CPBezierPath fillRect:CGRectMake(drawRect.origin.x - handleThickness,drawRect.origin.y - handleThickness,handleThickness,handleSize)];
		[CPBezierPath fillRect:CGRectMake(drawRect.origin.x - handleThickness,drawRect.origin.y - handleThickness,handleSize,handleThickness)];
		
		[CPBezierPath fillRect:CGRectMake(drawRect.origin.x + drawRect.size.width,drawRect.origin.y - handleThickness,handleThickness,handleSize)];
		[CPBezierPath fillRect:CGRectMake(drawRect.origin.x + drawRect.size.width - (handleSize - handleThickness),drawRect.origin.y - handleThickness,handleSize,handleThickness)];
		
		[CPBezierPath fillRect:CGRectMake(drawRect.origin.x - handleThickness,drawRect.origin.y + drawRect.size.height - (handleSize - handleThickness),handleThickness,handleSize)];
		[CPBezierPath fillRect:CGRectMake(drawRect.origin.x - handleThickness,drawRect.origin.y + drawRect.size.height,handleSize,handleThickness)];
		
		[CPBezierPath fillRect:CGRectMake(drawRect.origin.x + drawRect.size.width,drawRect.origin.y + drawRect.size.height - (handleSize - handleThickness),handleThickness,handleSize)];
		[CPBezierPath fillRect:CGRectMake(drawRect.origin.x + drawRect.size.width - (handleSize - handleThickness),drawRect.origin.y + drawRect.size.height,handleSize,handleThickness)];
				
	} else if (cropped) {
		[image drawInRect:imageRect fromRect:croppingRect operation:CPCompositeSourceOver fraction:1.0];
	} else {
		[image drawInRect:imageRect fraction:cropping ? 0.5 : 1.0];
	}
}

- (void)mouseUp:(CPEvent)event
{
	if (dragResizingCropBox || draggingCropBox || drawingCropBox) {
		guidesAlpha = MAXIMUM_GUIDE_ALPHA;
	
		fadingOutGuides = YES;
		guidesAnimation = [[FPAnimation alloc] initWithDuration:GUIDE_FADE_DURATION animationCurve:FPAnimationEaseOut];
		[guidesAnimation setDelegate:self];
		[guidesAnimation startAnimation];
	}
	
	drawingCropBox = NO;
	draggingCorner = -1;
	dragResizingCropBox = NO;
	draggingCropBox = NO;
	[self setNeedsDisplay:YES];
}

- (void)mouseDown:(CPEvent)event
{
	if (cropping)
	{
		var location = [self convertPoint:[event locationInWindow] fromView:nil];

		var bottomRightDragResizingRect = CPRectCreateCopy(drawRect);
		bottomRightDragResizingRect.origin.x += bottomRightDragResizingRect.size.width - 10.0;
		bottomRightDragResizingRect.size.width = 20.0;
		bottomRightDragResizingRect.origin.y += bottomRightDragResizingRect.size.height - 10.0;
		bottomRightDragResizingRect.size.height = 20.0;
		
		var topRightDragResizingRect = CPRectCreateCopy(drawRect);
		topRightDragResizingRect.origin.x += topRightDragResizingRect.size.width - 10.0;
		topRightDragResizingRect.size.width = 20.0;
		topRightDragResizingRect.origin.y -= 10.0;
		topRightDragResizingRect.size.height = 20.0;
		
		var bottomLeftDragResizingRect = CPRectCreateCopy(drawRect);
		bottomLeftDragResizingRect.origin.x -= 10.0;
		bottomLeftDragResizingRect.size.width = 20.0;
		bottomLeftDragResizingRect.origin.y += bottomLeftDragResizingRect.size.height - 10.0;
		bottomLeftDragResizingRect.size.height = 20.0;
		
		var topLeftDragResizingRect = CPRectCreateCopy(drawRect);
		topLeftDragResizingRect.origin.x -= 10.0;
		topLeftDragResizingRect.size.width = 20.0;
		topLeftDragResizingRect.origin.y -= 10.0;
		topLeftDragResizingRect.size.height = 20.0;
		
		if (CGRectContainsPoint(bottomRightDragResizingRect,location)) {
			draggingCorner = 2;
			dragResizingCropBox = YES;
			
		} else if (CGRectContainsPoint(topRightDragResizingRect,location)) {
			draggingCorner = 1;
			dragResizingCropBox = YES;
			
		} else if (CGRectContainsPoint(bottomLeftDragResizingRect,location)) {
			draggingCorner = 3;
			dragResizingCropBox = YES;
			
		} else if (CGRectContainsPoint(topLeftDragResizingRect,location)) {
			draggingCorner = 0;
			dragResizingCropBox = YES;

		} else if (CGRectContainsPoint(drawRect,location)) {
			draggingCropBox = YES;
			clickOffset = CGPointMake(location.x-drawRect.origin.x,location.y-drawRect.origin.y);
			
		} else {
			drawnCropBoxOrigin = CGPointMake(location.x,location.y);
			drawingCropBox = YES;
			return;
		}
		
		guidesAlpha = 0.0;
		
		guidesAnimation = [[FPAnimation alloc] initWithDuration:GUIDE_FADE_DURATION animationCurve:FPAnimationEaseIn];
		[guidesAnimation setDelegate:self];
		[guidesAnimation startAnimation];
		
		[self setNeedsDisplay:YES];
	}
}

- (void)animationFired:(FPAnimation)animation
{	
	if (fadingOutGuides)
		guidesAlpha = (1.0 - [animation currentValue]) * MAXIMUM_GUIDE_ALPHA;
	else
		guidesAlpha = [animation currentValue] * MAXIMUM_GUIDE_ALPHA;
	
	[self setNeedsDisplay:YES];
}

- (void)animationFinished:(FPAnimation)animation
{
	guidesAlpha = MAXIMUM_GUIDE_ALPHA;
	guidesAnimation = nil;
	fadingOutGuides = NO;
	
	[self setNeedsDisplay:YES];
}

- (void)mouseDragged:(CPEvent)event
{
	var location = [self convertPoint:[event locationInWindow] fromView:nil];
	var widthFactor = ([image size].width / imageRect.size.width);
	var heightFactor = ([image size].height / imageRect.size.height);

	if (dragResizingCropBox) {
		
		// Bottom Right
		if (draggingCorner == 2) {
			croppingRect.size.width = Math.floor((location.x - drawRect.origin.x) * widthFactor);
			croppingRect.size.height = Math.floor((location.y - drawRect.origin.y) * heightFactor);
			
		// Top Right
		} else if (draggingCorner == 1) {
			var newYLocation = (location.y - imageRect.origin.y) * heightFactor;
			croppingRect.size.height = croppingRect.size.height + (croppingRect.origin.y - newYLocation);
			croppingRect.origin.y = newYLocation;
			croppingRect.size.width = Math.floor((location.x - drawRect.origin.x) * widthFactor);
		
		// Bottom Left
		} else if (draggingCorner == 3) {
	
			var newXLocation = (location.x - imageRect.origin.x) * heightFactor;
			croppingRect.size.width = croppingRect.size.width + (croppingRect.origin.x - newXLocation);
			croppingRect.origin.x = newXLocation;
			croppingRect.size.height = Math.floor((location.y - drawRect.origin.y) * heightFactor);
		
		// Top Left
		} else if (draggingCorner == 0) {

			var newXLocation = (location.x - imageRect.origin.x) * heightFactor;
			croppingRect.size.width = croppingRect.size.width + (croppingRect.origin.x - newXLocation);
			croppingRect.origin.x = newXLocation;
			
			var newYLocation = (location.y - imageRect.origin.y) * heightFactor;
			croppingRect.size.height = croppingRect.size.height + (croppingRect.origin.y - newYLocation);
			croppingRect.origin.y = newYLocation;
		}
			
	} else if (draggingCropBox && cropping)	{
		
		var location = [self convertPoint:[event locationInWindow] fromView:nil];
		location.x -= imageRect.origin.x;
		location.y -= imageRect.origin.y;
		location.x -= clickOffset.x;
		location.y -= clickOffset.y;
		
		if (location.x < 1.0)
			location.x = 1.0;
		else if (location.x + drawRect.size.width >= imageRect.size.width - 1.0)
			location.x = imageRect.size.width - drawRect.size.width - 1.0;
		
		if (location.y < 1.0)
			location.y = 1.0;
		else if (location.y + drawRect.size.height >= imageRect.size.height - 1.0)
			location.y = imageRect.size.height - drawRect.size.height - 1.0;

		location.x *= widthFactor
		location.y *= heightFactor;

		location.x = Math.floor(location.x);
		location.y = Math.floor(location.y);
		
		croppingRect.origin = location;
		[self setNeedsDisplay:YES];
		
	} else if (drawingCropBox) {
		
		var drawnCropBoxRect = CGRectMake(drawnCropBoxOrigin.x - imageRect.origin.x,drawnCropBoxOrigin.y - imageRect.origin.y,location.x - drawnCropBoxOrigin.x,location.y - drawnCropBoxOrigin.y);
		
		drawnCropBoxRect.origin.x *= widthFactor;
		drawnCropBoxRect.origin.y *= heightFactor;
		drawnCropBoxRect.size.width *= widthFactor;
		drawnCropBoxRect.size.height *= heightFactor;
		
		if (drawnCropBoxRect.size.width < 0)
		{
			drawnCropBoxRect.origin.x += drawnCropBoxRect.size.width;
			drawnCropBoxRect.size.width *= -1;
		}
		if (drawnCropBoxRect.size.height < 0)
		{
			drawnCropBoxRect.origin.y += drawnCropBoxRect.size.height;
			drawnCropBoxRect.size.height *= -1;
		}
		
		croppingRect = drawnCropBoxRect;
	}
	
	if (croppingRect.origin.x < 1.0) {
		croppingRect.size.width -= Math.abs(1.0 - croppingRect.origin.x);
		croppingRect.origin.x = 1.0;
	}
	
	if (croppingRect.origin.y < 1.0) {
		croppingRect.size.height -= Math.abs(1.0 - croppingRect.origin.y);
		croppingRect.origin.y = 1.0;
	}
	
	var imageWidth = [image size].width - 1.0;
	var remainingWidth = (croppingRect.origin.x + croppingRect.size.width);
	if (remainingWidth >= imageWidth)
		croppingRect.size.width -= Math.abs((croppingRect.origin.x + croppingRect.size.width) - imageWidth);

	var imageHeight = [image size].height - 1.0;
	var remainingHeight = (croppingRect.origin.y + croppingRect.size.height);
	if (remainingHeight >= imageHeight)
		croppingRect.size.height -= Math.abs((croppingRect.origin.y + croppingRect.size.height) - imageHeight);
		
	[self setNeedsDisplay:YES];
}

- (var)proportionallyScaledFrameForSize:(CGSize)size inFrame:(CGRect)containerFrame
{
	var scaledRect = CGRectMake(0.0,0.0,containerFrame.size.width,containerFrame.size.height);

	var width = size.width;
	var height = size.height;

	var targetWidth = containerFrame.size.width;
	var targetHeight = containerFrame.size.height;

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

	scaledRect.size.width = Math.floor(scaledWidth);
	scaledRect.size.height = Math.floor(scaledHeight);
	
	return scaledRect;
}

@end