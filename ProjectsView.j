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

@import "Project.j"
@import "JTButtonBar.j"
@import "JTAddButton.j"

var BUTTONBAR_HEIGHT = 29;

@implementation ProjectsView : CPView
{
	CPCollectionView	projectCollectionView @accessors;
	JTButtonBar	buttonBar @accessors;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		//alert("init");
		//var projectsView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, SIDEBAR_WIDTH, CGRectGetHeight([contentView frame]))];
		[self setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];

		var projectScrollFrame = [self bounds];
		projectScrollFrame.size.height -= BUTTONBAR_HEIGHT;
		var projectScrollView = [[CPScrollView alloc] initWithFrame:projectScrollFrame];
	    [projectScrollView setAutohidesScrollers:YES];
	    var projectListItem = [[CPCollectionViewItem alloc] init];
	    [projectListItem setView:[[ProjectCell alloc] initWithFrame:CGRectMakeZero()]];
	    projectCollectionView = [[CPCollectionView alloc] initWithFrame:projectScrollFrame];
	    //[projectCollectionView setDelegate:self];
		[projectCollectionView setSelectable:YES];
		[projectCollectionView setAllowsMultipleSelection:NO];
		[projectCollectionView setAllowsEmptySelection:YES];
	    [projectCollectionView setItemPrototype:projectListItem];
	    [projectCollectionView setMinItemSize:CGSizeMake(20.0, 40.0)];
	    [projectCollectionView setMaxItemSize:CGSizeMake(1000.0, 40.0)];
	    [projectCollectionView setMaxNumberOfColumns:1];
	    [projectCollectionView setVerticalMargin:0.0];
	    [projectCollectionView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
	    [projectScrollView setDocumentView:projectCollectionView];     
		[projectScrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
		[[projectScrollView contentView] setBackgroundColor:[CPColor colorWithHexString:@"4b4d4d"]];

		buttonBar = [[JTButtonBar alloc] initWithFrame:CGRectMake(0,CGRectGetHeight([self bounds])-BUTTONBAR_HEIGHT,frame.size.width,BUTTONBAR_HEIGHT)];
		
		var addButton = [[JTAddButton alloc] initWithFrame:CGRectMake(0,0,34,29)];
		[buttonBar addSubview:addButton];
		[self addSubview:buttonBar];
		
		//CPLog([self superview]);
		//[buttonBar setSplitView:[self superview]];
		
		[self addSubview:projectScrollView];
	}
	return self;
}

@end