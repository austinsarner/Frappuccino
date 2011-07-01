/*
 * FPCell.j
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

/*
	@global
	@group FPFocusRingType
*/

FPFocusRingTypeDefault = 0;
FPFocusRingTypeNone = 1;
FPFocusRingTypeExterior = 2;

/*
	@global
	@group FPCellStateValue
*/

FPMixedState = -1;
FPOffState = 0;
FPOnState = 1;

/*
	@global
	@group FPControlSize
*/

FPRegularControlSize = 0;
FPSmallControlSize = 1;
FPMiniControlSize = 2;

@implementation FPCell : CPObject
{
	id objectValue @accessors;
	BOOL allowsMixedState @accessors;
	BOOL enabled @accessors(getter=isEnabled,setter=setEnabled:);
	BOOL bezeled @accessors(getter=isBezeled,setter=setBezeled:);
	BOOL bordered @accessors(getter=isBordered,setter=setBordered:);
	BOOL opaque @accessors(getter=isOpaque,setter=setOpaque:);
	FPCellStateValue state @accessors;
	SEL	action @accessors;
	id target @accessors;
	BOOL continuous	@accessors(getter=isContinuous,setter=setContinuous:);
	int tag @accessors;
	FPFocusRingType focusRingType @accessors;
	id representedObject @accessors;
	CPView controlView @accessors;
	BOOL highlighted @accessors(getter=isHighlighted,setter=setHighlighted:);
	FPControlSize controlSize @accessors;
}

+ (FPFocusRingType)defaultFocusRingType
{
	return FPFocusRingTypeNone;
}

- (id)init
{
	if (self = [super init])
	{
		highlighted = NO;
		enabled = YES;
		bordered = NO;
		bezeled = NO;
		tag = 0;
		opaque = NO;
		allowsMixedState = NO;
		focusRingType = [[self class] defaultFocusRingType];
		state = FPOffState;
		controlSize = FPRegularControlSize;
	}
	return self;
}

// States

- (FPCellStateValue)nextState
{
	if (!allowsMixedState)
		return (state==FPOffState)?FPOnState:FPOffState;
	else
	{
		if (state==FPOffState)
			return FPMixedState;
		else
			return (state==FPOnState)?FPOffState:FPOnState;
	}
}

- (void)setNextState
{
	[self setState:[self nextState]];
}

// Numbers

- (int)intValue
{
	return [objectValue intValue];
}

- (void)setIntValue:(int)intValue
{
	objectValue = [CPNumber numberWithInt:intValue];
}

- (double)doubleValue
{
	return [objectValue doubleValue];
}

- (void)setDoubleValue:(int)doubleValue
{
	objectValue = [CPNumber numberWithDouble:doubleValue];
}

- (float)floatValue
{
	return [objectValue floatValue];
}

- (void)setFloatValue:(int)floatValue
{
	objectValue = [CPNumber numberWithFloat:floatValue];
}

// Text Cell

- (CPString)title
{
	return [self stringValue];
}

- (void)setTitle:(CPString)aString
{
	[self setStringValue:aString];
}

- (void)setStringValue:(CPString)aString
{
	objectValue = aString;
}

- (CPString)stringValue
{
	return objectValue;
}

// Cell

- (BOOL)hasValidObjectValue
{
	if (objectValue != nil)
		return ([objectValue isKindOfClass:[CPString class]]||[objectValue isKindOfClass:[CPNumber class]]||[objectValue isKindOfClass:[CPImage class]]);
	return NO;
}

// Responder

- (void)performClick:(id)sender
{
	
}

// Size

- (CPSize)cellSize
{
	return CPMakeSize(0,0);
}

- (CPSize)cellSizeForBounds:(CPRect)aRect
{
	return CPMakeSize(0,0);
}

// Drawing

- (void)drawWithFrame:(CPRect)cellFrame inView:(CPView)view
{
	controlView = view;
}

- (void)drawInteriorWithFrame:(CPRect)cellFrame inView:(CPView)view
{
	controlView = view;
}

- (void)highlight:(BOOL)flag withFrame:(CPRect)cellFrame inView:(CPView)view
{
	controlView = view;
}

// Mouse Events

- (void)mouseDown:(CPEvent)event
{
	
}

- (void)mouseUp:(CPEvent)event
{
	
}

- (void)mouseEntered:(CPEvent)event
{
}

- (void)mouseExited:(CPEvent)event
{
}

@end

/*
	@global
	@group FPTextAlignment
*/

FPLeftTextAlignment = 0;
FPRightTextAlignment = 1;
FPCenterTextAlignment = 2;
FPJustifiedTextAlignment = 3;
FPNaturalTextAlignment = 4;

/*
	@global
	@group FPLineBreakMode
*/

FPLineBreakByWordWrapping = 0;
FPLineBreakByCharWrapping = 1;
FPLineBreakByClipping = 2;
FPLineBreakByTruncatingHead = 3;
FPLineBreakByTruncatingTail = 4;
FPLineBreakByTruncatingMiddle = 5;

@implementation FPTextCell : FPCell
{
	BOOL editable @accessors(getter=isEditable,setter=setEditable:);
	BOOL selectable @accessors(getter=isSelectable,setter=setSelectable:);
	BOOL scrollable @accessors(getter=isScrollable,setter=setScrollable:);
	FPTextAlignment alignment @accessors;
	CPFont font	@accessors;
	FPLineBreakMode lineBreakMode @accessors;
	BOOL truncatesLastVisisbleLine @accessors;
	BOOL wraps @accessors;
}

- (id)initWithStringValue:(CPString)stringVal
{
	if (self = [super init])
		[self setStringValue:stringVal];
	return self;
}

@end

/*
	@global
	@group FPImageScaling
*/

FPScaleProportionally	= 0;
FPScaleToFit            = 1;
FPScaleNone             = 2;

@implementation FPImageCell : FPCell
{
	FPImageScaling imageScaling @accessors;
}

- (id)init
{
	if (self = [super init])
		imageScaling = FPScaleProportionally;
	
	return self;
}

- (id)initWithImage:(CPImage)image
{
	if (self = [super init])
	{
		[self setImage:image];
		imageScaling = FPScaleProportionally;
	}
	return self;
}

// Image Cell

- (void)setImage:(CPImage)image
{
	objectValue = image;
}

- (CPImage)image
{
	return objectValue;
}

- (CPRect)imageRectForBounds:(CPRect)theRect
{
	var imageRect = CPRectCreateCopy(theRect);
	var image = [self image];
	if (image && [image loadStatus]==CPImageLoadStatusCompleted && imageScaling == FPScaleProportionally)
	{
		var imageSize = [image size];

		if (imageSize.width > imageSize.height)
		{
			var newImageHeight = imageSize.height * (imageRect.size.width / imageSize.width);
			imageRect.origin.y = CGRectGetMidY(imageRect) - newImageHeight/2;
			imageRect.size.height = newImageHeight;
		}
		else if (imageSize.height > imageSize.width)
		{
			var newImageWidth = imageSize.width * (imageRect.size.height / imageSize.height);
			imageRect.origin.x = CGRectGetMidX(imageRect) - newImageWidth/2;
			imageRect.size.width = newImageWidth;
		}
	}
	return imageRect;
}

- (void)drawWithFrame:(CPRect)cellFrame inView:(CPView)view
{
	var image = [self image];
	if (image && [image loadStatus]==CPImageLoadStatusCompleted)
	{
		var imageRect = [self imageRectForBounds:cellFrame];
		[image drawInRect:imageRect fraction:1.0];
	}
}

@end

@implementation FPButtonCell : FPCell
{
	CPImage image @accessors;
	CPPoint	imageOffset @accessors;
}

+ (id)buttonCell
{
	var cell = [[self alloc] init];
	return [cell autorelease];
}

- (void)drawWithFrame:(CPRect)cellFrame inView:(CPView)view
{
	var outerPath = [CPBezierPath bezierPath];
	[outerPath appendBezierPathWithRoundedRect:cellFrame xRadius:3.0 yRadius:3.0];
	[[CPColor colorWithCalibratedWhite:0.7 alpha:1.0] set];
	[outerPath fill];
	
	var buttonPath = [CPBezierPath bezierPath];
	[buttonPath appendBezierPathWithRoundedRect:CGRectInset(cellFrame,1,1) xRadius:3.0 yRadius:3.0];
	var startColor = [CPColor colorWithCalibratedWhite:0.95 alpha:1.0];
	var endColor = [CPColor colorWithCalibratedWhite:0.75 alpha:1.0];
	var gradient = [[FPGradient alloc] initWithStartingColor:[self isHighlighted]?endColor:startColor endingColor:[self isHighlighted]?startColor:endColor];
	
	[CPGraphicsContext saveGraphicsState];
	[buttonPath setClip];
	[gradient drawInRect:cellFrame angle:-90];
	[CPGraphicsContext restoreGraphicsState];
	
	if ([self title] != nil)
	{
		var textFont = [CPFont boldSystemFontOfSize:12];
		var textSize = [[self title] sizeWithFont:textFont];
		var textRect = CPMakeRect(parseInt(CGRectGetMidX(cellFrame)-textSize.width/2),parseInt(CGRectGetMidY(cellFrame))+5,textSize.width,textSize.height);
	
		[CPGraphicsContext saveGraphicsState];
		[[FPShadow shadowWithOffset:CPMakePoint(0,-1) blur:1 color:[CPColor colorWithCalibratedWhite:1.0 alpha:1.0]] set];
		[[CPColor colorWithCalibratedWhite:0.2 alpha:1.0] set];
		[[self title] drawAtPoint:textRect.origin withFont:textFont];
		[CPGraphicsContext restoreGraphicsState];
	}
	
	[self drawImageWithFrame:[self imageRectForBounds:cellFrame] inView:view];
}

- (CPRect)imageRectForBounds:(CPRect)bounds
{
	if (image != nil && [image loadStatus]==CPImageLoadStatusCompleted)
	{
		var imageSize = [[self image] size];
		var imageRect = CPMakeRect(parseInt(CGRectGetMidX(bounds)-imageSize.width/2),parseInt(CGRectGetMidY(bounds)-imageSize.height/2),imageSize.width,imageSize.height);
		if (imageOffset != nil)
		{
			imageRect.origin.x += imageOffset.x;
			imageRect.origin.y += imageOffset.y;
		}
		return imageRect;
	}
	return CGRectMakeZero();
}

- (void)drawImageWithFrame:(CPRect)cellFrame inView:(CPView)view
{
	if (image != nil && [image loadStatus]==CPImageLoadStatusCompleted)
		[image drawInRect:cellFrame fraction:1.0];
}

- (void)highlight:(BOOL)flag withFrame:(CPRect)cellFrame inView:(CPView)view
{
	[self setHighlighted:flag];
	CGContextClearRect([[CPGraphicsContext currentContext] graphicsPort],cellFrame);
	[self drawWithFrame:cellFrame inView:view];
}

- (void)setImage:(CPImage)anImage
{
	image = anImage;
	[image setDelegate:self];
}

- (void)imageDidLoad:(CPImage)anImage
{
	if (controlView != nil)
		[controlView setNeedsDisplay:YES];
}

@end