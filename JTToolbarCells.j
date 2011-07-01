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

function JTToolbarCellGradient(highlight)
{
	var startColor = highlight?[CPColor colorWithHexString:@"17171a"]:[CPColor colorWithHexString:@"494c51"];
	var endColor = highlight?[CPColor colorWithHexString:@"393b3f"]:[CPColor colorWithHexString:@"17171a"];
 	return [[FPGradient alloc] initWithStartingColor:startColor endingColor:endColor];
}

function JTToolbarCellTopShadow()
{
	return [FPShadow shadowWithOffset:CPMakePoint(0,1) blur:1 color:[CPColor colorWithCalibratedWhite:1.0 alpha:0.1]];
}

function JTToolbarCellBottomShadow()
{
	return [FPShadow shadowWithOffset:CPMakePoint(0,-1) blur:1 color:[CPColor colorWithCalibratedWhite:0.0 alpha:0.2]];
}

@implementation JTToolbarButtonCell : FPButtonCell { }

- (void)drawWithFrame:(CPRect)frame inView:(CPView)view
{
	var buttonPath = [CPBezierPath bezierPath];
	[buttonPath appendBezierPathWithRoundedRect:CGRectInset(frame,1,1) xRadius:3.0 yRadius:3.0];
	[[CPColor blackColor] set];
	[CPGraphicsContext saveGraphicsState];
	[JTToolbarCellTopShadow() set];
	[buttonPath fill];
	[CPGraphicsContext restoreGraphicsState];
	
	[CPGraphicsContext saveGraphicsState];
	[JTToolbarCellBottomShadow() set];
	[buttonPath fill];
	[CPGraphicsContext restoreGraphicsState];
	
	var linearGradient = JTToolbarCellGradient([self isHighlighted]);
	var innerRect = CGRectInset(frame,2,2);
	var innerPath = [self drawGradient:linearGradient inRect:innerRect];
	[[CPColor colorWithCalibratedWhite:1.0 alpha:0.08] set];
	[innerPath fill];
	
	[self drawGradient:linearGradient inRect:CGRectInset(frame,3,3)];
	
	if ([self image] != nil)
		[self drawImageWithFrame:[self imageRectForBounds:frame] inView:view];
	else if ([self title]!=nil)
	{
		var textFont = [CPFont boldSystemFontOfSize:12];
		var textSize = [[self title] sizeWithFont:textFont];
		var textRect = CPMakeRect(parseInt(CGRectGetMidX(frame)-textSize.width/2),parseInt(CGRectGetMidY(frame)-textSize.height/2),textSize.width,textSize.height);
	
		[CPGraphicsContext saveGraphicsState];
		[[FPShadow shadowWithOffset:CPMakePoint(0,-1) blur:1 color:[CPColor colorWithCalibratedWhite:0.2 alpha:1.0]] set];
		[[CPColor colorWithCalibratedWhite:1.0 alpha:1.0] set];
		[[self title] drawAtPoint:textRect.origin withFont:textFont];
		[CPGraphicsContext restoreGraphicsState];
	}
}

- (CPBezierPath)drawGradient:(FPGradient)gradient inRect:(CPRect)rect
{
	var bezierPath = [CPBezierPath bezierPath];
	[bezierPath appendBezierPathWithRoundedRect:rect xRadius:2.0 yRadius:2.0];
	
	[CPGraphicsContext saveGraphicsState];
	[bezierPath setClip];
	[gradient drawInRect:rect angle:90];
	[CPGraphicsContext restoreGraphicsState];
	
	return bezierPath;
}

@end

@implementation JTToolbarPublishButtonCell : JTToolbarButtonCell
{
	
}

- (void)drawWithFrame:(CPRect)aRect inView:(CPView)aView
{
	[super drawWithFrame:aRect inView:aView];
	
	var dividerRect = CPMakeRect(27,2,1,CGRectGetHeight(aRect)-4);
	
	[[CPColor colorWithCalibratedWhite:0.0 alpha:0.4] set];
	[[CPBezierPath bezierPathWithRect:dividerRect] fill];
	
	[[CPColor colorWithCalibratedWhite:1.0 alpha:0.08] set];
	
	dividerRect.origin.x--;
	dividerRect.origin.y++;
	//dividerRect.size.height--;
	[[CPBezierPath bezierPathWithRect:dividerRect] fill];
	
	dividerRect.origin.x+=2;
	[[CPBezierPath bezierPathWithRect:dividerRect] fill];
	
	[self drawGlowWithFrame:CPMakeRect(4,3,22,22)];
	
	[[FPShadow shadowWithOffset:CPMakePoint(0,-1) blur:1 color:[CPColor colorWithCalibratedWhite:0.0 alpha:0.5]] set];
	[[CPColor colorWithCalibratedWhite:0.8 alpha:1.0] set];
	[@"Published" drawAtPoint:CPMakePoint(36,9) withFont:[CPFont boldSystemFontOfSize:11.0]];
}

- (void)drawGlowWithFrame:(CPRect)frame
{
	[CPGraphicsContext saveGraphicsState];
	var glowColor = [CPColor colorWithHexString:@"54df20"];
	var circleRect = CPRectCreateCopy(frame);
	
	for (var i=0;i<5;i++)
	{
		var glowPath = [CPBezierPath bezierPathWithOvalInRect:circleRect];
		var alpha = i * 0.04;
		[[glowColor colorWithAlphaComponent:alpha] set];
		[glowPath fill];
		circleRect = CGRectInset(circleRect,1,1);
	}
	
	var outerPath = [CPBezierPath bezierPathWithOvalInRect:circleRect];
	[outerPath setClip];
	
	var linearGradient = [[FPGradient alloc] initWithStartingColor:[CPColor colorWithHexString:@"214f1b"] endingColor:[CPColor colorWithHexString:@"368c21"]];
	[linearGradient drawInRect:circleRect angle:90];
	
	circleRect = CGRectInset(circleRect,1,1);
	var circlePath = [CPBezierPath bezierPathWithOvalInRect:circleRect];
	[circlePath setClip];
	linearGradient = [[FPGradient alloc] initWithStartingColor:[CPColor colorWithHexString:@"38921f"] endingColor:[CPColor colorWithHexString:@"4ec71a"]];
	[linearGradient drawInRect:circleRect angle:90];
	
	circleRect = CGRectInset(circleRect,1,1);
	var innerCirclePath = [CPBezierPath bezierPathWithOvalInRect:circleRect];
	[innerCirclePath setClip];
	linearGradient = [[FPGradient alloc] initWithStartingColor:[CPColor colorWithHexString:@"a8f886"] endingColor:[CPColor colorWithHexString:@"40aa18"]];
	[linearGradient drawInRect:circleRect angle:90];
	
	circleRect = CGRectInset(circleRect,1,1);
	var centerCirclePath = [CPBezierPath bezierPathWithOvalInRect:circleRect];
	[centerCirclePath setClip];
	linearGradient = [[FPGradient alloc] initWithStartingColor:[CPColor colorWithHexString:@"63ec3c"] endingColor:[CPColor colorWithHexString:@"40aa18"]];
	[linearGradient drawInRect:circleRect angle:90];
	
	[CPGraphicsContext restoreGraphicsState];
}

@end

// Segmented Cells

@implementation FPToolbarSegmentedCell : FPSegmentedCell { }

- (void)drawWithFrame:(CPRect)frame inView:(CPView)view
{
	var regularState = ([self isHighlighted]==NO && [self state]!=FPOnState);
	
	[CPGraphicsContext saveGraphicsState];
	[[CPColor blackColor] set];
	[JTToolbarCellTopShadow() set];
	var backgroundRect = CGRectInset(frame,0,1);
	var buttonPath = [self backgroundPathWithRect:backgroundRect radius:3.0];
	[buttonPath fill];
	[CPGraphicsContext restoreGraphicsState];
	
	[CPGraphicsContext saveGraphicsState];
	[JTToolbarCellBottomShadow() set];
	[buttonPath fill];
	[CPGraphicsContext restoreGraphicsState];
	
	var innerRect = CGRectInset(frame,1,2);
	if ([self cellCap]!=FPSegmentedCellLeftCap)
	{
		innerRect.origin.x--;
		innerRect.size.width++;
	}
	
	[CPGraphicsContext saveGraphicsState];
	var innerPath = [self backgroundPathWithRect:innerRect radius:2.0];
	var gradient = JTToolbarCellGradient(!regularState);
	[innerPath setClip];
	[gradient drawInRect:innerRect angle:-90];
	[CPGraphicsContext restoreGraphicsState];
	[[CPColor colorWithCalibratedWhite:1.0 alpha:0.08] set];
	[innerPath fill];
	
	[CPGraphicsContext saveGraphicsState];
	innerRect = CGRectInset(innerRect,1,1);
	innerPath = [self backgroundPathWithRect:innerRect radius:2.0];
	[innerPath setClip];
	[gradient drawInRect:innerRect angle:-90];
	[CPGraphicsContext restoreGraphicsState];
	
	if ([self image])
	{
		if ([[self image] loadStatus]==CPImageLoadStatusCompleted)
		{
			var imageSize = [[self image] size];
			var imagePoint = CPMakePoint(parseInt(CGRectGetMidX(frame)-imageSize.width/2),parseInt(CGRectGetMidY(frame)-imageSize.height/2)-1);
			[[self image] drawAtPoint:imagePoint fraction:1.0];
		}
	}
	else
	{
		var labelFont = [CPFont boldFontWithName:@"Times" size:14];
		if ([[self title] isEqualToString:@"I"])
			labelFont = [CPFont fontWithCSSString:@"bold italic 14px Times"];
		var labelSize = [[self title] sizeWithFont:labelFont];
		var labelPoint = CPMakePoint(parseInt(CGRectGetMidX(frame)-labelSize.width/2),parseInt(CGRectGetMidY(frame)-labelSize.height/2)+1);
		if ([self cellCap]==FPSegmentedCellLeftCap)
			labelPoint.x++;
	
		[CPGraphicsContext saveGraphicsState];
		[[CPColor colorWithCalibratedWhite:0.8 alpha:1.0] set];
		[[FPShadow shadowWithOffset:CPMakePoint(0,-1) blur:1 color:[CPColor colorWithCalibratedWhite:0.0 alpha:0.5]] set];
		[[self title] drawAtPoint:labelPoint withFont:labelFont];
		[CPGraphicsContext restoreGraphicsState];
	}
}

@end

@implementation FPToolbarTabSegmentedCell : FPSegmentedCell {}

- (void)drawWithFrame:(CPRect)frame inView:(CPView)view
{
	var leftRect = CPMakeRect(CGRectGetMinX(frame),1,1,CGRectGetHeight(frame)-3);
	[[CPColor colorWithCalibratedWhite:1.0 alpha:0.08] set];
	[[CPBezierPath bezierPathWithRect:leftRect] fill];
	
	var rightRect = CPMakeRect(CGRectGetMaxX(frame)-1,1,1,CGRectGetHeight(frame)-1);
	[[CPColor colorWithCalibratedWhite:0.0 alpha:0.25] set];
	[[CPBezierPath bezierPathWithRect:rightRect] fill];
	
	rightRect = CPMakeRect(CGRectGetMaxX(frame)-2,1,1,CGRectGetHeight(frame)-3);
	[[CPColor colorWithCalibratedWhite:1.0 alpha:0.08] set];
	[[CPBezierPath bezierPathWithRect:rightRect] fill];
	
	var innerRect = CGRectInset(frame,1,1);
	if (state==FPOnState)
	{
		var shadowWidth = 5;
		
		[[CPColor blackColor] set];
		[[CPBezierPath bezierPathWithRect:frame] fill];
		
		var linearGradient = [[FPGradient alloc] initWithStartingColor:[CPColor colorWithHexString:@"414449"] endingColor:[CPColor colorWithHexString:@"1a1b1f"]];
		[linearGradient drawInRect:innerRect angle:90];
		
		var bottomRect = CPRectCreateCopy(frame);
		bottomRect.size.height=1;
		bottomRect.origin.y = CGRectGetMaxY(frame)-2;
		bottomRect.origin.x++;
		bottomRect.size.width-=2;
		var linePath = [CPBezierPath bezierPathWithRect:bottomRect];
		[[CPColor colorWithCalibratedWhite:1.0 alpha:0.05] set];
		[linePath fill];
		
		var shadowGradient = [[FPGradient alloc] initWithStartingColor:[CPColor colorWithCalibratedWhite:0 alpha:0.0] endingColor:[CPColor colorWithCalibratedWhite:0 alpha:0.2]];
		var rightShadowRect = CPMakeRect(CGRectGetMaxX(frame)-shadowWidth,1,shadowWidth,CGRectGetHeight(frame));
		[shadowGradient drawInRect:rightShadowRect angle:0];
		
		shadowGradient = [[FPGradient alloc] initWithStartingColor:[CPColor colorWithCalibratedWhite:0 alpha:0.2] endingColor:[CPColor colorWithCalibratedWhite:0 alpha:0.0]];
		var leftShadowRect = CPMakeRect(CGRectGetMinX(frame)+1,1,shadowWidth,CGRectGetHeight(frame));
		[shadowGradient drawInRect:leftShadowRect angle:0];
		
		var topShadowRect = CPMakeRect(CGRectGetMinX(frame)+1,1,CGRectGetWidth(frame)-2,shadowWidth);
		[shadowGradient drawInRect:topShadowRect angle:90];
	} else if ([self isHighlighted])
	{
		[[CPColor colorWithCalibratedWhite:0.0 alpha:0.05] set];
		[[CPBezierPath bezierPathWithRect:innerRect] fill];
	}
	
	if ([self image])
	{
		if ([[self image] loadStatus]==CPImageLoadStatusCompleted)
		{
			var imageSize = [[self image] size];
			var imagePoint = CPMakePoint(parseInt(CGRectGetMidX(frame)-imageSize.width/2),parseInt(CGRectGetMidY(frame)-imageSize.height/2)-1);
			[[self image] drawAtPoint:imagePoint fraction:1.0];
		}
	}
	else
	{
		[[FPShadow shadowWithOffset:CPMakePoint(0,-1) blur:1 color:[CPColor blackColor]] set];
		[[CPColor colorWithCalibratedWhite:0.8 alpha:1.0] set];
	
		var text = [[self title] uppercaseString];
		var textFont = [CPFont boldSystemFontOfSize:12];
		var textSize = [text sizeWithFont:textFont];
		var textRect = CGRectIntegral(CPMakeRect(CGRectGetMidX(frame)-textSize.width/2,CGRectGetMidY(frame)-textSize.height/2+2.0),textSize.width,textSize.height);
	
		[text drawAtPoint:textRect.origin withFont:textFont];
	}
}

@end