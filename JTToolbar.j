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

@implementation JTToolbar : CPView
{
	BOOL drawsLeftInset @accessors;
}

- (void)drawRect:(CPRect)drawRect
{
	var lineRect, linePath;
	
	lineRect = CPMakeRect(0,0,CGRectGetWidth([self bounds]),1);
	[[CPColor colorWithHexString:@"24262c"] set];
	linePath = [CPBezierPath bezierPathWithRect:lineRect];
	[linePath fill];
	
	lineRect.origin.y++;
	[[CPColor colorWithHexString:@"76797e"] set];
	linePath = [CPBezierPath bezierPathWithRect:lineRect];
	[linePath fill];
	
	lineRect.origin.y = CGRectGetMaxY([self bounds])-2;
	[[CPColor colorWithHexString:@"2b2d32"] set];
	linePath = [CPBezierPath bezierPathWithRect:lineRect];
	[linePath fill];
	
	lineRect.origin.y++;
	[[CPColor borderColor] set];
	linePath = [CPBezierPath bezierPathWithRect:lineRect];
	[linePath fill];
	
	var gradientRect = [self bounds];
	gradientRect.origin.y += 2;
	gradientRect.size.height -= 4;
	var linearGradient = [[FPGradient alloc] initWithStartingColor:[CPColor colorWithHexString:@"53575d"] endingColor:[CPColor colorWithHexString:@"23252b"]];
	[linearGradient drawInRect:gradientRect angle:90];
	
	if (drawsLeftInset)
	{
		var leftLineRect = CPMakeRect(0,1,1,CGRectGetHeight([self bounds])-2);
		[[CPColor colorWithCalibratedWhite:1.0 alpha:0.06] set];
		[[CPBezierPath bezierPathWithRect:leftLineRect] fill];
	}
	
	var rightLineRect = CPMakeRect(CGRectGetMaxX([self bounds])-1,1,1,CGRectGetHeight([self bounds])-2);
	[[CPColor colorWithCalibratedWhite:1.0 alpha:0.06] set];
	[[CPBezierPath bezierPathWithRect:rightLineRect] fill];
}

@end

@implementation JTToolbarSeparatorView : CPView
{
	
}

// 28

- (void)drawRect:(CPRect)aRect
{
	var alt = NO;
	for (var i=0;i<[self bounds].size.height;i++)
	{
		var pixelRect = CPMakeRect(0,i,1,1);
		[[CPColor colorWithCalibratedWhite:alt?0.0:1.0 alpha:0.25] set];
		[[CPBezierPath bezierPathWithRect:pixelRect] fill];
		alt = !alt;
	}
}

@end