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

@import "JTToolbarCells.j"

var TOOLBAR_HEIGHT = 39;

@implementation JTChooserViewController : FPViewController
{
	id			detailViewController @accessors;
	JTToolbar	toolbar	@accessors;
	FPSegmentedControl	segmentedTabControl @accessors;
}

- (void)loadView
{
	var contentView = self.view;
	
	toolbar = [[JTToolbar alloc] initWithFrame:CPMakeRect(0,0,CGRectGetWidth([contentView bounds]),TOOLBAR_HEIGHT)];
	[toolbar setAutoresizingMask:CPViewWidthSizable|CPViewMaxYMargin];
	
	segmentedTabControl = [[FPSegmentedControl alloc] initWithFrame:CPMakeRect(-2,0,0.0,TOOLBAR_HEIGHT)];
	[segmentedTabControl setTarget:self];
	[segmentedTabControl setAction:@selector(tabChanged:)];
	[segmentedTabControl setCell:[[FPToolbarTabSegmentedCell alloc] init]];
	[toolbar addSubview:segmentedTabControl];
	
	[contentView addSubview:toolbar];
}

- (void)tabChanged:(id)sender
{
	
}

@end