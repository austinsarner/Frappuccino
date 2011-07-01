/*
 * FPTextStorage.j
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

//FPTextStorageEditedAttributesMask	1 << FPTextStorageEditedAttributes;
//FPTextStorageEditedCharactersMask	1 << FPTextStorageEditedCharacters;

@implementation FPTextStorage : CPObject
{
	//CPMutableArray layoutManagers;
	CPMutableArray	blocks @accessors;
	CPFont	font @accessors;
	CPColor	foregroundColor @accessors;
	id	delegate @accessors;
	CPString string @accessors;
}

- (id)initWithString:(CPString)aString attributes:(CPDictionary)attributes
{
	if (self = [super init])
	{
		string = aString;
		layoutManagers = [[CPMutableArray alloc] init];
	}
	return self;
}

+ (id)textStorageWithString:(CPString)aString attributes:(CPDictionary)attributes
{
	return [[[self alloc] initWithString:aString attributes:attributes] autorelease];
}

/*- (CPMutableArray)layoutManagers
{
	return layoutManagers;
}

- (void)addLayoutManager:(JTLayoutManager)aLayoutManager
{
	[layoutManagers addObject:aLayoutManager];
}

- (void)removeLayoutManager:(JTLayoutManager)aLayoutManager
{
	[layoutManagers removeObject:aLayoutManager];
}*/

- (CPArray)breakContents
{
	var breakStrings = [string componentsSeparatedByString:@"\n"];
	var breakContents = [[CPMutableArray alloc] init];
	for (var i=0;i<[breakStrings count];i++)
	{
		var breakString = [breakStrings objectAtIndex:i];
		[breakContents addObject:[breakString componentsSeparatedByString:@" "]];
	}
	return breakContents;
}

- (CPArray)paragraphs
{
	var paragraphArray = [CPMutableArray array];
	var paragraphStrings = [string componentsSeparatedByString:@"\n\n"];
	for (var i=0;i<[paragraphStrings count];i++)
	{
		var paragraphString = [paragraphStrings objectAtIndex:i];
		[paragraphArray addObject:[FPTextStorage textStorageWithString:paragraphString attributes:nil]];
	}
	return paragraphArray;
}

- (void)setParagraphs:(CPArray)paragraphs
{
	self.string = [paragraphs componentsJoinedByString:@"\n\n"];
}

- (CPArray)words
{
	return [string componentsSeparatedByString:@" "];
}

- (void)setWords:(CPArray)words
{
	self.string = [words componentsJoinedByString:@" "];
}

- (void)processEditing
{
	if (delegate)
		[delegate textStorageWillProcessEditing:self];
	
	// Do edit processing here
	for (var i=0;i<[layoutManagers count];i++)
	{
		var layoutManager = [layoutManagers objectAtIndex:i];
		[layoutManager textStorage:self edited:FPTextStorageEditedCharactersMask range:CPMakeRange(0,0) changeInLength:0 invalidatedRange:CPMakeRange(0,0)];
	}
	
	if (delegate)
		[delegate textStorageDidProcessEditing:self];
}

@end