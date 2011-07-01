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

@implementation MDScroller : CPScroller
{
	
}

- (void)drawRect:(CPRect)aRect
{
	[self drawButtonInRect:CPMakeRect(1,CGRectGetMaxY([self bounds])-30,CGRectGetWidth([self bounds]),16) direction:CPArrowDirectionUp];
	[self drawButtonInRect:CPMakeRect(1,CGRectGetMaxY([self bounds])-15,CGRectGetWidth([self bounds]),16) direction:CPArrowDirectionDown];
	
	[self drawKnobSlot];
}

- (CPView)createViewForPart:(CPScrollerPart)aPart { return; }

- (CPView)createEphemeralSubviewNamed:(CPString)aName { return; }

- (CPRect)knobSlotRect
{
	var knobSlotRect = CPRectCreateCopy([self bounds]);
	knobSlotRect.origin.y += 5;
	knobSlotRect.size.height -= 35;
	knobSlotRect.origin.x ++;
	knobSlotRect.size.width --;
	return knobSlotRect;
}

- (void)setFloatValue:(float)aValue
{
	[super setFloatValue:aValue];
	[self drawParts];
}

- (void)drawKnobSlot
{
	//var knobRect = _partRects[CPScrollerKnob];
	//CPLog(@"%f",[self knobProportion]);
	//CPLog(@"{%f,%f,%f,%f}",knobRect.origin.x,knobRect.origin.y,knobRect.size.width,knobRect.size.height);
	
	var rect = CPRectCreateCopy([self bounds]);
	
	var leftRect = CPMakeRect(rect.origin.x-1,rect.origin.y+1,CGRectGetWidth(rect)/2+1,CGRectGetHeight(rect));
	[[CPColor colorWithCalibratedWhite:0.8 alpha:0.1] set];
	[[CPBezierPath bezierPathWithRect:leftRect] fill];
	
	[[CPColor colorWithCalibratedWhite:0.2 alpha:0.1] set];
	var rightRect = CPRectCreateCopy(leftRect);
	rightRect.origin.x = CGRectGetMaxX(leftRect);
	[[CPBezierPath bezierPathWithRect:rightRect] fill];
	
	var verticalLine = [CPBezierPath bezierPathWithRect:CPMakeRect(0,0,1,CGRectGetHeight([self bounds]))];
	[[CPColor colorWithCalibratedWhite:1.0 alpha:0.1] set];
	[verticalLine fill];
	
	var knobSlotRect = [self knobSlotRect];
	var slotBorderPath = [CPBezierPath bezierPath];
	[slotBorderPath appendBezierPathWithRoundedRect:knobSlotRect xRadius:6 yRadius:6];
	[[CPColor colorWithCalibratedWhite:0.0 alpha:0.3] set];
	[slotBorderPath fill];
	
	knobSlotRect.origin.x ++;
	knobSlotRect.origin.y ++;
	knobSlotRect.size.width -=2;
	knobSlotRect.size.height -=2;
	var knobSlotPath = [CPBezierPath bezierPath];
	[knobSlotPath appendBezierPathWithRoundedRect:knobSlotRect xRadius:6 yRadius:6];
	
	var gradient = [[FPGradient alloc] initWithStartingColor:[CPColor colorWithCalibratedWhite:0.2 alpha:1.0] endingColor:[CPColor colorWithCalibratedWhite:0.2 alpha:1.0]];
	[gradient addColor:[CPColor colorWithCalibratedWhite:0.25 alpha:1.0] atStopLocation:0.5];
	[knobSlotPath setClip];
	[gradient drawInRect:knobSlotRect angle:0];
	
	//[[CPColor colorWithCalibratedWhite:0.9 alpha:0.1] set];
	//[knobSlotPath fill];
	
	[self drawKnob];
}

- (void)drawParts
{
	[self setNeedsDisplay:YES];
}

- (void)drawKnob
{
	var knobSlotRect = [self knobSlotRect];
	knobSlotRect.origin.x ++;
	knobSlotRect.origin.y ++;
	knobSlotRect.size.width -=2;
	knobSlotRect.size.height -=2;
	
	var knobHeight = knobSlotRect.size.height * [self knobProportion];
	var maxPosition = knobSlotRect.size.height - knobHeight;
	knobSlotRect.origin.y += [self floatValue] * maxPosition;
	knobSlotRect.size.height = knobHeight;
	
	var knobPath = [CPBezierPath bezierPath];
	[knobPath appendBezierPathWithRoundedRect:knobSlotRect xRadius:6 yRadius:6];
	
	var gradient = [[FPGradient alloc] initWithStartingColor:[CPColor colorWithHexString:@"a4a7ab"] endingColor:[CPColor colorWithHexString:@"6f7378"]];
	[knobPath setClip];
	[gradient drawInRect:knobSlotRect angle:0];
}

- (void)drawButtonInRect:(CPRect)rect direction:(CPArrowDirection)direction
{
	if (direction==CPArrowDirectionDown)
	{
		[[CPColor colorWithCalibratedWhite:0 alpha:0.3] set];
		var arrowSeparator = [CPBezierPath bezierPathWithRect:CPMakeRect(rect.origin.x,rect.origin.y,CGRectGetWidth(rect)-1,1)];
		[arrowSeparator fill];
	}

	var downArrow = [CPBezierPath bezierPathWithArrowInRect:CPMakeRect(rect.origin.x+3.5,rect.origin.y+6,6.5,5) direction:direction];
	[[CPColor whiteColor] set];
	[downArrow fill];
}

@end