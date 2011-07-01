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

function DEGREES(radians)
{
	return ((-radians / PI) * 180 + 360) % 360;
}

function RADIANS(degrees)
{
	return -(((degrees - 360) / 180) * PI);
}

@implementation MDRadialControl : CPView
{
	var floatValue @accessors;
	CPTimer	animateTimer;
	BOOL running @accessors;
	BOOL pressed;
	BOOL indeterminate @accessors;
	float defaultStartAngle;
	BOOL showProgress @accessors;
	CPColor	highlightColor;
	CPColor backgroundColor;
	CPColor fillColor;
	
	id target @accessors;
	SEL	action @accessors;
}

- (id)initWithFrame:(CPFrame)aFrame
{
	if (self = [super initWithFrame:aFrame])
	{
		[self setFloatValue:0.0];
		defaultStartAngle = RADIANS(90);
		indeterminate = NO;
		showProgress = NO;
		backgroundColor = [CPColor colorWithHexString:@"222"];
		highlightColor = [CPColor blackColor];
		fillColor = [CPColor colorWithCalibratedWhite:0.7 alpha:1.0];
	}
	return self;
}

/*- (void)startAnimation:(id)sender
{
	running = YES;
	showProgress = YES;
	animateTimer = [CPTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(animate:) userInfo:nil repeats:YES];
}

- (void)stopAnimation:(id)sender
{
	[animateTimer invalidate];
	running = NO;
	[self setNeedsDisplay:YES];
}

- (void)toggleAnimation:(id)sender
{
	if (running)
		[self stopAnimation:nil];
	else
		[self startAnimation:nil];
}

- (void)animate:(id)sender
{
	floatValue += 0.002;
	if (floatValue >= 1.0)
	{
		[self stopAnimation:nil];
		showProgress = NO;
		floatValue = 0.0;
	}
	[self setNeedsDisplay:YES];
}*/

- (void)setFloatValue:(float)newValue
{
	floatValue = newValue;
	[self setNeedsDisplay:YES];
}

- (void)setRunning:(BOOL)isRunning
{
	running = isRunning;
	showProgress = isRunning;
	[self setNeedsDisplay:YES];
}

- (BOOL)isRunning
{
	return running;
}

- (void)drawRect:(CPRect)aRect
{
	var centerInset = parseInt([self bounds].size.width/6);
	var borderInset = parseInt(centerInset/5);
	
	if (showProgress)
	{
		[[CPColor whiteColor] set];
		[[CPBezierPath bezierPathWithOvalInRect:[self bounds]] fill];
		
		[backgroundColor set];
		var radialCircle = CGRectInset([self bounds],borderInset,borderInset);
		[[CPBezierPath bezierPathWithOvalInRect:radialCircle] fill];
	
		var startPoint = CPMakePoint(parseInt(CGRectGetMidX(radialCircle))+1,parseInt(CGRectGetMidY(radialCircle)));
		var startAngle = defaultStartAngle;
		var degrees = 90-360*floatValue;
		var endAngle = RADIANS(degrees);
		if (indeterminate) startAngle = endAngle - 0.35;
	
		if (endAngle<startAngle)
		{
			var newEndAngle = startAngle;
			startAngle = endAngle;
			endAngle = newEndAngle;
		}
	
		var radius = CGRectGetWidth(radialCircle)/2;
	
		[fillColor set];
		
		var strokeLineWidth = [self bounds].size.width/18;
		for (var angle = startAngle; angle < endAngle; angle += 0.05)
		{
			var xDistance = radius * Math.cos(angle);
			var yDistance = radius * Math.sin(angle);
		
			var endPoint = CPMakePoint(startPoint.x + xDistance, startPoint.y + yDistance);
		
			var bezierPath = [CPBezierPath bezierPath];
			[bezierPath setLineWidth:strokeLineWidth];
			[bezierPath moveToPoint:startPoint];
			[bezierPath lineToPoint:endPoint];
			[bezierPath stroke];
		}
	}
	
	var centerCircleOutlineRect = CGRectInset([self bounds],centerInset,centerInset);
	[[CPColor whiteColor] set];
	[[CPBezierPath bezierPathWithOvalInRect:centerCircleOutlineRect] fill];
	
	var centerCircleRect = CGRectInset(centerCircleOutlineRect,borderInset,borderInset);
	[pressed?highlightColor:backgroundColor set];
	[[CPBezierPath bezierPathWithOvalInRect:centerCircleRect] fill];
	
	var iconWidth = parseInt([self bounds].size.width/5.1);
	var iconHeight = parseInt([self bounds].size.height/4.3);
	var iconRect = CPMakeRect(CGRectGetMidX([self bounds])-iconWidth/2,CGRectGetMidY([self bounds])-iconHeight/2,iconWidth,iconHeight);
	
	[[CPColor whiteColor] set];
	if (running)
	{
		var pauseGap = parseInt([self bounds].size.width / 36);
		var lineWidth = parseInt(iconRect.size.width/2) - pauseGap;
		[[CPBezierPath bezierPathWithRect:CPMakeRect(iconRect.origin.x,iconRect.origin.y,lineWidth,iconRect.size.height)] fill];
		[[CPBezierPath bezierPathWithRect:CPMakeRect(CGRectGetMaxX(iconRect)-lineWidth,iconRect.origin.y,lineWidth,iconRect.size.height)] fill];
	}
	else
	{
		iconRect.origin.x += 1;
		[[CPBezierPath bezierPathWithArrowInRect:iconRect direction:CPArrowDirectionRight] fill];
	}
}

- (void)mouseDown:(CPEvent)mouseEvent
{
	pressed = YES;
	[self setNeedsDisplay:YES];
}

- (void)mouseUp:(CPEvent)mouseEvent
{
	pressed = NO;
	[self setNeedsDisplay:YES];
	if (target != nil)
		[target performSelector:action withObject:self];
}

@end