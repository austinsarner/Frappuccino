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

@import "JTChooserViewController.j"
@import "JTDocumentEditorViewController.j"
@import "JTMediaGalleryEditorViewController.j"
@import "DocumentLibrary.j"
@import "JTLayoutView.j"
@import "JTAnimatingImageView.j"

var TOOLBAR_HEIGHT = 39;
var BUTTONBAR_HEIGHT = 36;
var MAX_IMAGE_SIZE = 200.0;

@implementation JTDocumentChooserViewController : JTChooserViewController
{
	JTMediaBrowserView*		documentBrowserView	@accessors;
	JTButtonBar				buttonBar @accessors;
	CPMutableArray			documents;
	//JPSegmentedControl	sourceDocumentSortingSegmentedControl;
	//JPTextField			filterTextField;
	//CPTimer				filterDelayTimer;
	CPString				filteredEntity @accessors;
	JTScrollView			scrollView;
	
	JTAnimatingImageView 	animatingImageView;
	BOOL 					animatingImageViewOut;
	
	var 					documentEditorViewController;
}

- (void)loadView
{
	[super loadView];
	
	self.filteredEntity = @"Article";
	
	var contentView = self.view;
	var documentBrowserBackgroundColor = [CPColor colorWithHexString:@"16171a"];
	[contentView setBackgroundColor:documentBrowserBackgroundColor];
	
	[segmentedTabControl setSegmentCount:2];
	[segmentedTabControl setLabel:@"Articles" forSegment:0];
	[segmentedTabControl setWidth:100 forSegment:0];
	[segmentedTabControl setSelectedSegment:0];
	[segmentedTabControl setLabel:@"Galleries" forSegment:1];
	[segmentedTabControl setWidth:104 forSegment:1];
	
	buttonBar = [[JTButtonBar alloc] initWithFrame:CGRectMake(0,CGRectGetHeight([contentView bounds])-BUTTONBAR_HEIGHT,[contentView bounds].size.width,BUTTONBAR_HEIGHT)];
	[buttonBar setBlurColor:documentBrowserBackgroundColor];
	[buttonBar setAutoresizingMask:CPViewMinYMargin|CPViewWidthSizable];
	
	var addButton = [[JTAddButton alloc] initWithFrame:CGRectMake(0,0,40,BUTTONBAR_HEIGHT)];
	[buttonBar addSubview:addButton];
	[contentView addSubview:buttonBar];
	
	var zoomSlider = [[FPSlider alloc] initWithFrame:CGRectMake(CGRectGetMaxX([buttonBar bounds])-150.0,4.0,140.0,28.0)];
	[zoomSlider setMinValue:0.3];
	[zoomSlider setMaxValue:1.0];
	[zoomSlider setFloatValue:0.4];
	[zoomSlider setTarget:self];
	[zoomSlider setAction:@selector(zoomSliderAdjusted:)]
	
	[zoomSlider setAutoresizingMask:CPViewMinXMargin];
	[buttonBar addSubview:zoomSlider];
	
	var documentBrowserFrame = CPRectCreateCopy([contentView bounds]);
	documentBrowserFrame.origin.y += TOOLBAR_HEIGHT;
	documentBrowserFrame.size.height -= TOOLBAR_HEIGHT;
	scrollView = [[JTScrollView alloc] initWithFrame:documentBrowserFrame];
	[scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
	[scrollView setScrollerBottomPadding:BUTTONBAR_HEIGHT];
	[scrollView setAutohidesScrollers:YES];
	
    documentBrowserView = [[JTMediaBrowserView alloc] initWithFrame:[scrollView bounds]];
	[documentBrowserView setBackgroundColor:documentBrowserBackgroundColor];
	[documentBrowserView setDataSource:self];
	[documentBrowserView setDelegate:self];
    [documentBrowserView setAutoresizingMask:CPViewWidthSizable];
	
	[scrollView setDocumentView:documentBrowserView];
	[scrollView setBackgroundColor:documentBrowserBackgroundColor];
	
	[scrollView setDelegate:documentBrowserView]; // update on scroll
	
    [contentView addSubview:scrollView positioned:CPWindowBelow relativeTo:buttonBar];

	[documentBrowserView setViewSize:CGSizeMake(180.0,180.0)];
}

- (void)setShowsButtonBar:(BOOL)showToolbar
{
	[scrollView setScrollerBottomPadding:0];
	[buttonBar setHidden:!showToolbar];
}

- (void)setViewSize:(var)newSize
{
	[documentBrowserView setViewSize:newSize];
}

- (void)sortdocumentItemsWithKey:(CPString)keyPath ascending:(BOOL)ascending
{
	[documentBrowserView sortdocumentItemsWithKey:keyPath ascending:ascending];
}

- (void)setFilterString:(CPString)filterString
{
	[documentBrowserView setFilterString:filterString];
}

- (void)zoomSliderAdjusted:(var)sender
{
	var imageSize = Math.ceil([sender floatValue] * MAX_IMAGE_SIZE);
	
	[documentBrowserView setViewSizeAdjustedBySlider:CGSizeMake(imageSize,imageSize)];
}

- (void)setZoomValue:(var)zoomValue
{
	var imageSize = Math.ceil(zoomValue * MAX_IMAGE_SIZE);
	
	[documentBrowserView setViewSize:CGSizeMake(imageSize,imageSize)];
}

- (void)setDraggingDestinationForOtherDocumentBrowsers:(var)isDestination
{
	[documentBrowserView setDraggingDestinationForOtherDocumentBrowsers:isDestination];
}

- (void)resetData
{
	var documentItems = [self.detailViewController details];
	documents = [[CPMutableDictionary alloc] init];
	for (var i=0;i<[documentItems count];i++)
	{
		var documentItem = [documentItems objectAtIndex:i];
		var entity = [documentItem className];
		if (![documents valueForKey:entity])
			[documents setValue:[CPMutableArray array] forKey:entity];
		[[documents valueForKey:entity] addObject:documentItem];
	}
	
	[documentBrowserView reloadData];
}

- (void)tabChanged:(id)sender
{
	documentEditorViewController = [[JTDocumentEditorViewController alloc] initWithViewFrame:[self.view bounds]];
	[self.view addSubview:documentEditorViewController.view];
	return;
	
	var selectedTabName = [segmentedTabControl labelForSegment:[segmentedTabControl selectedSegment]];
	var entity = @"Article";
	
	if ([selectedTabName isEqualToString:@"Galleries"])
		entity = @"Gallery";
	
	self.filteredEntity = entity;
	[documentBrowserView reloadData];
}

- (CPMutableArray)documentItems
{
	var entity = [self filteredEntity];	
	return [documents valueForKey:entity];
}

// JTMediaBrowserView Delegate

- (unsigned int)numberOfMediaItems
{
	return [[self documentItems] count];
}

/*- (void)mediaBrowserView:(id)mediaBrowserView doubleClickedCell:(id)mediaItemCell
{
	var editorViewController;
	
	if ([[self filteredEntity] isEqualToString:@"Article"])
 		editorViewController = [[JTDocumentEditorViewController alloc] initWithViewFrame:[self.view bounds]];
	else if ([[self filteredEntity] isEqualToString:@"Gallery"])
		editorViewController = [[JTMediaGalleryEditorViewController alloc] initWithViewFrame:[self.view bounds]];
	
	[self.detailViewController setContentViewController:editorViewController];
}*/

- (void)mediaBrowserView:(JTMediaBrowserView)mediaBrowserView doubleClickedCell:(JTMediaItemCell)mediaItemCell
{
	if ([[self filteredEntity] isEqualToString:@"Article"])
	{
		//var DocumentItem = [self DocumentItemWithUUID:[mediaItemCell uuid]];
		var documentItem = [[DocumentLibrary sharedDocumentLibrary] documentItemWithID:[mediaItemCell uniqueID]];
		//CPLog([DocumentItem markup]);
		var xmlDocument = [FPXMLDocument documentWithContentsOfURL:[DocumentItem documentURL]];
		//CPLog([DocumentItem markup].document);
		//var markupDictionary = [CPDictionary dictionaryWithXMLString:[DocumentItem markup]];
		
		//CPLog(@"Document markup:\n %@",[markupDictionary description]);
		
		animatingImageView = [[JTAnimatingImageView alloc] initWithFrame:[self.view frame]];
		[animatingImageView setImage:[mediaItemCell image]];
		[animatingImageView setDelegate:self];
		[animatingImageView setImageScaling:FPScaleToFit];
		[animatingImageView setDimmingEnabled:YES];
		[animatingImageView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];

		var cellImageFrame = [mediaItemCell imageRectWithFrameOffset];
		var layoutWidth = 700.0;
		var destinationAnimatingImageViewFrame = CGRectMake(([animatingImageView frame].size.width - 250.0) / 2.0 - (layoutWidth / 2.0),59.0,layoutWidth,cellImageFrame.size.height * (layoutWidth / cellImageFrame.size.width + 0.045));
		var initialAnimatingImageViewFrame = [self.view convertRect:cellImageFrame fromView:mediaBrowserView];

		animatingImageViewOut = NO;
	
		[animatingImageView setStartingImageFrame:initialAnimatingImageViewFrame];
		[animatingImageView setDestinationImageFrame:destinationAnimatingImageViewFrame];
		[self.view addSubview:animatingImageView];// positioned:CPWindowBelow relativeTo:buttonBar];

		[animatingImageView animateImage];
	} else if ([[self filteredEntity] isEqualToString:@"Gallery"])
		[self.detailViewController setContentViewController:[[JTMediaGalleryEditorViewController alloc] initWithViewFrame:[self.view bounds]]];
}

- (void)finishedAnimatingImageView:(var)imageView
{
	if (imageView == animatingImageView) {
		
		window.setTimeout(function() {
			documentEditorViewController = [[JTDocumentEditorViewController alloc] initWithViewFrame:[self.view bounds]];
			[self.view addSubview:documentEditorViewController.view positioned:CPWindowBelow relativeTo:animatingImageView];
			var fadeAnimation = [[FPAnimation alloc] initWithDuration:0.55 animationCurve:FPAnimationEaseInOut];
			[fadeAnimation setDelegate:self];
			[fadeAnimation startAnimation];
		}, 0.5 )
	}
}

- (void)animationFired:(FPAnimation)animation
{
	var currentValue = 1.0 - [animation currentValue];
	[animatingImageView setOverallAlpha:currentValue];
}

- (void)animationFinished:(FPAnimation)animation
{
	[animatingImageView removeFromSuperview];
	[documentEditorViewController.view removeFromSuperview];
	[self.detailViewController setContentViewController:documentEditorViewController];
}

- (CPView)cellForMediaItemAtIndex:(unsigned int)index
{
	var documentItem = [[self documentItems] objectAtIndex:index];
	var documentCell = [[JTMediaItemCell alloc] initWithRepresentedObject:documentItem];
	[documentCell setControlView:documentBrowserView];
	
	if ([[self filteredEntity] isEqualToString:@"Gallery"]) {
		[documentCell setDisplayBorder:NO];
	}
	
	documentCell.displayTitle = YES;
	documentCell.uniqueID = [documentItem recordValueForKey:@"id"];
	return documentCell;
}

- (BOOL)mediaItemReorderedFromIndexes:(CPIndexSet)dragIndexSet toIndex:(unsigned int)dropIndex
{
	var documentItemsToMove = [[CPMutableArray alloc] init];
	var currentIndex = [dragIndexSet firstIndex];
	var adjustedDropIndex = dropIndex;
	
	while (currentIndex != CPNotFound) {
	
		if (currentIndex < dropIndex)
			adjustedDropIndex--;
		 	
		[documentItemsToMove addObject:[[[self documentItems] objectAtIndex:currentIndex] copy]];
		currentIndex = [dragIndexSet indexGreaterThanIndex:currentIndex]; 
	}
	
	[[self documentItems] removeObjectsAtIndexes:dragIndexSet];
	
	for (var i = 0; i < [documentItemsToMove count]; i++)
		[[self documentItems] insertObject:[documentItemsToMove objectAtIndex:i] atIndex:adjustedDropIndex + i];
			
	return YES;
}

- (BOOL)mediaBrowserShouldDeleteItemsAtIndexes:(CPIndexSet)indexes
{
	[[self documentItems] removeObjectsAtIndexes:indexes];
	
	return NO;
}

- (BOOL)mediaBrowserShouldAdddocumentItems:(CPArray)addeddocumentItems atIndex:(unsigned int)index
{
	for (var i = 0; i < [addeddocumentItems count]; i++)
		[[self documentItems] insertObject:[addeddocumentItems objectAtIndex:i]  atIndex:index + i];
	
	return NO;
}



// Document Actions

/*- (void)controlTextDidChange:(CPNotification)notification
{
	if ([notification object] == filterTextField) {

		return;
		
		// And then there is a slight delay so that it doesn't refresh when typing fast
		if (filterDelayTimer != nil && [filterDelayTimer isValid])
			[filterDelayTimer invalidate];
			
		var filterString = [filterTextField stringValue];
		
		// In IKImageBrowser Apple sends the update imDocumenttely if the user supplies an empty filter string
		if ([filterString isEqualToString:@""]) {
			[self setFilterString:filterString];
			return;
		}
			
		filterDelayTimer = [CPTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(filterStringAdjustedAndDelayPassed:) userInfo:filterString repeats:NO];
	}
}*/

/*- (void)filterStringAdjustedAndDelayPassed:(var)timer
{
	[self setFilterString:[timer userInfo]];
}

- (void)toggledSourceDocumentSorting:(var)sender
{
	if ([sender selectedSegment] == 0)
		[self sortdocumentItemsWithKey:@"title" ascending:NO];
	else
		[self sortdocumentItemsWithKey:@"title" ascending:YES];
}*/

@end