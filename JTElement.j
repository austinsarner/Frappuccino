/* 
 * Copyright (C) 2010 by Austin Sarner and Mark Davis
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

@import "MDElementInspector.j"

/*
	@global
	@group JTElementAlign
*/

JTElementAlignNone = 0;
JTElementAlignLeft = 1;
JTElementAlignRight = 2;

/*
	@global
	@group	JTElementCorner
*/

JTElementTopLeftCorner = 0;
JTElementBottomLeftCorner = 1;
JTElementTopRightCorner = 2;
JTElementBottomRightCorner = 3;

@implementation JTElement : CPView
{
	JTElementAlign		alignment			@accessors;
	int					padding				@accessors;
	BOOL				fixed				@accessors;
	CPPoint				clickLocation		@accessors;
	BOOL				isDragging			@accessors;
	BOOL				isResizing			@accessors;
	BOOL				proportionalScale	@accessors;
	JTElementCorner		resizeCorner		@accessors;
	BOOL				usesInspector		@accessors;
	MDElementInspector	inspectorPanel		@accessors;
	JSObject			grabberRects;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		fixed = NO;
		usesInspector = NO;
		[self resetGrabberRects];
	}
	return self;
}

- (void)resetGrabberRects
{
	grabberRects = new Array();
	grabberRects[JTElementTopLeftCorner] = CPMakeRect(0,0,6,6);
	grabberRects[JTElementBottomLeftCorner] = CPMakeRect(0,CGRectGetMaxY([self bounds])-6,6,6);
	grabberRects[JTElementTopRightCorner] = CPMakeRect(CGRectGetMaxX([self bounds])-6,0,6,6);
	grabberRects[JTElementBottomRightCorner] = CPMakeRect(CGRectGetMaxX([self bounds])-6,CGRectGetMaxY([self bounds])-6,6,6);
}

+ (MDElementInspector)elementInspector
{
	return nil;
}

- (JTLayoutView)layoutView
{
	return [self superview];
}

- (void)setCursor:(JTCursor)cursor
{
	[self valueForKey:@"_DOMElement"].style.cursor = cursor.cursorName;
}

- (void)drawGrabberInRect:(CPRect)rect
{
	[[CPColor colorWithCalibratedWhite:0.2 alpha:1.0] set];
	var grabberPath = [CPBezierPath bezierPath];
	[grabberPath appendBezierPathWithOvalInRect:rect];
	[grabberPath fill];
	
	[[CPColor whiteColor] set];
	var grabberInnerPath = [CPBezierPath bezierPath];
	[grabberInnerPath appendBezierPathWithOvalInRect:CGRectInset(rect,1,1)];
	[grabberInnerPath fill];
}

- (void)drawRect:(CPRect)rect
{
	if ([self isFirstResponder]&&!fixed)
	{
		for (var i=0;i<grabberRects.length;i++)
			[self drawGrabberInRect:grabberRects[i]];
	}
}

- (void)mouseDown:(CPEvent)event
{
	clickLocation = [event locationInWindow];
	if ([event clickCount]==2 && usesInspector)
		[[self layoutView] showInspectorForElement:self];
	else if (!fixed)
	{
		var localPoint = [self convertPoint:clickLocation fromView:nil];
		var resizing = NO;
		for (var i=0;i<grabberRects.length;i++)
		{
			if (CPRectContainsPoint(grabberRects[i],localPoint))
			{
				resizeCorner = i;
				resizing = YES;
			}
		}
		isResizing = resizing;
		isDragging = !resizing;
	}
}

- (void)mouseUp:(CPEvent)event
{
	if (isDragging||isResizing)
	{
		if (isResizing)
			[self elementDidFinishResizing];
		isDragging = NO;
		isResizing = NO;
		[[self layoutView] elementFinishedTransforming:self];
	}
}

- (void)keyDown:(CPEvent)event
{
	if (!fixed)
	{
		var isShiftKey = ([event modifierFlags] & CPShiftKeyMask) != 0;
		var keyCode = [event keyCode];
		var multiplier = isShiftKey?10:1;
		
		if (keyCode == 8)
		{
			[[self layoutView] removeElement:self];
			return;
		}
		
		var newFrame = CPRectCreateCopy([self frame]);
		if (keyCode == CPLeftArrowKeyCode)
			newFrame.origin.x -=multiplier;
		else if (keyCode == CPRightArrowKeyCode)
			newFrame.origin.x +=multiplier;
		else if (keyCode == CPUpArrowKeyCode)
			newFrame.origin.y -=multiplier;
		else if (keyCode == CPDownArrowKeyCode)
			newFrame.origin.y +=multiplier;
		[self setFrame:newFrame];
		[[self layoutView] elementIsTransforming:self];
	}
}

- (void)mouseDragged:(CPEvent)event
{
	if (!fixed)
	{
		var location = [event locationInWindow];
		var newFrame = [self frame];
		var deltaY = location.y - clickLocation.y;
		var deltaX = location.x - clickLocation.x;
		if (isDragging)
		{
			newFrame.origin.y += deltaY;
			newFrame.origin.x += deltaX;
		} else
		{
			if (resizeCorner==JTElementTopRightCorner || resizeCorner==JTElementBottomRightCorner)
				newFrame.size.width += deltaX;
			
			if (resizeCorner==JTElementTopLeftCorner || resizeCorner==JTElementBottomLeftCorner)
			{
				newFrame.origin.x += deltaX;
				newFrame.size.width -= deltaX;
			}
			
			if (resizeCorner==JTElementTopLeftCorner || resizeCorner==JTElementTopRightCorner)
			{
				newFrame.origin.y += deltaY;
				newFrame.size.height -= deltaY;
			}
			
			if (resizeCorner==JTElementBottomLeftCorner || resizeCorner==JTElementBottomRightCorner)
				newFrame.size.height += deltaY;
		}
		clickLocation = CPPointCreateCopy(location);
		[self setFrame:newFrame];
		if (isResizing)
			[self elementIsResizing];
		[[self layoutView] elementIsTransforming:self];
	}
}

- (void)elementIsResizing
{
	[self resetGrabberRects];
}

- (void)elementDidFinishResizing
{
	
}

// First Responder

- (BOOL)isFirstResponder
{
	return ([self window] && [[self window] firstResponder] == self);
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	[self setNeedsDisplay:YES];
	return YES;
}

- (BOOL)resignFirstResponder
{
	if (inspectorPanel)
	{
		[inspectorPanel fadeOut:nil];
		inspectorPanel = nil;
	}
	[self setNeedsDisplay:YES];
	return YES;
}

@end

@implementation JTCursor : CPObject
{
	CPString cursorName @accessors;
}

- (id)initWithCursorName:(CPString)name
{
	if (self=[super init])
	{
		self.cursorName = name;
	}
	return self;
}

+ (JTCursor)defaultCursor
{
	return [[[self alloc] initWithCursorName:@"default"] autorelease];
}

+ (JTCursor)textCursor
{
	return [[[self alloc] initWithCursorName:@"text"] autorelease];
}

@end