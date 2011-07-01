/*
 * FPTextLayoutManager.j
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

@import "FPTextBitmapCache.j"

function FPTextGetNumberOfCharactersInLine(line)
{
	var words = [line valueForKey:@"words"];
	var numberOfCharactersInLine = 0;
	for (var k = 0; k < [words count]; k++)
		numberOfCharactersInLine += [[words objectAtIndex:k] length] + 1;
	return numberOfCharactersInLine;
}

function FPTextCreateParagraph()
{
	var paragraph = [CPMutableDictionary dictionary];
	[paragraph setValue:Math.uuid() forKey:@"uuid"];
	[paragraph setValue:[CPMutableArray array] forKey:@"intersectionRects"];
	return paragraph;
}

function FPTextCreateLine()
{
	var newLine = [CPMutableDictionary dictionary];
	[newLine setValue:Math.uuid() forKey:@"uuid"];
	[newLine setValue:CPMakeSize(0,0) forKey:@"size"];
	[newLine setValue:[CPMutableArray array] forKey:@"words"];
	[newLine setValue:[CPNumber numberWithInt:0] forKey:@"numberOfCharacters"];
	return newLine;
}

function FPTextNumberOfCharactersInLine(line)
{
	return [[line valueForKey:@"numberOfCharacters"] intValue];
}

function FPTextNumberOfCharactersInParagraph(paragraph)
{
	var lines = [paragraph valueForKey:@"lines"];
	var numberOfCharactersInParagraph = 0;
	for (var l = 0; l < [lines count]; l++)
		numberOfCharactersInParagraph += FPTextNumberOfCharactersInLine([lines objectAtIndex:l]);
	return numberOfCharactersInParagraph;
}

@implementation CPObject (FPTextLayoutManagerDelegate) {}

- (void)layoutManager:(CPTextLayoutManager)aTextLayoutManager didRecalculateLayoutInFrame:(CPRect)aFrame {}

@end

@implementation FPTextLayoutManager : CPObject
{
	CPMutableArray	clippedAreas;
	CPMutableArray	paragraphs @accessors;
	FPTextStorage	textStorage @accessors;
	FPText			textView @accessors;
	BOOL			shouldWrapText @accessors;
	BOOL			initiatedLayout @accessors;
	int				defaultWordSpacing @accessors;
	int				lineHeightMultiplier @accessors;
	int				defaultLineWidth;
}

- (id)initWithTextView:(FPText)aTextView
{
	if (self = [super init])
	{
		initiatedLayout = NO;
		shouldWrapText = YES;
		textView = aTextView;
		var characterSize = [FPTextBitmapCache sizeOfCharacter:@" " withFont:[textView font]];
		defaultWordSpacing = characterSize.width;
		lineHeightMultiplier = 1.2;
		defaultLineWidth = lineHeightMultiplier * characterSize.height;
		
		textStorage = [textView textStorage];
		paragraphs = [[CPMutableArray alloc] init];
		clippedAreas = [[CPMutableArray alloc] init];
	}
	return self;
}

- (void)textLocationAtPoint:(CPPoint)point
{
	var textLocation = 0;
	var currentPoint = CPMakePoint(0,-2);
	
	for (var i = 0; i < [paragraphs count]; i++)
	{
		currentPoint.x = 0;
		var paragraph = [paragraphs objectAtIndex:i];
		var paragraphSize = [paragraph valueForKey:@"size"];
		var paragraphRect = CPMakeRect(currentPoint.x,currentPoint.y,paragraphSize.width,paragraphSize.height);
		
		if (CGRectContainsPoint(paragraphRect,point))
		{
			var lines = [[paragraphs objectAtIndex:i] valueForKey:@"lines"];
		
			for (var j = 0; j < [lines count]; j++) {
				currentPoint.x = 0;
				var line = [lines objectAtIndex:j];
				var lineSize = [line valueForKey:@"size"];
				var lineRect = CPMakeRect(0,currentPoint.y,[textView bounds].size.width,lineSize.height);
			
				if (CGRectContainsPoint(lineRect,point))
				{
					var words = [line valueForKey:@"words"];
				
					for (var w = 0; w < [words count]; w++)
					{
						var word = [words objectAtIndex:w];
						var wordSpacing = [FPTextBitmapCache sizeOfCharacter:@" " withFont:[textView font]].width;
						var wordSize = [FPTextBitmapCache sizeOfWord:word withFont:[textView font]];
						var wordRect = CPMakeRect(currentPoint.x,currentPoint.y,wordSize.width,wordSize.height);
						if (CGRectContainsPoint(wordRect,point))
						{
							for (var c = 0; c < [word length]; c++)
							{
								var character = [word characterAtIndex:c];
								var characterSize = [FPTextBitmapCache sizeOfCharacter:character withFont:[textView font]];
								if (currentPoint.x + characterSize.width/2 >= point.x)
									return textLocation - 1;
								currentPoint.x += characterSize.width;
								textLocation++;
							}
							return textLocation;
						}
						textLocation += [word length] + 1;
						currentPoint.x += wordSize.width + wordSpacing;
					}
					return textLocation-1;				
				} else {
					textLocation += FPTextNumberOfCharactersInLine(line);
					currentPoint.y += lineSize.height;
				}
			}
			return textLocation;
		} else {
			textLocation += FPTextNumberOfCharactersInParagraph(paragraph);
			currentPoint.y += paragraphSize.height;
		}
	}
}

- (void)pointAtTextLocation:(int)characterIndex
{
	var point = CPMakePoint(0,0);
	var currentCharacterIndex = 0;
	
	for (var i = 0; i < [paragraphs count]; i++) {
		var paragraph = [paragraphs objectAtIndex:i];
		var numberOfCharactersInParagraph = FPTextNumberOfCharactersInParagraph(paragraph)+1;
		var paragraphRange = CPMakeRange(currentCharacterIndex,numberOfCharactersInParagraph);
		
		if (CPLocationInRange(characterIndex,paragraphRange))
		{
			var lines = [paragraph valueForKey:@"lines"];
		
			for (var j = 0; j < [lines count]; j++) {
							
				var line = [lines objectAtIndex:j];
				var words = [line valueForKey:@"words"];
				var numberOfCharactersInLine = FPTextNumberOfCharactersInLine(line);
				var lineRange = CPMakeRange(currentCharacterIndex,numberOfCharactersInLine);
			
				if (currentCharacterIndex == characterIndex)
					return point;
			
				if (CPLocationInRange(characterIndex,lineRange))
				{
					var characterIndexInLine = characterIndex - currentCharacterIndex;
					var currentIndexInLine = 0;
				
					for (var l = 0; l < [words count]; l++) {
						var word = [words objectAtIndex:l];
						var charactersInWord = [word length];
					
						if ((charactersInWord + currentIndexInLine) >= characterIndexInLine) {
						
							var characterIndexInWord = characterIndexInLine - currentIndexInLine;
							var subStringLength = [FPTextBitmapCache sizeOfWord:[word substringWithRange:CPMakeRange(0,characterIndexInWord)] withFont:[textView font]].width;
							point.x += subStringLength;
						
							return point;
						}
						
						var wordSpacing = [FPTextBitmapCache sizeOfCharacter:@" " withFont:[textView font]].width;
						point.x += [FPTextBitmapCache sizeOfWord:word withFont:[textView font]].width + wordSpacing;
						currentIndexInLine += charactersInWord;
						currentIndexInLine++;
					}
				}
			
				point.y += [line valueForKey:@"size"].height;
				currentCharacterIndex += numberOfCharactersInLine;
			}
		} else
		{
			point.y += [paragraph valueForKey:@"size"].height;
			currentCharacterIndex += numberOfCharactersInParagraph;
		}
	}
	
	return CGPointMakeZero();
}

- (CPRange)rangeOfWordAtPoint:(CPPoint)localPoint
{
	var textLocation = [self textLocationAtPoint:localPoint];
	var textRange = CPMakeRange(textLocation,1);
	
	var clickedText = [[textView string] substringWithRange:textRange];
	if ([clickedText isEqual:@" "])
		return textRange;
	
	var selFirstWord = NO;
	while (![clickedText hasPrefix:@" "]&&![clickedText hasPrefix:@"\n"])
	{
		textRange.location--;
		textRange.length++;
		
		if (textRange.location<0)
		{
			selFirstWord = YES;
			textRange.location++;
			textRange.length--;
			clickedText = [@" " stringByAppendingString:clickedText];
		}
		else
			clickedText = [[textView string] substringWithRange:textRange];
	}
	while (![clickedText hasSuffix:@" "]&&![clickedText hasSuffix:@"\n"])
	{
		textRange.length++;
		if (CPMaxRange(textRange)>[[textView string] length])
			clickedText = [clickedText stringByAppendingString:@" "]
		else
			clickedText = [[textView string] substringWithRange:textRange];
	}
	if ([clickedText hasSuffix:@". "]||[clickedText hasSuffix:@", "]||[clickedText hasSuffix:@"\n"])
		textRange.length--;
	
	if (!selFirstWord) textRange.location++;
	textRange.length-=(!selFirstWord)?2:1;
	
	return textRange;
}

- (CPRange)rangeOfParagraphAtPoint:(CPPoint)localPoint
{
	var paragraphOrigin = CPMakePoint(0,0);
	var currentCharacterIndex = 0;
	
	for (var i = 0; i < [paragraphs count]; i++) {
		var paragraph = [paragraphs objectAtIndex:i];
		var paragraphSize = [paragraph valueForKey:@"size"];
		var paragraphRect = CPMakeRect(paragraphOrigin.x,paragraphOrigin.y,paragraphSize.width,paragraphSize.height);
		var numberOfCharactersInParagraph = FPTextNumberOfCharactersInParagraph(paragraph)+1;
		var paragraphRange = CPMakeRange(currentCharacterIndex,numberOfCharactersInParagraph);
		
		if (CGRectContainsPoint(paragraphRect,localPoint))
			return CPMakeRange(paragraphRange.location,paragraphRange.length-2);
			
		paragraphOrigin.y += paragraphSize.height;
		currentCharacterIndex += numberOfCharactersInParagraph;
	}
	return CPMakeRange(0,0);
}

// Layout

- (void)_initiateLayout
{
	[paragraphs removeAllObjects];
	initiatedLayout = YES;
	
	var textViewBounds = [textView bounds];
	var globalMaxLineWidth = CGRectGetWidth(textViewBounds);
	var breakContentsInText = [textStorage breakContents];
	
	for (var i=0;i<[breakContentsInText count];i++)
	{
		var words = [breakContentsInText objectAtIndex:i];
		
		if ([words count]>1)
		{
			var paragraph = FPTextCreateParagraph();
			[paragraph setValue:CPMakeSize(CGRectGetWidth([textView bounds]),0) forKey:@"size"];
			[paragraph setValue:words forKey:@"words"];
			[paragraph setValue:[CPNumber numberWithInt:i] forKey:@"breakIndex"];
			[self _layoutParagraph:paragraph];
			[paragraphs addObject:paragraph];
		}
	}
}

- (void)_resetWordsInParagraph:(CPDictionary)paragraph
{
	var breakContentsInText = [textStorage breakContents];
	var breakIndex = [[paragraph valueForKey:@"breakIndex"] intValue];
	[paragraph setValue:[breakContentsInText objectAtIndex:breakIndex] forKey:@"words"];
	FPTextBitmapCacheRemoveParagraph([paragraph valueForKey:@"uuid"]);
	[paragraph setValue:Math.uuid() forKey:@"uuid"];
}

- (void)_layoutParagraph:(CPDictionary)paragraph
{
	//FPTextBitmapCacheRemoveLines([paragraph valueForKey:@"lines"]);
	
	var existingLineArray = [paragraph valueForKey:@"lines"];
	if (existingLineArray == nil) existingLineArray = [CPArray array];
	
	var lineArray = [[CPMutableArray alloc] init];
	var currentLine = nil;
	var paragraphHeight = 0;
	var wordIndex = 0;
	var lineWidth = 0;
	var globalMaxLineWidth = CGRectGetWidth([textView frame]);
	var lineY = 0;
	var words = [paragraph valueForKey:@"words"];
	
	while (wordIndex<[words count])
	{
		var word = [words objectAtIndex:wordIndex];
		var wordSize = [FPTextBitmapCache sizeOfWord:word withFont:[textView font]];
		var maxLineWidth = globalMaxLineWidth;
		var lineSize = CPMakeSize(maxLineWidth,parseInt(wordSize.height * lineHeightMultiplier));
		var lineRect = CPMakeRect(0,lineY,CGRectGetWidth([textView bounds]),lineSize.height);
		
		if (currentLine == nil) currentLine = FPTextCreateLine();
		
		if (shouldWrapText)
		{
			var intersectionRectangles = [paragraph valueForKey:@"intersectionRects"];
			var clippedIntersectionWidth = 0;
			
			for (var r=0;r<[intersectionRectangles count];r++)
			{
				var intersectionRect = [intersectionRectangles objectAtIndex:r];
				var rectOriginX = intersectionRect.origin.x;
				
				var lineIntersectionRect = CGRectIntersection(lineRect,intersectionRect);
				var lineClippedWidth = CGRectGetWidth([textView bounds]) - lineIntersectionRect.origin.x;
				
				if (lineIntersectionRect.size.width > 0 && lineClippedWidth > clippedIntersectionWidth)
					clippedIntersectionWidth = lineClippedWidth;
			}
			
			maxLineWidth -= clippedIntersectionWidth;
		}

		var newLineWidth = lineWidth + wordSize.width + defaultWordSpacing;

		if (newLineWidth < maxLineWidth)
		{
			var lineLeftMargin = 0;
			[[currentLine valueForKey:@"words"] addObject:word];
			lineWidth = newLineWidth;
			lineSize.width = lineWidth;
			[currentLine setValue:lineSize forKey:@"size"];
			wordIndex++;
			continue;
		}
		
		var removeCache = YES;
		if ([lineArray count]<[existingLineArray count])
		{
			var currentLineIndex = [lineArray count];
			var existingLine = [existingLineArray objectAtIndex:currentLineIndex];
			
			if ([[existingLine valueForKey:@"words"] isEqual:[currentLine valueForKey:@"words"]])
			{
				[currentLine setValue:[existingLine valueForKey:@"uuid"] forKey:@"uuid"];
				removeCache = NO;
			} else
			{
				FPTextBitmapCacheRemoveLine(existingLine);
			}
		}
		
		lineWidth = 0;
		lineY += lineSize.height;
		
		var numberOfCharactersInLine = FPTextGetNumberOfCharactersInLine(currentLine);
		[currentLine setValue:[CPNumber numberWithInt:numberOfCharactersInLine] forKey:@"numberOfCharacters"];
		[lineArray addObject:currentLine];
		currentLine = nil;
		paragraphHeight += lineSize.height;
	}
	
	lineY += lineSize.height;
	[lineArray addObject:currentLine];
	paragraphHeight += lineSize.height * 2;
	
	lineWidth = 0;
	
	var newParagraphSize = CPMakeSize(globalMaxLineWidth,paragraphHeight);
	[paragraph setValue:newParagraphSize forKey:@"size"];
	FPTextBitmapCacheRemoveLines([paragraph valueForKey:@"lines"]);
	
	var emptyLine = FPTextCreateLine();
	emptyLine.size = CPMakeSize(0,wordSize.height);
	[lineArray addObject:emptyLine];
	
	[paragraph setValue:lineArray forKey:@"lines"];
}

- (void)recalculateLayout
{
	[self recalculateLayoutInFrame:[textView bounds]];
}

- (void)recalculateLayoutInFrame:(CPRect)aFrame
{
	if (!initiatedLayout)
		[self _initiateLayout];
	else
	{
		if ([paragraphs count] > 0) {
			var yOffset = 0.0;
			var paragraphsAffectedByClip = [[CPMutableArray alloc] init];
			var paragraphOrigin = CPMakePoint(0,0);
			
			for (var i = 0; i < [paragraphs count]; i++) {
				var paragraph = [paragraphs objectAtIndex:i];
				var paragraphSize = [paragraph valueForKey:@"size"];
				var paragraphRect = CPMakeRect(paragraphOrigin.x,paragraphOrigin.y,paragraphSize.width,paragraphSize.height);
				
				if (CGRectIntersectsRect(paragraphRect,aFrame))
				{
					for (var a=0;a<[clippedAreas count];a++)
					{
						var clippedBounds = [self clippedBoundsAtIndex:a];
						var intersectionRect = CGRectIntersection(paragraphRect,clippedBounds);
						intersectionRect.origin.y -= paragraphOrigin.y;
						if (intersectionRect.size.width > 0.0) {
							[[paragraph valueForKey:@"intersectionRects"] addObject:intersectionRect];
						
							if (![paragraphsAffectedByClip containsObject:paragraph])
								[paragraphsAffectedByClip addObject:paragraph];
						}
					}
				}
				
				paragraphOrigin.y += paragraphSize.height;
			}
			
			var globalMaxLineWidth = CGRectGetWidth([textView frame]);
			
			for (var i = 0; i < [paragraphs count]; i++) {
				var paragraph = [paragraphs objectAtIndex:i];
				var paragraphIsAffected = [paragraphsAffectedByClip containsObject:paragraph];
				
				if (paragraphIsAffected || [[paragraph valueForKey:@"wrapping"] intValue]>0)
				{
					FPTextBitmapCacheRemoveParagraph([paragraph valueForKey:@"uuid"]);
					[paragraph setValue:Math.uuid() forKey:@"uuid"];
					[paragraph setValue:[CPNumber numberWithInt:paragraphIsAffected?1:0] forKey:@"wrapping"];
					[self _layoutParagraph:paragraph];
					if (paragraphIsAffected) [[paragraph valueForKey:@"intersectionRects"] removeAllObjects];
				}
			}
		}
	}
	
	[textView layoutManager:self didRecalculateLayoutInFrame:aFrame];
}

- (void)recalculateLayoutInRange:(CPRange)range
{
	var startPoint = [self pointAtTextLocation:range.location];
	var endPoint = [self pointAtTextLocation:CPMaxRange(range)];
	
	var paragraphOrigin = CPMakePoint(0,0);

	for (var i = 0; i < [paragraphs count]; i++) {
		var paragraph = [paragraphs objectAtIndex:i];
		var paragraphSize = [paragraph valueForKey:@"size"];
		var paragraphRect = CPMakeRect(paragraphOrigin.x,paragraphOrigin.y,paragraphSize.width,paragraphSize.height);
		
		if (CGRectContainsPoint(paragraphRect,startPoint) || CGRectContainsPoint(paragraphRect,endPoint))
		{
			[self _resetWordsInParagraph:paragraph];
			[self recalculateLayoutInFrame:paragraphRect];
		}
		
		paragraphOrigin.y += paragraphSize.height;
	}
}

// Clipped Areas

- (void)removeAllClippedAreas
{
	[clippedAreas removeAllObjects];
}

- (void)addClippedArea:(CPRect)clippedRect
{
	var clippedValue = [CPValue valueWithJSObject:clippedRect];
	[clippedAreas addObject:clippedValue];
}

- (CPRect)clippedBoundsAtIndex:(int)index
{
	var clippedArea = CPRectCreateCopy([[clippedAreas objectAtIndex:index] JSObject]);
	clippedArea.origin.y -= [textView frame].origin.y;
	clippedArea.origin.x -= [textView frame].origin.x;
	return clippedArea;
}

@end