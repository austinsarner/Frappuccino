/*
 * FPShadow.j
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

@implementation FPShadow : CPObject
{
	CPPoint shadowOffset @accessors;
	float shadowBlur @accessors;
	CPColor	shadowColor @accessors;
}

+ (id)shadowWithOffset:(CPPoint)offset blur:(float)blur color:(CPColor)color
{
	var shadow = [[self alloc] init];
	shadow.shadowOffset = offset;
	shadow.shadowBlur = blur;
	shadow.shadowColor = color;
	return shadow;
}

- (void)set
{
	var ctx = [[CPGraphicsContext currentContext] graphicsPort];
	ctx.shadowOffsetX = shadowOffset.x;
	ctx.shadowOffsetY = shadowOffset.y;
	ctx.shadowBlur = shadowBlur;
	ctx.shadowColor = [shadowColor cssString];
}

@end