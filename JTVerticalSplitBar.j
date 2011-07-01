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

@import "JTSplitBar.j"

var VIEW_PADDING = 20;

@implementation JTSplitBar : CPView
{
	FPAnimation animation @accessors;
	CPView leftView @accessors;
	CPView rightView @accessors;
	CPPoint	clickLocation;
	BOOL	mouseDown;
	BOOL	collapsing;
	BOOL	collapsed @accessors;
	BOOL	enabled @accessors;
	
	JTCollapseButton	collapseButton;
	float previousCollapseDistance;
	float startingYForCollapse;
	MDGrabber	grabber;
	
	float previousSuperviewHeight;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		enabled = YES;
		collapsed = NO;
		collapsing = NO;
		
		[self setAutoresizingMask:CPViewWidthSizable];
		
		[[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(frameChanged) name:@"CPViewFrameDidChangeNotification" object:[[self window] contentView]];
		previousSuperviewHeight = -1;

	 	/*collapseButton = [[JTCollapseButton alloc] initWithFrame:CPMakeRect(0,0,31,30)];
		[collapseButton setAutoresizingMask:CPViewMinXMargin];
		[collapseButton setTarget:self]
		[collapseButton setAction:@selector(beginCollapsing:)];
		[collapseButton setCollapsed:collapsed];
		[collapseButton setHidden:YES];
		[self addSubview:collapseButton];*/
	}
	return self;
}

- (void)setEnabled:(BOOL)en
{
	enabled = en;
	//[collapseButton setEnabled:en];
}

- (void)frameChanged
{
	/*var currentSuperviewHeight = [[self superview] frame].size.height;
	
	if (!collapsed && !collapsing && previousSuperviewHeight != -1 && (previousSuperviewHeight != currentSuperviewHeight)) {
		var offset = currentSuperviewHeight - previousSuperviewHeight;
		var frame = [self frame];
		frame.origin.y += offset;
		
		if (frame.origin.y > 100.0) {
			[self setFrame:frame];

			var bottomViewFrame = [bottomView frame];
			bottomViewFrame.origin.x = VIEW_PADDING-10;
			bottomViewFrame.origin.y = currentSuperviewHeight - bottomViewFrame.size.height;
			[bottomView setFrame:bottomViewFrame];
			
			[bottomView setAutoresizingMask:CPViewWidthSizable];
			[topView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
		} else {
			[topView setAutoresizingMask:CPViewWidthSizable];
			[bottomView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
			
			var bottomViewFrame = [bottomView frame];
			var oldHeight = bottomViewFrame.size.height;
			bottomViewFrame.size.height = currentSuperviewHeight - [topView frame].size.height - [self frame].size.height - VIEW_PADDING + 10;
			bottomViewFrame.origin.x = VIEW_PADDING-10;
			bottomViewFrame.origin.y -= (oldHeight - bottomViewFrame.size.height);
			[bottomView setFrame:bottomViewFrame];
		}
		
	} else if (collapsed && !collapsing) {*/
		/*var frame = [self frame];
		frame.origin.y = [[self superview] frame].size.height - [self frame].size.height + 1.0;
		[self setFrame:frame];
		[self resizeViews];*/
	//}
	
	//previousSuperviewHeight = currentSuperviewHeight;
}

- (void)resizeViews
{
	var frameWidth = CGRectGetWidth([self frame]);
	var frameHeight = CGRectGetHeight([[self.leftView superview] frame]);
	
	var leftViewFrame = CGRectMake(0,0,[self frame].origin.x,frameHeight);
	[self.leftView setFrame:leftViewFrame];
	
	var rightViewFrame = CGRectMake(CGRectGetMaxX([self frame]),0,CGRectGetWidth([self frame]),frameHeight-CGRectGetMaxY([self frame])-VIEW_PADDING + 10);
	[self.rightView setFrame:rightViewFrame];
}

- (void)mouseDown:(CPEvent)anEvent
{
	if (enabled && !collapsing)
	{
		mouseDown = YES;
		clickLocation = [anEvent locationInWindow];
		[self setNeedsDisplay:YES];
	}
}

- (void)mouseUp:(CPEvent)anEvent
{
	if (enabled)
	{
		mouseDown = NO;
		[self setNeedsDisplay:YES];
	}
}

- (void)mouseDragged:(CPEvent)anEvent
{
	if (enabled && !collapsing)
	{
		collapsed = NO;
		[collapseButton setCollapsed:collapsed];
		var location = [anEvent locationInWindow];

		var newFrame = [self frame];
		newFrame.origin.y += location.y - clickLocation.y;
		clickLocation = location;
		
		var maxY = CGRectGetHeight([[self superview] frame])-CGRectGetHeight([self bounds])+1;
		if (CGRectGetMaxY(newFrame)>maxY)
		{
			//[self beginCollapsing:nil];
			collapsed = YES;
			[collapseButton setCollapsed:YES];
			newFrame.origin.y = maxY;
		} else if (CGRectGetMinY(newFrame)<100)
			newFrame.origin.y = 100;
		[self setFrame:newFrame];
		[self resizeViews];
	}
}

- (void)beginCollapsing:(id)sender
{
	if (collapsing)
		return;

	collapsing = YES;

	startingYForCollapse = [self frame].origin.y;

	var spacingForUncollapse = 100.0;
	
	if (!collapsed)
		collapseDistance = [[self superview] frame].size.height - [self frame].origin.y - [self frame].size.height + 1.0;
	else if (previousCollapseDistance > [[self superview] frame].size.height - spacingForUncollapse)
		previousCollapseDistance = [[self superview] frame].size.height - spacingForUncollapse;
		
	self.animation = [[FPAnimation alloc] initWithDuration:0.7 animationCurve:FPAnimationEaseInOut];
	[animation setDelegate:self];
	[animation startAnimation];
}

- (void)animationFired:(FPAnimation)animation
{
	var collapseLocation = startingYForCollapse;
	if (collapsed)
	 	collapseLocation -= (previousCollapseDistance * [animation currentValue]);
	else
		collapseLocation += (collapseDistance * [animation currentValue]);
	
	var newFrame = [self frame];
	newFrame.origin.y = collapseLocation;
	[self setFrame:newFrame];
	[self resizeViews];
}

- (void)animationFinished:(FPAnimation)animation
{
	previousCollapseDistance = collapseDistance;
	collapsed = !collapsed;
	[collapseButton setCollapsed:collapsed];
	collapsing = NO;
}

@end