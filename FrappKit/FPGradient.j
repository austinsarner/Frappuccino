/*
 * FPGradient.j
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

@implementation FPGradient : CPObject
{
	CPMutableArray	colorStops @accessors;
}

- (id)initWithStartingColor:(CPColor)startColor endingColor:(CPColor)endColor
{
	if (self = [super init])
	{
		colorStops = [[CPMutableArray alloc] init];
		[self addColor:startColor atStopLocation:0.0];
		[self addColor:endColor atStopLocation:1.0];
	}
	return self;
}

- (id)initWithColors:(CPArray)colors
{
	if (self = [super init])
	{
		colorStops = [[CPMutableArray alloc] init];
		var i;
		for (i=0;i<[colors count];i++)
		{
			var location = i/[colors count];
			[self addColor:[colors objectAtIndex:i] atStopLocation:location];
		}
	}
	return self;
}

- (id)initWithColors:(CPArray)colorArray atLocations:(CPArray)locationArray
{
	if (self = [super init])
	{
		colorStops = [[CPMutableArray alloc] init];
		if ([colorArray count]==[locationArray count])
		{
			var i;
			for (i=0;i<[colors count];i++)
			{
				var location = [locationArray objectAtIndex:i];
				[self addColor:[colors objectAtIndex:i] atStopLocation:location];
			}
		}
	}
	return self;
}

- (int)numberOfColorStops
{
	return [colorStops count];
}

- (void)addColor:(CPColor)aColor atStopLocation:(float)aLocation
{
	var colorStop = [MDColorStop colorStopWithColor:aColor location:aLocation];
	[colorStops addObject:colorStop];
}

- (void)drawInRect:(CPRect)rect angle:(float)angle
{
	var gradient = [self _linearGradientWithRect:rect angle:angle];
	[self _addStopsToGradient:gradient];
	[self _fillGradient:gradient inRect:rect];
}

- (void)drawInRect:(CPRect)rect relativeCenterPosition:(CPPoint)relativeCenterPosition
{
	var gradient = [self _radialGradientWithRect:rect relativeCenterPosition:relativeCenterPosition];
	[self _addStopsToGradient:gradient];
	[self _fillGradient:gradient inRect:rect];
}

/* @ignore */

- (void)_addStopsToGradient:(JSObject)gradient
{
	var i;
	for (i=0;i<[colorStops count];i++)
	{
		var colorStop = [colorStops objectAtIndex:i];
		gradient.addColorStop(colorStop.location, [colorStop cssString]);
	}
}

- (void)_fillGradient:(JSObject)gradient inRect:(CPRect)rect
{
	var ctx = [[CPGraphicsContext currentContext] graphicsPort];
	ctx.fillStyle = gradient;
	ctx.fillRect(rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
}

- (JSObject)_linearGradientWithRect:(CPRect)rect angle:(CPPoint)angle
{
	var ctx = [[CPGraphicsContext currentContext] graphicsPort];
	/* @fixme - needs angle calculations */
	var startPoint = rect.origin;
	var endPoint = CPMakePoint(rect.origin.x,CGRectGetMaxY(rect));
	if (angle==0)
	{
		endPoint.y = startPoint.y;
		endPoint.x = CGRectGetMaxX(rect);
	}
	
	return ctx.createLinearGradient(startPoint.x,startPoint.y,endPoint.x,endPoint.y);
}

- (JSObject)_radialGradientWithRect:(CPRect)rect relativeCenterPosition:(CPPoint)relativeCenterPosition
{
	var ctx = [[CPGraphicsContext currentContext] graphicsPort];
	return ctx.createRadialGradient(rect.origin.x,rect.origin.y,rect.size.width,rect.size.height,CGRectGetMidX(rect)+relativeCenterPosition.x,CGRectGetMidY(rect)+relativeCenterPosition.y);
}

@end

@implementation MDColorStop : CPObject
{
	CPColor	color @accessors;
	float location @accessors;
}

+ (id)colorStopWithColor:(CPColor)aColor location:(float)aLocation
{
	var colorStop = [[self alloc] init];
	colorStop.color = aColor;
	colorStop.location = aLocation;
	return colorStop;
}

- (CPString)cssString
{
	return [color cssString];
}

@end