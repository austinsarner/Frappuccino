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

@import "JTElement.j"

@implementation JTTextElement : JTElement
{
	FPText	textView;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		self.fixed = YES;
		textView = [[FPText alloc] initWithFrame:[self bounds]];
		[textView setDelegate:self];
		[self addSubview:textView];
	}
	return self;
}

- (BOOL)wraps
{
	return [textView wraps];
}

- (void)setWraps:(BOOL)wraps
{
	[textView setWraps:wraps];
}

- (void)setFont:(CPFont)font
{
	[textView setFont:font];
}

- (void)setLineHeight:(int)lineHeight
{
	[textView setLineHeight:lineHeight];
}

- (void)setString:(CPString)string
{
	[textView setString:string];
}

- (void)setPadding:(int)padding
{
	[super setPadding:padding];
	[textView setFrame:CGRectInset([self bounds],padding,padding)];
}

- (void)display
{
	[textView display];
}

- (void)textFrameChanged:(FPText)text
{
	[[self superview] elementFinishedTransforming:self];
}

- (void)removeAllClippedAreas
{
	[textView removeAllClippedAreas];
}

- (void)addClippedArea:(CPRect)clippedRect
{
	var localClipRect = CPRectCreateCopy(clippedRect);
	localClipRect.origin.x -= [self frame].origin.x;
	localClipRect.origin.y -= [self frame].origin.y;
	[textView addClippedArea:localClipRect];
}

- (void)updateClippedAreas
{
	[[textView textLayoutManager] recalculateLayout];
}

@end