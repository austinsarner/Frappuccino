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

@import "JTTextField.j"

/* Internal Proxy */

@implementation JTOutlineViewRepresentedItem : CPObject
{
	CPString title @accessors;
	
	BOOL expanded @accessors;
	BOOL expandable @accessors;
	BOOL selected @accessors;
	BOOL animating @accessors;
	
	CPArray representedItems @accessors;
	
	CGRect displayFrame @accessors;
	float displayYIgnoringAnimation @accessors;
}

- (id)init
{
	if (self = [super init]) {
		
		animating = NO;
		selected = NO;
		
		return self;
	}
	
	return nil;
}

@end

/* Default Dragging View */
@implementation JTOutlineViewDraggingView : CPView
{
	FPCell draggingCell @accessors;
	var representedItem @accessors;
	
	var delegate @accessors;
	
	unsigned int section @accessors;
	unsigned int row @accessors;
	unsigned int subRow @accessors;
}

- (void)drawRect:(CGRect)rect
{
	[draggingCell setRepresentedObject:representedItem];
	
	[delegate outlineView:self willDisplayCell:draggingCell forRow:row subRow:subRow inSection:section];
	[draggingCell drawWithFrame:[self bounds] inView:self];
}

@end

/* Data Source Protocol */

@implementation CPObject (JTOutlineViewDataSource)

/* @required */

- (unsigned int)numberOfSectionsInOutlineView:(JTOutlineView)outlineView {}
- (unsigned int)outlineView:(JTOutlineView)outlineView numberOfRowsInSection:(unsigned int)section {}
- (unsigned int)outlineView:(JTOutlineView)outlineView numberOfSubRowsInRow:(unsigned int)row section:(unsigned int)section {}

- (CPString)outlineView:(JTOutlineView)outlineView titleForSection:(unsigned int)section {}
- (CPString)outlineView:(JTOutlineView)outlineView titleForRow:(unsigned int)row section:(unsigned int)section {}
- (CPString)outlineView:(JTOutlineView)outlineView titleForSubRow:(unsigned int)subRow parentRow:(unsigned int)parentRow section:(unsigned int)section {}

/* @optional */

@end

/* Delegate Protocol */

@implementation CPObject (JTOutlineViewDelegate)

/* @required when dragging destination */

- (BOOL)outlineView:(JTOutlineView)outlineView shouldAcceptDropOnRow:(unsigned int)rowIndex subRow:(unsigned int)subRowIndexOrNegativeOne inSection:(unsigned int)section {}
- (void)outlineView:(JTOutlineView)outlineView didAcceptDropOnRow:(unsigned int)rowIndex subRow:(unsigned int)subRowIndexOrNegativeOne inSection:(unsigned int)section sender:(var)sender {}

/* @requireud when dragging source */

- (BOOL)outlineView:(JTOutlineView)outlineView shouldAllowDragFromRow:(unsigned int)rowIndex subRow:(unsigned int)subRowIndexOrNegativeOne inSection:(unsigned int)section {}

/* @optional */

- (void)outlineView:(JTOutlineView)outlineView didSelectRow:(unsigned int)row subRow:(unsigned int)subRowOrNegativeOne inSection:(unsigned int)section {}
- (void)outlineView:(JTOutlineView)outlineView willDisplayCell:(id)cell forRow:(unsigned int)row subRow:(unsigned int)subRowOrNegativeOne inSection:(unsigned int)section {}

@end

var DEFAULT_BACKGROUND_COLOR = [CPColor colorWithCalibratedRed:0.837 green:0.867 blue:0.900 alpha:1.000];
var DEFAULT_ROW_HEIGHT = 18.0;
var DEFAULT_SECTION_HEIGHT = 20.0;

@implementation JTOutlineView : FPView
{
	id /*<JTOutlineViewDataSource>*/ dataSource @accessors;
	id /*<JTOutlineViewDelegate>*/ delegate @accessors;
	
	CPMutableArray sections;
	
	JTTextField textField @accessors;
	CPColor backgroundColor @accessors;
	
	float rowHeight @accessors;
	float sectionHeight @accessors;
	
	float rowIndentWidth @accessors;
	float subRowIndentWidth @accessors;
	
	unsigned int dropSection;
	unsigned int dropRow;
	unsigned int dropSubRow;
	
	unsigned int clickedSection;
	unsigned int clickedRow;
	unsigned int clickedSubRow;
	
	FPCell sectionCell @accessors;
	FPCell rowCell @accessors;
	
	var clickedRowRepresentedItem;
	
	// Animated Expanding
	unsigned int expandingSection;
	unsigned int expandingRow;
	float heightToCollapse;
	float animatedSectionAlpha;
	
	FPAnimation expandAnimation;
	BOOL animatingCollapse;
	BOOL performingAnimatingExpandOnSection;
	BOOL performingAnimatingExpandOnRow;
}

- (void)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		textField = [JTTextField textFieldWithStringValue:@"Barcelona" placeholder:@"" width:CGRectGetWidth(frame)];
		[textField setHidden:YES];
		[textField setFont:[CPFont systemFontOfSize:13.0]];
		[self addSubview:textField];
		
		performingAnimatingExpandOnSection = NO;
		performingAnimatingExpandOnRow = NO;
		animatingCollapse = NO;
		
		backgroundColor = DEFAULT_BACKGROUND_COLOR;
		
		rowHeight = DEFAULT_ROW_HEIGHT;
		sectionHeight = DEFAULT_SECTION_HEIGHT;
		
		rowIndentWidth = 20.0;
		subRowIndentWidth = 40.0;
		
		dropSection = -1;
		dropRow = -1;
		dropSubRow = -1;
		
		sectionCell = [[FPCell alloc] init];
		rowCell = [[FPCell alloc] init];
		
		sections = [[CPMutableArray alloc] init]
		
		return self;
	}
	
	return nil;
}

- (void)setRowHeight:(float)newRowHeight
{
	rowHeight = newRowHeight;
	[self layout];
}

- (void)setSectionHeight:(float)newSectionHeight
{
	sectionHeight = newSectionHeight;
	[self layout];
}

- (void)layout
{
	var frame = CPRectCreateCopy([self frame]);
	var currentCellDisplayFrame = CGRectMake(0.0,0.0,frame.size.width,0.0);
	
	for (var sectionIndex = 0; sectionIndex < [sections count]; sectionIndex++) {
		
		currentCellDisplayFrame.origin.x = 0.0;
		currentCellDisplayFrame.size.width = frame.size.width;
		currentCellDisplayFrame.size.height = sectionHeight;
				
		var section = [sections objectAtIndex:sectionIndex];
		[section setDisplayFrame:CPRectCreateCopy(currentCellDisplayFrame)];
		[section setDisplayYIgnoringAnimation:currentCellDisplayFrame.origin.y];

		currentCellDisplayFrame.origin.y += sectionHeight;
		
		if (![section expanded])
			continue;
			
		var rows = [section representedItems];
		for (var rowIndex = 0; rowIndex < [rows count]; rowIndex++) {
			
			currentCellDisplayFrame.origin.x = rowIndentWidth;
			currentCellDisplayFrame.size.width = frame.size.width - rowIndentWidth;
			currentCellDisplayFrame.size.height = rowHeight;
						
			var row = [rows objectAtIndex:rowIndex];
			[row setDisplayFrame:CPRectCreateCopy(currentCellDisplayFrame)];
			[row setDisplayYIgnoringAnimation:currentCellDisplayFrame.origin.y];
			
			currentCellDisplayFrame.origin.y += rowHeight;
									
			if ([row expandable] && [row expanded]) {

				var subRows = [row representedItems];
				for (var subRowIndex = 0; subRowIndex < [subRows count]; subRowIndex++) {

					currentCellDisplayFrame.origin.x = subRowIndentWidth;
					currentCellDisplayFrame.size.width = frame.size.width - subRowIndentWidth;
					currentCellDisplayFrame.size.height = rowHeight;
								
					var subRow = [subRows objectAtIndex:subRowIndex];
					[subRow setDisplayFrame:CPRectCreateCopy(currentCellDisplayFrame)];
					[subRow setDisplayYIgnoringAnimation:currentCellDisplayFrame.origin.y];
					
					currentCellDisplayFrame.origin.y += rowHeight;
				}

			} else
				continue;
		}
	}
	
	var height = currentCellDisplayFrame.origin.y;
	
	if (height > [[self enclosingScrollView] frame].size.height)
		frame.size.height = height;
	else
		frame.size.height = [[self enclosingScrollView] frame].size.height;
		
	[self setFrame:frame];
	[self setNeedsDisplay:YES];
}

- (void)drawSelectionInFrame:(CGRect)frame
{
	var selectionRect = CPRectCreateCopy(frame);
	selectionRect.size.width = [self frame].size.width;
	selectionRect.origin.x = 0.0;
	selectionRect.origin.y += 1.0;
	selectionRect.size.height -= 1.0;
	
	var linearGradient = [[FPGradient alloc] initWithStartingColor:[CPColor colorWithCalibratedWhite:0 alpha:0.02] endingColor:[CPColor colorWithCalibratedWhite:0 alpha:0.12]];
	[linearGradient drawInRect:selectionRect angle:90];
	
	[[CPColor colorWithCalibratedWhite:0.0 alpha:0.2] set];
	[CPBezierPath fillRect:CPMakeRect(0,selectionRect.origin.y,selectionRect.size.width,1)];
	[[CPColor colorWithCalibratedWhite:0.0 alpha:0.3] set];
	[CPBezierPath fillRect:CPMakeRect(0,CGRectGetMaxY(frame),selectionRect.size.width,1)];
	[[CPColor colorWithCalibratedWhite:1.0 alpha:0.05] set];
	[CPBezierPath fillRect:CPMakeRect(0,selectionRect.origin.y+1,selectionRect.size.width,1)];
}

- (void)drawDropHighlightInFrame:(CGRect)frame
{
	var highlightRect = CPRectCreateCopy(frame);
	highlightRect.size.width = [self frame].size.width - 4.0;
	highlightRect.origin.x = 2.0;
	highlightRect.origin.y += 1.0;
	highlightRect.size.height -= 1.0;
	
	var highlightPath = [CPBezierPath bezierPath];
	[highlightPath appendBezierPathWithRoundedRect:highlightRect xRadius:6.0 yRadius:6.0];
	[highlightPath setLineWidth:2.0];
	
	[[[CPColor whiteColor] colorWithAlphaComponent:0.15] set];
	[highlightPath fill];
	
	[[CPColor whiteColor] set];
	[highlightPath stroke];
}

- (void)drawRect:(CGRect)rect
{			
	[backgroundColor set];
	[CPBezierPath fillRect:rect];
	var ctx = [[CPGraphicsContext currentContext] graphicsPort];
	
	for (var sectionIndex = 0; sectionIndex < [sections count]; sectionIndex++) {
				
		var section = [sections objectAtIndex:sectionIndex];
		[sectionCell setRepresentedObject:section];
		[sectionCell drawWithFrame:CPRectCreateCopy([section displayFrame]) inView:self];
		
		var animatedExpandOnThisSection = (performingAnimatingExpandOnSection && sectionIndex == expandingSection);
		if (![section expanded] && !animatedExpandOnThisSection)
			continue;
		
		if (animatedExpandOnThisSection) {
			ctx.globalAlpha = animatedSectionAlpha;		
		}	
		
		var rows = [section representedItems];
		for (var rowIndex = 0; rowIndex < [rows count]; rowIndex++) {
			
			var row = [rows objectAtIndex:rowIndex];
			var displayFrame = CPRectCreateCopy([row displayFrame]);
			
			if ([row selected])
				[self drawSelectionInFrame:displayFrame];
				
			if (dropSection == sectionIndex && dropRow == rowIndex && dropSubRow == -1)
				[self drawDropHighlightInFrame:displayFrame];
			
			[delegate outlineView:self willDisplayCell:rowCell forRow:rowIndex subRow:-1 inSection:sectionIndex];
			[rowCell setRepresentedObject:row];
			[rowCell drawWithFrame:displayFrame inView:self];
									
			if ([row expandable] && [row expanded]) {

				var subRows = [row representedItems];
					
				for (var subRowIndex = 0; subRowIndex < [subRows count]; subRowIndex++) {
								
					var subRow = [subRows objectAtIndex:subRowIndex];
					var subRowDisplayFrame = CPRectCreateCopy([subRow displayFrame]);
					
					if ([subRow selected])
						[self drawSelectionInFrame:subRowDisplayFrame];
					
					if (dropSection == sectionIndex && dropRow == rowIndex && dropSubRow == subRowIndex)
						[self drawDropHighlightInFrame:subRowDisplayFrame];
					
					[delegate outlineView:self willDisplayCell:rowCell forRow:rowIndex subRow:subRowIndex inSection:sectionIndex];
					[rowCell setRepresentedObject:subRow];
					[rowCell drawWithFrame:subRowDisplayFrame inView:self];
				}

			} else
				continue;
		}
		
		if (animatedExpandOnThisSection) {
			ctx.globalAlpha = 1.0;		
		}
	}
}

- (void)reloadData
{		
	if (dataSource == nil) {
		CPLog(@"JTOutlineView: dataSource not specified")
		return;
	}
		
	[sections removeAllObjects];
	
	for (var sectionIndex = 0; sectionIndex < [dataSource numberOfSectionsInOutlineView:self]; sectionIndex++) {
		
		var section = [[JTOutlineViewRepresentedItem alloc] init];
		[section setTitle:[dataSource outlineView:self titleForSection:sectionIndex]];
		[section setExpandable:YES];
		[section setExpanded:YES];
						
		var rows = [[CPMutableArray alloc] init];
		for (var rowIndex = 0; rowIndex < [dataSource outlineView:self numberOfRowsInSection:sectionIndex]; rowIndex++) {
			
			var row = [[JTOutlineViewRepresentedItem alloc] init];
			[row setTitle:[dataSource outlineView:self titleForRow:rowIndex section:sectionIndex]];
			
			var numberOfSubRows = [dataSource outlineView:self numberOfSubRowsInRow:rowIndex section:sectionIndex];
			
			if (numberOfSubRows > 0) {
				[row setExpandable:YES];
				[row setExpanded:YES];
				
				var subRows = [[CPMutableArray alloc] init];
				for (var subRowIndex = 0; subRowIndex < numberOfSubRows; subRowIndex++) {
					
					var subRow = [[JTOutlineViewRepresentedItem alloc] init];
					
					[subRow setTitle:[dataSource outlineView:self titleForSubRow:subRowIndex parentRow:rowIndex section:sectionIndex]];
					[subRow setExpanded:NO];
					[subRow setExpandable:NO];
					
					[subRows addObject:subRow];
				}
				
				[row setRepresentedItems:subRows];
				
			} else {
				[row setExpandable:NO];
				[row setExpanded:NO];
			}
			
			[rows addObject:row];
		}
		
		[section setRepresentedItems:rows];
		[sections addObject:section];
	}
		
	[self layout];
}

- (void)mouseDragged:(CPEvent)event
{
	if (delegate == nil || ![delegate outlineView:self shouldAllowDragFromRow:clickedRow subRow:clickedSubRow inSection:clickedSection])
		return;
		
	var pasteboard = [CPPasteboard pasteboardWithName:CPDragPboard];
	[pasteboard declareTypes:[CPArray arrayWithObject:@"JOURNALIST_SOURCE_ITEM_PBOARD_TYPE"] owner:self];
	
	var draggingView = [[JTOutlineViewDraggingView alloc] init];
	[draggingView setRepresentedItem:clickedRowRepresentedItem];
	[draggingView setDraggingCell:rowCell];
	[draggingView setDelegate:delegate];
	[draggingView setSection:clickedSection];
	[draggingView setRow:clickedRow];
	[draggingView setSubRow:clickedSubRow];
	
	var clickedRowDisplayFrame = [clickedRowRepresentedItem displayFrame];
	[draggingView setFrame:CGRectMake(0.0,0.0,clickedRowDisplayFrame.size.width,clickedRowDisplayFrame.size.height)];
	
	[self dragView:draggingView at:CGPointMake([self frame].origin.x + clickedRowDisplayFrame.origin.x,[self frame].origin.y + clickedRowDisplayFrame.origin.y) offset:CGSizeMakeZero() event:event pasteboard:pasteboard source:self slideBack:YES];
}

- (void)mouseDown:(CPEvent)event
{
	clickedSection = -1;
	clickedRow = -1;
	clickedSubRow = -1;
	
	//if (performingAnimatingExpandOnSection || performingAnimatingExpandOnRow)
		//return;
	
	var mouseLocation = [self convertPoint:[event locationInWindow] fromView:[[self window] contentView]];
	
	for (var sectionIndex = 0; sectionIndex < [sections count]; sectionIndex++) {
		
		var section = [sections objectAtIndex:sectionIndex];
		if (CGRectContainsPoint([section displayFrame],mouseLocation)) {
			
			[section setExpanded:![section expanded]];
			[self layout];
			/*performingAnimatingExpandOnSection = YES;
			expandingSection = sectionIndex;
			heightToCollapse = 0;
			animatingCollapse = [section expanded];
				
			var rows = [section representedItems];
			for (var rowIndex = 0; rowIndex < [rows count]; rowIndex++) {
				heightToCollapse += rowHeight;
				
				var row = [rows objectAtIndex:rowIndex];
				[row setAnimating:YES];
				
				if ([row expandable] && [row expanded]) {
					
					var subRows = [row representedItems];
					for (var subRowIndex = 0; subRowIndex < [subRows count]; subRowIndex++) {
						heightToCollapse += rowHeight;
						[[subRows objectAtIndex:subRowIndex] setAnimating:YES];
					}
				}
			}
			
			expandAnimation = [[FPAnimation alloc] initWithDuration:0.35 animationCurve:FPAnimationEaseInOut];
			[expandAnimation setDelegate:self];
			[expandAnimation startAnimation]; */
			
			break;
		}
		
		if (![section expanded])
			continue;
			
		var rows = [section representedItems];
		for (var rowIndex = 0; rowIndex < [rows count]; rowIndex++) {
		
			var row = [rows objectAtIndex:rowIndex];
			if (CGRectContainsPoint([row displayFrame],mouseLocation)) {
			
				var adjustedMouseLocationX = mouseLocation.x - [row displayFrame].origin.x;
				
				if ([row expandable] && adjustedMouseLocationX < 18.0) {
					[row setExpanded:![row expanded]];
					[self layout];
				} else {
					[self deselectAllItems];
					[row setSelected:YES];
					
					clickedSection = sectionIndex;
					clickedRow = rowIndex;
					clickedRowRepresentedItem = row;
					
					[self setNeedsDisplay:YES];
					if (delegate != nil)
						[delegate outlineView:self didSelectRow:rowIndex subRow:-1 inSection:sectionIndex];
				}
			
				break;
			}
			
			if ([row expandable] && [row expanded]) {
				var subRows = [row representedItems];
				for (var subRowIndex = 0; subRowIndex < [subRows count]; subRowIndex++) {
					
					var subRow = [subRows objectAtIndex:subRowIndex];
					
					if (CGRectContainsPoint([subRow displayFrame],mouseLocation)) {
						[self deselectAllItems];
						[subRow setSelected:YES];
						
						clickedSection = sectionIndex;
						clickedRow = rowIndex;
						clickedSubRow = subRowIndex;
						clickedRowRepresentedItem = subRow;
						
						[self setNeedsDisplay:YES];
						if (delegate != nil)
							[delegate outlineView:self didSelectRow:rowIndex subRow:subRowIndex inSection:sectionIndex];
					}
				}
			}
		}
	}
	
	if ([event clickCount] == 2)
	{
		[self _showFieldEditor];
		[[self window] makeFirstResponder:textField];
		[textField selectAll:nil];
	}
}

- (void)_showFieldEditor
{
	if (clickedSubRow > -1)
	{
		var section = [sections objectAtIndex:clickedSection];
		var row = [[section representedItems] objectAtIndex:clickedRow];
		var subRow = [[row representedItems] objectAtIndex:clickedSubRow];
		
		[textField setStringValue:[subRow title]];
		
		var textFieldFrame = CPRectCreateCopy([subRow displayFrame]);
		textFieldFrame.origin.x += 35;
		textFieldFrame.size.width -= 35;
		[textField setFrame:textFieldFrame];
		[textField setHidden:NO];
	}
}

- (void)animationFired:(FPAnimation)animation
{
	var currentProgress = [animation currentValue];

	if (animation == expandAnimation) {
		
		if (performingAnimatingExpandOnSection) {
			
			if (animatingCollapse)
				animatedSectionAlpha = 1.0 - currentProgress;
			else
				animatedSectionAlpha = currentProgress;
				
			for (var sectionIndex = expandingSection + 1; sectionIndex < [sections count]; sectionIndex++) {
				
				var section = [sections objectAtIndex:sectionIndex];
				
				if (animatingCollapse)
					[section displayFrame].origin.y = [section displayYIgnoringAnimation] - (currentProgress * heightToCollapse);
				else
					[section displayFrame].origin.y = [section displayYIgnoringAnimation] + (currentProgress * heightToCollapse);
				
				var rows = [section representedItems];
				for (var rowIndex = 0; rowIndex < [rows count]; rowIndex++) {
					
					var row = [rows objectAtIndex:rowIndex];
					
					if (animatingCollapse)
						[row displayFrame].origin.y = [row displayYIgnoringAnimation] - (currentProgress * heightToCollapse);
					else
						[row displayFrame].origin.y = [row displayYIgnoringAnimation] + (currentProgress * heightToCollapse);
					
					if ([row expandable] && [row expanded]) {
						
						var subRows = [row representedItems];
						for (var subRowIndex = 0; subRowIndex < [subRows count]; subRowIndex++) {
							
							var subRow = [subRows objectAtIndex:subRowIndex];
							
							if (animatingCollapse)
								[subRow displayFrame].origin.y = [subRow displayYIgnoringAnimation] - (currentProgress * heightToCollapse);
							else
								[subRow displayFrame].origin.y = [subRow displayYIgnoringAnimation] + (currentProgress * heightToCollapse);
						}
					}
				}
			}
			
			[self setNeedsDisplay:YES];
		}
	}
}

- (void)animationFinished:(FPAnimation)animation
{
	if (animation == expandAnimation) {
		
		if (performingAnimatingExpandOnSection) {
			
			[[sections objectAtIndex:expandingSection] setExpanded:!animatingCollapse];
			[self layout];
		}
		
		performingAnimatingExpandOnSection = NO;
		performingAnimatingExpandOnRow = NO;
		animatingCollapse = NO;
	}
}

- (void)setRowExpanded:(BOOL)expanded atIndex:(unsigned int)rowIndex inSection:(unsigned int)sectionIndex
{
	[[[[sections objectAtIndex:sectionIndex] representedItems] objectAtIndex:rowIndex] setExpanded:expanded];
	
	[self layout];
}

- (void)setSectionExpanded:(BOOL)expanded atIndex:(unsigned int)sectionIndex
{
	[[sections objectAtIndex:sectionIndex] setExpanded:expanded];
	
	[self layout];
}

- (void)selectRow:(unsigned int)rowIndex subRow:(unsinged int)subRowIndexOrNegativeOne inSection:(unsigned int)sectionIndex
{
	[self deselectAllItems];
	
	var row = [[[sections objectAtIndex:sectionIndex] representedItems] objectAtIndex:rowIndex];
	if (subRowIndexOrNegativeOne != -1)
		row = [[row representedItems] objectAtIndex:subRowIndexOrNegativeOne];
		
	[row setSelected:YES];
	[self setNeedsDisplay:YES];
}

- (void)deselectAllItems
{
	for (var sectionIndex = 0; sectionIndex < [sections count]; sectionIndex++) {
		
		var section = [sections objectAtIndex:sectionIndex];
		[section setSelected:NO];
		
		var rows = [section representedItems];
		for (var rowIndex = 0; rowIndex < [rows count]; rowIndex++) {
			
			var row = [rows objectAtIndex:rowIndex];
			[row setSelected:NO];
			
			if ([row expandable]) {

				var subRows = [row representedItems];
				for (var subRowIndex = 0; subRowIndex < [subRows count]; subRowIndex++)
					[[subRows objectAtIndex:subRowIndex] setSelected:NO];
			}
		}
	}
}

- (CPDragOperation)draggingEntered:(var)sender
{		
	if (delegate == nil)
		return CPDragOperationNone;
	
	dropSection = -1;
	dropRow = -1;
	dropSubRow = -1;
		
	var location = [self convertPoint:[sender draggingLocation] fromView:nil];
	
	return CPDragOperationCopy;
}

- (CPDragOperation)draggingExited:(var)sender
{	
	if (delegate == nil)
		return CPDragOperationNone;
		
	dropSection = -1;
	dropRow = -1;
	dropSubRow = -1;
	
	[self setNeedsDisplay:YES];
		
	return CPDragOperationNone;
}

- (CPDragOperation)draggingUpdated:(var)sender
{	
	if (delegate == nil)
		return CPDragOperationNone;
		
	var mouseLocation = [self convertPoint:[sender draggingLocation] fromView:nil];
	
	dropSection = -1;
	dropRow = -1;
	dropSubRow = -1;
	
	for (var sectionIndex = 0; sectionIndex < [sections count]; sectionIndex++) {
		
		var section = [sections objectAtIndex:sectionIndex];
		
		if (![section expanded])
			continue;
			
		var rows = [section representedItems];
		for (var rowIndex = 0; rowIndex < [rows count]; rowIndex++) {
			
			var row = [rows objectAtIndex:rowIndex];
						
			if (CGRectContainsPoint([row displayFrame],mouseLocation) && [delegate outlineView:self shouldAcceptDropOnRow:rowIndex subRow:-1 inSection:sectionIndex]) {
				dropSection = sectionIndex;
				dropRow = rowIndex;
				dropSubRow = -1;
				[self setNeedsDisplay:YES];
				return CPDragOperationCopy;
			}

			if (![row expanded])
				continue;
			
			var subRows = [row representedItems];
			for (var subRowIndex = 0; subRowIndex < [subRows count]; subRowIndex++) {
			
				var subRow = [subRows objectAtIndex:subRowIndex];
				
				if (CGRectContainsPoint([subRow displayFrame],mouseLocation) && [delegate outlineView:self shouldAcceptDropOnRow:rowIndex subRow:subRowIndex inSection:sectionIndex]) {
					dropSection = sectionIndex;
					dropRow = rowIndex;
					dropSubRow = subRowIndex;
					[self setNeedsDisplay:YES];
					return CPDragOperationCopy;
				}
			}
		}
	}
	
	[self setNeedsDisplay:YES];
	
	return CPDragOperationNone;
}

- (BOOL)performDragOperation:(var)sender
{	
	if (delegate == nil)
		return NO;
		
	if (dropRow != -1)
		[delegate outlineView:self didAcceptDropOnRow:dropRow subRow:dropSubRow inSection:dropSection sender:sender];
		
	dropSection = -1;
	dropRow = -1;
	dropSubRow = -1;
	
	[self setNeedsDisplay:YES];
	
	return YES;
}

@end