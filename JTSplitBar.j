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

@import "MDGrabber.j"
@import "JTColor.j"

@implementation JTSplitBar : CPView
{
	FPAnimation animation @accessors;
	CPView topView @accessors;
	CPView bottomView @accessors;
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

	 	collapseButton = [[JTCollapseButton alloc] initWithFrame:CPMakeRect(CGRectGetWidth([self bounds])-30,0,31,30)];
		[collapseButton setAutoresizingMask:CPViewMinXMargin];
		[collapseButton setTarget:self]
		[collapseButton setAction:@selector(beginCollapsing:)];
		[collapseButton setCollapsed:collapsed];
		[collapseButton setHidden:YES];
		[self addSubview:collapseButton];
	}
	return self;
}

- (void)setEnabled:(BOOL)en
{
	enabled = en;
	[collapseButton setEnabled:en];
}

- (void)frameChanged
{
	var currentSuperviewHeight = [[self superview] frame].size.height;
	
	if (!collapsed && !collapsing && previousSuperviewHeight != -1 && (previousSuperviewHeight != currentSuperviewHeight)) {
		var offset = currentSuperviewHeight - previousSuperviewHeight;
		var frame = [self frame];
		frame.origin.y += offset;
		
		if (frame.origin.y > 100.0) {
			[self setFrame:frame];

			var bottomViewFrame = [bottomView frame];
			bottomViewFrame.origin.x = 0;
			bottomViewFrame.origin.y = currentSuperviewHeight - bottomViewFrame.size.height;
			[bottomView setFrame:bottomViewFrame];
			
			[bottomView setAutoresizingMask:CPViewWidthSizable];
			[topView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
		} else {
			[topView setAutoresizingMask:CPViewWidthSizable];
			[bottomView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
			
			var bottomViewFrame = [bottomView frame];
			var oldHeight = bottomViewFrame.size.height;
			bottomViewFrame.size.height = currentSuperviewHeight - [topView frame].size.height - [self frame].size.height;
			bottomViewFrame.origin.x = 0;
			bottomViewFrame.origin.y -= (oldHeight - bottomViewFrame.size.height);
			[bottomView setFrame:bottomViewFrame];
		}
		
	} else if (collapsed && !collapsing) {
		var frame = [self frame];
		frame.origin.y = [[self superview] frame].size.height - [self frame].size.height + 1.0;
		[self setFrame:frame];
		[self resizeViews];
	}
	
	previousSuperviewHeight = currentSuperviewHeight;
}

- (void)resizeViews
{
	var frameWidth = CGRectGetWidth([self frame]);
	var frameHeight = CGRectGetHeight([[self.topView superview] frame]);
	
	var topViewFrame = CGRectMake(0,0,frameWidth,[self frame].origin.y);
	[self.topView setFrame:topViewFrame];
	
	var bottomViewFrame = CGRectMake(0,CGRectGetMaxY([self frame]),frameWidth,frameHeight-CGRectGetMaxY([self frame]));
	[self.bottomView setFrame:bottomViewFrame];
}

- (void)drawRect:(CPRect)aRect
{
	var gradientRect = [self bounds];
	gradientRect.origin.y += 2;
	gradientRect.size.height -= 4;
	var linearGradient = [[FPGradient alloc] initWithStartingColor:[CPColor colorWithHexString:@"3e4249"] endingColor:[CPColor colorWithHexString:@"26292e"]];
	[linearGradient drawInRect:gradientRect angle:90];
	
	var horizontalRect = CPMakeRect(0,0,CGRectGetWidth([self bounds]),1);
	[[CPColor colorWithHexString:@"24262c"] set];
	[[CPBezierPath bezierPathWithRect:horizontalRect] fill];
	
	horizontalRect.origin.y++;
	[[CPColor colorWithHexString:@"5c6065"] set];//@"666a6f"] set];
	[[CPBezierPath bezierPathWithRect:horizontalRect] fill];
	
	horizontalRect.origin.y = CGRectGetMaxY([self bounds])-1;
	[[CPColor borderColor] set];
	[[CPBezierPath bezierPathWithRect:horizontalRect] fill];
	
	horizontalRect.origin.y--;
	[[CPColor colorWithHexString:@"2d2f33"] set];
	[[CPBezierPath bezierPathWithRect:horizontalRect] fill];
}

// Mouse Events

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

// Animation

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

@implementation JTCollapseButton : CPView
{
	id	target @accessors;
	SEL action @accessors;
	BOOL pressed;
	BOOL collapsed @accessors;
	BOOL enabled @accessors;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		enabled = YES;
	}
	return self;
}

- (void)setEnabled:(BOOL)en
{
	enabled = en;
	[self setNeedsDisplay:YES];
}

- (void)mouseDown:(CPEvent)event
{
	if (enabled)
	{
		pressed = YES;
		[self setNeedsDisplay:YES];
	}
}

- (void)mouseUp:(CPEvent)event
{
	if (enabled)
	{
		var localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
		if (CPRectContainsPoint([self bounds],localPoint))
			[self.target performSelector:self.action withObject:self];
	
		pressed = NO;
		[self setNeedsDisplay:YES];
	}
}

- (void)setCollapsed:(BOOL)isCollapsed
{
	collapsed=isCollapsed;
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(CPRect)rect
{
	if (enabled)
	{
		/*[[CPColor colorWithCalibratedWhite:0.3 alpha:pressed?0.1:0.05] set];
		[[CPBezierPath bezierPathWithRect:[self bounds]] fill];*/
	
		[[CPColor colorWithCalibratedWhite:pressed?1.0:0.9 alpha:0.4] set];
		//var arrowPath = [CPBezierPath bezierPath];
	
		var arrowRect = CPMakeRect(12,8,9,4.5);
		
		var arrowPath = [CPBezierPath bezierPathWithArrowInRect:arrowRect direction:collapsed?CPArrowDirectionUp:CPArrowDirectionDown];
	
		//[arrowPath closePath];
		[arrowPath fill];
	}
}

@end