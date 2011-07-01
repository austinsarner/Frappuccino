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

@import "JTScrollView.j"
@import "JTSourceMediaViewController.j"
@import "JTMediaBrowserView.j"
@import "MediaLibrary.j"

var TOOLBAR_HEIGHT = 39;
var BUTTONBAR_HEIGHT = 36;
var SOURCE_MEDIA_WIDTH = 250;

@implementation JTMediaGalleryEditorViewController : FPViewController
{
	JTButtonBar		buttonBar @accessors;
	JTScrollView	scrollView;
	JTToolbar		toolbar
	JTSourceMediaViewController	sourceMediaViewController @accessors;
}

- (void)loadView
{
	[self.view setBackgroundColor:[CPColor blackColor]];
	var mediaBrowserBackgroundColor = [CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:@"corkboard_pattern.jpg"]];
	
	toolbar = [[JTToolbar alloc] initWithFrame:CPMakeRect(0,0,CGRectGetWidth([self.view bounds])-SOURCE_MEDIA_WIDTH-1,TOOLBAR_HEIGHT)];
	[toolbar setAutoresizingMask:CPViewWidthSizable|CPViewMaxYMargin];
	
	//var toolbarButton = [[JTToolbarButton alloc] initWithFrame:CPMakeRect(7.0,6.0,35.0,28.0)];
	//[toolbar addSubview:toolbarButton];
	
	/*var publishButton = [[JTPublishToolbarButton alloc] initWithFrame:CPMakeRect(CGRectGetMaxX([toolbar bounds])-114,6,107,28)];
	[publishButton setAutoresizingMask:CPViewMinXMargin];
	[toolbar addSubview:publishButton];*/
	
	[self.view addSubview:toolbar];
	
	var scrollViewFrame = CPRectCreateCopy([self.view bounds]);
	scrollViewFrame.origin.y += TOOLBAR_HEIGHT;
	scrollViewFrame.size.height -= TOOLBAR_HEIGHT;
	scrollViewFrame.size.width -= SOURCE_MEDIA_WIDTH + 1;
	scrollView = [[JTScrollView alloc] initWithFrame:scrollViewFrame];
	[scrollView setAutohidesScrollers:YES];
	[scrollView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
	
    mediaBrowserView = [[JTMediaBrowserView alloc] initWithFrame:[scrollView bounds]];
	[mediaBrowserView setBackgroundColor:mediaBrowserBackgroundColor];
	[mediaBrowserView setDataSource:self];
	[mediaBrowserView setDelegate:self];
    [mediaBrowserView setAutoresizingMask:CPViewWidthSizable];
	
	[scrollView setDocumentView:mediaBrowserView];
	[scrollView setBackgroundColor:mediaBrowserBackgroundColor];
	
	[scrollView setDelegate:mediaBrowserView]; // update on scroll
	
    [self.view addSubview:scrollView positioned:CPWindowBelow relativeTo:buttonBar];
	
	sourceMediaViewController = [[JTSourceMediaViewController alloc] initWithViewFrame:CPMakeRect(CGRectGetMaxX([self.view bounds])-SOURCE_MEDIA_WIDTH,0,SOURCE_MEDIA_WIDTH,CGRectGetHeight([self.view bounds]))]
	var sourceMediaView = sourceMediaViewController.view;
	[sourceMediaView setAutoresizingMask:CPViewHeightSizable|CPViewMinXMargin];
	[self.view addSubview:sourceMediaView];
	[sourceMediaViewController resetData];
	
	[mediaBrowserView reloadData];
	[mediaBrowserView setViewSize:CGSizeMake(160.0,160.0)];
}

- (unsigned int)numberOfMediaItems
{	
	return 10;
}

- (CPView)cellForMediaItemAtIndex:(unsigned int)index
{	
	var mediaItem = [[[MediaLibrary sharedMediaLibrary] mediaItems] objectAtIndex:index + 30];

	var mediaCell = [[JTMediaItemCell alloc] initWithRepresentedObject:mediaItem];
	[mediaCell setControlView:mediaBrowserView];
	mediaCell.displayTitle = YES;
	mediaCell.displayLargeBorder = YES;
	mediaCell.uniqueID = [mediaItem uid];
	return mediaCell;
}

@end