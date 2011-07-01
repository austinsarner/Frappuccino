/*
 * FPSegmentedControl.j
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

@implementation FPSegmentedControl : FPControl
{
	CPMutableArray representedObjects @accessors;
	id target @accessors;
	SEL action @accessors;
	int highlightedSegment;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		representedObjects = [[CPMutableArray alloc] init];
		[self setCell:[[FPSegmentedCell alloc] init]];
	}
	return self;
}

- (void)setCell:(FPCell)aCell
{
	[super setCell:aCell];
	[self setNeedsDisplay:YES];
}

// Specifying Number of Segments

- (void)setSegmentCount:(int)count
{
	[representedObjects removeAllObjects];
	for (var i=0;i<count;i++)
		[representedObjects addObject:[[FPSegmentRepresentedItem alloc] init]];
}

- (int)segmentCount
{
	return [representedObjects count];
}

// Specifying Selected Segment

- (void)setSelectedSegment:(int)selectedSegment
{
	for (var i=0;i<[self segmentCount];i++)
		[self setSelected:(i==selectedSegment) forSegment:i];
}

- (int)selectedSegment
{
	for (var i=0;i<[self segmentCount];i++)
	{
		var isSelected = [self isSelectedForSegment:i];
		if (isSelected) return i;
	}
	return -1;
}

- (void)selectSegmentWithTag:(int)tag
{
	for (var i=0;i<[self segmentCount];i++)
	{
		var representedObject = [representedObjects objectAtIndex:i];
		if ([representedObject tag]==tag)
		{
			[self setSelectedSegment:i];
			return;
		}
	}
}

// Drawing Segments

- (void)_cellFrameAtIndex:(int)index
{
	var xLocation = 0;
	var width = 0;
	for (var i=0;i<=index;i++)
	{
		width = [[representedObjects objectAtIndex:i] width];
		if (i!=index)
			xLocation += width;
	}
	return CPMakeRect(xLocation,0,width,CGRectGetHeight([self bounds]));
}

- (int)_segmentAtPoint:(CPPoint)point
{
	for (var i=0;i<[self segmentCount];i++)
	{
		var cellFrame = [self _cellFrameAtIndex:i];
		if (CGRectContainsPoint(cellFrame,point))
			return i;
	}
	return -1;
}

- (void)drawRect:(CPRect)aRect
{
	for (var i=0;i<[self segmentCount];i++)
	{
		var cell = [self cell];
		[cell setRepresentedObject:[representedObjects objectAtIndex:i]];
		[cell drawWithFrame:[self _cellFrameAtIndex:i] inView:self];
	}
}

- (void)mouseDown:(CPEvent)mouseEvent
{
	var localPoint = [self convertPoint:[mouseEvent locationInWindow] fromView:nil];
	var index = [self _segmentAtPoint:localPoint];
	if (index>-1)
	{
		highlightedSegment = index;
		[self lockFocus];
		var cell = [self cell];
		[cell setRepresentedObject:[representedObjects objectAtIndex:index]];
		[cell highlight:YES withFrame:[self _cellFrameAtIndex:index] inView:self];
		[self unlockFocus];
	}
}

- (void)mouseUp:(CPEvent)mouseEvent
{
	if (highlightedSegment>-1)
	{
		var localPoint = [self convertPoint:[mouseEvent locationInWindow] fromView:nil];
		
		[self lockFocus];
		var cell = [self cell];
		[cell setRepresentedObject:[representedObjects objectAtIndex:highlightedSegment]];
		[cell highlight:NO withFrame:[self _cellFrameAtIndex:highlightedSegment] inView:self];
		[self unlockFocus];
		
		if (highlightedSegment == [self _segmentAtPoint:localPoint] && highlightedSegment!=[self selectedSegment])
		{
			[self setSelectedSegment:highlightedSegment];
			[target performSelector:action withObject:self];
		}
	}
}

// Working with Individual Segments

- (void)setWidth:(int)width forSegment:(int)segment
{
	[[representedObjects objectAtIndex:segment] setWidth:width];
	
	var newFrame = CPRectCreateCopy([self frame]);
	newFrame.size.width = 0;
	for (var i=0;i<[self segmentCount];i++)
		newFrame.size.width += [[representedObjects objectAtIndex:i] width];
	[self setFrame:newFrame];
	
	[self setNeedsDisplay:YES];
}

- (int)widthForSegment:(int)segment
{
	return [[representedObjects objectAtIndex:segment] width];
}

- (void)setImage:(CPImage)image forSegment:(int)segment
{
	[image setDelegate:self];
	[[representedObjects objectAtIndex:segment] setImage:image];
	[self setNeedsDisplay:YES];
}

- (void)imageDidLoad:(CPImage)image
{
	[self setNeedsDisplay:YES];
}

- (CPImage)imageForSegment:(int)segment
{
	return [[representedObjects objectAtIndex:segment] image];
}

- (void)setLabel:(CPString)label forSegment:(int)segment
{
	[[representedObjects objectAtIndex:segment] setLabel:label];
	[self setNeedsDisplay:YES];
}

- (CPString)labelForSegment:(int)segment
{
	return [[representedObjects objectAtIndex:segment] label];
}

- (void)setSelected:(BOOL)flag forSegment:(int)segment
{
	[[representedObjects objectAtIndex:segment] setSelected:flag];
	[self setNeedsDisplay:YES];
}

- (BOOL)isSelectedForSegment:(int)segment
{
	return [[representedObjects objectAtIndex:segment] isSelected];
}

- (void)setEnabled:(BOOL)flag forSegment:(int)segment
{
	[[representedObjects objectAtIndex:segment] setEnabled:flag];
	[self setNeedsDisplay:YES];
}

- (BOOL)isEnabledForSegment:(int)segment
{
	return [[representedObjects objectAtIndex:segment] isEnabled];
}

@end

/*
	@global
	@group FPSegmentedCellCap
*/

FPSegmentedCellLeftCap = 0;
FPSegmentedCellRightCap = 1;
FPSegmentedCellNoCap = 2;

@implementation FPSegmentedCell : FPButtonCell
{
}

- (void)setRepresentedObject:(id)object
{
	self.representedObject = object;
	[self setTitle:[object label]];
	[self setImage:[object image]];
	[self setState:[object isSelected]?FPOnState:FPOffState];
}

- (CPBezierPath)backgroundPathWithRect:(CPRect)aRect radius:(int)radius
{
	var backgroundRect = aRect;
	var backgroundPath = [CPBezierPath bezierPath];
	var cellCap = [self cellCap];
	
	if (cellCap == FPSegmentedCellLeftCap || cellCap == FPSegmentedCellRightCap)
	{
		[backgroundPath appendBezierPathWithRoundedRect:backgroundRect xRadius:radius yRadius:radius];
		var blockPath = CPRectCreateCopy(backgroundRect);
		if (cellCap == FPSegmentedCellLeftCap)
			blockPath.origin.x = CGRectGetMaxX(blockPath)-5;
		blockPath.size.width = 5;
		[backgroundPath appendBezierPathWithRect:blockPath];
	}
	else
		[backgroundPath appendBezierPathWithRect:backgroundRect];
	
	return backgroundPath;
}

- (FPSegmentedCellCap)cellCap
{
	var cellIndex = [[controlView representedObjects] indexOfObject:representedObject];
	if (cellIndex==0)
		return FPSegmentedCellLeftCap;
	else if (cellIndex==[[controlView representedObjects] count]-1)
		return FPSegmentedCellRightCap;
	return FPSegmentedCellNoCap;
}

- (void)drawWithFrame:(CPRect)frame inView:(CPView)view
{
	var startWhiteAmount = (state==FPOnState)?0.7:0.8;
	var endWhiteAmount = (state==FPOnState)?0.4:0.5;
	
	if ([self isHighlighted])
	{
		startWhiteAmount -= 0.05;
		endWhiteAmount -= 0.05;
	}
	
	var startColor = [CPColor colorWithCalibratedWhite:startWhiteAmount alpha:1.0];
	var endColor = [CPColor colorWithCalibratedWhite:endWhiteAmount alpha:1.0];
	
	var backgroundRect = frame;
	[CPGraphicsContext saveGraphicsState];
	
	var backgroundPath = [self backgroundPathWithRect:backgroundRect radius:4];
	var cellCap = [self cellCap];
	
	var gradient = [[FPGradient alloc] initWithStartingColor:startColor endingColor:endColor];
	[backgroundPath setClip];
	[gradient drawInRect:backgroundRect angle:-90];
	[CPGraphicsContext restoreGraphicsState];
	
	var borderColor = [CPColor colorWithCalibratedWhite:0.0 alpha:0.2];
	var insetColor = [CPColor colorWithCalibratedWhite:1.0 alpha:0.2];
	var rightBorderRect = CPMakeRect(CGRectGetMaxX(backgroundRect)-1,0,1,CGRectGetHeight(backgroundRect));
	var leftBorderRect = CPMakeRect(CGRectGetMinX(backgroundRect),0,1,CGRectGetHeight(backgroundRect));
	
	if (cellCap == FPSegmentedCellLeftCap)
	{
		[borderColor set];
		[[CPBezierPath bezierPathWithRect:rightBorderRect] fill];
		
		rightBorderRect.origin.x--;
		[insetColor set];
		[[CPBezierPath bezierPathWithRect:rightBorderRect] fill];
	}
	else if (cellCap == FPSegmentedCellRightCap)
	{
		[borderColor set];
		[[CPBezierPath bezierPathWithRect:leftBorderRect] fill];
		
		leftBorderRect.origin.x++;
		[insetColor set];
		[[CPBezierPath bezierPathWithRect:leftBorderRect] fill];
	}
	else
	{
		[insetColor set];
		[[CPBezierPath bezierPathWithRect:leftBorderRect] fill];
		[[CPBezierPath bezierPathWithRect:rightBorderRect] fill];
	}
	
	[[CPColor blackColor] set];
	var labelFont = [CPFont boldSystemFontOfSize:12];
	var labelSize = [[self title] sizeWithFont:labelFont];
	
	[CPGraphicsContext saveGraphicsState];
	[[FPShadow shadowWithOffset:CPMakePoint(0,-1) blur:1 color:[CPColor colorWithCalibratedWhite:1.0 alpha:0.5]] set];
	[[self title] drawAtPoint:CPMakePoint(CGRectGetMidX(frame)-labelSize.width/2,CGRectGetMidY(frame)+1-labelSize.height/2) withFont:labelFont];
	[CPGraphicsContext restoreGraphicsState];
}

@end

@implementation FPSegmentRepresentedItem : CPObject
{
	int width @accessors;
	CPImage image @accessors;
	CPString label @accessors;
	int tag @accessors;
	BOOL selected @accessors(getter=isSelected,setter=setSelected:);
}

- (id)init
{
	if (self = [super init])
		tag = 0;
	return self;
}

@end