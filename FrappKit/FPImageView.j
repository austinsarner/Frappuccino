/*
 * FPImageView.j
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

@import "FPControl.j"

@implementation FPImageView : FPControl
{
	
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
		[self setCell:[[FPImageCell alloc] init]];
	return self;
}

// Choosing the Image

- (CPImage)image
{
	return [[self cell] image];
}

- (void)setImage:(CPImage)image
{
	[[self cell] setImage:image];
	[self setNeedsDisplay:YES];
}

// Scaling the Image

- (FPImageScaling)imageScaling
{
	return [[self cell] imageScaling];
}

- (void)setImageScaling:(FPImageScaling)imageScaling
{
	[[self cell] setImageScaling:imageScaling];
}

// Drawing

- (void)drawRect:(CPRect)aRect
{
	[[self cell] drawWithFrame:aRect inView:self];
}

@end