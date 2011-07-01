/*
 * FPStringAddons.j
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

@implementation CPString (FPStringAddons)

- (id)initWithContentsOfFile:(CPString)fileName
{
	var filePath = [[CPBundle mainBundle] pathForResource:fileName];
	return [[[self class] alloc] initWithContentsOfURL:[CPURL URLWithString:[CPString stringWithFormat:@"file://%@",filePath]]];
}

- (id)initWithContentsOfURL:(CPURL)url
{
	var fileRequest = [CPURLRequest requestWithURL:url];
	var fileData = [CPURLConnection sendSynchronousRequest:fileRequest returningResponse:nil];
	return [fileData rawString];
}

+ (CPString)stringWithContentsOfFile:(CPString)fileName
{
	return [[[self alloc] initWithContentsOfFile:fileName] autorelease];
}

+ (CPString)stringWithContentsOfURL:(CPURL)url
{
	return [[[self alloc] initWithContentsOfURL:url] autorelease];
}

- (void)drawAtPoint:(CPPoint)point withFont:(CPFont)font
{
	var ctx = [[CPGraphicsContext currentContext] graphicsPort];
	ctx.textBaseline = "top";
	FPContextSetFont(ctx,font);
	ctx.fillText(self,point.x,point.y);
}

- (void)drawAtPoint:(CPPoint)point withFont:(CPFont)font
{
	var ctx = [[CPGraphicsContext currentContext] graphicsPort];
	ctx.textBaseline = "top";
	FPContextSetFont(ctx,font);
	FPContextFillString(ctx,self,point);
}

- (void)drawInRect:(CPRect)rect withFont:(CPFont)font alignment:(CPTextAlignment)alignment
{
	var ctx = [[CPGraphicsContext currentContext] graphicsPort];
	ctx.textBaseline = "top";
	ctx.font = [font cssString];
	
	var alignString = @"left";
	if (alignment==CPCenterTextAlignment) alignString = @"center";
	else if (alignment==CPRightTextAlignment) alignString = @"right";
	
	var textLeft = rect.origin.x;
	if (alignment==CPCenterTextAlignment) textLeft = CGRectGetMidX(rect);
	
	ctx.textAlign = alignString;
	ctx.fillText(self,textLeft,rect.origin.y);//,rect.size.width);
	//return nil;
}

@end