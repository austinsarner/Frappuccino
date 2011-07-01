/*
 * FPSlider.j
 * Frappuccino
 *
 * Created by Austin Sarner and Mark Davis.
 * Copyright 2010 Austin Sarner and Mark Davis.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@implementation FPSlider : CPView
{
	double	minValue @accessors;
	double	maxValue @accessors;
	double	floatValue @accessors;
	//double	value	@accessors;
	id		target @accessors;
	SEL		action @accessors;
	BOOL	dragging @accessors;
	CPPoint knobOffset @accessors;
	CPSize	knobSize @accessors;
	BOOL	shouldDrawIcons @accessors;
	//BOOL	pressed @accessors;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		knobOffset = CPMakePoint(0,0);
		shouldDrawIcons = NO;
		knobSize = CPMakeSize(12,12);
	}
	return self;
}

- (void)drawRect:(CPRect)aRect
{
	if (shouldDrawIcons) [self drawIcons];
	[self drawKnobSlot];
	[self drawKnob];
}

- (void)drawIcons
{
	[[FPShadow shadowWithOffset:CPMakePoint(0,1) blur:0 color:[CPColor colorWithCalibratedWhite:1.0 alpha:0.05]] set];
	
	[[CPColor colorWithCalibratedWhite:0.9 alpha:0.7] set];
	
	var smallPhotoPath = [CPBezierPath bezierPathWithRect:CPMakeRect(1,9,11,9)];
	[smallPhotoPath setLineWidth:2];
	[smallPhotoPath stroke];
	
	var bigPhotoPath = [CPBezierPath bezierPathWithRect:CPMakeRect(CGRectGetWidth([self bounds])-14,8,13,11)];
	[bigPhotoPath setLineWidth:2];
	[bigPhotoPath stroke];
}

- (void)drawKnobSlot
{
	[[CPColor colorWithCalibratedWhite:1.0 alpha:0.2] set];
	var knobSlotPath = [CPBezierPath bezierPath];
	[knobSlotPath appendBezierPathWithRoundedRect:[self knobSlotRect] xRadius:5.0 yRadius:5.0];
	[knobSlotPath fill];
	
	[[CPColor colorWithCalibratedWhite:0.0 alpha:0.6] set];
	var innerPath = [CPBezierPath bezierPath];
	var innerRect = CGRectInset([self knobSlotRect],0.5,0.5);
	[innerPath appendBezierPathWithRoundedRect:innerRect xRadius:5.0 yRadius:5.0];
	//[innerPath fill];
	
	[CPGraphicsContext saveGraphicsState];
	var gradient = [[FPGradient alloc] initWithStartingColor:[CPColor colorWithCalibratedWhite:0.0 alpha:1.0] endingColor:[CPColor colorWithCalibratedWhite:0.1 alpha:1.0]];
	[innerPath setClip];
	[gradient drawInRect:innerRect angle:-90];
	[CPGraphicsContext restoreGraphicsState];
}

- (void)drawKnob
{
	var innerRect = [self knobRect];
	
	[CPGraphicsContext saveGraphicsState];
	var innerPath = [CPBezierPath bezierPathWithOvalInRect:innerRect];
	var gradient = [[FPGradient alloc] initWithStartingColor:[CPColor colorWithHexString:@"fff"] endingColor:[CPColor colorWithHexString:@"47494d"]];
	[innerPath setClip];
	[gradient drawInRect:innerRect angle:-90];
	[CPGraphicsContext restoreGraphicsState];
	
	[CPGraphicsContext saveGraphicsState];
	innerPath = [CPBezierPath bezierPathWithOvalInRect:CGRectInset(innerRect,1,1)];
	gradient = [[FPGradient alloc] initWithStartingColor:[CPColor colorWithHexString:@"a8acb0"] endingColor:[CPColor colorWithHexString:@"404348"]];
	[innerPath setClip];
	[gradient drawInRect:innerRect angle:-90];
	[CPGraphicsContext restoreGraphicsState];
	
	var centerRect = CGRectInset(innerRect,4,4);
	var centerPath = [CPBezierPath bezierPathWithOvalInRect:centerRect];

	var startColor = [CPColor colorWithHexString:dragging?@"003f6f":@"23252b"];
	var endColor = [CPColor colorWithHexString:dragging?@"1573bb":@"36393f"];
	
	[CPGraphicsContext saveGraphicsState];
	[[FPShadow shadowWithOffset:CPMakePoint(0,1) blur:1 color:[CPColor colorWithCalibratedWhite:1.0 alpha:0.5]] set];
	[[CPColor colorWithCalibratedWhite:0.0 alpha:0.75] set];
	[centerPath fill];
	
	gradient = [[FPGradient alloc] initWithStartingColor:startColor endingColor:endColor];
	[centerPath setClip];
	[gradient drawInRect:innerRect angle:-90];
	[CPGraphicsContext restoreGraphicsState];
}

- (CPRect)knobSlotRect
{
	var knobSlotRect = CGRectInset([self bounds],shouldDrawIcons?20:5,10);
	//CPLog(@"knobSlotWidth: %d",knobSlotRect.size.width);
	//knobSlotRect.origin.x--;
	//knobSlotRect.origin.y--;
	return CGRectIntegral(knobSlotRect);
}

- (CPRect)knobRect
{
	var rectLength = [self slideRange].length;
	var valueLength = maxValue - minValue;
	
	var lengthMultiplier = (floatValue - minValue) / valueLength;
	var xValue = parseInt([self slideRange].location + (lengthMultiplier * rectLength));
	
	return CPMakeRect(xValue,8,knobSize.width,knobSize.height);
}

- (CPRange)slideRange
{
	var minSliderX = CGRectGetMinX([self knobSlotRect]);
	var maxSliderX = CGRectGetMaxX([self knobSlotRect]) - knobSize.width;
	var slideLength = maxSliderX - minSliderX;
	return CPMakeRange(minSliderX,slideLength);
}

// CPResponder

- (void)mouseDown:(CPEvent)event
{
	var localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	var knobRect = [self knobRect];
	dragging = YES;
	
	if (CPRectContainsPoint(knobRect,localPoint)) {
		knobOffset = CPMakePoint(localPoint.x-knobRect.origin.x,localPoint.y-knobRect.origin.y);
		[self setNeedsDisplay:YES];
		
	}  else if (CPRectContainsPoint([self knobSlotRect],localPoint)) {
		var offset = Math.ceil([self knobRect].size.width / 2.0);
		knobOffset = CPMakePoint(offset,0.0);
		localPoint.x -= offset;
		[self moveToPoint:localPoint];
	}
}

- (void)mouseDragged:(CPEvent)event
{
	if (dragging)
	{
		var localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
		localPoint.x -= knobOffset.x;
		[self moveToPoint:localPoint];
	}
}

- (void)mouseUp:(CPEvent)event
{
	dragging = NO;
	[self setNeedsDisplay:YES];
}

- (void)scrollWheel:(CPEvent)event
{
	var scrollAmount = [event deltaY] / 10.0;
	var maxDecrease = floatValue - minValue;
	var maxIncrease = maxValue - floatValue;
	
	if (scrollAmount>0)
	{
		var decreaseAmount = maxDecrease * scrollAmount;
		if (decreaseAmount > maxDecrease)
			decreaseAmount = maxDecrease;
		
		floatValue -= decreaseAmount;
		[self setNeedsDisplay:YES];
	} else if (scrollAmount<0)
	{
		var increaseAmount = maxIncrease * -scrollAmount;
		if (increaseAmount > maxIncrease)
			increaseAmount = maxIncrease;

		floatValue += increaseAmount;
		
		[self setNeedsDisplay:YES];
	}
	
	[target performSelector:action withObject:self];
	//var newValue = floatValue += valueLength * 
	
}

- (void)moveToPoint:(CPPoint)localPoint
{
	var newFloatValue = 0.0;
	var xValue = localPoint.x;
	var slideRange = [self slideRange];
	
	if (xValue >= CPMaxRange(slideRange))
		newFloatValue = maxValue;
	else if (xValue <= slideRange.location)
		newFloatValue = minValue;
	else
	{
		newFloatValue = (xValue - slideRange.location)/slideRange.length;
		
		newFloatValue *= maxValue-minValue;
		newFloatValue += minValue;
	}
	
	if (newFloatValue < minValue)
		newFloatValue = minValue;
	
	if (newFloatValue != floatValue)
	{
		[self setFloatValue:newFloatValue];
		[target performSelector:action withObject:self];
		[self setNeedsDisplay:YES];
	}
}

@end