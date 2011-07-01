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

@implementation MDSplitView : CPSplitView
{
	CPString	autosaveName @accessors;
	CPColor		dividerColor @accessors;
}

- (id)initWithFrame:(CPRect)aRect
{
	if (self = [super initWithFrame:aRect])
	{
		dividerColor = [CPColor colorWithHexString:@"2d2e2e"];
	}
	return self;
}

- (void)setPosition:(float)position ofDividerAtIndex:(int)dividerIndex
{
	[super setPosition:position ofDividerAtIndex:dividerIndex];
	[self autosavePosition:position ofDividerAtIndex:dividerIndex];
}

- (void)drawDividerInRect:(CGRect)aRect
{
	[super drawDividerInRect:aRect];
	_DOMDividerElements[_drawingDivider].style.backgroundColor = [dividerColor cssString];
}

// Autosaving

- (void)autosavePosition:(float)position ofDividerAtIndex:(int)dividerIndex
{
	//CPLog(@"save");
	var dividerString = [CPString stringWithFormat:@"_div%d",dividerIndex];
	var autosaveCookie = [[CPCookie alloc] initWithName:[self.autosaveName stringByAppendingString:dividerString]];
	[autosaveCookie setValue:[CPString stringWithFormat:@"%d",position] expires:[CPDate dateWithTimeIntervalSinceNow:3600] domain:@"localhost"];
}

- (void)addSubview:(CPView)view
{
	[super addSubview:view];
	[self loadAutosavedPositions];
}

- (void)loadAutosavedPositions
{
	/*CPLog(@"load");
	var i;
	for (i=0;i<[[self subviews] count];i++)
	{
		var dividerString = [CPString stringWithFormat:@"_div%d",i];
		var autosaveCookie = [[CPCookie alloc] initWithName:[self.autosaveName stringByAppendingString:dividerString]];
		CPLog([autosaveCookie value]);
		if ([autosaveCookie value] && ![[loginCookie value] isEqualToString:@""])
		{
			[super setPosition:[[autosaveCookie value] intValue] forDividerAtIndex:i];
		}
	}*/
}

@end