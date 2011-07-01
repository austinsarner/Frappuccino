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
@import "MediaLibrary.j"
@import "MDRadialControl.j"
@import "JTMediaItemCell.j"
@import "JTAnimatingImageView.j"
@import "JTImageEditorViewController.j"

var TOOLBAR_HEIGHT = 39;
var BUTTONBAR_HEIGHT = 36;
var MAX_IMAGE_SIZE = 200.0;

var JTMediaChooserZoomSliderDefaultsKey = @"MediaZoom";
var JTMediaChooserSelectedTabDefaultsKey = @"MediaSelectedTab";

var JTMediaChooserPhotosSegment = 0;
var JTMediaChooserVideosSegment = 1;
var JTMediaChooserAudioSegment = 2;

@implementation JTMediaChooserViewController : JTChooserViewController
{
	CPString				autosaveName @accessors;
	JTMediaBrowserView*		mediaBrowserView	@accessors;
	JTButtonBar				buttonBar @accessors;
	CPMutableDictionary 	media;
	//JPSegmentedControl	sourceMediaSortingSegmentedControl;
	CPTextField				filterTextField @accessors;
	//CPTimer				filterDelayTimer;
	JTScrollView			scrollView;
	
	CPImage					largePreviewImage;
	JTAnimatingImageView 	animatingImageView;
	BOOL 					animatingImageViewOut;
	JTMediaItemCell 		animatedMediaItemCell;
	
	var						mediaItemForEditing;
}

- (id)initWithViewFrame:(CGRect)frame autosaveName:(CPString)anAutosaveName
{
	if (self = [super init])
	{
		view = [[FPView alloc] initWithFrame:frame];
		autosaveName = anAutosaveName;
		[self viewWillLoad];
		[self loadView];
		[self viewDidLoad];
	}
	return self;
}

- (void)loadView
{	
	[super loadView];
	
	var contentView = self.view;
	var mediaBrowserBackgroundColor = [CPColor colorWithHexString:@"16171a"];
	[contentView setBackgroundColor:mediaBrowserBackgroundColor];
	
	var selectedSegment = 0;
	var segmentDefaultsKey = autosaveName + JTMediaChooserSelectedTabDefaultsKey;
	var selectedSegmentString = [[FPLocalStorage sharedLocalStorage] valueForKey:segmentDefaultsKey];
	if (selectedSegmentString != nil)
		selectedSegment = [selectedSegmentString intValue];
	
	[segmentedTabControl setSegmentCount:3];
	[segmentedTabControl setLabel:@"Photos" forSegment:JTMediaChooserPhotosSegment];
	[segmentedTabControl setWidth:90 forSegment:JTMediaChooserPhotosSegment];
	[segmentedTabControl setLabel:@"Videos" forSegment:JTMediaChooserVideosSegment];
	[segmentedTabControl setWidth:82 forSegment:JTMediaChooserVideosSegment];
	[segmentedTabControl setLabel:@"Audio" forSegment:JTMediaChooserAudioSegment];
	[segmentedTabControl setWidth:76 forSegment:JTMediaChooserAudioSegment];
	[segmentedTabControl setSelectedSegment:selectedSegment];
	
	filterTextField = [CPTextField roundedTextFieldWithStringValue:@"" placeholder:@"Filter Media" width:150];
	var textFieldFrame = [filterTextField frame];
	textFieldFrame.origin.x = CGRectGetMaxX([contentView bounds]) - textFieldFrame.size.width - 15.0;
	textFieldFrame.origin.y = 4.0;
	[filterTextField setFrame:textFieldFrame];
	[toolbar addSubview:filterTextField];
	
	buttonBar = [[JTButtonBar alloc] initWithFrame:CGRectMake(0,CGRectGetHeight([contentView bounds])-BUTTONBAR_HEIGHT,[contentView bounds].size.width,BUTTONBAR_HEIGHT)];
	[buttonBar setBlurColor:mediaBrowserBackgroundColor];
	[buttonBar setAutoresizingMask:CPViewMinYMargin|CPViewWidthSizable];
	
	var addButton = [[JTOpenFilesAddButton alloc] initWithFrame:CGRectMake(0,0,40,BUTTONBAR_HEIGHT)];
	[buttonBar addSubview:addButton];
	[contentView addSubview:buttonBar];
	
	var zoomValue = 0.4;
	var zoomDefaultsKey = autosaveName + JTMediaChooserZoomSliderDefaultsKey;
	var zoomString = [[FPLocalStorage sharedLocalStorage] valueForKey:zoomDefaultsKey];
	if (zoomString != nil)
		zoomValue = [zoomString floatValue];
	
	var zoomSlider = [[FPSlider alloc] initWithFrame:CGRectMake(CGRectGetMaxX([buttonBar bounds])-150.0,4.0,140.0,28.0)];
	[zoomSlider setMinValue:0.3];
	[zoomSlider setMaxValue:1.0];
	[zoomSlider setFloatValue:zoomValue];
	[zoomSlider setTarget:self];
	[zoomSlider setAction:@selector(zoomSliderAdjusted:)]
	
	[zoomSlider setAutoresizingMask:CPViewMinXMargin];
	[buttonBar addSubview:zoomSlider];
	
	var mediaBrowserFrame = CPRectCreateCopy([contentView bounds]);
	mediaBrowserFrame.origin.y += TOOLBAR_HEIGHT;
	mediaBrowserFrame.size.height -= TOOLBAR_HEIGHT;
	scrollView = [[JTScrollView alloc] initWithFrame:mediaBrowserFrame];
	[scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
	[scrollView setScrollerBottomPadding:BUTTONBAR_HEIGHT];
	[scrollView setAutohidesScrollers:YES];
	
    mediaBrowserView = [[JTMediaBrowserView alloc] initWithFrame:[scrollView bounds]];
	[mediaBrowserView setBackgroundColor:mediaBrowserBackgroundColor];
	[mediaBrowserView setDataSource:self];
	[mediaBrowserView setDelegate:self];
    [mediaBrowserView setAutoresizingMask:CPViewWidthSizable];
	
	[scrollView setDocumentView:mediaBrowserView];
	[scrollView setBackgroundColor:mediaBrowserBackgroundColor];
	
	[scrollView setDelegate:mediaBrowserView]; // update on scroll
	
    [contentView addSubview:scrollView positioned:CPWindowBelow relativeTo:buttonBar];
	[self _adjustToZoomValue:[zoomSlider floatValue]];
	[addButton setMediaBrowserToUpdate:mediaBrowserView];
}

- (void)tabChanged:(id)sender
{
	if (autosaveName != nil && [autosaveName length]>0)
	{
		var selectedTabIndex = [segmentedTabControl selectedSegment];
		var tabString = [CPString stringWithFormat:@"%d",selectedTabIndex];
		var tabDefaultsKey = autosaveName + JTMediaChooserSelectedTabDefaultsKey;
		[[FPLocalStorage sharedLocalStorage] setValue:tabString forKey:tabDefaultsKey];
	}
	[mediaBrowserView reloadData];
}

- (CPString)filteredEntity
{
	var selectedTabIndex = [segmentedTabControl selectedSegment];
	
	var entity = @"Photo";
	if (selectedTabIndex == JTMediaChooserVideosSegment)
		entity = @"Video";
	else if (selectedTabIndex == JTMediaChooserAudioSegment)
		entity = @"Audio";
	
	return entity;
}

- (CPMutableArray)mediaItems
{
	var entity = [self filteredEntity];
	return [media valueForKey:entity];
}

- (void)setShowsButtonBar:(BOOL)showToolbar
{
	[scrollView setScrollerBottomPadding:0];
	[buttonBar setHidden:!showToolbar];
}

- (void)setViewSize:(var)newSize
{
	[mediaBrowserView setViewSize:newSize];
}

- (void)sortMediaItemsWithKey:(CPString)keyPath ascending:(BOOL)ascending
{
	[mediaBrowserView sortMediaItemsWithKey:keyPath ascending:ascending];
}

- (void)setFilterString:(CPString)filterString
{
	[mediaBrowserView setFilterString:filterString];
}

- (void)zoomSliderAdjusted:(var)sender
{
	if (autosaveName != nil && [autosaveName length]>0)
	{
		var saveValue = [CPString stringWithFormat:@"%f",[sender floatValue]];
		var zoomDefaultsKey = autosaveName + JTMediaChooserZoomSliderDefaultsKey;
		[[FPLocalStorage sharedLocalStorage] setValue:saveValue forKey:zoomDefaultsKey];
	}
	[self _adjustToZoomValue:[sender floatValue]];
}

- (void)_adjustToZoomValue:(float)zoomValue
{
	var imageSize = Math.ceil(zoomValue * MAX_IMAGE_SIZE);
	[mediaBrowserView setViewSizeAdjustedBySlider:CGSizeMake(imageSize,imageSize)];
}

- (void)setZoomValue:(var)zoomValue
{
	var imageSize = Math.ceil(zoomValue * MAX_IMAGE_SIZE);
	
	[mediaBrowserView setViewSize:CGSizeMake(imageSize,imageSize)];
}

- (void)setDraggingDestinationForOtherMediaBrowsers:(var)isDestination
{
	[mediaBrowserView setDraggingDestinationForOtherMediaBrowsers:isDestination];
}

- (void)removeAllPhotos
{
	//[mediaItems removeAllObjects];
	[mediaBrowserView reloadData];
}

- (void)resetData
{
	var mediaItems = [self.detailViewController details];
	
	media = [[CPMutableDictionary alloc] init];
	for (var i=0;i<[mediaItems count];i++)
	{
		var mediaItem = [mediaItems objectAtIndex:i];
		var entity = [mediaItem className];
		if (![media valueForKey:entity])
			[media setValue:[CPMutableArray array] forKey:entity];
		[[media valueForKey:entity] addObject:mediaItem];
	}
	
	[mediaBrowserView reloadData];
}

// JTMediaBrowserView Delegate

- (void)mediaBrowserView:(JTMediaBrowserView)aMediaBrowserView doubleClickedCell:(JTMediaItemCell)mediaItemCell
{
	if ([[self filteredEntity] isEqualToString:@"Photo"])
	{
		var mediaItem = [[MediaLibrary sharedMediaLibrary] mediaItemWithID:[mediaItemCell uniqueID]];
		mediaItemForEditing = mediaItem;
		var photoURL = [mediaItem mediaURL];
		largePreviewImage = [[CPImage alloc] initWithContentsOfFile:[photoURL absoluteString]];
		[largePreviewImage setDelegate:self];
		
		animatedMediaItemCell = mediaItemCell;
	
		var animatingImageViewFrame = CPRectCreateCopy([scrollView frame]);
		animatingImageViewFrame.size.height -= BUTTONBAR_HEIGHT;
		
		animatingImageView = [[JTAnimatingImageView alloc] initWithFrame:animatingImageViewFrame];
		if ([largePreviewImage loadStatus] != CPImageLoadStatusCompleted)
			[animatingImageView setImage:[mediaItemCell image]];
		else
			[animatingImageView setImage:largePreviewImage];
		[animatingImageView setDimmingEnabled:YES];
		[animatingImageView setMaxDimmerAlpha:0.8];
		[animatingImageView setDelegate:self];
		[animatingImageView setImageScaling:FPScaleToFit];
		[animatingImageView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];

		var destinationAnimatingImageViewFrame = CPRectCreateCopy([animatingImageView bounds]);

		var mediaItemSize = [mediaItem mediaSize];

		// if (destinationAnimatingImageViewFrame.size.width > mediaItemSize.width)
		// 	destinationAnimatingImageViewFrame.size.width = mediaItemSize.width;
		if (destinationAnimatingImageViewFrame.size.height > mediaItemSize.height) {
			destinationAnimatingImageViewFrame.origin.y += ((destinationAnimatingImageViewFrame.size.height - mediaItemSize.height) / 2.0)
			destinationAnimatingImageViewFrame.size.height = mediaItemSize.height;
		}
		
		CPLog(@"DestinationAnimatingImageViewFrame: %@",CPStringFromRect(destinationAnimatingImageViewFrame));
	 	var initialAnimatingImageViewFrame = [self.view convertRect:[mediaItemCell imageRectWithFrameOffset] fromView:mediaBrowserView];
		initialAnimatingImageViewFrame.origin.y -= TOOLBAR_HEIGHT;
		
		var size = initialAnimatingImageViewFrame.size;
		var width = size.width;
		var height = size.height;

		var targetWidth = destinationAnimatingImageViewFrame.size.width;
		var targetHeight = destinationAnimatingImageViewFrame.size.height;

		var scaleFactor = 1.0;
		var scaledWidth = targetWidth;
		var scaledHeight = targetHeight;

		var widthFactor = targetWidth / width;
	    var heightFactor = targetHeight / height;

	    if (widthFactor < heightFactor)
	      scaleFactor = widthFactor;
	    else
	      scaleFactor = heightFactor;

	    scaledWidth = width  * scaleFactor;
	    scaledHeight = height * scaleFactor;

	    if (widthFactor < heightFactor)
	      destinationAnimatingImageViewFrame.origin.y += (targetHeight - scaledHeight) * 0.5;

	    else if (widthFactor > heightFactor)
	      destinationAnimatingImageViewFrame.origin.x += (targetWidth - scaledWidth) * 0.5;

		destinationAnimatingImageViewFrame.size.width = scaledWidth;
		destinationAnimatingImageViewFrame.size.height = scaledHeight;
		destinationAnimatingImageViewFrame = CGRectIntegral(destinationAnimatingImageViewFrame);
	
		animatingImageViewOut = NO;
	
		[animatingImageView setDimmingReversed:NO];
		[animatingImageView setStartingImageFrame:initialAnimatingImageViewFrame];
		[animatingImageView setDestinationImageFrame:destinationAnimatingImageViewFrame];
		[self.view addSubview:animatingImageView];
		
		[animatingImageView animateImage];
		CPLog(@"Adjusted DestinationAnimatingImageViewFrame: %@",CPStringFromRect(destinationAnimatingImageViewFrame));
	}
}

- (void)imageDidLoad:(CPImage)image
{
	if ([image loadStatus] == CPImageLoadStatusCompleted) {
		if (image == largePreviewImage && animatingImageView != nil && [animatingImageView superview] != nil && animatingImageViewOut == NO) {
			[animatingImageView setImage:largePreviewImage];
		}
	}		
}

- (void)animateOutImageView
{
	[animatingImageView setDimmingReversed:YES];
	[animatingImageView setStartingImageFrame:CPRectCreateCopy([animatingImageView destinationImageFrame])];
	
	var destinationImageFrame = CPRectCreateCopy([self.view convertRect:[animatedMediaItemCell imageRectWithFrameOffset] fromView:mediaBrowserView]);
	destinationImageFrame.origin.y -= TOOLBAR_HEIGHT;
	[animatingImageView setDestinationImageFrame:destinationImageFrame];
	
	[animatingImageView animateImage];
}

- (void)detailViewController:(var)aDetailViewController dismissedModalContentViewController:(var)aModalContentViewController
{
	if (animatingImageView != nil)
		[self animateOutImageView];
}

- (void)finishedAnimatingImageView:(var)imageView
{
	if (imageView == animatingImageView) {
		
		if ([animatingImageView dimmingReversed])
			[animatingImageView removeFromSuperview];
		else if ([largePreviewImage loadStatus] == CPImageLoadStatusCompleted && ![animatingImageView fadingInNewImage]) {
			var imageEditorViewController = [[JTImageEditorViewController alloc] initWithViewFrame:[self.view bounds]];
			[imageEditorViewController setImage:largePreviewImage];
			[imageEditorViewController setMediaItem:mediaItemForEditing];
			[self.detailViewController presentModalContentViewController:imageEditorViewController];
		}
	}
}

- (void)animatingImageView:(JTAnimatingImageView)imageView finishedFadingInNewImage:(CPImage)image
{
	if (imageView == animatingImageView) {
		
		if ([self.detailViewController contentViewController] == self) {
			var imageEditorViewController = [[JTImageEditorViewController alloc] initWithViewFrame:[self.view bounds]];
			[imageEditorViewController setImage:largePreviewImage];
			[imageEditorViewController setMediaItem:mediaItemForEditing];
			[self.detailViewController presentModalContentViewController:imageEditorViewController];
		}
	}
}
// JTMediaBrowserView DataSource

- (unsigned int)numberOfMediaItems
{
	return [[self mediaItems] count];
}

- (CPView)cellForMediaItemAtIndex:(unsigned int)index
{	
	var mediaItem = [[self mediaItems] objectAtIndex:index];
	
	var cellClass = [JTMediaItemCell class];
	if ([[self filteredEntity] isEqualToString:@"Audio"])
		cellClass = [JTAudioItemCell class];
	else if ([[self filteredEntity] isEqualToString:@"Video"])
		cellClass = [JTVideoItemCell class];
	
	var mediaCell = [[cellClass alloc] initWithRepresentedObject:mediaItem];
	[mediaCell setControlView:mediaBrowserView];
	
	if ([[self filteredEntity] isEqualToString:@"Audio"])
		mediaCell.soundURL = [mediaItem mediaURL];
	
	if (![[self filteredEntity] isEqualToString:@"Photo"])
		mediaCell.displayTitle = YES;
	
	mediaCell.uniqueID = [mediaItem uid];
	return mediaCell;
}

- (BOOL)mediaItemReorderedFromIndexes:(CPIndexSet)dragIndexSet toIndex:(unsigned int)dropIndex
{
	var mediaItemsToMove = [[CPMutableArray alloc] init];
	var currentIndex = [dragIndexSet firstIndex];
	var adjustedDropIndex = dropIndex;
	
	while (currentIndex != CPNotFound) {
	
		if (currentIndex < dropIndex)
			adjustedDropIndex--;
		 	
		[mediaItemsToMove addObject:[[[self mediaItems] objectAtIndex:currentIndex] copy]];
		currentIndex = [dragIndexSet indexGreaterThanIndex:currentIndex]; 
	}
	
	[[self mediaItems] removeObjectsAtIndexes:dragIndexSet];
	
	for (var i = 0; i < [mediaItemsToMove count]; i++)
		[[self mediaItems] insertObject:[mediaItemsToMove objectAtIndex:i] atIndex:adjustedDropIndex + i];
			
	return YES;
}

- (BOOL)mediaBrowserShouldDeleteItemsAtIndexes:(CPIndexSet)indexes
{
	var sidebarViewController = [[[self detailViewController] masterViewController] sidebarViewController];
	var selectedObject = [sidebarViewController selectedObject];
	
	if ([selectedObject isKindOfClass:[MediaGroup class]])
	{
		for (var i=0;i<[[self mediaItems] count];i++)
		{
			if ([indexes containsIndex:i])
			{
				var mediaItem = [[self mediaItems] objectAtIndex:i];
				[selectedObject removeMediaItem:mediaItem];
			}
		}
		
		[[self mediaItems] removeObjectsAtIndexes:indexes];
		
		return YES;
	}
	return NO;
}

- (BOOL)mediaBrowserShouldAddMediaItems:(CPArray)addedMediaItems atIndex:(unsigned int)index
{
	for (var i = 0; i < [addedMediaItems count]; i++)
		[[self mediaItems] insertObject:[addedMediaItems objectAtIndex:i]  atIndex:index + i];
	
	return YES;
}

// Media Actions

/*- (void)controlTextDidChange:(CPNotification)notification
{
	if ([notification object] == filterTextField) {

		return;
		
		// And then there is a slight delay so that it doesn't refresh when typing fast
		if (filterDelayTimer != nil && [filterDelayTimer isValid])
			[filterDelayTimer invalidate];
			
		var filterString = [filterTextField stringValue];
		
		// In IKImageBrowser Apple sends the update immediately if the user supplies an empty filter string
		if ([filterString isEqualToString:@""]) {
			[self setFilterString:filterString];
			return;
		}
			
		filterDelayTimer = [CPTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(filterStringAdjustedAndDelayPassed:) userInfo:filterString repeats:NO];
	}
}*/

- (void)filterStringAdjustedAndDelayPassed:(var)timer
{
	[self setFilterString:[timer userInfo]];
}

- (void)toggledSourceMediaSorting:(var)sender
{
	if ([sender selectedSegment] == 0)
		[self sortMediaItemsWithKey:@"title" ascending:NO];
	else
		[self sortMediaItemsWithKey:@"title" ascending:YES];
}

@end

/*@implementation JTMediaItemOverlayView : CPView
{
	MDRadialControl	radialControl @accessors;
	CPTimer	mediaTimer;
}

- (id)initWithFrame:(CPRect)aFrame
{
	if (self = [super initWithFrame:aFrame])
	{
		hoverElement = document.createElement("div");
	    hoverElement.style.width  = "100%";
	    hoverElement.style.height = "100%";
		hoverElement.onmouseover = function(e){ [self mouseEntered:e]; };
		hoverElement.onmouseout = function(e) { [self mouseExited:e]; };
		_DOMElement.appendChild(hoverElement);
		
		radialControl = [[MDRadialControl alloc] initWithFrame:[self bounds]];
		[radialControl setTarget:self];
		[radialControl setAction:@selector(togglePreview:)];
		[radialControl setAutoresizingMask:CPViewMinXMargin|CPViewMaxXMargin|CPViewMinYMargin|CPViewMaxYMargin];
		[self addSubview:radialControl];
	}
	return self;
}

- (void)togglePreview:(id)sender
{
	
}

- (void)mouseEntered:(JSObject)mouseEvent
{
	//CPLog(@"enter: {%@,%@}",mouseEvent.pageX,mouseEvent.pageY);
	//[radialControl setHidden:NO];
}

- (void)mouseExited:(JSObject)mouseEvent
{
	//CPLog(@"exit: {%@,%@}",mouseEvent.pageX,mouseEvent.pageY);
	//[radialControl setHidden:YES];
}

@end

@implementation JTAudioItemOverlayView : JTMediaItemOverlayView
{
	FPSound	sound @accessors;
}

- (void)togglePreview:(id)sender
{
	if ([self.radialControl isRunning])
	{
		[self.mediaTimer invalidate];
		[sound pause];
	}
	else
	{
		self.mediaTimer = [CPTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
		[sound play];
	}
	[self.radialControl setRunning:![self.radialControl isRunning]];
}

- (void)willRemove
{
	[sound stop];
}

- (void)timerFired:(id)sender
{
	[self.radialControl setFloatValue:[[FPSoundManager sharedSoundManager] progress]];
}

@end

@implementation JTMovieItemOverlayView : JTMediaItemOverlayView
{
	DOMElement	hoverElement;
	FPMovieView	movieView @accessors;
	FPMovie		movie @accessors;
}

- (id)initWithFrame:(CPRect)aFrame
{
	if (self = [super initWithFrame:aFrame])
	{
		movieView = [[FPMovieView alloc] initWithFrame:[self bounds]];
		[movieView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
		[self addSubview:movieView positioned:CPWindowBelow relativeTo:self.radialControl];
	}
	return self;
}

- (void)willRemove
{
	[movieView stop:nil];
}

- (void)togglePreview:(id)sender
{
	CPLog(@"toggle");
	if ([self.radialControl isRunning])
	{
		//[self.mediaTimer invalidate];
		//[movieView pause];
	}
	else
	{
		[self.radialControl setAlphaValue:0.2];
		[movieView setMovie:movie];
		[movieView play:nil];
	}
	[self.radialControl setRunning:![self.radialControl isRunning]];
}

- (void)timerFired:(id)sender
{
	//[self.radialControl setFloatValue:[[FPSoundManager sharedSoundManager] progress]];
}

@end*/

@implementation JTPlayableMediaItemCell : JTMediaItemCell
{
	//BOOL showPlayButton;
	CPRect	circleRect @accessors;
	FPAnimation playButtonFadeInAnimation @accessors;
	double	buttonAlpha;
}

- (id)init
{
	if (self = [super init])
	{
		//showPlayButton = NO;
		buttonAlpha = 0.0;
	}
}

- (void)mouseEntered:(CPEvent)event
{
	[self fadeIn:nil];
}

- (void)mouseExited:(CPEvent)event
{
	[self fadeOut:nil];
}

- (void)fadeIn:(id)sender
{
	fadeIn = YES;
	buttonAlpha = 0.0;
	self.playButtonFadeInAnimation = [[FPAnimation alloc] initWithDuration:0.2 animationCurve:FPAnimationEaseInOut];
	[playButtonFadeInAnimation setDelegate:self];
	[playButtonFadeInAnimation startAnimation];
}

- (void)fadeOut:(id)sender
{
	fadeIn = NO;
	buttonAlpha = 1.0;
	self.playButtonFadeInAnimation = [[FPAnimation alloc] initWithDuration:0.2 animationCurve:FPAnimationEaseInOut];
	[playButtonFadeInAnimation setDelegate:self];
	[playButtonFadeInAnimation startAnimation];
}

- (void)animationFired:(FPAnimation)animation
{
	if (animation == playButtonFadeInAnimation)
	{
		var alphaValue = [animation currentValue];
		if (fadeIn)
			buttonAlpha = alphaValue;
		else
			buttonAlpha = 1.0 - alphaValue;
		[controlView setNeedsDisplay:YES];
	} else
		[super animationFired:animation];
}

- (void)animationFinished:(FPAnimation)animation
{
	if (animation == playButtonFadeInAnimation)
	{
		buttonAlpha = fadeIn?1.0:0.0;
		[controlView setNeedsDisplay:YES];
	} else
		[super animationFinished:animation];
}

- (void)drawWithFrame:(CPRect)frame inView:(CPView)view
{
	[super drawWithFrame:frame inView:view];
	
	circleRect = CPMakeRect(0,0,28,28);
	circleRect.origin.x = CGRectGetMidX(frame)-circleRect.size.width/2;
	circleRect.origin.y = CGRectGetMidY(imageRect)-circleRect.size.height/2;
	circleRect.origin.y += 2;
	
	if (buttonAlpha > 0.0)
		[self drawButtonWithFrame:circleRect fraction:buttonAlpha];
}

- (void)drawButtonWithFrame:(CPRect)aCircleRect fraction:(float)alpha
{
	var circlePath = [CPBezierPath bezierPathWithOvalInRect:aCircleRect];
	[[CPColor colorWithCalibratedWhite:0.0 alpha:0.8 * alpha] set];
	[circlePath fill];
	
	var arrowRect = CGRectInset(aCircleRect, 9, 8);
	arrowRect.origin.x++;
	var arrowPath = [CPBezierPath bezierPathWithArrowInRect:arrowRect direction:CPArrowDirectionRight];
	[[CPColor colorWithCalibratedWhite:1.0 alpha:1.0*alpha] set];
	[arrowPath fill];
	[circlePath setLineWidth:1.5];
	[circlePath stroke];
}

- (void)mouseDown:(CPEvent)mouseEvent
{
	var viewPoint = [controlView convertPoint:mouseEvent fromView:[[controlView window] contentView]];
	if (CGRectContainsPoint(circleRect,viewPoint))
		[self playMedia];
	else
		[super mouseDown:mouseEvent];
}

- (void)playMedia
{
	
}

@end

@implementation JTAudioItemCell : JTPlayableMediaItemCell
{
	CPURL soundURL @accessors;
}

- (void)playMedia
{
	var sound = [FPSound soundWithURL:soundURL];
	[sound play];
}

@end

@implementation JTVideoItemCell : JTPlayableMediaItemCell { }

@end