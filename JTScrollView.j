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

@import "MDScroller.j"

@implementation JTScrollView : CPScrollView
{
	int scrollerBottomPadding @accessors;
	id	delegate @accessors;
}

- (id)initWithFrame:(CPRect)aRect
{
	if (self = [super initWithFrame:aRect])
	{
		var scroller = [[MDScroller alloc] initWithFrame:CPMakeRect(0,0,15,aRect.size.height)];
		[scroller setAutoresizingMask:CPViewHeightSizable];
		[self setVerticalScroller:scroller];
	}
	return self;
}

- (void)setScrollerBottomPadding:(int)bottomPadding
{
	scrollerBottomPadding = bottomPadding;
	//[self setVerticalScroller:[[CPScroller alloc] initWithFrame:CPRectMake(0.0, 0.0, [CPScroller scrollerWidth], CPRectGetHeight([self bounds])-bottomPadding)]];
}

/*- (void)setHasVerticalScroller:(BOOL)shouldHaveVerticalScroller
{
	if (_hasVerticalScroller === shouldHaveVerticalScroller)
		return;
	
	_hasVerticalScroller = shouldHaveVerticalScroller;
	
	if (_hasVerticalScroller && !_verticalScroller)
		[self setVerticalScroller:[[CPScroller alloc] initWithFrame:CPRectMake(0.0, 0.0, [CPScroller scrollerWidth], CPRectGetHeight([self bounds])-scrollerBottomPadding)]];
	else if (!_hasVerticalScroller && _verticalScroller)
	{
		[_verticalScroller setHidden:YES];
		[self reflectScrolledClipView:_contentView];
	}
}*/

- (void)reflectScrolledClipView:(CPClipView)aClipView
{
	[super reflectScrolledClipView:aClipView];
	
	var newVerticalScrollerFrame = [_verticalScroller frame];
	newVerticalScrollerFrame.size.height = CGRectGetHeight([self bounds])-scrollerBottomPadding;
	[_verticalScroller setFrame:newVerticalScrollerFrame];
	
	if (delegate) [delegate scrollViewDidScroll:self];
}

- (void)_verticalScrollerDidScroll:(CPScroller)aScroller
{
	[super _verticalScrollerDidScroll:aScroller];
	if (delegate) [delegate scrollViewDidScroll:self];
}

@end