/*
 * CPBezierPathAddons.j
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

@import "CPGraphicsContextAddons.j"

/*
	@global
	@group CPArrowDirection
*/

CPArrowDirectionLeft	= 1;
CPArrowDirectionRight	= 2;
CPArrowDirectionUp		= 3;
CPArrowDirectionDown	= 4;

@implementation CPBezierPath (CPBezierPathAddons)

+ (id)bezierPathWithArrowInRect:(CPRect)arrowRect direction:(CPArrowDirection)direction
{
	var arrowPath = [CPBezierPath bezierPath];
	if (direction==CPArrowDirectionUp)
	{
		[arrowPath moveToPoint:CPMakePoint(CGRectGetMinX(arrowRect),CGRectGetMaxY(arrowRect))];
		[arrowPath lineToPoint:CPMakePoint(CGRectGetMaxX(arrowRect),CGRectGetMaxY(arrowRect))];
		[arrowPath lineToPoint:CPMakePoint(CGRectGetMidX(arrowRect),CGRectGetMinY(arrowRect))];
	}
	else if (direction==CPArrowDirectionDown)
	{
		[arrowPath moveToPoint:CPMakePoint(CGRectGetMinX(arrowRect),CGRectGetMinY(arrowRect))];
		[arrowPath lineToPoint:CPMakePoint(CGRectGetMaxX(arrowRect),CGRectGetMinY(arrowRect))];
		[arrowPath lineToPoint:CPMakePoint(CGRectGetMidX(arrowRect),CGRectGetMaxY(arrowRect))];
	}
	else if (direction==CPArrowDirectionLeft)
	{
		[arrowPath moveToPoint:CPMakePoint(CGRectGetMinX(arrowRect),CGRectGetMidY(arrowRect))];
		[arrowPath lineToPoint:CPMakePoint(CGRectGetMaxX(arrowRect),CGRectGetMinY(arrowRect))];
		[arrowPath lineToPoint:CPMakePoint(CGRectGetMaxX(arrowRect),CGRectGetMaxY(arrowRect))];
	}
	else if (direction==CPArrowDirectionRight)
	{
		[arrowPath moveToPoint:CPMakePoint(CGRectGetMaxX(arrowRect),CGRectGetMidY(arrowRect))];
		[arrowPath lineToPoint:CPMakePoint(CGRectGetMinX(arrowRect),CGRectGetMinY(arrowRect))];
		[arrowPath lineToPoint:CPMakePoint(CGRectGetMinX(arrowRect),CGRectGetMaxY(arrowRect))];
	}
	[arrowPath closePath];
	return arrowPath;
}

- (void)setClip
{
	var ctx = [[CPGraphicsContext currentContext] graphicsPort];
	CGContextBeginPath(ctx);
	CGContextAddPath(ctx, _path);
	CGContextClosePath(ctx);
	FPContextClipPath(ctx);
}

@end