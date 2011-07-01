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

@import "JTMediaItemInspectorPanel.j"
@import "JTMediaItemDraggingView.j"

var ANIMATED_LAYOUT_DURATION = 0.4;

@implementation CPObject (JTMediaBrowserViewDataSource)

- (unsigned int)numberOfMediaItems {}
- (JTMediaItemCell)cellForMediaItemAtIndex:(unsigned int)index {}
- (BOOL)mediaItemReorderedFromIndexes:(CPIndexSet)indexSet toIndex:(unsigned int)index {}
- (BOOL)mediaBrowserShouldAddMediaItems:(CPArray)addedMediaItems atIndex:(unsigned int)index {}
- (BOOL)mediaBrowserShouldDeleteItemsAtIndexes:(CPIndexSet)indexes {}

@end

@implementation CPObject (JTMediaBrowserViewDelegate)

- (void)mediaBrowserView:(JTMediaBrowserView)mediaBrowserView doubleClickedCell:(JTMediaItemCell)mediaItemCell {}
- (void)mediaBrowserViewDidChangeSelection:(JTMediaBrowserView)mediaBrowserView {}

@end

@implementation JTMediaBrowserView : FPView
{
	var dataSource @accessors;
	var delegate @accessors;
	
	var mediaItemCells @accessors;
	var mediaItemCellsBeingRemoved;
	var viewSize;
	var reordering;
	var numberOfItemsPerRow;
	var numberOfRows;
	var dropIndex;
	var addingItem;
	var rowSpacing;
	var spacing;
	var centerOffset;
	var draggingDestinationForOtherMediaBrowsers @accessors;
	
	// Optimize animation
	var indexesOfAnimatingItemsThatNeedDisplay;
	
	var previousSizeOfAddedItems;
	var animatingAddedItems;
	var animatingAddedItemIndexes;
	
	var animatingReorderedItems;
	var animatingReorderedItemIndexes;
	
	// Filter query
	var contentFiltered;
	var animatingForFilterQuery;
	
	// For when the animation gets interrupted as you type your query
	var animatingItemsToFinishFadingOut;
	var animatingItemsToFinishFadingIn;
	var needToFinishFadingMediaItemViews;
	
	var dragIndicatorTextField;
	var showingDragIndicatorTextField;
	
	var performingDragSelection;
	var dragSelectionStartPoint;
	var dragSelectionEndPoint;
	var dragSelectionRect;
	
	JTMediaItemInspectorPanel mediaItemInspectorPanel;
	
	// Drag and drop
	var validClickForDraggingMediaItem;
	var dragIndexSet;
	var dragInitiated;
	var indexOfItemThatInitiatedDrag;
	var dragClickOffset @accessors;
	
	// Removal
	var removingIndexSet;
	var removingMediaItems;

	// Animated layout
	FPAnimation layoutAnimation @accessors;
	var animatingItems;
	var startingXOrigins;
	var startingYOrigins;
	var destinationXOrigins;
	var destinationYOrigins;
	
	// Zooming
	var zoomingWithoutRedrawingItemsYet;
	var zoomingTimer;
	
	// Keyboard nav
	var startingScrollY;
	var endingScrollY;
	var allowingAnimatedScrollForKeyboardNavigation;
	var allowingAnimatedScrollForKeyboardNavigationTimer;
	
	FPAnimation scrollAnimation;
		
	var previousWidth;
	var previousScrollerVisible;
	
	JPCell hoveredCell;
}

- (void)setDraggingDestinationForOtherMediaBrowsers:(var)isDraggingDestination
{
	draggingDestinationForOtherMediaBrowsers = isDraggingDestination;
	[self setShowsDragIndicatorTextField:YES];
}

- (void)setShowsDragIndicatorTextField:(var)shouldShowIndicatorTextField
{
	if (!draggingDestinationForOtherMediaBrowsers)
		return;
	
	if (shouldShowIndicatorTextField) {
		
		if (dragIndicatorTextField == nil) {
			
			dragIndicatorTextField = [CPTextField labelWithTitle:@"Drag media here to build a gallery or slideshow."];
			[dragIndicatorTextField setFont:[CPFont boldSystemFontOfSize:18]];
			[dragIndicatorTextField setTextColor:[CPColor colorWithCalibratedWhite:0.3 alpha:1.0]];
			[dragIndicatorTextField setValue:CPCenterTextAlignment forThemeAttribute:@"alignment"];
			[dragIndicatorTextField setFrame:CPMakeRect(0,CPRectGetMidY([self bounds])-15,CPRectGetWidth([self bounds]),30)];
			[dragIndicatorTextField setAutoresizingMask:CPViewWidthSizable|CPViewMinYMargin|CPViewMaxYMargin];
		}
		
		[dragIndicatorTextField setCenter:[self center]];
		[self addSubview:dragIndicatorTextField];
	} else if (!shouldShowIndicatorTextField && dragIndicatorTextField != nil && [dragIndicatorTextField superview] == self)
		[dragIndicatorTextField removeFromSuperview];
		
	showingDragIndicatorTextField = shouldShowIndicatorTextField;
}

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		[self setShouldTrackMouseMoved:YES];
		
		allowingAnimatedScrollForKeyboardNavigation = YES;
		zoomingTimer = nil;
		zoomingWithoutRedrawingItemsYet = NO;
		
		previousScrollerVisible = NO;
		indexOfItemThatInitiatedDrag = -1;
		dragInitiated = NO;
		validClickForDraggingMediaItem = NO;
		previousWidth = 0.0;
		animatingForFilterQuery = NO;
		needToFinishFadingMediaItemViews = NO;
		contentFiltered = NO;
		animatingReorderedItems = NO;
		animatingAddedItems = NO;
		spacing = 16.0;
		rowSpacing = 2.0;
		showingDragIndicatorTextField = NO;
		removingMediaItems = NO;
		mediaItemInspectorPanel = [[JTMediaItemInspectorPanel alloc] initWithContentRect:CPMakeRect(0,0,140,120)];
		
		addingItem = NO;
		animatingItems = NO;
		performingDragSelection = NO;
		mediaItemCells = [[CPMutableArray alloc] init];
		[self setPostsFrameChangedNotifications:YES];
		[self registerForDraggedTypes:[CPArray arrayWithObject:@"JOURNALIST_MEDIA_ITEM_PBOARD_TYPE"]];
		viewSize = CGSizeMake(100.0,100.0);

		[[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged) name:@"CPViewFrameDidChangeNotification" object:[self enclosingScrollView]];
	}
	
	return self;
}

- (void)setViewSizeAdjustedBySlider:(var)newSize
{	
	if (CGSizeEqualToSize(viewSize,newSize))
	 	return;
	
	if (zoomingTimer != nil) 
		[zoomingTimer invalidate];
	
	zoomingTimer = [CPTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(viewSizeAdjustedBySliderDelayTimerFired:) userInfo:nil repeats:NO];
	
	zoomingWithoutRedrawingItemsYet = YES;
	viewSize = newSize;
	[self layout:NO];
}

- (void)viewSizeAdjustedBySliderDelayTimerFired:(var)timer
{
	[zoomingTimer invalidate];
	
	zoomingWithoutRedrawingItemsYet = NO;
	[self layout:NO];
}

- (void)setViewSize:(var)newSize
{
	viewSize = newSize;
	[self layout:NO];
}

- (void)showInspectorForMediaItem:(var)mediaItem
{
	var lockPoint = [mediaItem frame].origin;
	lockPoint.x += [mediaItem frame].size.width / 2.0;
	lockPoint.y += [mediaItem frame].size.height;
	
	[mediaItemInspectorPanel setRepresentedMediaItem:mediaItem];
	
	if ([mediaItemInspectorPanel locked] || ![mediaItemInspectorPanel isVisible])
		[mediaItemInspectorPanel lockToPoint:[self convertPoint:lockPoint toView:nil]];
	
	if (![mediaItemInspectorPanel isVisible])
		[mediaItemInspectorPanel fadeIn:nil];
}

- (void)mediaItem:(var)mediaItem changedSelection:(var)isSelected byExtendingSelection:(var)extendingSelection
{
	if (!extendingSelection && isSelected) {
		var selectedIndexes = [self selectedIndexes];
		[selectedIndexes removeIndex:[mediaItemCells indexOfObject:mediaItem]];
		[self deselectMediaItemsAtIndexes:selectedIndexes];
	}
	
	if (isSelected && [mediaItemInspectorPanel isVisible])
		[self showInspectorForMediaItem:mediaItem];
}

- (CPIndexSet)selectedIndexes
{
	var indexSet = [CPIndexSet indexSet];
	
	for (var i = 0; i < [mediaItemCells count]; i++) {
		if ([[mediaItemCells objectAtIndex:i] isSelected])
			[indexSet addIndex:i];
	}
		
	return indexSet;
}

- (void)selectionChanged
{
	if ([[self selectedIndexes] count]==1)
	{
		var mediaItemIndex = [[self selectedIndexes] lastIndex];
		var mediaItemCell = [mediaItemCells objectAtIndex:mediaItemIndex];
	}
	
	if (delegate != nil)
		[delegate mediaBrowserViewDidChangeSelection:self];
}

- (void)deselectMediaItemsAtIndexes:(CPIndexSet)indexSet
{
	var numberOfIndexes = [indexSet count];
	if (numberOfIndexes == 0)
		return;
		
	var currentIndex = [indexSet firstIndex];
	while (currentIndex != CPNotFound) {
		[[mediaItemCells objectAtIndex:currentIndex] setSelected:NO];
		currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
	}
	
	[self selectionChanged];
}

- (void)deselectAllMediaItems
{
	[self deselectMediaItemsAtIndexes:[self selectedIndexes]];
}

/*- (void)fileDroppedWithPath:(CPString)filePath
{
	CPLog(@"dropped file with path: %@",filePath);
}*/

- (void)setDataSource:(CPObject)newDataSource
{	
	dataSource = newDataSource;
}

- (void)reloadData
{	    
	if (dataSource == nil) {
		CPLog(@"JTMediaBrowserView: Data source not specified.");
		return;
	}
		
	if ([mediaItemCells count] > 0)
		[mediaItemCells removeAllObjects]
		
	var numberOfMediaItems = [dataSource numberOfMediaItems];
    CPLog(@"numberOfMediaItems: %d", numberOfMediaItems);

	for (var i = 0; i < numberOfMediaItems; i++) {
		
		var cell = [dataSource cellForMediaItemAtIndex:i];
		[mediaItemCells addObject:cell];
		 	
		var cellFrame = CGRectMake(0,0,viewSize.width,viewSize.height);
		[cell setLayoutFrame:cellFrame];
	}	
			
	[self layout:NO];
	
	[self selectionChanged];
}

- (void)addMediaItemCell:(var)aCell
{
	[aCell setControlView:self];
	
	[mediaItemCells addObject:aCell];
	
	[aCell setLayoutFrame:CGRectMake(0,0,viewSize.width,viewSize.height)];
	[self layout:NO];
	[self selectionChanged];
}

- (void)frameChanged
{
	var currentWidth = [[self enclosingScrollView] frame].size.width;
	var currentScrollerVisible = ![[[self enclosingScrollView] verticalScroller] isHidden];
	
	if ((previousScrollerVisible != currentScrollerVisible) || (previousWidth != currentWidth)) {
		[self layout:NO];
		previousWidth = currentWidth;
		previousScrollerVisible = currentScrollerVisible;
	}
}

- (void)scrollViewDidScroll:(var)scrollView
{
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)dirtyRect
{
	var numberOfMediaItems = [mediaItemCells count];
	
	if (numberOfMediaItems > 0) {
	
		var visibleRect = [self visibleRect];
		
		var startingIndex;
		var endingIndex;
		
		if (numberOfItemsPerRow <= 0) {
			startingIndex = 0;
			endingIndex = [mediaItemCells count] - 1
		} else {
			// Calculate where we actually need to start displaying instead of checking intersection with every cell frame
			startingIndex = (Math.floor((visibleRect.origin.y - rowSpacing) / (rowSpacing + viewSize.height)) * numberOfItemsPerRow);
			if (startingIndex < 0)
				startingIndex = 0;
			
			// ... and precalculate where we'll be ending so we don't have to check rect intersection in the drawing loop
			endingIndex = (Math.ceil(((visibleRect.origin.y + visibleRect.size.height) - rowSpacing) / (rowSpacing + viewSize.height)) * numberOfItemsPerRow)
			if (endingIndex >= numberOfMediaItems)
				endingIndex = numberOfMediaItems - 1;
			else if (endingIndex < 0)
				endingIndex = 0;
		}
			
		if (animatingItems == NO) {
							
			for (var i = startingIndex; i <= endingIndex; i++) {
				
				var mediaItemCell = [mediaItemCells objectAtIndex:i];
				var cellFrame = [mediaItemCell frame];
				
				[mediaItemCell drawWithFrame:cellFrame inView:self];
			}
			
		} else {
						
			for (var i = startingIndex; i <= endingIndex; i++) {

				var mediaItemCell = [mediaItemCells objectAtIndex:i];
				
				if ([indexesOfAnimatingItemsThatNeedDisplay containsIndex:i])
					continue;
				else if (removingMediaItems && [removingIndexSet containsIndex:i]) // We can't use the cached image when removing and item something because it's fading out
					[mediaItemCell drawWithFrame:[mediaItemCell frame] useCachedImageIfAvailable:NO alpha:[mediaItemCell alphaValue]];
				else
				 	[mediaItemCell drawWithFrame:[mediaItemCell frame] inView:self];
			}			
			
			var currentIndex = [indexesOfAnimatingItemsThatNeedDisplay lastIndex];
			
			while (currentIndex != CPNotFound) {
				var mediaItemCell = [mediaItemCells objectAtIndex:currentIndex];
				
				// If this is an item that you're reordering then we want to draw it later and without cache because the cached image has the background and no transparency
				// and we also want to use the cached version of the items that move around to account for the reorder so we have to draw the moved items above to avoid visual issues
				if (!(animatingReorderedItems && [animatingReorderedItemIndexes containsIndex:currentIndex]))					
					[mediaItemCell drawWithFrame:[mediaItemCell frame] useCachedImageIfAvailable:YES alpha:[mediaItemCell alphaValue]];
				
				currentIndex = [indexesOfAnimatingItemsThatNeedDisplay indexLessThanIndex:currentIndex];
			}
			
			// Draw items you've added/reordered on top and without cached image
			if (animatingReorderedItems) {
				currentIndex = [animatingReorderedItemIndexes firstIndex];
				
				while (currentIndex != CPNotFound) {
					var mediaItemCell = [mediaItemCells objectAtIndex:currentIndex];

					[mediaItemCell drawWithFrame:[mediaItemCell frame] useCachedImageIfAvailable:NO alpha:[mediaItemCell alphaValue]];
					currentIndex = [animatingReorderedItemIndexes indexGreaterThanIndex:currentIndex]; 
				}
			}
			
			return;
		}
	}
	
	if (performingDragSelection) {
				
		[[CPColor colorWithCalibratedWhite:1.0 alpha:0.1] set];
		[CPBezierPath fillRect:dragSelectionRect];
		[[CPColor colorWithCalibratedWhite:1.0 alpha:0.7] set];
		[CPBezierPath strokeRect:dragSelectionRect];
	}
	
	if ((addingItem || reordering) && dropIndex != -1 && [mediaItemCells count] >= dropIndex) {
		[[[CPColor whiteColor] colorWithAlphaComponent:0.4] set];
		
		var dropIndicatorFrame;
		
		if ([mediaItemCells count] == 0) {
			dropIndicatorFrame = CGRectInset(CGRectMake(spacing,rowSpacing,viewSize.width,viewSize.height),0.0,20.0);
			
		} else if (dropIndex == [mediaItemCells count]) {
			dropIndicatorFrame = CGRectInset([[mediaItemCells objectAtIndex:dropIndex - 1] frame],0.0,20.0);
			dropIndicatorFrame.origin.x += viewSize.width + spacing + centerOffset;
			
		} else {
			dropIndicatorFrame = CGRectInset([[mediaItemCells objectAtIndex:dropIndex] frame],0.0,20.0);
			
			if (dropIndicatorFrame.origin.x < viewSize.width) // If it's on the left we add the extra spacing
				dropIndicatorFrame.origin.x += Math.ceil((centerOffset / 4.0) + (spacing / 4.0));
		}
	
		dropIndicatorFrame.origin.x = Math.floor(dropIndicatorFrame.origin.x);
		
		var previousHeight = dropIndicatorFrame.size.height;
		dropIndicatorFrame.origin.x -= Math.ceil((spacing + centerOffset) / 2.0);
		dropIndicatorFrame.size.width = 2.0;
		[CPBezierPath fillRect:dropIndicatorFrame];
		
		dropIndicatorFrame.size.width = 4.0;
		dropIndicatorFrame.size.height = 4.0;
		dropIndicatorFrame.origin.y -= 5.0;
		dropIndicatorFrame.origin.x -= 1.0;
		
		var topCirclePath = [CPBezierPath bezierPathWithOvalInRect:dropIndicatorFrame];
		[topCirclePath setLineWidth:2.0];
		[topCirclePath stroke];
		
		dropIndicatorFrame.origin.y += previousHeight + 6.0;
		topCirclePath = [CPBezierPath bezierPathWithOvalInRect:dropIndicatorFrame];
		[topCirclePath setLineWidth:2.0];
		[topCirclePath stroke];
	}
}

- (void)layout:(BOOL)animated
{		
	// There could be 0 views displayed if this is the animated layout call for deleting the last item(s)
	if ([mediaItemCells count] == 0 && !removingMediaItems) { 
		[self setFrame:[[self superview] frame]];
		[self setShowsDragIndicatorTextField:YES];
		
		return;
	} else if (showingDragIndicatorTextField)
		[self setShowsDragIndicatorTextField:NO];
		
	// Allow an animation to be interrupted by another animation so that things pick up where they left off,
	// but ignore a non animated layout call while we're animating
	if (animatingItems) {
		if (animated)
			[self.layoutAnimation stopAnimation];
		else
		 	return;
	}
		
	if (animated) {
		animatingItems = YES;
		indexesOfAnimatingItemsThatNeedDisplay = [CPIndexSet indexSet];
		
		startingXOrigins = new Array();
		startingYOrigins = new Array();
		destinationXOrigins = new Array();
		destinationYOrigins = new Array();
	}
	
	var frame = [self frame];
	var currentOrigin = CGPointMake(spacing / 2.0,rowSpacing);
		
	// Determines the center offset
	centerOffset = -1;
	var currentSpace = 0.0;
	for (var i = 0; i < [mediaItemCells count]; i++) {
		
		var mediaItemView = [mediaItemCells objectAtIndex:i];
		if ((removingMediaItems && [removingIndexSet containsIndex:i]) || [mediaItemView filteredOut] && ![mediaItemView beingFilteredIn])
			continue;
		
		currentSpace += spacing + viewSize.width;
	
		if (currentSpace + viewSize.width > frame.size.width) {
			numberOfItemsPerRow = i + 1; // Cache the number of items we can fit on a row
			centerOffset = (viewSize.width - (((currentSpace + viewSize.width) - frame.size.width))) / (i + 1);
			break;
		}
	}
			
	// If we've just got one row we need to set the center offset differently
	if (centerOffset == -1) {
		centerOffset = 0;//(([self frame].size.width - (numberOfMediaItemViews * (viewSize.width + spacing))) / numberOfMediaItemViews);
	}
		
	numberOfRows = 1;
	var numberOfRowsNeeded = 1;
	var animationInfoArrayIndex = 0;
	var visibleRect = [self visibleRect];
	
	for (var i = 0; i < [mediaItemCells count]; i++) {

		if (removingMediaItems && [removingIndexSet containsIndex:i])
			continue;
			
		var view = [mediaItemCells objectAtIndex:i];
		var viewFrame = CPRectCreateCopy([view frame]);
				
		if ([view filteredOut]) {
			if (animated && ![view beingFilteredIn]) {
				continue;
			}
			
			if (![view beingFilteredIn])
				continue;
		}
			
		if (numberOfRowsNeeded < numberOfRows) {
			currentOrigin.y += rowSpacing + viewSize.height;
			currentOrigin.x = spacing / 2.0;
			numberOfRowsNeeded++;
		}
		
		var adjustedOrigin = currentOrigin;
		adjustedOrigin.x += centerOffset;
 		viewFrame.origin = adjustedOrigin;

		viewFrame.size = viewSize;
								
		if (animated) {
			if (!CGRectEqualToRect(viewFrame,[view frame])) {
				// Make sure the current location or ending location will actually be visible at some point during the animation, otherwise leave it out
				if (CGRectIntersectsRect(viewFrame,visibleRect) || CGRectIntersectsRect([view frame],visibleRect)) {
					startingXOrigins[animationInfoArrayIndex] = [view frame].origin.x;
					startingYOrigins[animationInfoArrayIndex] = [view frame].origin.y;
					destinationXOrigins[animationInfoArrayIndex] = viewFrame.origin.x;
					destinationYOrigins[animationInfoArrayIndex] = viewFrame.origin.y;
				
					animationInfoArrayIndex++;
				
					[indexesOfAnimatingItemsThatNeedDisplay addIndex:i];
				}
			}			
		} else {
			
			if (zoomingWithoutRedrawingItemsYet)
				[view setLayoutFrameWithoutRedrawing:viewFrame];
			else
				[view setLayoutFrame:viewFrame];
		}		
		
		currentOrigin.x += spacing + viewSize.width;
		
		if (currentOrigin.x + viewSize.width > frame.size.width)
			numberOfRows++;
	}
		
	frame.size.height = currentOrigin.y + rowSpacing + viewSize.height + 36.0; // 36 for the transparent bar
	if (frame.size.height < [[self superview] frame].size.height)
		[self setFrame:[[self superview] frame]];
	else
		[self setFrame:frame];

	if (animated) {		
		self.layoutAnimation = [[FPAnimation alloc] initWithDuration:ANIMATED_LAYOUT_DURATION animationCurve:FPAnimationEaseInOut];
		[layoutAnimation setDelegate:self];
		[layoutAnimation startAnimation];
	} else
		[self setNeedsDisplay:YES];
}
	
- (void)animationFired:(FPAnimation)animation
{
	var currentProgress = [animation currentValue];

	if (animation == layoutAnimation) {
	
		if (removingMediaItems) {
		
			var currentIndex = [removingIndexSet firstIndex];
		
			while (currentIndex != CPNotFound) {
				[[mediaItemCells objectAtIndex:currentIndex] setAlphaValue:1.0 - currentProgress];
				currentIndex = [removingIndexSet indexGreaterThanIndex:currentIndex]; 
			}
		}
	
		// Only go through the frames we actually NEED to change
		var currentIndex = [indexesOfAnimatingItemsThatNeedDisplay firstIndex];
		var infoIndex = 0;
	
		while (currentIndex != CPNotFound) {
				
			var mediaItemView = [mediaItemCells objectAtIndex:currentIndex];
			var newOrigin = CGPointMakeZero();
		
			var startingXOrigin = startingXOrigins[infoIndex];
			var startingYOrigin = startingYOrigins[infoIndex];
				
			newOrigin.x = startingXOrigin + (currentProgress * (destinationXOrigins[infoIndex] - startingXOrigin));
			newOrigin.y = startingYOrigin + (currentProgress * (destinationYOrigins[infoIndex] - startingYOrigin));
		
			// if (animatingAddedItems && [animatingAddedItemIndexes containsIndex:currentIndex]) { // Scale up or down items that are coming from a media browser with a different zoom value
			// 	[mediaItemView setAlphaValue:0.6 + (currentProgress * 0.4)];
			// 
			// 	mediaItemFrame.size.width = previousSizeOfAddedItems.width + (currentProgress * (viewSize.width - previousSizeOfAddedItems.width));
			// 	mediaItemFrame.size.height = previousSizeOfAddedItems.height + (currentProgress * (viewSize.height - previousSizeOfAddedItems.height));
			// }
		
			if (animatingReorderedItems && [animatingReorderedItemIndexes containsIndex:currentIndex])
				[mediaItemView setAlphaValue:0.6 + (currentProgress * 0.4)];
		
			[mediaItemView setFrameOrigin:newOrigin];
			
			infoIndex++;
		    currentIndex = [indexesOfAnimatingItemsThatNeedDisplay indexGreaterThanIndex:currentIndex];
		}
		
		if (animatingForFilterQuery) {
			for (var i = 0; i < [mediaItemCells count]; i++) {
		
				var mediaItemView = [mediaItemCells objectAtIndex:i];
		
				if (needToFinishFadingMediaItemViews) {
			
					if ([animatingItemsToFinishFadingIn containsObject:mediaItemView]) {
						[mediaItemView setAlphaValue:[mediaItemView startingAlphaForFilteringFade] + ((1.0 - [mediaItemView startingAlphaForFilteringFade]) * currentProgress)]
						if (![mediaItemView beingFilteredIn])
							continue;
					
					} else if ([animatingItemsToFinishFadingOut containsObject:mediaItemView]) {
				
						[mediaItemView setAlphaValue:[mediaItemView startingAlphaForFilteringFade] - ([mediaItemView startingAlphaForFilteringFade] * currentProgress)]
						continue;
					}
				} else {
		
					if ([mediaItemView beingFilteredOut]) {
						[mediaItemView setAlphaValue:1.0 - currentProgress];
						continue;
			
					} else if ([mediaItemView beingFilteredIn])
						[mediaItemView setAlphaValue:currentProgress];
				}
			}
		}
	
		[self setNeedsDisplay:YES];
		
	} else if (animation == scrollAnimation) {
		
		[[[self enclosingScrollView] contentView] scrollToPoint:CGPointMake(0.0,startingScrollY + ((endingScrollY - startingScrollY) * currentProgress))];
	}
}

- (void)animationFinished:(FPAnimation)animation
{
	if (animation == layoutAnimation) {
		animatingItems = NO;
	
		if (removingMediaItems) {
			removingMediaItems = NO;
			[mediaItemCells removeObjectsAtIndexes:removingIndexSet];
		}
	
		if (animatingAddedItems)
			animatingAddedItems = NO;
		
		if (animatingReorderedItems)
			animatingReorderedItems = NO;
		
		if (animatingForFilterQuery) {
	
			var interrupted = [animation interrupted];
		
			if (!interrupted && !needToFinishFadingMediaItemViews)
				animatingForFilterQuery = NO
			else if (interrupted && !needToFinishFadingMediaItemViews) {
				needToFinishFadingMediaItemViews = YES;
		
				animatingItemsToFinishFadingIn = [[CPMutableArray alloc] init];
				animatingItemsToFinishFadingOut = [[CPMutableArray alloc] init];
			}
	
			needToFinishFadingMediaItemViews = interrupted;
		
			for (var i = 0; i < [mediaItemCells count]; i++) {

				var mediaItemView = [mediaItemCells objectAtIndex:i];

				if ([mediaItemView beingFilteredIn]) {

					if (needToFinishFadingMediaItemViews) {
				
						if (![animatingItemsToFinishFadingIn containsObject:mediaItemView]) {
							[mediaItemView setStartingAlphaForFilteringFade:[mediaItemView alphaValue]];
							[animatingItemsToFinishFadingIn addObject:mediaItemView];
					
						} else if ([animatingItemsToFinishFadingOut containsObject:mediaItemView])
							[animatingItemsToFinishFadingOut removeObject:mediaItemView];
					
					} else {
						[mediaItemView setAlphaValue:1.0];
						[mediaItemView setBeingFilteredIn:NO];
						if ([mediaItemView isSelected]) [mediaItemView setSelected:NO];
					}

				} else if ([mediaItemView beingFilteredOut]) {

					if (needToFinishFadingMediaItemViews) {
				
						if (![animatingItemsToFinishFadingOut containsObject:mediaItemView]) {
							[mediaItemView setStartingAlphaForFilteringFade:[mediaItemView alphaValue]];
							[animatingItemsToFinishFadingOut addObject:mediaItemView];
					
						} else if ([animatingItemsToFinishFadingIn containsObject:mediaItemView])
							[animatingItemsToFinishFadingIn removeObject:mediaItemView];
					
					} else {
						[mediaItemView setAlphaValue:0.0];
						[mediaItemView setBeingFilteredOut:NO];
						if ([mediaItemView isSelected]) [mediaItemView setSelected:NO];
					}
				}
			}
		}
	
		[self layout:NO];
		
	} else if (animation == scrollAnimation) {
		
		if (![animation interrupted])
			[[[self enclosingScrollView] contentView] scrollToPoint:CGPointMake(0.0,endingScrollY)];
			
		endingScrollY = -1;
		startingScrollY = -1;
	}
}

- (void)zoomSliderAdjusted:(CPSlider)slider
{
	var maxImageSize = 250.0;
	var imageSize = [slider floatValue] * maxImageSize;
	
	viewSize.width = imageSize;
	viewSize.height = imageSize;
	
	[self layout:NO];
}

// Drag and drop

- (void)initiatedDragReorderWithDraggedIndexSet:(var)newDraggedIndexSet
{
	dragIndexSet = newDraggedIndexSet;
}

- (CPDragOperation)draggingEntered:(var)sender
{
	dropIndex = -1;
	
	if ([sender draggingSource] != self) {
		if (draggingDestinationForOtherMediaBrowsers) {
			addingItem = YES;
			return CPDragOperationCopy;
		} else
			return CPDragOperationNone;
	} else {
		
		if (!contentFiltered) {
			reordering = YES;
			return CPDragOperationMove;
		}
	}
	
	return CPDragOperationNone;
}

- (CPDragOperation)draggingExited:(var)sender
{
	dropIndex = -1;
	reordering = NO;
	addingItem = NO;
	[self setNeedsDisplay:YES];
	
	return CPDragOperationNone;
}

- (CPDragOperation)draggingUpdated:(var)sender
{	
	if (!reordering && !draggingDestinationForOtherMediaBrowsers)
		return CPDragOperationNone;
		
	if (addingItem || (reordering && dragIndexSet != nil)) {
		
		dropIndex = [mediaItemCells count];
		var location = [self convertPoint:[sender draggingLocation] fromView:nil];
		
		location.x += .5 * viewSize.width;
		
		for (var i = 0; i < [mediaItemCells count]; i++) {
			var mediaItemView = [mediaItemCells objectAtIndex:i];
			if (CGRectContainsPoint(CGRectInset([mediaItemView frame],(-spacing-centerOffset),(-rowSpacing / 2.0)),location))
				dropIndex = i;
		}
		
		[self setNeedsDisplay:YES];
	}
	
	if (addingItem)
		return CPDragOperationCopy;
	
	return CPDragOperationMove;
}

- (BOOL)performDragOperation:(var)sender
{	
	if (!reordering && !draggingDestinationForOtherMediaBrowsers)
		return CPDragOperationNone;
		
	if (reordering && dragIndexSet != nil) {
		
		 if ([dataSource mediaItemReorderedFromIndexes:dragIndexSet toIndex:dropIndex] == NO) {
		 	CPLog(@"JTMediaBrowserView: Data source did not allow reordering")
		 	reordering = NO;
		 	dropIndex = -1;
			dragIndexSet = nil;
		 	[self setNeedsDisplay:YES];
		 	return;
		}
		
		var mediaItemCellsBeingDragged = [[CPMutableArray alloc] init];
		var currentIndex = [dragIndexSet firstIndex];
		var adjustedDropIndex = dropIndex;
		
		while (currentIndex != CPNotFound) {

			if (currentIndex < dropIndex)
				adjustedDropIndex--;
				
			[mediaItemCellsBeingDragged addObject:[[mediaItemCells objectAtIndex:currentIndex] copy]];
		    currentIndex = [dragIndexSet indexGreaterThanIndex:currentIndex]; 
		}
		
		[mediaItemCells removeObjectsAtIndexes:dragIndexSet];
		
		var offsetAmount = 0.0;
		
		animatingReorderedItems = YES;
		animatingReorderedItemIndexes = [CPIndexSet indexSet];
		
		for (var i = 0; i < [mediaItemCellsBeingDragged count]; i++) {
						
			var currentMediaItemCell = [mediaItemCellsBeingDragged objectAtIndex:i];
			[mediaItemCells insertObject:currentMediaItemCell atIndex:adjustedDropIndex + i];
						
			[animatingReorderedItemIndexes addIndex:adjustedDropIndex + i];
			[currentMediaItemCell setAlphaValue:0.6];
			
			var clickOffset = [[sender draggingSource] dragClickOffset];
												
			var draggedViewLocation = [self convertPoint:[sender draggingLocation] fromView:nil];			
			[currentMediaItemCell setLayoutFrame:CGRectMake(draggedViewLocation.x + offsetAmount - clickOffset.x,draggedViewLocation.y + offsetAmount - clickOffset.y,viewSize.width,viewSize.height)];
			offsetAmount += 5.0;
		}
		
		// Ensure that the dragged items are visually updated to their drag frame so their animation starts in the right place
		[self setNeedsDisplay:YES];	
		
		reordering = NO;
		dropIndex = -1;
		dragIndexSet = nil;
		dragInitiated = NO;
		validClickForDraggingMediaItem = NO;
				
		[self layout:YES];
		
		return YES;
		
	} else if (addingItem) {
		
		var mediaItemCellsBeingDragged = [[sender draggingSource] mediaItemCellsBeingDragged];
		var offsetAmount = 0.0;
		var clickOffset = [[sender draggingSource] dragClickOffset];
		
		var mediaItemsForDataSource = [[CPMutableArray alloc] init];
		for (var i = 0; i < [mediaItemCellsBeingDragged count]; i++)
			[mediaItemsForDataSource addObject:[[mediaItemCellsBeingDragged objectAtIndex:i] representedMediaItem]];
		
		if ([dataSource mediaBrowserShouldAddMediaItems:mediaItemCellsBeingDragged atIndex:dropIndex]) {
			
			previousSizeOfAddedItems = [[sender draggingSource] frame].size;
			// If the media browser they're dragging from is using a different zoom value then we need to know so we can animate
			if (previousSizeOfAddedItems.width != viewSize.width || previousSizeOfAddedItems.height != viewSize.height) {
				animatingAddedItems = YES;
				animatingAddedItemIndexes = [CPIndexSet indexSet];
			}
				
			for (var i = 0; i < [mediaItemCellsBeingDragged count]; i++) {
				
				var mediaItemView = [mediaItemCellsBeingDragged objectAtIndex:i];
				var addedMediaItemView = [[JTMediaItemView alloc] initWithImage:[[mediaItemView imageView] image] title:[mediaItemView title]];
				var draggedViewLocation = [self convertPoint:[sender draggingLocation] fromView:nil];
					
				[addedMediaItemView setLayoutFrame:CGRectMake(draggedViewLocation.x + offsetAmount - clickOffset.x,draggedViewLocation.y + offsetAmount - clickOffset.y,previousSizeOfAddedItems.width,previousSizeOfAddedItems.height)];
				
				[mediaItemCells insertObject:addedMediaItemView atIndex:dropIndex + i];
				
				if (animatingAddedItems) {
					[animatingAddedItemIndexes addIndex:dropIndex + i];
					[addedMediaItemView setAlphaValue:0.6];
				}
				
				[self addSubview:addedMediaItemView];
				offsetAmount += 5.0;
			}
		}
		
		addingItem = NO;
		[self layout:YES];
	}

	reordering = NO;
	dropIndex = -1;
	dragIndexSet = nil;
	[self setNeedsDisplay:YES];	
	
	return YES;
}

- (void)pasteboard:(CPPasteboard)sender provideDataForType:(CPString)type
{
	if ([type isEqualToString:@"JOURNALIST_MEDIA_ITEM_PBOARD_TYPE"])
	{
		var mediaItemCells = [mediaItemCells objectsAtIndexes:dragIndexSet];
		var mediaItemIDs = [CPMutableArray array];
		for (var i=0; i<[mediaItemCells count];i++)
		{
			var mediaItemCell = [mediaItemCells objectAtIndex:i];
			[mediaItemIDs addObject:mediaItemCell.uniqueID];
		}
		reordering = NO;
		[sender setData:mediaItemIDs forType:type];
	}
	/*if([type compare: NSTIFFPboardType]==NSOrderedSame)
	  {
	  //set data for TIFF type on the pasteboard as requested
	  [sender setData:[[self image] TIFFRepresentation] forType:NSTIFFPboardType];
	  }
	 else if([type compare: NSPDFPboardType]==NSOrderedSame)
	  {
	  [sender setData:[self dataWithPDFInsideRect:[self bounds]] forType:NSPDFPboardType];
	  }*/
}

- (int)mediaItemIndexAtLocation:(CPPoint)location
{
	for (var i=0;i<[mediaItemCells count];i++)
	{
		var mediaItemCell = [mediaItemCells objectAtIndex:i];
		if ([mediaItemCell filteredOut])
			continue;
		
		var imageRect = [mediaItemCell imageRectWithFrameOffset];		

		if (CGRectContainsPoint(imageRect,location))
			return i;
	}
	return -1;
}

- (void)mouseDown:(CPEvent)event
{	
	var clickLocation = [self convertPoint:[event locationInWindow] fromView:[[self window] contentView]];
	var validClickForDraggingMediaItem = NO;
	var mediaItemIndex = [self mediaItemIndexAtLocation:clickLocation];
	dragIndexSet = [CPIndexSet indexSet];
	
	if (mediaItemIndex>-1)
	{
		var mediaItemCell = [[self mediaItemCells] objectAtIndex:mediaItemIndex];
		[mediaItemCell mouseDown:event];
	}
	else
	{
		[self deselectAllMediaItems];
		dragSelectionStartPoint = [self convertPoint:[event locationInWindow] fromView:[[self window] contentView]];
		[self setNeedsDisplay:YES];
	}
}

- (void)cell:(JPCell)mediaItemCell beganDrag:(CPEvent)event
{
	var dragLocation = [self convertPoint:[event locationInWindow] fromView:[[self window] contentView]];
	var mediaItemIndex = [[self mediaItemCells] indexOfObject:mediaItemCell];
	validClickForDraggingMediaItem = YES;
	
	dragClickOffset = CGPointMake(dragLocation.x - [mediaItemCell frame].origin.x,dragLocation.y - [mediaItemCell frame].origin.y);
	indexOfItemThatInitiatedDrag = mediaItemIndex;

	if ([mediaItemCell isSelected])
		[dragIndexSet addIndexes:[self selectedIndexes]]; // If the cell you're starting a drag on is selected, you also want to drag the other selected ones
	else
		[dragIndexSet addIndex:mediaItemIndex]; // But even if others are selected we only want the one you're dragging if it's not selected
}

- (void)cell:(JPCell)mediaItemCell doubleClicked:(CPEvent)event
{
	if (delegate != nil)
	{
		[[self delegate] mediaBrowserView:self doubleClickedCell:mediaItemCell];
	}
}

- (void)mouseMoved:(CPEvent)event
{
	if (!performingDragSelection)
	{
		var mouseLocation = [self convertPoint:[event locationInWindow] fromView:[[self window] contentView]];
		var mediaItemIndex = [self mediaItemIndexAtLocation:mouseLocation];
	
		if (mediaItemIndex>-1)
		{
			var mediaItemCell = [[self mediaItemCells] objectAtIndex:mediaItemIndex];
		
			if (mediaItemCell!=hoveredCell)
			{
				[mediaItemCell mouseEntered:event];
				hoveredCell = mediaItemCell;
			}
		}
		else
		{
			[hoveredCell mouseExited:event];
			hoveredCell = nil;
		}
	}
}

- (void)mouseDragged:(CPEvent)event
{
	if (validClickForDraggingMediaItem && !dragInitiated) {
		
		mediaItemDraggingView = [[JTMediaItemDraggingView alloc] initWithFrame:CGRectMake(0.0,0.0,viewSize.width,viewSize.height)];
		[mediaItemDraggingView setDraggedMediaItemCells:[mediaItemCells objectsAtIndexes:dragIndexSet]];
		
		var pasteboard = [CPPasteboard pasteboardWithName:CPDragPboard];
		[pasteboard declareTypes:[CPArray arrayWithObject:@"JOURNALIST_MEDIA_ITEM_PBOARD_TYPE"] owner:self];
		
		[self dragView:mediaItemDraggingView at:[[mediaItemCells objectAtIndex:indexOfItemThatInitiatedDrag] frame].origin offset:CGSizeMakeZero() event:event pasteboard:pasteboard source:self slideBack:NO];
				
		dragInitiated = YES;
		
	} else if (!dragInitiated && !validClickForDraggingMediaItem) {
		
		performingDragSelection = YES;
		dragSelectionEndPoint = [self convertPoint:[event locationInWindow] fromView:[[self window] contentView]];
	
		dragSelectionRect = CGRectIntegral(CGRectMake(dragSelectionStartPoint.x,dragSelectionStartPoint.y,dragSelectionEndPoint.x - dragSelectionStartPoint.x,dragSelectionEndPoint.y - dragSelectionStartPoint.y));
		dragSelectionRect.origin.x += 0.5;
		dragSelectionRect.origin.y += 0.5;
	
		// Fix
		if (dragSelectionRect.size.width < 0) {
			dragSelectionRect.size.width = -dragSelectionRect.size.width;
			dragSelectionRect.origin.x -= dragSelectionRect.size.width;
		}
	
		if (dragSelectionRect.size.height < 0) {
			dragSelectionRect.size.height = -dragSelectionRect.size.height;
			dragSelectionRect.origin.y -= dragSelectionRect.size.height;
		}
	
		for (var i = 0; i < [mediaItemCells count]; i++) {
			var mediaItemView = [mediaItemCells objectAtIndex:i];
			if ([mediaItemView filteredOut])
				continue;
			
			var imageRect = [mediaItemView imageRectWithFrameOffset];		
		
			if (CGRectIntersectsRect(imageRect,dragSelectionRect))
				[mediaItemView setSelected:YES];
			else
				[mediaItemView setSelected:NO];
		}
		
		[self selectionChanged];
		[self setNeedsDisplay:YES];
	}
}

- (void)mouseUp:(CPEvent)event
{				
	if (performingDragSelection) {
		performingDragSelection = NO;
		[self setNeedsDisplay:YES];
		return;
		
	}
		
	if (validClickForDraggingMediaItem) {
		validClickForDraggingMediaItem = NO;
		dragInitiated = NO;
	}
		
	if ([mediaItemInspectorPanel locked] && [mediaItemInspectorPanel isVisible])
		[mediaItemInspectorPanel fadeOut:nil];
}

- (void)keyDown:(CPEvent)anEvent
{	
	[self interpretKeyEvents:[CPArray arrayWithObject:anEvent]];
}

- (void)interpretKeyEvents:(CPArray)events
{
	if ([events count] == 1) {
		
		var selectedIndexes = [self selectedIndexes];
		var event = [events objectAtIndex:0];
		var isShiftKey = ([event modifierFlags] & CPShiftKeyMask) != 0;
		
		if ([event keyCode] == CPDeleteKeyCode && [selectedIndexes count] > 0) {

			if ([dataSource mediaBrowserShouldDeleteItemsAtIndexes:selectedIndexes]) {
		
				removingIndexSet = [CPIndexSet indexSet];
				[removingIndexSet addIndexes:selectedIndexes];	
				
				removingMediaItems = YES;
													
				[self layout:YES];
			} else
				CPLog(@"JTMediaBrowserView: Data source prevented deletion of media items");
					
			return;
			
		} else if ([event keyCode] == CPLeftArrowKeyCode && [selectedIndexes count] > 0) {

			var indexToSelect = [selectedIndexes firstIndex] - 1;
				
			if (indexToSelect >= 0) {
				
				if (!isShiftKey)
					[self deselectAllMediaItems];
				
				[self selectItemAtIndex:indexToSelect byAdjustingVisibleFrameDown:NO];
			}
						
		} else if ([event keyCode] == CPRightArrowKeyCode && [selectedIndexes count] > 0) {

			var indexToSelect = [selectedIndexes lastIndex] + 1;

			if (indexToSelect < [mediaItemCells count]) {
				
				if (!isShiftKey)
					[self deselectAllMediaItems];
					
				[self selectItemAtIndex:indexToSelect byAdjustingVisibleFrameDown:YES];
			}
						
		} else if ([event keyCode] == CPUpArrowKeyCode && [selectedIndexes count] > 0) {

			var indexToSelect = [selectedIndexes firstIndex] - numberOfItemsPerRow;
			var selectionDifference = 0;
			
			if (indexToSelect < 0)
				if (isShiftKey) {
					selectionDifference = Math.abs(indexToSelect);
					indexToSelect = 0;
				} else
					return;
						
			if (!isShiftKey)
				[self deselectAllMediaItems];
			else
				[self selectIndexesInRange:CPMakeRange(indexToSelect + 1,numberOfItemsPerRow - 1 - selectionDifference)];

			[self selectItemAtIndex:indexToSelect byAdjustingVisibleFrameDown:NO];
			
		} else if ([event keyCode] == CPDownArrowKeyCode && [selectedIndexes count] > 0) {

			var indexToSelect = [selectedIndexes lastIndex] + numberOfItemsPerRow;

			if (indexToSelect >= [mediaItemCells count])
				if (isShiftKey)
					indexToSelect = [mediaItemCells count] - 1;
				else
					return;
				
			if (!isShiftKey)
				[self deselectAllMediaItems];
			else
				[self selectIndexesInRange:CPMakeRange([selectedIndexes lastIndex] + 1,numberOfItemsPerRow - 1)];

			[self selectItemAtIndex:indexToSelect byAdjustingVisibleFrameDown:YES];
		} else if ([event keyCode] == 32 && [selectedIndexes count] > 0) {
			
			var index = [selectedIndexes lastIndex];
			//if (delegate != nil)
				//[delegate mediaBrowserView:self doubleClickedCell:[mediaItemCells objectAtIndex:index]];
			
		}
	} 
}

- (void)selectIndexesInRange:(var)range
{	
	for (var indexInRange = 0; indexInRange < range.length; indexInRange++) {
		
		var index = range.location + indexInRange;
		
		if ((index >= 0) && (index < [mediaItemCells count]))
			[[mediaItemCells objectAtIndex:index] setSelected:YES];
	}
	
	[self selectionChanged];
}

- (void)selectItemAtIndex:(var)index byAdjustingVisibleFrameDown:(var)scrollDown
{
	var mediaItemCell = [mediaItemCells objectAtIndex:index];
	[mediaItemCell setSelected:YES];
	[self setNeedsDisplay:YES];
	
	var comparisonRect = CPRectCreateCopy([self visibleRect]);
	if (scrollDown)
		comparisonRect.size.height -= 36.0;
	
	var intersectionRect = CGRectIntersection(comparisonRect,[mediaItemCell frame]);
	var scrollPoint = CPPointCreateCopy([[[self enclosingScrollView] contentView] boundsOrigin]);
	startingScrollY = scrollPoint.y;
	
	if (intersectionRect.size.height <= 0.0) {
		
		if (scrollDown)
			scrollPoint.y += ([mediaItemCell frame].origin.y + viewSize.height) - (comparisonRect.origin.y + comparisonRect.size.height);
		else
			scrollPoint.y = [mediaItemCell frame].origin.y;

	} else if (intersectionRect.size.height < viewSize.height) {

		if (scrollDown)
			scrollPoint.y += viewSize.height - intersectionRect.size.height;
		else
			scrollPoint.y -= viewSize.height - intersectionRect.size.height;
	}

	if ([[[self enclosingScrollView] contentView] boundsOrigin].y == scrollPoint.y)
		return;

	// If it's animating and you manage to catch up with the animation you must be selecting up or down quickly (maybe holding the key)
	// in this case we'll just disable the animation and wait for a small delay to enable it again (the delay resets until it actually is fully passed)
	
	if (allowingAnimatedScrollForKeyboardNavigation && !(scrollAnimation != nil && [scrollAnimation running])) {
	
		endingScrollY = scrollPoint.y;
	
		self.scrollAnimation = [[FPAnimation alloc] initWithDuration:0.2 animationCurve:FPAnimationEaseInOut];
		[scrollAnimation setDelegate:self];
		[scrollAnimation startAnimation];
		
	} else {
		
		if (scrollAnimation != nil && [scrollAnimation running])
			[scrollAnimation stopAnimation];
		
		if (allowingAnimatedScrollForKeyboardNavigationTimer != nil && [allowingAnimatedScrollForKeyboardNavigationTimer isValid])
			[allowingAnimatedScrollForKeyboardNavigationTimer invalidate];
			
		allowingAnimatedScrollForKeyboardNavigationTimer = [CPTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(animatedScrollDelayPassed:) userInfo:nil repeats:NO];
		
		[[[self enclosingScrollView] contentView] scrollToPoint:scrollPoint];
	}
	
	[self selectionChanged];
}

- (void)animatedScrollDelayPassed:(var)timer
{
	allowingAnimatedScrollForKeyboardNavigation = YES;
}

- (void)sortMediaItemsWithKey:(CPString)keyPath ascending:(BOOL)ascending
{
	var sortDescriptor = [[CPSortDescriptor alloc] initWithKey:keyPath ascending:ascending];
	[mediaItemCells sortUsingDescriptors:[CPArray arrayWithObject:sortDescriptor]];
	[self layout:YES];
}

- (void)setFilterString:(CPString)filterString
{		
	contentFiltered = !([filterString isEqualToString:@""] || filterString == nil);
		
	for (var i = 0; i < [mediaItemCells count]; i++) {
		var mediaItemView = [mediaItemCells objectAtIndex:i];

		if (!contentFiltered || ([[mediaItemView title] rangeOfString:filterString options:CPCaseInsensitiveSearch].location != CPNotFound)) {
			if ([mediaItemView filteredOut]) {
				[mediaItemView setBeingFilteredIn:YES];
				[mediaItemView setBeingFilteredOut:NO];
			}
			
			[mediaItemView setFilteredOut:NO];
			
		} else {
			if (![mediaItemView filteredOut]) {
				[mediaItemView setBeingFilteredOut:YES]
				[mediaItemView setBeingFilteredIn:NO]
			}
			
			[mediaItemView setFilteredOut:YES];
		}
	}
		
	animatingForFilterQuery = YES;
	[self layout:YES];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

@end