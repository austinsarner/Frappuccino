/*
 * FPControl.j
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

@import "FPView.j"
@import "FPCell.j"

@implementation FPControl : FPView
{
	BOOL enabled @accessors(getter=isEnabled,setter=setEnabled:);
	FPCell cell @accessors;
	Class cellClass @accessors;
}

// Initializing an FPControl

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		
	}
	return self;
}

// Setting the Control's Cell

- (FPCell)cell
{
	return cell;
}

- (void)setCell:(FPCell)aCell
{
	cell = aCell;
	[cell setControlView:self];
}

// Identifying the Selected Cell

- (FPCell)selectedCell
{
	if ([cell state]==FPOnState)
		return cell;
	return nil;
}

- (int)selectedTag
{
	if ([self selectedCell]!=nil)
		return [[self selectedCell] tag];
	return -1;
}

// Setting the Control’s Value

- (double)doubleValue
{
	return [cell doubleValue];
}

- (void)setDoubleValue:(double)doubleValue
{
	[cell setDoubleValue:doubleValue];
}

- (float)floatValue
{
	return [cell floatValue];
}

- (void)setFloatValue:(float)floatValue
{
	[cell setFloatValue:floatValue];
}

- (int)intValue
{
	return [cell intValue];
}

- (void)setIntValue:(int)intValue
{
	[cell setIntValue:intValue];
}

- (id)objectValue
{
	return [cell objectValue];
}

- (void)setObjectValue:(id)objectValue
{
	[cell setObjectValue:objectValue];
}

- (CPString)stringValue
{
	return [cell stringValue];
}

- (void)setStringValue:(CPString)stringValue
{
	[cell setStringValue:stringValue];
}

// Interacting with Other Controls

// Formatting Text

// Managing the Field Editor

// Resizing the Control

// Displaying a Cell

- (void)selectCell:(FPCell)aCell
{
	if ([cell controlView]==self && [cell state]!=FPOnState)
	{
		[cell setState:FPOnState];
		[self setNeedsDisplay:YES];
	}
}

- (void)drawCell:(FPCell)aCell
{
	if (cell == aCell)
		[cell drawWithFrame:[self bounds] inView:self];
}

- (void)drawCellInside:(FPCell)aCell
{
	if (cell == aCell)
		[cell drawInteriorWithFrame:[self bounds] inView:self];
}

- (void)updateCell:(FPCell)aCell
{
	[self setNeedsDisplay:YES];
}

- (void)updateCellInside:(FPCell)aCell
{
	[self setNeedsDisplay:YES];
}

// Drawing

- (void)drawRect:(CPRect)aRect
{
	[self drawCell:cell];
	//[[self cell] drawWithFrame:[self bounds] inView:self];
}

@end