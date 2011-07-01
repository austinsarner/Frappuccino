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

@import "JTTextElement.j"
@import "JTImageElement.j"
@import "JTMapElement.j"

HEADER_HEIGHT = 40;

@implementation JTLayoutView : FPView
{
	CPMutableArray		elements @accessors;
	JTTextElement		contentElement;
	JTTextElement		headerElement;
	CPMutableArray		guides @accessors;
	CPMutableArray		guideViews @accessors;
	int					guideProximity @accessors;
	MDElementInspector	inspectorPanel @accessors;
	JTMapElement		mapElement @accessors;
}

- (id)initWithFrame:(CPRect)frameRect
{
	if (self = [super initWithFrame:frameRect])
	{
		[self registerForDraggedTypes:[CPArray arrayWithObject:@"JOURNALIST_MEDIA_ITEM_PBOARD_TYPE"]];
		[self setPostsFrameChangedNotifications:YES];
		guideProximity = 5;
		elements = [[CPMutableArray alloc] init];
		guides = [[CPMutableArray alloc] init];
		guideViews = [[CPMutableArray alloc] init];
		
		var headerElementFrame = CPRectCreateCopy([self bounds]);
		headerElementFrame.size.height = HEADER_HEIGHT - 10;
		headerElementFrame.origin.y = 10;
		headerElementFrame.origin.x = 10;
		headerElementFrame.size.width -= 20;
		headerElement = [[JTTextElement alloc] initWithFrame:headerElementFrame];
		//[headerElement setWraps:NO];
		[headerElement setAutoresizingMask:CPViewWidthSizable|CPViewMaxYMargin];
		[headerElement setFont:[CPFont fontWithName:@"Georgia" size:24]];
		[headerElement setLineHeight:30];
		[headerElement setPadding:2];
		[headerElement setString:@"Lorem of Ipsum"];
		[self addElement:headerElement];
		
		var contentElementFrame = CPRectCreateCopy([self bounds]);
		contentElementFrame.origin.y += HEADER_HEIGHT + 10;
		contentElementFrame.origin.x = 10;
		contentElementFrame.size.width -= 20;
		contentElementFrame.size.height -= HEADER_HEIGHT*2 - 20;
		contentElement = [[JTTextElement alloc] initWithFrame:contentElementFrame];
		[contentElement setAutoresizingMask:CPViewWidthSizable];
		[contentElement setFont:[CPFont fontWithName:@"Georgia" size:14]];
		[contentElement setLineHeight:18];
		[contentElement setPadding:2];
		//[contentElement setPadding:10];
		[self addElement:contentElement];
		
		var imageElement = [[JTImageElement alloc] initWithFrame:CPMakeRect(CPRectGetMaxX([self bounds])-208,HEADER_HEIGHT+6,200,140)];
		[imageElement setAutoresizingMask:CPViewMinXMargin];
		[imageElement setPadding:2];
		[imageElement setImage:[[CPImage alloc] initWithContentsOfFile:@"http://s3.amazonaws.com/davisml/media/1/europe_15.jpg"]];
		[self addElement:imageElement];
		
		mapElement = [[JTMapElement alloc] initWithFrame:CPMakeRect(CPRectGetMaxX([self bounds])-208,182,200,140)];
		[mapElement setAutoresizingMask:CPViewMinXMargin];
		[mapElement setPadding:2];
		[self addElement:mapElement];
			
		window.setTimeout(function(){[self wrapTextElements];},0.0);
	}
	return self;
}

- (void)removeElement:(JTElement)element
{
	[elements removeObject:element];
	[element removeFromSuperview];
	[self wrapTextElements];
}

- (void)addElement:(JTElement)element
{
	[self addSubview:element];
	[elements addObject:element];
}

- (void)frameChanged
{
	for (var i=0;i<[elements count];i++)
	{
		var element = [elements objectAtIndex:i];
		
		if ([element respondsToSelector:@selector(frameChanged)])
			[element frameChanged];
	}
	[self wrapTextElements];
}

- (void)setString:(CPString)contentString
{
	[contentElement setString:contentString];
	[self setNeedsDisplay:YES];
}

- (void)showInspectorForElement:(JTElement)element
{
	if (inspectorPanel && [element inspectorPanel]==inspectorPanel)
		return;
	
	inspectorPanel = [[element class] elementInspector];
	if (inspectorPanel)
	{
		inspectorPanel.element = element;
		[element setInspectorPanel:inspectorPanel];
		[self lockInspector];
		[inspectorPanel fadeIn:nil];
	}
}

- (void)lockInspector
{
	if (inspectorPanel)
	{
		var element = inspectorPanel.element;
		
		var offset = [self convertPoint:CPMakePoint(0,0) toView:nil];
		
		var lockPoint = CPMakePoint(CGRectGetMidX([element frame])+offset.x,CGRectGetMaxY([element frame])+offset.y);
		[inspectorPanel lockToPoint:lockPoint];
	}
}

- (void)elementIsTransforming:(JTElement)element
{
	[guides removeAllObjects];
	
	if ([element isDragging])
	{
		[self lockInspector];
		
		var guideMinX = 10;
		var leftLockSide = [self element:element isInProximityOfXValue:guideMinX];
		if (leftLockSide==0)
		{
			var guideRect = CPMakeRect(guideMinX,0,1,CGRectGetHeight([self bounds]));
			[guides addObject:[CPValue valueWithJSObject:guideRect]];
			[self lockElement:element toGuideRect:guideRect onSide:leftLockSide];
		}
	
		var guideMidX = parseInt(CGRectGetMidX([self bounds]));
		var midLockSide = [self element:element isInProximityOfXValue:guideMidX];
		if (midLockSide==1)
		{
			var guideRect = CPMakeRect(guideMidX,0,1,CGRectGetHeight([self bounds]));
			[guides addObject:[CPValue valueWithJSObject:guideRect]];
			[self lockElement:element toGuideRect:guideRect onSide:midLockSide];
		}
	
		var guideMaxX = [self bounds].size.width-guideMinX;
		var rightLockSide = [self element:element isInProximityOfXValue:guideMaxX];
		if (rightLockSide==2)
		{
			var guideRect = CPMakeRect(guideMaxX,0,1,CGRectGetHeight([self bounds]));
			[guides addObject:[CPValue valueWithJSObject:guideRect]];
			[self lockElement:element toGuideRect:guideRect onSide:rightLockSide];
		}
	}
	
	[self displayGuides];
	[self wrapTextElements];
}

- (void)displayGuides
{
	for (var i=0;i<[guideViews count];i++)
	{
		var guideView = [guideViews objectAtIndex:i];
		[guideView removeFromSuperview];
		[guideViews removeObject:guideView];
	}
	
	var guideColor = [CPColor yellowColor];
	for (var i=0;i<[guides count];i++)
	{
		var guideFrame = [[guides objectAtIndex:i] JSObject];
		var guideView = [[CPView alloc] initWithFrame:guideFrame];
		[guideView setBackgroundColor:guideColor];
		[self addSubview:guideView];
		[guideViews addObject:guideView];
		//[[CPBezierPath bezierPathWithRect:guide] fill];
	}
}

- (void)lockElement:(CPElement)element toGuideRect:(CPRect)guideRect onSide:(int)lockSide
{
	var isVertical = (guideRect.size.height>1);
	if (isVertical)
	{
		var elementFrame = [element frame];
		if (lockSide==0)
			elementFrame.origin.x = guideRect.origin.x - [element padding];
		else if (lockSide==1)
			elementFrame.origin.x = guideRect.origin.x - [element frame].size.width/2;
		else if (lockSide==2)
			elementFrame.origin.x = guideRect.origin.x - [element frame].size.width + [element padding];
		[element setFrame:elementFrame];
	}
}

- (int)element:(JTElement)element isInProximityOfXValue:(int)xValue
{
	var proximityRange = CPMakeRange(xValue-guideProximity,guideProximity*2);
	
	if (CPLocationInRange(CGRectGetMinX([element frame]),proximityRange))
		return 0;
	else if (CPLocationInRange(CGRectGetMidX([element frame]),proximityRange))
		return 1;
	else if (CPLocationInRange(CGRectGetMaxX([element frame]),proximityRange))
		return 2;
	
	return -1;
}

- (int)element:(JTElement)element isInProximityOfYValue:(int)yValue
{
	var proximityRange = CPMakeRange(yValue-guideProximity,guideProximity*2);
	
	if (CPLocationInRange(CGRectGetMinY([element frame]),proximityRange))
		return 0;
	else if (CPLocationInRange(CGRectGetMidY([element frame]),proximityRange))
		return 1;
	else if (CPLocationInRange(CGRectGetMaxY([element frame]),proximityRange))
		return 2;
	
	return -1;
}

- (void)elementFinishedTransforming:(JTElement)element
{
	//[guides removeAllObjects];
	
	var newHeight = 0;
	for (var i=0;i<[elements count];i++)
	{
		var element = [elements objectAtIndex:i];
		var elementHeight = CGRectGetMaxY([element frame]);
		if (elementHeight>newHeight)
			newHeight = elementHeight;
	}
	
	if ([[self superview] isKindOfClass:[CPScrollView class]])
	{
		var minHeight = [[self superview] frame].size.height;
		if (newHeight < minHeight)
			newHeight = minHeight;
	}
	
	//CPLog(@"new height: %d",newHeight);
	
	var newFrame = [self frame];
	newFrame.size.height = newHeight;
	[self setFrame:newFrame];
	
	//[self displayGuides];
}

- (void)wrapTextElements
{
	var elementFrames = [CPMutableArray array];
	for (var i=0;i<[elements count];i++)
	{
		var element = [elements objectAtIndex:i];
		if (![element isKindOfClass:[JTTextElement class]])
			[elementFrames addObject:[CPValue valueWithJSObject:[element frame]]];
	}
	
	for (var i=0;i<[elements count];i++)
	{
		var element = [elements objectAtIndex:i];
		if ([element isKindOfClass:[JTTextElement class]] && [element wraps])
		{
			[element removeAllClippedAreas];
			for (var e=0;e<[elementFrames count];e++)
			{
				var wrapObjectRect = [[elementFrames objectAtIndex:e] JSObject];
				var intersectionRect = CPRectIntersection([element frame],wrapObjectRect);
				[element addClippedArea:intersectionRect];
				//CPLog(@"{%f,%f,%f,%f}",intersectionRect.origin.x,intersectionRect.origin.y,intersectionRect.size.width,intersectionRect.size.height);
			}
			[element updateClippedAreas];
			//setNeedsDisplay:YES];
		}
	}
}

- (CPDragOperation)draggingEntered:(var)sender
{
	return CPDragOperationCopy;
}

- (CPDragOperation)draggingExited:(var)sender
{
	return CPDragOperationNone;
}

- (CPDragOperation)draggingUpdated:(var)sender
{	
	return CPDragOperationCopy;
}

- (BOOL)performDragOperation:(var)sender
{	
	CPLog(@"perform drag");
	
	var mediaIDs = [[sender draggingPasteboard] dataForType:@"JOURNALIST_MEDIA_ITEM_PBOARD_TYPE"];
	var mediaItem = [[MediaLibrary sharedMediaLibrary] mediaItemWithID:[mediaIDs lastObject]];
	
	var location = [self convertPoint:[sender draggingLocation] fromView:nil];
	
	//var dragImageSize = [[sender draggedImage] frame].size;
	//CPLog(@"{%f,%f}",dragImageSize.width,dragImageSize.height);
	//var imageSize = [sender]
	
	var imageElement = [[JTImageElement alloc] initWithFrame:CPMakeRect(location.x-125,location.y-125,250,250)];
	[imageElement setAutoresizingMask:CPViewMinXMargin];
	[imageElement setPadding:2];
	[imageElement setImage:[[CPImage alloc] initWithContentsOfFile:[[mediaItem mediaURL] absoluteString]]];
	[self addElement:imageElement];
	[self wrapTextElements];
		
	//[self setNeedsDisplay:YES];
	
	return YES;
}

- (void)drawRect:(CPRect)aRect
{
	var gradientRect = CGRectInset([self bounds],1,1);
	gradientRect.size.height = 200;
	var linearGradient = [[FPGradient alloc] initWithStartingColor:[CPColor colorWithCalibratedWhite:0.8 alpha:1.0] endingColor:[CPColor whiteColor]];
	[linearGradient drawInRect:gradientRect angle:-90];
}

@end