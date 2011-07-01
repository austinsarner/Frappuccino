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

@import "JTElement.j"

/*
	@global
	@group	JTMapElementType
*/

JTMapElementBasic = 0;
JTMapElementSatellite = 1;
JTMapElementHybrid = 2;

@implementation JTMapElement : JTElement
{
	CPImage 			image	@accessors;
	JTMapElementType	mapType	@accessors;
	CPString			address	@accessors;
	int					zoom	@accessors;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		zoom = 10;
		mapType = JTMapElementSatellite;
		address = @"Barcelona, Spain";
		self.usesInspector = YES;
		[self reloadImage];
	}
	return self;
}

- (CPString)mapTypeString
{
	if (mapType==JTMapElementSatellite)
		return @"satellite";
	else if (mapType==JTMapElementHybrid)
		return @"hybrid";
	return @"roadmap";
}

- (CPString)urlFormattedAddress
{
	return [address stringByReplacingOccurrencesOfString:@" " withString:@"+"];
}

- (void)setInspectorPanel:(MDElementInspector)inspector
{
	inspectorPanel = inspector;
	//CPLog(@"load data");
	[inspectorPanel loadData];
}

+ (MDElementInspector)elementInspector
{
	return [[JTMapInspector alloc] initWithContentRect:CPMakeRect(0.0,0.0,260.0,130.0)];
}

- (CPString)mapURL
{
	var width = CGRectGetWidth([self bounds])-12;
	var height = CGRectGetHeight([self bounds])-12;
	return [CPString stringWithFormat:@"http://maps.google.com/maps/api/staticmap?center=%@&zoom=%d&size=%dx%d&maptype=%@&sensor=true",[self urlFormattedAddress],zoom,width,height,[self mapTypeString]];
}

- (void)reloadImage
{
	//CPLog(@"reload image");
	//CPLog([self mapURL]);
	var newImage = [[CPImage alloc] initWithContentsOfFile:[self mapURL]];
	[newImage setDelegate:self];
	if ([newImage loadStatus]==CPImageLoadStatusCompleted)
		[self imageDidLoad:newImage];
}

- (void)elementDidFinishResizing
{
	//CPLog(@"FINISHED RESIZING");
	[super elementDidFinishResizing];
	[self reloadImage];
}

- (void)imageDidLoad:(CPImage)loadedImage
{
	//CPLog(@"image did load");
	self.image = loadedImage;
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(CPRect)aRect
{
	var imageRect = CGRectInset([self bounds],padding,padding);
	
	if (image && [image loadStatus]==CPImageLoadStatusCompleted)
		[image drawInRect:imageRect fraction:1.0];
	else
	{
		[[CPColor colorWithHexString:@"d4f5b1"] set];
		[[CPBezierPath bezierPathWithRect:imageRect] fill];
		[[CPColor blackColor] set];
		var font = [CPFont systemFontOfSize:14];
		var string = @"Loading Map...";
		var stringSize = [string sizeWithFont:font];
		[string drawAtPoint:CPMakePoint(CGRectGetMidX([self bounds])-stringSize.width/2,CGRectGetMidY([self bounds])) withFont:font];
	}
	
	[super drawRect:aRect];
}

@end

@implementation JTMapInspector : MDElementInspector
{
	FPTextField			addressField;
	FPSlider			zoomSlider;
	JPSegmentedControl	mapTypeSegmentedControl;
}

- (id)initWithContentRect:(CPRect)contentRect
{
	if (self = [super initWithContentRect:contentRect])
	{
		addressField = [FPTextField textFieldWithStringValue:@"" placeholder:@"Address" width:220];
		[addressField setFrame:CPMakeRect(15,20,230,28)];
		[addressField setTarget:self];
		[addressField setAction:@selector(addressChanged:)];
		[self.attachedView addSubview:addressField];

		zoomSlider = [[FPSlider alloc] initWithFrame:CGRectMake(13.0,49.0,234.0,28.0)];
		[zoomSlider setMinValue:0];
		[zoomSlider setFloatValue:10];
		[zoomSlider setMaxValue:20];
		[zoomSlider setTarget:self];
		[zoomSlider setAction:@selector(zoomChanged:)];
		[self.attachedView addSubview:zoomSlider];
		
		mapTypeSegmentedControl = [[FPSegmentedControl alloc] initWithFrame:CGRectMake(18.0,82.0,0.0,28.0)];
		[mapTypeSegmentedControl setSegmentCount:3];
		[mapTypeSegmentedControl setLabel:@"Map" forSegment:0];
		[mapTypeSegmentedControl setSelectedSegment:0];
		[mapTypeSegmentedControl setWidth:72 forSegment:0];
		[mapTypeSegmentedControl setLabel:@"Satellite" forSegment:1];
		[mapTypeSegmentedControl setWidth:72 forSegment:1];
		[mapTypeSegmentedControl setLabel:@"Combined" forSegment:2];
		[mapTypeSegmentedControl setWidth:80 forSegment:2];
		[mapTypeSegmentedControl setTarget:self];
		[mapTypeSegmentedControl setAction:@selector(changeMapType:)];
		[self.attachedView addSubview:mapTypeSegmentedControl];
		//[sourceMediaSortingSegmentedControl setAction:@selector(toggledSourceMediaSorting:)];
	}
	return self;
}

- (void)loadData
{
	[addressField setStringValue:element.address];
	[zoomSlider setFloatValue:element.zoom];
	[mapTypeSegmentedControl setSelectedSegment:element.mapType];
}

- (void)addressChanged:(id)sender
{
	[self.element setAddress:[sender stringValue]];
	[self.element reloadImage];
}

- (void)changeMapType:(id)sender
{
	CPLog(@"set map type");
	[self.element setMapType:[sender selectedSegment]];
	[self.element reloadImage];
}

- (void)zoomChanged:(id)sender
{
	[self.element setZoom:[sender floatValue]];
	[self.element reloadImage];
}

@end