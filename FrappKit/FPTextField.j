/*
 * FPTextField.j
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

@implementation FPTextField : CPView
{
	BOOL bordered @accessors;
	BOOL bezeled @accessors;
	CPString placeholderString @accessors;
	CPString stringValue @accessors;
	FPText textView @accessors;
	CPFont font @accessors;
	//BOOL _showPlaceholder;
	BOOL _isFirstResponder;
	id target @accessors;
	SEL action @accessors;
	CPView nextKeyView @accessors;
	id	delegate @accessors;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		var textViewFrame = CGRectInset([self bounds],8,6);
		textViewFrame.origin.y ++;
		textViewFrame.size.height += 4;
		textView = [[FPText alloc] initWithFrame:textViewFrame];
		[textView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
		//[textView setWraps:NO];
		[textView setDelegate:self];
		[textView setLineHeight:14];
		[textView setMultiLine:NO];
		[textView setDelegateShouldInterpretKeyEvents:YES];
		[self setFont:[CPFont systemFontOfSize:13]];
		[self addSubview:textView];
		
		//[self valueForKey:@"_DOMElement"].style.cursor = "text";
	}
	return self;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	[[self window] makeFirstResponder:textView];
	return NO;
}

- (BOOL)resignFirstResponder
{
	[self textResignedFirstResponder:textView];
	return YES;
}

- (void)textBecameFirstResponder:(FPText)text
{
	CPLog(@"text view became first responder");
	_isFirstResponder = YES;
	[textView setHidden:NO];
	[textView setSelectedRange:CPMakeRange([[textView string] length],0)];
	[self setNeedsDisplay:YES];
}

- (void)textResignedFirstResponder:(FPText)text
{
	_isFirstResponder = NO;
	[textView setHidden:YES];
	[self setNeedsDisplay:YES];
}

- (void)textFrameChanged:(FPText)text
{
	
}

- (void)text:(FPText)text shouldInterpretKeyEvents:(CPArray)events
{
	if ([events count]==1)
	{
		var event = [events lastObject];
		var keyCode = [event keyCode];
		//CPLog(@"%d",keyCode);
		//var characters = [event charactersIgnoringModifiers];
		if (keyCode == 9)
		{
			[[self window] makeFirstResponder:nextKeyView];
			return NO;
		} else if (keyCode == 13)
			[target performSelector:action withObject:self];
	}
	return YES;
}

- (void)mouseDown:(CPEvent)mouseEvent
{
	//CPLog(@"make first responder!");
	
	[textView setHidden:NO];
	[[self window] makeFirstResponder:textView];
	[self setNeedsDisplay:YES];
}

- (void)keyDown:(CPEvent)mouseEvent
{
	CPLog(@"key down");
}

- (void)setFont:(CPFont)aFont
{
	font = aFont;
	[textView setFont:aFont];
}

+ (id)textFieldWithStringValue:(CPString)stringVal placeholder:(CPString)placeholderVal width:(int)width
{
	var textField = [[self alloc] initWithFrame:CPMakeRect(0,0,width,29)];
	[textField setStringValue:stringVal];
	[textField setPlaceholderString:placeholderVal];
	return textField;
}

- (void)setStringValue:(CPString)stringVal
{
	stringValue = stringVal;
	[textView setString:stringVal];
	[self setNeedsDisplay:YES];
}

- (CPString)stringValue
{
	return [textView string];
}

- (void)setPlaceholderString:(CPString)placeholderVal
{
	placeholderString = placeholderVal;
	if ([stringValue length]==0)
	{
		[textView setHidden:YES];
		[self setNeedsDisplay:YES];
	}
}

- (void)drawBezel
{
	if (_isFirstResponder)
	{
		CPLog(@"we're first");
		var focusColor = [CPColor colorWithHexString:@"6baae0"];
		for (var i=0;i<4;i++)
		{
			var focusRect = CGRectInset([self bounds],i,i);
			
			[[focusColor colorWithAlphaComponent:0.1+0.3*i] set];
			var focusPath = [CPBezierPath bezierPath];
			[focusPath appendBezierPathWithRoundedRect:focusRect xRadius:3 yRadius:3];
			[focusPath fill];
		}
	}
	
	var outerRect = CGRectInset([self bounds],3,3);
	[[CPColor whiteColor] set];
	[[CPBezierPath bezierPathWithRect:outerRect] fill];
	
	var lineRect = CPRectCreateCopy(outerRect);
	lineRect.origin.y = CGRectGetMaxY(lineRect)-1;
	lineRect.size.height = 1;
	
	[[CPColor colorWithCalibratedWhite:0.9 alpha:1.0] set];
	[[CPBezierPath bezierPathWithRect:lineRect] fill];
	
	lineRect = CPRectCreateCopy(outerRect);
	lineRect.size.width = 1;
	[[CPColor colorWithCalibratedWhite:0.3 alpha:0.3] set];
	[[CPBezierPath bezierPathWithRect:lineRect] fill];
	
	lineRect.origin.x = CGRectGetMaxX(outerRect)-1;
	[[CPBezierPath bezierPathWithRect:lineRect] fill];
	
	lineRect = CPRectCreateCopy(outerRect);
	lineRect.size.height = 1;
	[[CPColor colorWithCalibratedWhite:0.0 alpha:0.4] set];
	[[CPBezierPath bezierPathWithRect:lineRect] fill];
	
	lineRect.origin.y++;
	[[CPColor colorWithCalibratedWhite:0.5 alpha:0.4] set];
	[[CPBezierPath bezierPathWithRect:lineRect] fill];
}

- (void)drawRect:(CPRect)aRect
{
	[self drawBezel];
	
	var showPlaceholder = ([[self stringValue] length]==0 && !_isFirstResponder);
	
	[[CPColor colorWithCalibratedWhite:showPlaceholder?0.75:0.0 alpha:1.0] set];
	
	var textPoint = [textView frame].origin;
	textPoint.y += 2;
	
	[showPlaceholder?placeholderString:[self stringValue] drawAtPoint:textPoint withFont:font];
}

@end

@implementation FPSecureTextField : FPTextField
{
	
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
		[self.textView setDelegateShouldFilterText:YES];
	return self;
}

- (void)text:(FPText)text filteredString:(CPString)string
{
	var passwordString = [self passwordString:[string substringWithRange:CPMakeRange(0,[string length]-1)]];
	passwordString = [passwordString stringByAppendingString:@" "];
	return passwordString;
}

- (void)drawRect:(CPRect)aRect
{
	[self drawBezel];
	
	var showPlaceholder = ([[self stringValue] length]==0 && !_isFirstResponder);
	
	[[CPColor colorWithCalibratedWhite:showPlaceholder?0.75:0.0 alpha:1.0] set];
	
	var textPoint = [textView frame].origin;
	textPoint.y += 12;
	
	var passwordString = [self passwordString:[self stringValue]];
	[showPlaceholder?placeholderString:passwordString drawAtPoint:textPoint withFont:font];
}

- (CPString)passwordString:(CPString)string
{
	var passwordString = @"";
	for (var i=0;i<[string length];i++)
		passwordString = [passwordString stringByAppendingString:@"•"];
	return passwordString;
}

@end