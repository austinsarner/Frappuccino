/*
 * FPButton.j
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

@implementation FPButton : FPControl
{
	id target @accessors;
	SEL	action @accessors;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		[self setCell:[[FPButtonCell alloc] init]];
	}
	return self;
}

+ (id)buttonWithTitle:(CPString)title
{
	var button = [[self alloc] initWithFrame:CPMakeRect(0,0,100,24)];
	[button setTitle:title];
	return [button autorelease];
}

+ (id)buttonWithImage:(CPImage)image
{
	var button = [[self alloc] initWithFrame:CPMakeRect(0,0,100,24)];
	[button setImage:image];
	return [button autorelease];
}

+ (id)buttonWithCell:(FPCell)cell
{
	var button = [[self alloc] initWithFrame:CPMakeRect(0,0,100,24)];
	[button setCell:cell];
	return [button autorelease];
}

- (void)setTitle:(CPString)title
{
	[[self cell] setTitle:title];
}

- (CPString)title
{
	return [[self cell] title];
}

- (void)setImage:(CPImage)image
{
	[[self cell] setImage:image];
}

- (CPImage)image
{
	return [[self cell] image];
}

- (void)mouseDown:(CPEvent)mouseEvent
{
	[self lockFocus];
	[[self cell] highlight:YES withFrame:[self bounds] inView:self];
	[self unlockFocus];
}

- (void)mouseUp:(CPEvent)mouseEvent
{
	[self lockFocus];
	[[self cell] highlight:NO withFrame:[self bounds] inView:self];
	[self unlockFocus];
	
	var localPoint = [self convertPoint:[mouseEvent locationInWindow] fromView:nil];
	if (CGRectContainsPoint([self bounds],localPoint))
		[target performSelector:action withObject:self];
}

@end