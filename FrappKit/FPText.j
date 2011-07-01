/*
 * FPText.j
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

@import "FPStringAddons.j"
@import "FPTextStorage.j"
@import "FPTextBitmapCache.j"
@import "FPTextLayoutManager.j"

/*
	@global
	@group JTSelectionDirection
*/

JTNoSelectionDirection			= 0;
JTBackwardSelectionDirection	= 1;
JTFrontwardSelectionDirection	= 2;

var blinkInterval = 0.6;

@implementation FPText : CPView
{
	id					delegate	@accessors;
	FPTextStorage		textStorage @accessors;
	FPTextLayoutManager textLayoutManager @accessors;
	
	CPColor			textColor	@accessors;
	CPFont			font		@accessors;
	BOOL			multiLine	@accessors;
	int				lineHeight	@accessors;
	//CPMutableArray	lineArray	@accessors;
	CPColor			insertionPointColor	@accessors;
	CPRect			insertionPointRect @accessors;
	CPRange			selectedRange @accessors;
	CPTimer			insertionPointBlinkTimer;
	BOOL			showsInsertionPoint;
	int				selectionDirection;
	CPPoint			startSelectionPoint;
	BOOL			selectable;
	BOOL			editable;
	var				inputElement;
	// 
	BOOL			delegateShouldFilterText @accessors;
	BOOL			delegateShouldInterpretKeyEvents @accessors;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		editable = YES;
		selectable = YES;
		multiLine = YES;
		delegateShouldFilterText = NO;
		
		textColor = [CPColor blackColor];
		
		textStorage = [[FPTextStorage alloc] initWithString:@"" attributes:nil];
		textLayoutManager = [[FPTextLayoutManager alloc] initWithTextView:self];
		
		selectionDirection = JTNoSelectionDirection;
		
		showsInsertionPoint = NO;
		insertionPointColor = [CPColor blackColor];
		
		[self valueForKey:@"_DOMElement"].style.cursor = "text";
		[self setPostsFrameChangedNotifications:YES];
		
		inputElement = document.createElement("input");
		inputElement.style.position = "fixed";
		inputElement.style.bottom = -20;
		inputElement.style.height = 0;
	    inputElement.style.opacity = 0;
		_DOMElement.appendChild(inputElement);
		inputElement.onpaste = function() { window.setTimeout(function(){[self pasteText:inputElement.value]},0.0) };
		
		[self setSelectedRange:CPMakeRange(-1,0)];
	}
	return self;
}

- (void)resetLines
{
	
}

- (void)removeAllClippedAreas
{
	if (textLayoutManager != nil)
		[textLayoutManager removeAllClippedAreas];
}

- (void)addClippedArea:(CPRect)clippedArea
{
	if (textLayoutManager != nil)
		[textLayoutManager addClippedArea:clippedArea];
}

- (void)setWraps:(BOOL)flag
{
	if (textLayoutManager != nil)
		[textLayoutManager setShouldWrapText:flag];
	else if (flag)
		CPLog(@"ERROR: Cannot set wrapping without a layout manager");
}

- (BOOL)wraps
{
	if (textLayoutManager != nil)
		return [textLayoutManager shouldWrapText];
	return NO;
}

- (void)setSelectable:(BOOL)flag
{
	selectable = flag;
	if (flag==NO)
		editable = NO;
	[self setCursor:selectable?[JTCursor textCursor]:[JTCursor defaultCursor]];
	[self setSelectedRange:CPMakeRange(0,0)];
}

- (void)setFont:(CPFont)aFont
{
	font = aFont;
}

- (BOOL)isSelectable
{
	return selectable;
}

- (void)setEditable:(BOOL)flag
{
	editable = flag;
	if (flag==YES)
		selectable = YES;
	[self setCursor:selectable?[JTCursor textCursor]:[JTCursor defaultCursor]];
	[self setSelectedRange:CPMakeRange(0,0)];
}

- (BOOL)isEditable
{
	return editable;
}

- (void)startInsertionPointTimer
{
	if ([insertionPointBlinkTimer isValid]) [insertionPointBlinkTimer invalidate];
	insertionPointBlinkTimer = [CPTimer scheduledTimerWithTimeInterval:blinkInterval target:self selector:@selector(blinkInsertionPoint) userInfo:nil repeats:YES];
}

- (void)setSelectedRange:(CPRange)aRange
{
	if (selectedRange)
		[self setNeedsDisplay:YES];
	
	[insertionPointBlinkTimer invalidate];
	selectedRange = aRange;
	if (selectedRange.length>0)
	{
		inputElement.value = [[self string] substringWithRange:selectedRange];
		[self selectTextElement];
	} else
		inputElement.value = "";
	showsInsertionPoint = YES;
	[self resetInsertionPointRect];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	[self selectTextElement];
	if ([delegate respondsToSelector:@selector(textBecameFirstResponder:)])
		[delegate textBecameFirstResponder:self];
	[self setNeedsDisplay:YES];
	return YES;
}

- (BOOL)resignFirstResponder
{
	[self setSelectedRange:CPMakeRange(-1,0)];
	if ([delegate respondsToSelector:@selector(textResignedFirstResponder:)])
		[delegate textResignedFirstResponder:self];
	return YES;
}

- (void)selectTextElement
{
	window.setTimeout(function()
	{
		inputElement.focus();
		inputElement.select();
	},0.0);
}

- (CPString)filteredString
{
	return [self filteredStringAtLine:[self string]];
}

- (CPString)string
{
	return textStorage.string;
}

- (void)setString:(CPString)aString
{
	textStorage.string = aString;
	if (textLayoutManager != nil)
		[textLayoutManager recalculateLayoutInFrame:[self bounds]];
	//[self setSelectedRange:CPMakeRange(0,0)];
}

- (void)selectAll:(id)sender
{
	[self setSelectedRange:CPMakeRange(0,[[self string] length])];
}

- (void)pasteText:(CPString)text
{
	//alert("paste");
	inputElement.value = "";
	[self insertText:text];
}

- (void)mouseDown:(CPEvent)event
{
	var isShiftKey = ([event modifierFlags] & CPShiftKeyMask) != 0;
	[self selectTextElement];
	
	if (selectable)
	{
		var localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
		if ([event clickCount]==1)
		{
			selectionDirection = JTNoSelectionDirection;
			if (isShiftKey)
			{
				var endLocation = [self textLocationAtPoint:localPoint];
				[self setSelectedRange:CPMakeRange(selectedRange.location,endLocation-selectedRange.location)];
			}
			else
			{
				startSelectionPoint = localPoint;
				[self setSelectedRange:CPMakeRange([self textLocationAtPoint:startSelectionPoint],0)];
			}
		}
		else if ([event clickCount]==2)
		{
			var wordRange = [self rangeOfWordAtPoint:localPoint];
			[self setSelectedRange:wordRange];
		}
		else if ([event clickCount]==3)
			[self setSelectedRange:[self rangeOfParagraphAtPoint:localPoint]];
	}
}

- (void)mouseDragged:(CPEvent)event
{
	if (selectable)
	{
		var startLocation = [self textLocationAtPoint:startSelectionPoint];
		var endSelectionPoint = [self convertPoint:[event locationInWindow] fromView:nil];
		var endLocation = [self textLocationAtPoint:endSelectionPoint];
	
		if (startLocation<endLocation)
			[self setSelectedRange:CPMakeRange(startLocation,endLocation-startLocation)];
		else
			[self setSelectedRange:CPMakeRange(endLocation,startLocation-endLocation)];
	}
}

- (void)mouseUp:(CPEvent)event
{
	if (selectable)
		selectionDirection = JTNoSelectionDirection;
}

- (void)keyDown:(CPEvent)anEvent
{	
	[self interpretKeyEvents:[CPArray arrayWithObject:anEvent]];
}

- (BOOL)shouldInterpretKeyEvents:(CPArray)events
{
	if (delegateShouldInterpretKeyEvents)
		return [delegate text:self shouldInterpretKeyEvents:events];
	return YES;
}

- (void)interpretKeyEvents:(CPArray)events
{
	if ([events count] == 1 && [self shouldInterpretKeyEvents:events])
	{
		var event = [events lastObject];
		var keyCode = [event keyCode];
		var characters = [event charactersIgnoringModifiers];

		var isCommandKey = ([event modifierFlags] & CPCommandKeyMask) != 0;
		var isShiftKey = ([event modifierFlags] & CPShiftKeyMask) != 0;

		if (isCommandKey)
		{
			if ([characters isEqual:@"a"])
				[self selectAll:nil];
		}
		else if (keyCode == CPLeftArrowKeyCode)
		{
			var newLocation = selectedRange.location-1;
			if (newLocation<0)
				newLocation = 0;
			if (isShiftKey)
			{
				if (selectionDirection==JTFrontwardSelectionDirection)
					[self setSelectedRange:CPMakeRange(selectedRange.location,selectedRange.length-1)];
				else
				{
					selectionDirection = JTBackwardSelectionDirection;
					[self setSelectedRange:CPMakeRange(newLocation,selectedRange.length+1)];
				}
			}
			else
			{
				if (selectedRange.length>0)
					newLocation = selectedRange.location;
				[self setSelectedRange:CPMakeRange(newLocation,0)];
			}
		}
		else if (keyCode == CPRightArrowKeyCode)
		{
			var newLocation = selectedRange.location+1;
			if (newLocation>[[self string] length])
				newLocation--;
			if (isShiftKey)
			{
				if (selectionDirection==JTBackwardSelectionDirection)
					[self setSelectedRange:CPMakeRange(newLocation,selectedRange.length-1)];
				else
				{
					selectionDirection = JTFrontwardSelectionDirection;
					var rangeEndLocation = CPMaxRange(selectedRange);
					if (rangeEndLocation < [[self string] length]) rangeEndLocation++;
					var length = rangeEndLocation - selectedRange.location;
					[self setSelectedRange:CPMakeRange(selectedRange.location,length)];
				}
			}
			else
			{
				if (selectedRange.length>0)
					newLocation = CPMaxRange(selectedRange);
				[self setSelectedRange:CPMakeRange(newLocation,0)];
			}
		}
		else if (keyCode == CPUpArrowKeyCode)
		{
			var selectionStartPoint = [self pointAtTextLocation:selectedRange.location];
			var newLocation = [self textLocationAtPoint:CPMakePoint(selectionStartPoint.x,selectionStartPoint.y-lineHeight)];
			var endLocation = CPMaxRange(selectedRange);

			if (isShiftKey)
			{
				if (selectionDirection==JTFrontwardSelectionDirection)
				{
					var selectionEndPoint = [self pointAtTextLocation:endLocation];
					endLocation = [self textLocationAtPoint:CPMakePoint(selectionEndPoint.x,selectionEndPoint.y-lineHeight)];
					[self setSelectedRange:CPMakeRange(selectedRange.location,endLocation-selectedRange.location)];
				}
				else
				{
					selectionDirection = JTBackwardSelectionDirection;
					[self setSelectedRange:CPMakeRange(newLocation,endLocation-newLocation)];
				}
			}
			else
				[self setSelectedRange:CPMakeRange(newLocation,0)];
		}
		else if (keyCode == CPDownArrowKeyCode)
		{
			var selectionEndPoint = [self pointAtTextLocation:CPMaxRange(selectedRange)];
			var newLocation = [self textLocationAtPoint:CPMakePoint(selectionEndPoint.x,selectionEndPoint.y+lineHeight)];

			if (isShiftKey)
			{
				if (selectionDirection==JTBackwardSelectionDirection)
				{
					var selectionStartPoint = [self pointAtTextLocation:selectedRange.location];
					var newStartLocation = [self textLocationAtPoint:CPMakePoint(selectionStartPoint.x,selectionStartPoint.y+lineHeight)];
					[self setSelectedRange:CPMakeRange(newStartLocation,CPMaxRange(selectedRange)-newStartLocation)];
				}
				else
				{
					selectionDirection = JTFrontwardSelectionDirection;
					[self setSelectedRange:CPMakeRange(selectedRange.location,newLocation-selectedRange.location)];
				}
			}
			else
				[self setSelectedRange:CPMakeRange(newLocation,0)];
		}
		else if (keyCode==CPSpaceKeyCode || ![characters isEqualToString:@" "])
		{
			if (keyCode == CPReturnKeyCode)
				[self insertText:@"\n"];
			else if (keyCode!=91 && keyCode!=18 && keyCode!=16 && keyCode!=17)
			{
				if (keyCode==CPDeleteKeyCode)
				{
					if (selectedRange.length>0)
					{
						[self setString:[[self string] stringByReplacingCharactersInRange:selectedRange withString:@""]];
						[self setSelectedRange:CPMakeRange(selectedRange.location,0)];
					}
					else
					{
						[self setString:[[self string] stringByReplacingCharactersInRange:CPMakeRange(selectedRange.location-1,1) withString:@""]];
						[self setSelectedRange:CPMakeRange(selectedRange.location-1,0)];
					}
					if (textLayoutManager != nil)
						[textLayoutManager recalculateLayoutInRange:selectedRange];
					//[self resetLines];
				}
				else
				{
					var appendString = characters;
					if (isShiftKey)
						appendString = [appendString uppercaseString];

					[self insertText:appendString];
				}
			}
		}
		//else
			//[super keyDown:event];

		if (selectedRange.length==0)
			selectionDirection = JTNoSelectionDirection;
	}
}

- (void)insertText:(CPString)text
{
	[self setString:[[self string] stringByReplacingCharactersInRange:selectedRange withString:text]];
	if (textLayoutManager != nil)
		[textLayoutManager recalculateLayoutInRange:selectedRange];
	[self setSelectedRange:CPMakeRange(selectedRange.location+text.length,0)];
}

- (void)blinkInsertionPoint
{
	if (selectedRange.location>=0)
	{
		showsInsertionPoint = !showsInsertionPoint;
		//[self setNeedsDisplay:YES];
		if (insertionPointRect)
			[self setNeedsDisplayInRect:insertionPointRect]
	}
}

// Drawing

- (void)drawSelectedRect
{
	if (selectedRange.length>0)
	{
		/*var startPoint = [self pointAtTextLocation:selectedRange.location];
		var endPoint = [self pointAtTextLocation:CPMaxRange(selectedRange)];
		
		var selectionRectY;
		var selectionRectX = startPoint.x;*/
		
		if (textLayoutManager != nil)
		{
			var currentCharacterIndex = 0;
			var paragraphs = [textLayoutManager paragraphs];
			var paragraphOrigin = CPMakePoint(0,0);
			
			for (var i = 0; i < [paragraphs count]; i++) {
				var paragraph = [paragraphs objectAtIndex:i];
				var paragraphSize = [paragraph valueForKey:@"size"];
				var numberOfCharactersInParagraph = FPTextNumberOfCharactersInParagraph(paragraph);
				var paragraphRect = CPMakeRect(paragraphOrigin.x,paragraphOrigin.y,paragraphSize.width,paragraphSize.height);
				var paragraphRange = CPMakeRange(currentCharacterIndex,numberOfCharactersInParagraph);
				
				if (CPIntersectionRange(paragraphRange,selectedRange).length>0)
				{
					CPLog(@"intersects paragraph");
					var lineOrigin = CPPointCreateCopy(paragraphOrigin);
					var lineCharacterIndex = currentCharacterIndex;
					var lines = [paragraph valueForKey:@"lines"];
					for (var l=0; l<[lines count];l++)
					{
						var line = [lines objectAtIndex:l];
						var lineSize = [line valueForKey:@"size"];
						var lineRect = CPMakeRect(lineOrigin.x,lineOrigin.y,lineSize.width,lineSize.height);
						var numberOfCharactersInLine = FPTextNumberOfCharactersInLine(line);
						var lineRange = CPMakeRange(lineCharacterIndex,numberOfCharactersInLine+2);
						
						if (CPIntersectionRange(lineRange,selectedRange).length>0)
						{
							CPLog(@"intersects line");
							var selectionRect = CPRectCreateCopy(lineRect);
							if (selectedRange.location >= lineRange.location && selectedRange.location <= CPMaxRange(lineRange))
							{
								var startPoint = [self pointAtTextLocation:selectedRange.location+1];
								//startPoint.y += lineRect.size.height / 2;
								var xOffset = startPoint.x;
								selectionRect.origin.x += xOffset;
								selectionRect.size.width -= xOffset;
							}
							if (CPMaxRange(selectedRange) >= lineRange.location && CPMaxRange(selectedRange) <= CPMaxRange(lineRange))
							{
								var endPoint = [self pointAtTextLocation:CPMaxRange(selectedRange)+2];
								selectionRect.size.width -= (lineRect.size.width-selectionRect.origin.x) - endPoint.x;
							}
							
							[[CPColor colorWithHexString:@"b5d5ff"] set];
							[[CPBezierPath bezierPathWithRect:selectionRect] fill];
						}
						lineCharacterIndex+=numberOfCharactersInLine;
						lineOrigin.y += lineSize.height;
					}
				}
				
				
				currentCharacterIndex+=numberOfCharactersInParagraph;
				paragraphOrigin.y += paragraphSize.height;
			}
			
		}
		//while (selectionRectY < )
/*		for (var selectionRectY=startPoint.y; selectionRectY<=endPoint.y; selectionRectY+=lineHeight)
		{
			var selectionRectMaxX = endPoint.x;
			
			if (selectionRectY!=startPoint.y)
				selectionRectX = 0;
			
			var height = lineHeight;//-2;
			if (selectionRectY!=endPoint.y)
			{
				var lineNumber = selectionRectY/lineHeight;
				selectionRectMaxX = CGRectGetMaxX([self bounds]);//[self pointAtTextLocation:endOfLineLocation].x;
			}
			
			var width = selectionRectMaxX - selectionRectX;
			var selectedRect = [CPBezierPath bezierPathWithRect:CPMakeRect(selectionRectX,selectionRectY,width,height)];
			[[CPColor colorWithHexString:@"b5d5ff"] set];
			[selectedRect fill];
		}*/
	}
}

- (int)locationAtEndOfLine:(int)lineNumber
{
	var location = 0;
	
	//for (var i=0;i<=lineNumber;i++)
		//location+=[lineArray objectAtIndex:i].rect.size.width;
	
	return location-1;
}

- (CPString)filteredStringAtLine:(int)line
{
	//var lineString = [lineArray objectAtIndex:line].string;
	//if (delegateShouldFilterText)
		//lineString = [delegate text:self filteredString:lineString];
	return @"";//lineString;
}

- (void)drawInsertionPoint:(BOOL)flag
{
	if (flag && insertionPointRect)
	{
		[insertionPointColor set];
		[[CPBezierPath bezierPathWithRect:insertionPointRect] fill];
	}
}

- (void)drawRect:(CPRect)aRect
{
	if (textLayoutManager != nil)
	{
		var ctx = [[CPGraphicsContext currentContext] graphicsPort];
		
		var useCache = selectedRange.length < 1;
		[self drawSelectedRect];
		
		[textColor set];
		
		var paragraphOrigin = CPMakePoint(0,0);
		var paragraphs = [textLayoutManager paragraphs];
		var currentCharacterIndex = 0;
		
		for (var p=0;p<[paragraphs count];p++)
		{
			var paragraph = [paragraphs objectAtIndex:p];
			
			var drawParagraphUsingCache = useCache;
			if (!useCache)
			{
				var numberOfCharactersInParagraph = FPTextNumberOfCharactersInParagraph(paragraph);
				var paragraphRange = CPMakeRange(currentCharacterIndex,numberOfCharactersInParagraph);
				currentCharacterIndex+=numberOfCharactersInParagraph;
				
				if (CPIntersectionRange(paragraphRange,selectedRange).length<1)
					drawParagraphUsingCache = YES;
			}
			
			var paragraphSize = [FPTextBitmapCache drawParagraph:paragraph withFont:font atPoint:paragraphOrigin usingCache:drawParagraphUsingCache];
			paragraphOrigin.y += paragraphSize.height;
		}
		
		if (insertionPointRect && CGRectIntersectsRect(insertionPointRect,aRect))
			[self drawInsertionPoint:showsInsertionPoint];
	}
	[super drawRect:aRect];
}

// Auto Resizing

- (void)frameChanged
{
	if (textLayoutManager != nil)
		[textLayoutManager recalculateLayout];
	[self resetInsertionPointRect];
}

// Reset Drawing Variables

- (void)resetInsertionPointRect
{
	if (selectedRange.location>=0 && selectedRange.length==0 && editable)
	{
		var point = [self pointAtTextLocation:selectedRange.location];
		if (insertionPointRect) [self setNeedsDisplayInRect:insertionPointRect];
		insertionPointRect = CPMakeRect(point.x,point.y+1,1,lineHeight);
		[self startInsertionPointTimer];
		[self setNeedsDisplayInRect:insertionPointRect];
	}
	else
	{
		if (insertionPointRect) [self setNeedsDisplayInRect:insertionPointRect];
		insertionPointRect = nil;
		if ([insertionPointBlinkTimer isValid]) [insertionPointBlinkTimer invalidate];
		[self setNeedsDisplayInRect:[self selectedRangeBounds]];
	}
}

- (CPRect)selectedRangeBounds
{
	var startPoint = [self pointAtTextLocation:selectedRange.location];
	var endPoint = [self pointAtTextLocation:CPMaxRange(selectedRange)];
	//&para;
	var selectionRect = CPMakeRect(startPoint.x,startPoint.y,endPoint.x-startPoint.x,endPoint.y-startPoint.y);
	if (selectionRect.size.width<0)
		selectionRect.origin.x += selectionRect.size.width;
	if (selectionRect.size.height<0)
		selectionRect.origin.y += selectionRect.size.height;
	
	return selectionRect;
}

- (CPString)lineStringAtIndex:(int)lineIndex
{
	return @"";//[lineArray objectAtIndex:lineIndex].string;
}

// Point to location conversion

- (int)textLocationAtPoint:(CPPoint)point
{
	if (textLayoutManager != nil)
		return [textLayoutManager textLocationAtPoint:point];
	return 0;
}

- (CPPoint)pointAtTextLocation:(int)characterIndex
{
	if (textLayoutManager != nil)
		return [textLayoutManager pointAtTextLocation:characterIndex];
	return CGPointMakeZero();
}

- (CPRange)rangeOfWordAtPoint:(CPPoint)localPoint
{
	if (textLayoutManager != nil)
		return [textLayoutManager rangeOfWordAtPoint:localPoint];
	return CPMakeRange(0,0);
}

- (CPRange)rangeOfParagraphAtPoint:(CPPoint)localPoint
{
	if (textLayoutManager != nil)
		return [textLayoutManager rangeOfParagraphAtPoint:localPoint];
	return CPMakeRange(0,0);
}

// FPTextLayoutManagerDelegate

- (void)layoutManager:(FPTextLayoutManager)aTextLayoutManager didRecalculateLayoutInFrame:(CPRect)aFrame
{
	[self setNeedsDisplay:YES];
}

@end