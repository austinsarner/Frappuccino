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

var ARROW_HEIGHT = 4;
var ARROW_WIDTH = 12;
var PULL_DISTANCE = 160;

function CPLogRect(rect)
{
	CPLog(@"{%f,%f,%f,%f}",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
}

@implementation MDAttachedPanel : CPPanel
{
	FPAnimation	fadeAnimation @accessors;
	FPAnimation	pullAnimation @accessors;
	CPView attachedView @accessors;
	BOOL fadeIn @accessors;
	CPRect	lockedFrame @accessors;
	CPPoint	lockPoint @accessors;
	BOOL	locked @accessors;
}

- (id)initWithContentRect:(CPRect)contentRect
{
	if (self = [super initWithContentRect:contentRect styleMask:CPBorderlessWindowMask])
	{
		lockedFrame = CPRectCreateCopy([self frame]);
		var contentView = [self contentView];
		attachedView = [[MDAttachedView alloc] initWithFrame:[contentView bounds]];
		[attachedView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
		[contentView addSubview:attachedView];
		[self setFloatingPanel:YES];
		
	}
	return self;
}

- (void)lockToPoint:(CPPoint)point
{
	self.lockPoint = point;
	lockedFrame.origin = CPMakePoint(point.x - lockedFrame.size.width/2,point.y-3);
	[self lock];
}

- (CPPoint)lockedPoint
{
	return CPMakePoint(lockPoint.x - [self frame].origin.x,0);
}

- (void)lock
{
	[self setFrame:lockedFrame];
	[self setLocked:YES];
	[attachedView resetDimensions];
}

- (void)fadeIn:(id)sender
{
	[self lock];
	[attachedView setNeedsDisplay:YES];
	fadeIn = YES;
	[attachedView setAlphaValue:0.0];
	self.fadeAnimation = [[FPAnimation alloc] initWithDuration:0.25 animationCurve:FPAnimationEaseInOut];
	[fadeAnimation setDelegate:self];
	[fadeAnimation startAnimation];
	[self orderFront:sender];
}

- (void)fadeOut:(id)sender
{
	fadeIn = NO;
	[attachedView setAlphaValue:1.0];
	self.fadeAnimation = [[FPAnimation alloc] initWithDuration:0.25 animationCurve:FPAnimationEaseInOut];
	[fadeAnimation setDelegate:self];
	[fadeAnimation startAnimation];
}

- (void)beginPullAnimation:(id)sender
{
	if (self.pullAnimation && [self.pullAnimation running]) return;
	
	self.pullAnimation = [[FPAnimation alloc] initWithDuration:0.1 animationCurve:FPAnimationEaseInOut];
	[pullAnimation setDelegate:self];
	[pullAnimation startAnimation];
}

- (void)shiftBy:(CPPoint)shiftBy
{
	var newFrame = CPRectCreateCopy([self lockedFrame]);
	newFrame.origin.x += shiftBy.x;
	newFrame.size.height += shiftBy.y;
	
	var minHeight = [self lockedFrame].size.height;
	if (newFrame.size.height < minHeight)
		newFrame.size.height = minHeight;
	[self setFrame:newFrame];
	
	[[self attachedView] resetDimensions];
}

- (CPPoint)shiftPoint
{
	return CPMakePoint([self frame].origin.x-[self lockedFrame].origin.x,[self frame].size.height-[self lockedFrame].size.height)
}

- (void)animationFired:(FPAnimation)animation
{
	if (animation == fadeAnimation)
	{
		var alphaValue = [animation currentValue];
		if (!fadeIn) alphaValue = 1.0 - alphaValue;
		[attachedView setAlphaValue:alphaValue];
	}
	else if (animation==pullAnimation && [self locked])
	{
		//pullShift.x -= pullShift.x * [animation currentValue];
		//pullShift.y -= pullShift.y * [animation currentValue];
		var xShift = -[self shiftPoint].x*[animation currentValue];
		var yShift = -[self shiftPoint].y*[animation currentValue];
		[self shiftBy:CPMakePoint(xShift,yShift)];
		//[self resetDimensions];
	}
}

- (void)animationFinished:(FPAnimation)animation
{
	if (animation == fadeAnimation)
	{
		if (fadeIn)
			[attachedView setAlphaValue:1.0];
		else
			[self orderOut:self];
	}
	else if (animation==pullAnimation && [self locked])
	{
		[self setFrame:[self lockedFrame]];
	}
}

@end

@implementation MDAttachedView : CPView
{
	FPAnimation pullAnimation @accessors;
	FPAnimation snapAnimation @accessors;
	CPPoint	clickLocation;
	CPRect	roundedRect;
	//CPPoint	pullShift;
	CPSize	minimumSize;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		minimumSize = frame.size;//CPMakeSize(frame.size.width,frame.size.height);
		//pullShift = CPMakePoint(0,0);
		[self resetDimensions];
	}
	return self;
}

/*- (void)beginPullAnimation:(id)sender
{
	if (self.pullAnimation && [self.pullAnimation running]) return;
	
	self.pullAnimation = [[FPAnimation alloc] initWithDuration:0.1 animationCurve:FPAnimationEaseInOut];
	[pullAnimation setDelegate:self];
	[pullAnimation startAnimation];
}*/

- (void)beginSnapAnimation:(id)sender
{
	self.snapAnimation = [[FPAnimation alloc] initWithDuration:0.1 animationCurve:FPAnimationEaseInOut];
	[snapAnimation setDelegate:self];
	[snapAnimation startAnimation];
}

- (void)animationFired:(FPAnimation)animation
{
	/*if (animation==snapAnimation)
	{
		//CPLog([animation currentValue]);
		
		//if (roundedRect)
		//{
			var deltaX = roundedRect.origin.x - PULL_DISTANCE;
			var deltaY = roundedRect.origin.y - ARROW_HEIGHT;
			
			deltaX *= 1.25;
			deltaY *= 1.25;
			
			var newFrame = [[self window] frame];
			newFrame.origin.x -= (deltaX * [animation currentValue]);
			newFrame.origin.y -= (deltaY * [animation currentValue]);
			[[self window] setFrame:newFrame];
		//}

		//roundedRect = CGRectInset([self bounds],ARROW_HEIGHT,ARROW_HEIGHT);
		
	}
	else */
	if (animation==pullAnimation && [[self window] locked])
	{
		//pullShift.x -= pullShift.x * [animation currentValue];
		//pullShift.y -= pullShift.y * [animation currentValue];
		[self resetDimensions];
	}
}

- (void)animationFinished:(FPAnimation)animation
{
	/*if (animation==snapAnimation)
	{
		roundedRect = CGRectInset([self bounds],ARROW_HEIGHT,ARROW_HEIGHT);
	}
	else */
	if (animation==pullAnimation && [[self window] locked])
	{
		//pullShift.x = 0;
		//pullShift.y = 0;
		[self resetDimensions];
	}
	[self setNeedsDisplay:YES];
}

- (void)resetDimensions
{
	roundedRect = CPMakeRect(3,ARROW_HEIGHT+3,minimumSize.width-6,minimumSize.height-6);
	
	if ([self window]) roundedRect.origin.y += [[self window] shiftPoint].y;
	roundedRect.size.height -= ARROW_HEIGHT;
	
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(CPRect)aRect
{
	[[CPColor colorWithCalibratedWhite:1.0 alpha:0.6] set];
	
	var bezierPath = [CPBezierPath bezierPath];
	
	var arrowRect = nil;
	if ([[self window] locked])
	{
		var lockedPoint = [self convertPoint:[[self window] lockedPoint] fromView:nil];
		arrowRect = CPMakeRect(CGRectGetMidX(roundedRect)-(ARROW_WIDTH/2),lockedPoint.y+3,ARROW_WIDTH,ARROW_HEIGHT);
		var arrowPath = [CPBezierPath bezierPathWithArrowInRect:arrowRect direction:CPArrowDirectionUp];		
		[bezierPath appendBezierPath:arrowPath];
	}
	
	[CPGraphicsContext saveGraphicsState];
	[[FPShadow shadowWithOffset:CPMakePoint(0,0) blur:3 color:[CPColor colorWithCalibratedWhite:0.0 alpha:0.7]] set];
	[bezierPath appendBezierPathWithRoundedRect:roundedRect xRadius:8 yRadius:8];
	[bezierPath fill];
	[CPGraphicsContext restoreGraphicsState];
	
	[CPGraphicsContext saveGraphicsState];
	[bezierPath setClip];
	var clearRect = [self bounds];
	CGContextClearRect([[CPGraphicsContext currentContext] graphicsPort], clearRect);
	[bezierPath fill];
	[CPGraphicsContext restoreGraphicsState];
	
	var topColor = [CPColor colorWithCalibratedWhite:0.0 alpha:0.75];
	[topColor set];
	if (arrowRect != nil)
	{
		arrowRect.origin.y += 2;
		//arrowRect.size.height -= 1;
		[[CPBezierPath bezierPathWithArrowInRect:arrowRect direction:CPArrowDirectionUp] fill];
	}
	
	var innerBezierPath = [CPBezierPath bezierPath];
	var innerRect = CGRectInset(roundedRect,2,2);
	[innerBezierPath appendBezierPathWithRoundedRect:innerRect xRadius:6 yRadius:6];
	[CPGraphicsContext saveGraphicsState];
	[innerBezierPath setClip];
	var linearGradient = [[FPGradient alloc] initWithStartingColor:topColor endingColor:[CPColor colorWithCalibratedWhite:0.0 alpha:0.9]];
	[linearGradient drawInRect:[self bounds] angle:90];
	[CPGraphicsContext restoreGraphicsState];
}

- (void)mouseDown:(CPEvent)mouseEvent
{
	//clickLocation = [mouseEvent locationInWindow];
}

- (void)mouseUp:(CPEvent)mouseEvent
{
	/*if ([[self window] locked])
		[[self window] beginPullAnimation:nil];*/
}

- (void)mouseDragged:(CPEvent)mouseEvent
{
	/*var viewLocation = [mouseEvent locationInWindow];
	var deltaX = viewLocation.x - clickLocation.x;
	var deltaY = viewLocation.y - clickLocation.y;*/
	
	/*var newFrame = [[self window] lockedFrame];
	newFrame.origin.x = viewLocation.x 
	[[self window] setFrame:newFrame];*/
	
	//[[self window] shiftBy:CPMakePoint(deltaX,deltaY)];
	
	//clickLocation.x += deltaX;
	//clickLocation.y += deltaY;
	//clickLocation = [mouseEvent locationInWindow];
	/*if ([[self window] locked])
	{
		pullShift.x += deltaX;
		pullShift.y += deltaY;
		if (pullShift.y < 0) pullShift.y = 0;
		[self resetDimensions];
		[self setNeedsDisplay:YES];
	
		clickLocation = [mouseEvent locationInWindow];
	} else
	{
		CPLog(@"change window loc");
		var windowLocation = [[self window] frame];
		windowLocation.origin.x += deltaX;// + PULL_DISTANCE;
		windowLocation.origin.y += deltaY;// + PULL_DISTANCE;
		[[self window] setFrame:windowLocation];
	}*/
}

@end

@implementation MDAttachedCloseButton : CPView
{
	
}

- (void)drawRect:(CPRect)aRect
{
	
}

@end