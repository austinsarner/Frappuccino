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

@implementation MDGrabber : CPView
{
	int	dividerIndex @accessors;
	var startingWidth;
	BOOL isHorizontal @accessors;
	//CPPoint	clickLocation;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		[self valueForKey:@"_DOMElement"].style.cursor = "move";
	}
	return self;
}

- (void)drawRect:(CPRect)rect
{
	var i;
	for (i=0;i<=6;i+=3)
	{
		[[CPColor colorWithCalibratedWhite:0.0 alpha:0.55] set];
		[[CPBezierPath bezierPathWithRect:CPMakeRect(i,1,1,CGRectGetHeight([self bounds])-2)] fill];
		[[CPColor colorWithCalibratedWhite:1.0 alpha:0.25] set];
		[[CPBezierPath bezierPathWithRect:CPMakeRect(i+1,2,1,CGRectGetHeight([self bounds])-1)] fill];
	}
}

- (void)mouseDown:(CPEvent)mouseEvent
{
	/*startingWidth = 0;
	var i;
	for (i=0;i<=self.dividerIndex;i++)
		startingWidth += [[[[self splitView] subviews] objectAtIndex:i] frame].size.width;
	clickLocation = [mouseEvent locationInWindow];*/
}

- (void)mouseDragged:(CPEvent)mouseEvent
{
	/*var viewLocation = [mouseEvent locationInWindow];
	var deltaX = viewLocation.x - clickLocation.x;
	
	[self.splitView setPosition:startingWidth + deltaX ofDividerAtIndex:self.dividerIndex];*/
}

@end