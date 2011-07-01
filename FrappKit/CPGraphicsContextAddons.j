/*
 * CPGraphicsContextAddons.j
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

function FPContextClip(ctx)
{
	ctx.clip();
}

function FPContextSetFont(ctx,font)
{
	ctx.font = [font cssString];
}

function FPContextFillString(ctx,string,point)
{
	ctx.fillText(string,point.x,point.y);
}

function FPContextSetGlobalAlpha(ctx,alpha)
{
	ctx.globalAlpha = alpha;
}

function FPContextClipPath(ctx)
{
	ctx.clip();
}

@implementation CPGraphicsContext (CPGraphicsContextAddons)

+ (void)saveGraphicsState
{
	[[self currentContext] graphicsPort].save();
}

+ (void)restoreGraphicsState
{
	[[self currentContext] graphicsPort].restore();
}

@end