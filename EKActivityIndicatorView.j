/* EKActivityIndicatorView.j
 *
 * Created by Elias Klughammer on May 16, 2010 in Ulaan Bataar, Mongolia.
 *
 * The MIT License
 *
 * Copyright (c) 2010 Elias Klughammer
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

@implementation EKActivityIndicatorView : CPView
{
	BOOL		_isAnimating;
	int		_step;
	CPTimer		_timer;
	CPColor		_color;
	float		_colorRed;
	float		_colorGreen;
	float		_colorBlue;
}

- (id)initWithFrame:(CGRect)aFrame
{
	self = [super initWithFrame:aFrame];
	if(self) {
		_isAnimating = NO;
		[self setColor:[CPColor blackColor]];
	}
	return self;
}

- (void)setColor:(CPColor)aColor
{
	_color = aColor;
	_colorRed = [aColor redComponent];
	_colorGreen = [aColor greenComponent];
	_colorBlue = [aColor blueComponent];
}

- (void)startAnimating
{
	if (!_isAnimating) {
		_isAnimating = YES;
		_step = 1;
		_timer = [CPTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerDidFire) userInfo:nil repeats:YES];
	}
}

- (void)stopAnimating
{
	if (_isAnimating) {
		_isAnimating = NO;
		[_timer invalidate];
		[self setNeedsDisplay:YES];
	}
}

- (BOOL)isAnimating
{
	return _isAnimating;
}

- (CPColor)color
{
	return _color;
}

- (void)timerDidFire
{
	if (_step == 12)
		_step = 1;
	else
		_step++;
		
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(CGrect)rect
{	
	var bounds = [self bounds];
	var size = bounds.size.width;
	var c = [[CPGraphicsContext currentContext] graphicsPort];
	
	CGContextClearRect(c, rect);
	
	if (_isAnimating) {
		var thickness = bounds.size.width * 0.1;
		var length = bounds.size.width * 0.28;
		var radius = thickness / 2;
		var lineRect = CGRectMake(size / 2 - thickness / 2, 0, thickness, length);
		var minx = CGRectGetMinX(lineRect);
		var midx = CGRectGetMidX(lineRect);
		var maxx = CGRectGetMaxX(lineRect);
		var miny = CGRectGetMinY(lineRect);
		var midy = CGRectGetMidY(lineRect);
		var maxy = CGRectGetMaxY(lineRect);
		var delta1, delta2, delta3, delta4, delta5, delta6;

		CGContextSetFillColor(c, [CPColor blackColor]);

		for (i=1; i<=12; i++) {

			delta1 = (_step <= 1) ? 11 : -1;
			delta2 = (_step <= 2) ? 10 : -2;
			delta3 = (_step <= 3) ? 9 : -3;
			delta4 = (_step <= 4) ? 8 : -4;
			delta5 = (_step <= 5) ? 7 : -5;
			delta6 = (_step <= 6) ? 6 : -6;
			
			if (i==_step)
				CGContextSetFillColor(c, _color);
			else if (i==_step+delta1)
				CGContextSetFillColor(c, [CPColor colorWithRed:_colorRed green:_colorGreen blue:_colorBlue alpha:0.9]);
			else if (i==_step+delta2)
				CGContextSetFillColor(c, [CPColor colorWithRed:_colorRed green:_colorGreen blue:_colorBlue alpha:0.8]);	
			else if (i==_step+delta3)
				CGContextSetFillColor(c, [CPColor colorWithRed:_colorRed green:_colorGreen blue:_colorBlue alpha:0.7]);
			else if (i==_step+delta4)
				CGContextSetFillColor(c, [CPColor colorWithRed:_colorRed green:_colorGreen blue:_colorBlue alpha:0.6]);
			else if (i==_step+delta5)
				CGContextSetFillColor(c, [CPColor colorWithRed:_colorRed green:_colorGreen blue:_colorBlue alpha:0.5]);	
			else if (i==_step+delta6)
				CGContextSetFillColor(c, [CPColor colorWithRed:_colorRed green:_colorGreen blue:_colorBlue alpha:0.4]);
			else
				CGContextSetFillColor(c, [CPColor colorWithRed:_colorRed green:_colorGreen blue:_colorBlue alpha:0.3]);

			CGContextBeginPath(c);
			CGContextMoveToPoint(c, minx, midy);
			CGContextAddArcToPoint(c, minx, miny, midx, miny, radius);
			CGContextAddArcToPoint(c, maxx, miny, maxx, midy, radius);
			CGContextAddArcToPoint(c, maxx, maxy, midx, maxy, radius);
			CGContextAddArcToPoint(c, minx, maxy, minx, midy, radius);
			CGContextFillPath(c);
			CGContextClosePath(c);
			CGContextTranslateCTM(c, size/2, size/2); 
			CGContextRotateCTM(c, 30*(Math.PI/180));
			CGContextTranslateCTM(c, -size/2, -size/2);
		}
	}
}

@end

