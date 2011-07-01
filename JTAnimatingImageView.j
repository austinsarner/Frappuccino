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

@implementation JTAnimatingImageView : FPImageView 
{
	CPRect startingImageFrame @accessors;
	CPRect destinationImageFrame @accessors;
	CPRect actualImageFrame @accessors;
	id delegate @accessors;
	
	float dimmerAlpha;
	
	BOOL dimmingEnabled @accessors;
	
	BOOL animating @accessors;
	BOOL dimmingReversed @accessors;
	
	BOOL fadingInNewImage @accessors;
	CPImage newImageBeingFadedIn;
	float newImageAlpha;
	
	FPAnimation scaleAnimation;
	FPAnimation fadeAnimation;
	
	float overallAlpha;
	float maxDimmerAlpha @accessors;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame]) {
		animating = NO;
		dimmingEnabled = NO;
		dimmingReversed = NO;
		fadingInNewImage = NO;
		dimmerAlpha = 0.0;
		newImageAlpha = 0.0;
		overallAlpha = 1.0;
		maxDimmerAlpha = 1.0;
		newImageBeingFadedIn = nil;
	}
	
	return self;
}

- (void)setOverallAlpha:(float)newOverallAlpha
{
	overallAlpha = newOverallAlpha;
	[self setNeedsDisplay:YES];
}

- (void)setStartingImageFrame:(CPRect)newStartingImageFrame
{
	startingImageFrame = CPRectCreateCopy(newStartingImageFrame);
	actualImageFrame = CPRectCreateCopy(newStartingImageFrame);
}

- (void)setImage:(CPImage)image
{
	if (!animating && dimmerAlpha > 0.0) {
		fadingInNewImage = YES;
		newImageBeingFadedIn = image;
		newImageAlpha = 0.0;
		animating = YES;

		fadeAnimation = [[FPAnimation alloc] initWithDuration:0.25 animationCurve:FPAnimationEaseInOut];
		[fadeAnimation setDelegate:self];
		[fadeAnimation startAnimation];
	} else
		[[self cell] setImage:image];
}

- (void)mouseDown:(CPEvent)event
{
	if (animating)
		return;
		
	if (delegate && [event clickCount] == 1)
		[delegate animateOutImageView];
}

- (void)drawRect:(CPRect)aRect
{
	if (dimmingEnabled) {
		[[[CPColor blackColor] colorWithAlphaComponent:dimmerAlpha * overallAlpha] set];
		[CPBezierPath fillRect:aRect];
	}
	
	if (overallAlpha >= 1.0)
		[[self cell] drawWithFrame:actualImageFrame inView:self];
	else
		[[[self cell] image] drawInRect:actualImageFrame fraction:overallAlpha];
	
	if (fadingInNewImage)
		[newImageBeingFadedIn drawInRect:actualImageFrame fraction:newImageAlpha];
}

- (void)animateImage
{
	if (animating)
		return;
		
	animating = YES;
	
	scaleAnimation = [[FPAnimation alloc] initWithDuration:0.25 animationCurve:FPAnimationEaseInOut];
	[scaleAnimation setDelegate:self];
	[scaleAnimation startAnimation];
}

- (void)animationFired:(FPAnimation)animation
{
	var currentValue = [animation currentValue];
	
	if (animation == scaleAnimation) {
		
		if (dimmingEnabled) {
			var dimmerAlpha = dimmingReversed ? 1.0 - currentValue : currentValue;
	
			if (dimmerAlpha > maxDimmerAlpha)
				dimmerAlpha = maxDimmerAlpha;
		}
		
		var actualImageFrame = CPRectCreateCopy(startingImageFrame);
		actualImageFrame.origin.x = startingImageFrame.origin.x - (currentValue * (startingImageFrame.origin.x - destinationImageFrame.origin.x));
		actualImageFrame.origin.y = startingImageFrame.origin.y - (currentValue * (startingImageFrame.origin.y - destinationImageFrame.origin.y));
		actualImageFrame.size.width = startingImageFrame.size.width + (currentValue * (destinationImageFrame.size.width - startingImageFrame.size.width));
		actualImageFrame.size.height = startingImageFrame.size.height + (currentValue * (destinationImageFrame.size.height - startingImageFrame.size.height));
	
		[self display];
		
	} else if (animation == fadeAnimation) {
		newImageAlpha = currentValue;
		[self setNeedsDisplay:YES];
	}
}

- (void)animationFinished:(FPAnimation)animation
{		
	if (animation == scaleAnimation) {
		actualImageFrame = CPRectCreateCopy(destinationImageFrame);
		animating = NO;
		[self display];
		//[self setNeedsDisplay:YES];
	
		if (delegate)
			[delegate finishedAnimatingImageView:self];
			
	} else if (animation == fadeAnimation) {
		animating = NO;
		[super setImage:newImageBeingFadedIn];
		
		if (delegate)
			[delegate animatingImageView:self finishedFadingInNewImage:newImageBeingFadedIn];
		
		fadingInNewImage = NO;
		newImageBeingFadedIn = nil;
		newImageAlpha = 0.0;
	}
}

@end
