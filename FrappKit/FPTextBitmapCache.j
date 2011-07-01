/*
 * FPTextBitmapCache.j
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

var characterCache = nil;
var characterSizeCache = nil;

var wordCache = nil;
var wordSizeCache = nil;

var lineCache = nil;
var paragraphCache = nil;

function FPTextBitmapCacheRemoveLines(lineArray)
{
	for (var i=0;i<[lineArray count];i++)
	{
		FPTextBitmapCacheRemoveLine([[lineArray objectAtIndex:i] valueForKey:@"uuid"]);
	}
}

function FPTextBitmapCacheRemoveLine(lineUUID)
{
	lineCache[lineUUID] = nil;
}

function FPTextBitmapCacheRemoveParagraph(paragraphUUID)
{
	paragraphCache[paragraphUUID] = nil;
}

@implementation FPTextBitmapCache : CPObject {}

+ (CPSize)drawCharacter:(CPString)character withFont:(CPFont)font atPoint:(CPPoint)origin
{
	if (characterCache == nil) {
		CPLog(@"created characterCache");
		characterCache = new Array();
	}
	
	var keyString = character+"-"+[font size];
	var cachedImageData = characterCache[keyString];
	var ctx = [[CPGraphicsContext currentContext] graphicsPort];
	
	if (cachedImageData != nil)
	{
		ctx.putImageData(cachedImageData,origin.x,origin.y);
		return [characterSizeCache objectForKey:keyString];
	}
	
	[character drawAtPoint:origin withFont:font];
	var characterSize = [self sizeOfCharacter:character withFont:font];
	var imageData = ctx.getImageData(origin.x,origin.y,characterSize.width,characterSize.height);
	//[characterCache setObject:imageData forKey:keyString];
	characterCache[keyString] = imageData;
	
	//return CPMakeSize(0,0);
	return characterSize;
}

+ (CPSize)sizeOfCharacter:(CPString)character withFont:(CPFont)font
{
	if (characterSizeCache == nil)
		characterSizeCache = [[CPMutableDictionary alloc] init];
	
	var keyString = character+"-"+[font size];
	var cachedImageSize = [characterSizeCache objectForKey:keyString];
	
	if (cachedImageSize != nil)
		return cachedImageSize;
		
	cachedImageSize = [character sizeWithFont:font];
	[characterSizeCache setObject:cachedImageSize forKey:keyString];
	return cachedImageSize;
}

// Word Caching

+ (CPSize)drawWord:(CPString)word withFont:(CPFont)font atPoint:(CPPoint)origin
{
	[self drawWord:word withFont:font atPoint:origin usingCache:YES];
}

+ (CPSize)drawWord:(CPString)word withFont:(CPFont)font atPoint:(CPPoint)origin usingCache:(BOOL)useCache
{
	if (wordCache == nil)
		wordCache = new Array();
	
	var keyString = word+"-"+[font size];
	var cachedImageData = wordCache[keyString];
	var ctx = [[CPGraphicsContext currentContext] graphicsPort];
	
	if (useCache && cachedImageData != nil)
	{
		ctx.putImageData(cachedImageData,origin.x,origin.y);
		return [wordSizeCache objectForKey:keyString];
	}
	
	[word drawAtPoint:origin withFont:font];
	var wordSize = [self sizeOfWord:word withFont:font];
	
	if (useCache)
	{
		var imageData = ctx.getImageData(origin.x,origin.y,wordSize.width,wordSize.height);
		wordCache[keyString] = imageData;
	}
	
	return wordSize;
}

+ (CPSize)sizeOfWord:(CPString)word withFont:(CPFont)font
{
	if (wordSizeCache == nil)
		wordSizeCache = [[CPMutableDictionary alloc] init];
	
	var keyString = word+"-"+[font size];
	var cachedImageSize = [wordSizeCache objectForKey:keyString];
	if (cachedImageSize != nil)
		return cachedImageSize;
	
	var wordSize = CPMakeSize(0,0);
	for (var i=0;i<[word length];i++)
	{
		var character = [word substringWithRange:CPMakeRange(i,1)];
		var characterSize = [self sizeOfCharacter:character withFont:font];
		if (characterSize.height > wordSize.height)
			wordSize.height = characterSize.height;
		wordSize.width += characterSize.width;
	}
	[wordSizeCache setObject:wordSize forKey:keyString];
	return wordSize;
}

+ (CPSize)drawLine:(id)line withFont:(CPFont)font atPoint:(CPPoint)origin
{
	[self drawLine:line withFont:font atPoint:origin usingCache:YES];
}

+ (CPSize)drawLine:(id)line withFont:(CPFont)font atPoint:(CPPoint)origin usingCache:(BOOL)useCache
{
	var lineSize = [line valueForKey:@"size"];
	
	if (lineCache == nil)
		lineCache = new Array();
	
	var keyString = [line valueForKey:@"uuid"]+"-"+[font size];
	var cachedImageData = lineCache[keyString];
	var ctx = [[CPGraphicsContext currentContext] graphicsPort];
	
	if (useCache && cachedImageData != nil)
	{
		ctx.putImageData(cachedImageData,origin.x,origin.y);
		return lineSize;
	}
	
	var wordPoint = CPPointCreateCopy(origin);
	var wordSpacing = [self sizeOfCharacter:@" " withFont:font].width;
	var lineWords = [line valueForKey:@"words"];
	
	for (var wordIndex=0;wordIndex<[lineWords count];wordIndex++)
	{
		var word = [lineWords objectAtIndex:wordIndex];
		var wordSize = [FPTextBitmapCache drawWord:word withFont:font atPoint:wordPoint usingCache:useCache];
		wordPoint.x += wordSize.width + wordSpacing;
	}
	
	if (useCache)
	{
		var imageData = ctx.getImageData(origin.x,origin.y,lineSize.width,lineSize.height);
		lineCache[keyString] = imageData;
	}
	
	return lineSize;
}

+ (CPSize)drawParagraph:(id)paragraph withFont:(CPFont)font atPoint:(CPPoint)origin
{
	[self drawParagraph:paragraph withFont:font atPoint:origin usingCache:YES];
}

+ (CPSize)drawParagraph:(id)paragraph withFont:(CPFont)font atPoint:(CPPoint)origin usingCache:(BOOL)useCache
{
	var paragraphRect = CPMakeRect(0,0,0,0);
	paragraphRect.origin = origin;
	paragraphRect.size = [paragraph valueForKey:@"size"];
	
	if (paragraphCache == nil)
		paragraphCache = new Array();
	
	var keyString = [paragraph valueForKey:@"uuid"];
	var cachedImageData = paragraphCache[keyString];
	var ctx = [[CPGraphicsContext currentContext] graphicsPort];
	if (useCache && cachedImageData != nil)
	{
		ctx.putImageData(cachedImageData,paragraphRect.origin.x,paragraphRect.origin.y);
		return paragraphRect.size;
	}
	
	var lines = [paragraph valueForKey:@"lines"];
	var linePoint = CPPointCreateCopy(paragraphRect.origin);
	for (var l=0;l<[lines count];l++)
	{
		var line = [lines objectAtIndex:l];
		linePoint.y += [self drawLine:line withFont:font atPoint:linePoint usingCache:useCache].height;
	}
	
	if (useCache)
	{
		var imageData = ctx.getImageData(paragraphRect.origin.x,paragraphRect.origin.y,paragraphRect.size.width,paragraphRect.size.height);
		paragraphCache[keyString] = imageData;
	}
	
	return paragraphRect.size;
}

@end