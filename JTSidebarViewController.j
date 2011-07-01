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

@import "JTMasterViewController.j"
@import "JTButtonBar.j"
@import "JTOutlineView.j"
@import "JTScrollView.j"
@import "JTToolbar.j"
@import "MediaLibrary.j"
@import "DocumentLibrary.j"

var BUTTONBAR_HEIGHT = 36;
var TOOLBAR_HEIGHT = 39;
var systemIcons = new Array();

function JTSystemIcon(iconName)
{
	if (systemIcons[iconName])
		return systemIcons[iconName];
	var iconPath = [CPString stringWithFormat:@"http://s3.amazonaws.com/davisml/system/icons/%@.png",iconName];
	var icon = [[CPImage alloc] initWithContentsOfFile:iconPath];
	
	/*try {
	    window.applicationCache.add(iconPath);
	} catch (e) {
	    if (e == DOMException)
	        CPLog(@"ERROR: Couldn't cache");
	}*/
	
	systemIcons[iconName] = icon;
	return icon;
}

@implementation JTSidebarViewController : FPViewController
{
	JTMasterViewController	masterViewController @accessors;
	JTButtonBar				buttonBar @accessors;
	JTOutlineView			outlineView @accessors;
	JTScrollView			scrollView;
	JTToolbar				toolbar @accessors;
	int						selectedRow;
	int						selectedSection;
	int						selectedSubRow;
}

- (void)loadView
{
	selectedRow = 0;
	selectedSection = 0;
	selectedSubRow = -1;
	
	var contentView = self.view;
	[contentView setBackgroundColor:[CPColor sidebarBackgroundColor]];
	
	toolbar = [[JTToolbar alloc] initWithFrame:CPMakeRect(0,0,CGRectGetWidth([contentView bounds]),TOOLBAR_HEIGHT)];
	[contentView addSubview:toolbar];
	
	var scrollViewFrame = CPRectCreateCopy([contentView bounds]);
	scrollViewFrame.origin.y += TOOLBAR_HEIGHT;
	scrollViewFrame.size.height -= TOOLBAR_HEIGHT;
	scrollView = [[JTScrollView alloc] initWithFrame:scrollViewFrame];
	[scrollView setAutoresizingMask:CPViewHeightSizable|CPViewWidthSizable];
	[scrollView setAutohidesScrollers:YES];
	[scrollView setScrollerBottomPadding:BUTTONBAR_HEIGHT];
	
    outlineView = [[JTOutlineView alloc] initWithFrame:[scrollView bounds]];
	var sectionCell = [[SidebarSectionCell alloc] init];
	[outlineView setSectionCell:sectionCell];
	[outlineView setDelegate:self];
	[outlineView setDataSource:self];
	outlineView.sectionHeight = 26;
	var rowCell = [[SidebarRowCell alloc] init];
	[outlineView setRowCell:rowCell];
	outlineView.rowHeight = 30;
	[outlineView setBackgroundColor:[contentView backgroundColor]];
	[scrollView setDocumentView:outlineView];
	[contentView addSubview:scrollView];
	[outlineView registerForDraggedTypes:[CPArray arrayWithObjects:@"JOURNALIST_MEDIA_ITEM_PBOARD_TYPE",@"JOURNALIST_SOURCE_ITEM_PBOARD_TYPE",nil]]
	
	buttonBar = [[JTButtonBar alloc] initWithFrame:CGRectMake(0,CGRectGetHeight([contentView bounds])-BUTTONBAR_HEIGHT,[contentView bounds].size.width,BUTTONBAR_HEIGHT)];
	[buttonBar setBlurColor:[CPColor sidebarBackgroundColor]];
	[buttonBar setShowsGrabber:YES];
	[outlineView setAutoresizingMask:CPViewMaxYMargin|CPViewWidthSizable];
	var addButton = [[JTAddButton alloc] initWithFrame:CGRectMake(0,0,40,BUTTONBAR_HEIGHT)];
	[buttonBar addSubview:addButton];
	[contentView addSubview:buttonBar];
	
	[[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(documentsLoaded:) name:@"JTDocumentLibraryDidLoadNotification" object:nil];
	[[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(mediaLoaded:) name:@"JTMediaLibraryDidLoadNotification" object:nil];
}

- (void)documentsLoaded:(id)sender
{
	[self reloadData];
	//[self mediaLoaded:nil];
}

- (void)mediaLoaded:(id)sender
{
	var selectionString = [[FPLocalStorage sharedLocalStorage] valueForKey:@"sidebarSelection"];
	if (selectionString != nil)
	{
		var components = [selectionString componentsSeparatedByString:@":"];
		selectedSection = [[components objectAtIndex:0] intValue];
		selectedRow = [[components objectAtIndex:1] intValue];
		selectedSubRow = [[components objectAtIndex:2] intValue];
	}
	
	[self reloadData];
	[masterViewController.detailViewController reloadData];
}

- (void)reloadData
{
	[outlineView reloadData];
	[outlineView selectRow:selectedRow subRow:selectedSubRow inSection:selectedSection];
}

- (CPString)selectedType
{
	if (selectedSection==0 && selectedRow == 0)
		return @"Media";
	else if (selectedSection==0 && selectedRow == 1)
		return @"Document";
	else if (selectedSection==1 && selectedRow == 0)
		return @"Store";
	return nil;
}

- (id)selectedObject
{
	if (selectedSection==0)
	{
		if (selectedRow == 0)
		{
			var mediaLibrary = [MediaLibrary sharedMediaLibrary];
			if (selectedSubRow>-1)
				return [[mediaLibrary mediaGroups] objectAtIndex:selectedSubRow];
			return mediaLibrary;
		}
		else if (selectedRow == 1)
		{
			var documentLibrary = [DocumentLibrary sharedDocumentLibrary];
			if (selectedSubRow>-1)
				return [[documentLibrary documentGroups] objectAtIndex:selectedSubRow];
			return documentLibrary;
		}
	}
	return nil;
}

- (id)selectedDetails
{
	var selectedObject = [self selectedObject];
	if (selectedSection ==0 && selectedObject != nil)
	{
		if (selectedRow == 0) {
			CPLog(@"returning mediaItems");
			return [[self selectedObject] mediaItems];
		} else if (selectedRow == 1)
			return [[self selectedObject] documentItems];
	}
	return [CPMutableArray array];
}

- (void)viewDidLoad
{
	[self reloadData];
}

// Outline View

- (void)outlineView:(JTOutlineView)aOutlineView willDisplayCell:(id)cell forRow:(int)row subRow:(int)subRowOrNegativeOne inSection:(int)section
{
	if (section==0)
	{
		if (subRowOrNegativeOne>-1)
			cell.image = JTSystemIcon("folder");
		else if (row==0)
			cell.image = JTSystemIcon("media");
		else if (row==1)
			cell.image = JTSystemIcon("posts");
	} else if (section==1)
	{
		cell.image = JTSystemIcon("globe");
	}
	
	if ([cell.image loadStatus]!=CPImageLoadStatusCompleted)
		[cell.image setDelegate:self];
}

- (void)imageDidLoad:(CPImage)image
{
	[self reloadData];
}

- (unsigned int)numberOfSectionsInOutlineView:(JTOutlineView)aOutlineView 
{
	return 2;
}

- (unsigned int)outlineView:(JTOutlineView)aOutlineView numberOfRowsInSection:(unsigned int)section 
{
	if (section == 0)
		return 2;
	else if (section == 1)
		return 1;	
			
	return 0;
}

- (CPString)outlineView:(JTOutlineView)aOutlineView titleForSection:(unsigned int)section 
{
	if (section == 0)
		return @"Library";
	else if (section == 1)
		return @"Published";
	
	return @"";
}

- (CPString)outlineView:(JTOutlineView)aOutlineView titleForRow:(unsigned int)row section:(unsigned int)section
{
	if (section == 0)
	{
		if (row == 0)
			return @"Media";
		else if (row == 1)
			return @"Documents";
	}
	else if (section == 1)
	{
		if (row == 0)
			return @"Mark Davis";
	}
}

- (unsigned int)outlineView:(JTOutlineView)aOutlineView numberOfSubRowsInRow:(unsigned int)row section:(unsigned int)section
{
	if (section == 0)
	{
		if (row == 0)
			return [[[MediaLibrary sharedMediaLibrary] mediaGroups] count];
		else
			return [[[DocumentLibrary sharedDocumentLibrary] documentGroups] count];
	}
	
	if (section == 2)
		return 1;
		
	return 0;
}

- (CPString)outlineView:(JTOutlineView)aOutlineView titleForSubRow:(unsigned int)subRow parentRow:(unsigned int)parentRow section:(unsigned int)section
{
	if (section == 0)
	{
		var groups = (parentRow == 0)?[[MediaLibrary sharedMediaLibrary] mediaGroups]:[[DocumentLibrary sharedDocumentLibrary] documentGroups];
		return [[groups objectAtIndex:subRow] name];
	}
	return @"";
}

- (void)outlineView:(JTOutlineView)aOutlineView didSelectRow:(unsigned int)row subRow:(unsigned int)subRowOrNegativeOne inSection:(unsigned int)section
{
	selectedSection = section;
	selectedRow = row;
	selectedSubRow = subRowOrNegativeOne;
	
	var selectionValue = [CPString stringWithFormat:@"%d:%d:%d",selectedSection,selectedRow,selectedSubRow];
	[[FPLocalStorage sharedLocalStorage] setValue:selectionValue forKey:@"sidebarSelection"];
	
	//if (section==0 && row==0)
	[masterViewController.detailViewController reloadData];
	//CPLog(@"selected row %i sub row %i in section %i",row,subRowOrNegativeOne,section);
}

- (BOOL)outlineView:(JTOutlineView)aOutlineView shouldAcceptDropOnRow:(unsigned int)rowIndex subRow:(unsigned int)subRowIndexOrNegativeOne inSection:(unsigned int)sectionIndex
{
	return (sectionIndex == 1 || sectionIndex == 0);
}

- (void)outlineView:(JTOutlineView)aOutlineView didAcceptDropOnRow:(unsigned int)rowIndex subRow:(unsigned int)subRowIndexOrNegativeOne inSection:(unsigned int)section sender:(var)sender
{
	//CPLog([[sender draggingPasteboard] description]);
	//CPLog([sender description]);
	var mediaIDs = [[sender draggingPasteboard] dataForType:@"JOURNALIST_MEDIA_ITEM_PBOARD_TYPE"];
	
	for (var i=0;i<[mediaIDs count];i++)
	{
		var mediaID = [mediaIDs objectAtIndex:i];
		var mediaItem = [[MediaLibrary sharedMediaLibrary] mediaItemWithID:mediaID];
		
		if (section==0 && rowIndex==0 && subRowIndexOrNegativeOne>-1)
		{
			var group = [[[MediaLibrary sharedMediaLibrary] mediaGroups] objectAtIndex:subRowIndexOrNegativeOne];
			[group addMediaItem:mediaItem];
		}
	}
	
	//CPLog(@"pasteboard data: %@",data);
	//CPLog(@"Outline view accepted drop %i %i %i",section,rowIndex,subRowIndexOrNegativeOne);
}

- (BOOL)outlineView:(JTOutlineView)aOutlineView shouldAllowDragFromRow:(unsigned int)rowIndex subRow:(unsigned int)subRowIndexOrNegativeOne inSection:(unsigned int)section
{
	return rowIndex == 1;
}

@end

@implementation SidebarSectionCell : FPCell {}

- (void)drawWithFrame:(CGRect)frame inView:(CPView)view
{
	[CPGraphicsContext saveGraphicsState];
	[[FPShadow shadowWithOffset:CPMakePoint(0,-1) blur:1 color:[CPColor colorWithCalibratedWhite:0.0 alpha:0.5]] set];
	if ([representedObject expandable])
	{
		[[CPColor colorWithCalibratedWhite:0.6 alpha:0.8] set];
		var arrowRect = CPRectCreateCopy(frame);
		var arrowSize = CPMakeSize(5,7);
		arrowRect.size.height = [representedObject expanded]?arrowSize.width:arrowSize.height;
		arrowRect.size.width = [representedObject expanded]?arrowSize.height:arrowSize.width;
		arrowRect.origin.x += 7.0;
		arrowRect.origin.y += 11.0;
		if (![representedObject expanded]) { arrowRect.origin.y--; arrowRect.origin.x++; }
		[[CPBezierPath bezierPathWithArrowInRect:arrowRect direction:[representedObject expanded]?CPArrowDirectionDown:CPArrowDirectionRight] fill];
	}
	
	var textOrigin = CPRectCreateCopy(frame).origin;
	textOrigin.x += 20.0;
	textOrigin.y += 8.0;
	[[CPColor colorWithCalibratedWhite:0.55 alpha:1.0] set];
	[[[representedObject title] uppercaseString] drawAtPoint:textOrigin withFont:[CPFont boldSystemFontOfSize:11.0]];
	[CPGraphicsContext restoreGraphicsState];
}

@end

@implementation SidebarRowCell : FPCell
{
	CPImage image @accessors;
}

- (void)drawWithFrame:(CGRect)frame inView:(CPView)view
{
	var isSubRow = (frame.origin.x > 40);
	
	frame.origin.y += frame.size.height;
	
	var imagePoint = CPRectCreateCopy(frame).origin;
	imagePoint.x += 12;
	imagePoint.y -= 25;
	[image drawAtPoint:imagePoint fraction:1.0];
	
	var arrowRect = nil;
	if ([representedObject expandable])
	{
		var arrowRect = CPRectCreateCopy(frame);
		var arrowSize = CPMakeSize(5,7);
		arrowRect.size.height = [representedObject expanded]?arrowSize.width:arrowSize.height;
		arrowRect.size.width = [representedObject expanded]?arrowSize.height:arrowSize.width;
		//arrowRect.origin.x = 35.0;
		arrowRect.origin.y -= 17.0;
		//arrowRect.origin.y += 11.0;
		if (![representedObject expanded]) { arrowRect.origin.y--; arrowRect.origin.x++; }
		arrowRect = [CPBezierPath bezierPathWithArrowInRect:arrowRect direction:[representedObject expanded]?CPArrowDirectionDown:CPArrowDirectionRight];
	}
	
	[CPGraphicsContext saveGraphicsState];
	[[FPShadow shadowWithOffset:CPMakePoint(0,-1) blur:1 color:[CPColor colorWithCalibratedWhite:0.0 alpha:0.5]] set];
	if (arrowRect != nil)
	{
		[[CPColor colorWithCalibratedWhite:0.6 alpha:0.8] set];
		[arrowRect fill];
	}
	
	[[CPColor colorWithCalibratedWhite:0.7 alpha:1.0] set];
	var titlePoint = CPRectCreateCopy(frame).origin;
	titlePoint.y -= 21;
	titlePoint.x += 41;
	[[representedObject title] drawAtPoint:titlePoint withFont:[CPFont systemFontOfSize:13.0]];
	[CPGraphicsContext restoreGraphicsState];
}

@end