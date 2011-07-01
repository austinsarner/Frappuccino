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

@import "MDGrabber.j"

@implementation JTButtonBar : CPView
{
	MDGrabber	grabber @accessors;
	CPColor		blurColor @accessors;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self=[super initWithFrame:frame])
	{
		[self setAutoresizingMask:CPViewWidthSizable|CPViewMinYMargin];
	}
	return self;
}

- (void)setBlurColor:(CPColor)color
{
	blurColor = color;
	[self setNeedsDisplay:YES];
}

- (void)setShowsGrabber:(BOOL)shows
{
	if (shows && !grabber)
	{
		grabber = [[MDGrabber alloc] initWithFrame:CGRectMake(CGRectGetWidth([self bounds])-15,12,9,13)];
		[grabber setAutoresizingMask:CPViewMinXMargin];
		[self addSubview:grabber];
	}
	else if (!shows && grabber)
	{
		[grabber removeFromSuperview];
		self.grabber = nil;
	}
}

- (void)drawRect:(CPRect)aRect
{
	if (blurColor)
	{
		var linearGradient = [[FPGradient alloc] initWithStartingColor:[blurColor colorWithAlphaComponent:0.75] endingColor:blurColor];
		[linearGradient drawInRect:[self bounds] angle:90];
	}
	
	var gradientRect = [self bounds];
	gradientRect.size.height -= 10;
	var linearGradient = [[FPGradient alloc] initWithStartingColor:[CPColor colorWithCalibratedWhite:1.0 alpha:0.25] endingColor:[CPColor colorWithCalibratedWhite:1.0 alpha:0.0]];
	[linearGradient drawInRect:gradientRect angle:90];
	
	[[CPColor borderColor] set];
	var topLineRect = CPMakeRect(0,0,CGRectGetWidth([self bounds]),1);
	var topLinePath = [CPBezierPath bezierPathWithRect:topLineRect];
	[topLinePath fill];
	
	[[CPColor insetColor] set];
	topLineRect.origin.y++;
	topLinePath = [CPBezierPath bezierPathWithRect:topLineRect];
	[topLinePath fill];
}

@end