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

@import "JTLayoutView.j"
@import "JTScrollView.j"
@import "JTSourceMediaViewController.j"
@import "JTToolbarCells.j"

var TOOLBAR_HEIGHT = 39;
var BUTTONBAR_HEIGHT = 36;
var SOURCE_MEDIA_WIDTH = 250;

@implementation JTDocumentEditorViewController : FPViewController
{
	JTLayoutView	layoutView @accessors;
	JTButtonBar		buttonBar @accessors;
	JTScrollView	scrollView;
	JTToolbar		toolbar;
	JTSourceMediaViewController	sourceMediaViewController @accessors;
}

- (void)loadView
{
	[self.view setBackgroundColor:[CPColor blackColor]];
	
	toolbar = [[JTToolbar alloc] initWithFrame:CPMakeRect(0,0,CGRectGetWidth([self.view bounds])-SOURCE_MEDIA_WIDTH-1,TOOLBAR_HEIGHT)];
	[toolbar setAutoresizingMask:CPViewWidthSizable|CPViewMaxYMargin];
	[toolbar setDrawsLeftInset:YES];
	
	var layoutButton = [FPButton buttonWithCell:[JTToolbarButtonCell buttonCell]];
	[layoutButton setFrame:CPMakeRect(7.0,6.0,35.0,28.0)];
	[layoutButton setImage:[CPImage imageNamed:@"layout.png"]];
	[[layoutButton cell] setImageOffset:CPMakePoint(0,1)];
	[toolbar addSubview:layoutButton];
	
	var firstSeparator = [[JTToolbarSeparatorView alloc] initWithFrame:CPMakeRect(50.0,6.0,1.0,28.0)];
	[toolbar addSubview:firstSeparator];
	
	var formattingControl = [[FPSegmentedControl alloc] initWithFrame:CPMakeRect(60.0,6.0,0.0,28.0)];
	[formattingControl setSegmentCount:3];
	[formattingControl setLabel:@"B" forSegment:0];
	[formattingControl setWidth:28 forSegment:0];
	[formattingControl setLabel:@"I" forSegment:1];
	[formattingControl setWidth:28 forSegment:1];
	[formattingControl setLabel:@"U" forSegment:2];
	[formattingControl setWidth:28 forSegment:2];
	[formattingControl setTarget:self];
	[formattingControl setAction:@selector(formattingChanged:)];
	[formattingControl setCell:[[FPToolbarSegmentedCell alloc] init]];
	[toolbar addSubview:formattingControl];
	
	var secondSeparator = [[JTToolbarSeparatorView alloc] initWithFrame:CPMakeRect(153.0,6.0,1.0,28.0)];
	[toolbar addSubview:secondSeparator];
	
	var paragraphButton = [FPButton buttonWithCell:[JTToolbarButtonCell buttonCell]];
	[paragraphButton setFrame:CPMakeRect(162.0,6.0,30.0,28.0)];
	[paragraphButton setImage:[CPImage imageNamed:@"paragraph.png"]];
	[toolbar addSubview:paragraphButton];
	
	var thirdSeparator = [[JTToolbarSeparatorView alloc] initWithFrame:CPMakeRect(200.0,6.0,1.0,28.0)];
	[toolbar addSubview:thirdSeparator];
	
	var alignmentControl = [[FPSegmentedControl alloc] initWithFrame:CPMakeRect(210.0,6.0,0.0,28.0)];
	[alignmentControl setSegmentCount:4];
	[alignmentControl setImage:[CPImage imageNamed:@"alignleft.png"] forSegment:0];
	[alignmentControl setWidth:28 forSegment:0];
	[alignmentControl setImage:[CPImage imageNamed:@"aligncenter.png"] forSegment:1];
	[alignmentControl setWidth:28 forSegment:1];
	[alignmentControl setImage:[CPImage imageNamed:@"alignright.png"] forSegment:2];
	[alignmentControl setWidth:28 forSegment:2];
	[alignmentControl setImage:[CPImage imageNamed:@"alignjustify.png"] forSegment:3];
	[alignmentControl setWidth:28 forSegment:3];
	[alignmentControl setTarget:self];
	[alignmentControl setAction:@selector(alignmentChanged:)];
	[alignmentControl setCell:[[FPToolbarSegmentedCell alloc] init]];
	[toolbar addSubview:alignmentControl];
	
	var fourthSeparator = [[JTToolbarSeparatorView alloc] initWithFrame:CPMakeRect(331.0,6.0,1.0,28.0)];
	[toolbar addSubview:fourthSeparator];
	
	var listControl = [[FPSegmentedControl alloc] initWithFrame:CPMakeRect(340.0,6.0,0.0,28.0)];
	[listControl setSegmentCount:4];
	[listControl setImage:[CPImage imageNamed:@"numberlist.png"] forSegment:0];
	[listControl setWidth:28 forSegment:0];
	[listControl setImage:[CPImage imageNamed:@"bulletlist.png"] forSegment:1];
	[listControl setWidth:28 forSegment:1];
	[listControl setImage:[CPImage imageNamed:@"floatleft.png"] forSegment:2];
	[listControl setWidth:28 forSegment:2];
	[listControl setImage:[CPImage imageNamed:@"floatright.png"] forSegment:3];
	[listControl setWidth:28 forSegment:3];
	[listControl setTarget:self];
	[listControl setAction:@selector(listChanged:)];
	[listControl setCell:[[FPToolbarSegmentedCell alloc] init]];
	[toolbar addSubview:listControl];
	
	var fifthSeparator = [[JTToolbarSeparatorView alloc] initWithFrame:CPMakeRect(461.0,6.0,1.0,28.0)];
	[toolbar addSubview:fifthSeparator];
	
	var linkButton = [FPButton buttonWithCell:[JTToolbarButtonCell buttonCell]];
	[linkButton setFrame:CPMakeRect(470.0,6.0,30.0,28.0)];
	//[[linkButton cell] setImageOffset:CPMakePoint(0,-1)];
	[linkButton setImage:[CPImage imageNamed:@"hyperlink.png"]];
	[toolbar addSubview:linkButton];
	
	[self.view addSubview:toolbar];
	
	var layoutContainerBackgroundColor = [CPColor colorWithHexString:@"212326"];
	
	var scrollViewFrame = CPRectCreateCopy([self.view bounds]);
	scrollViewFrame.origin.y += TOOLBAR_HEIGHT;
	scrollViewFrame.size.height -= TOOLBAR_HEIGHT;
	scrollViewFrame.size.width -= SOURCE_MEDIA_WIDTH + 1;
	scrollView = [[CPScrollView alloc] initWithFrame:scrollViewFrame];
	[scrollView setAutohidesScrollers:YES];
	[scrollView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
	
	var layoutContainerView = [[FPView alloc] initWithFrame:[scrollView bounds]];
	[layoutContainerView setBackgroundColor:layoutContainerBackgroundColor];
	[layoutContainerView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
	
	var layoutViewWidth = 700;
	var layoutViewRect = CPMakeRect(CGRectGetMidX(scrollViewFrame) - layoutViewWidth/2,20,layoutViewWidth,600);
	layoutView = [[JTLayoutView alloc] initWithFrame:layoutViewRect];
	[layoutView setBackgroundColor:[CPColor whiteColor]];
	[layoutView setAutoresizingMask:CPViewMinXMargin|CPViewMaxXMargin];
	var sampleText = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur ac nisl tellus, vitae sodales lacus. Vivamus aliquet ligula in odio dapibus lacinia. Donec luctus porta hendrerit. Aenean sollicitudin, diam ut dictum dignissim, purus turpis viverra eros, eget pharetra nibh neque sed urna. Nulla facilisi. Phasellus eleifend erat et magna lobortis ac consectetur lectus tincidunt. Duis mauris velit, auctor mattis viverra nec, tincidunt sed enim. Cras posuere suscipit enim non porttitor. Nullam vulputate dolor ac diam posuere non fermentum arcu lobortis. Proin malesuada iaculis sapien. Nullam adipiscing sem in est tristique a ornare odio lacinia. Suspendisse eget est neque, a sodales diam.\n\nFusce egestas turpis et velit pretium id ultricies felis auctor. Pellentesque mattis condimentum convallis. Curabitur dui purus, viverra quis tempus ullamcorper, varius nec sapien. Maecenas bibendum tempor lectus vitae porta. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam vel orci eget sapien rutrum fringilla. Mauris suscipit lacus vitae nunc imperdiet pharetra. Fusce quis odio non sapien pretium semper. Nunc fermentum est in dui elementum imperdiet. Nam gravida condimentum arcu sed bibendum.\n\nSed elementum sapien eget leo malesuada pellentesque scelerisque ante placerat. Nunc sodales tempus placerat. Duis mauris dolor, tempus sed pretium eget, adipiscing fermentum quam. Maecenas scelerisque erat quis ipsum vulputate et bibendum nisi porta. Nulla tincidunt felis id diam tincidunt ut aliquam nulla dictum. Donec faucibus justo in turpis volutpat interdum. Nulla facilisi. Aliquam erat volutpat. Ut magna leo, eleifend in sollicitudin sed, faucibus nec metus. Etiam non quam nec leo posuere mattis et eget purus. Donec quam risus, pellentesque vel euismod sed, iaculis a urna. Aenean scelerisque nunc ligula. Pellentesque mauris dolor, ultrices et consequat sed, imperdiet eget eros. Aenean mattis vestibulum fermentum.\n\nSed purus eros, ultricies non ullamcorper vel, blandit eu tortor. Donec vel nunc nunc, facilisis dapibus ligula. Vivamus non cursus arcu. Mauris ut eros eu orci sagittis hendrerit sit amet id mi. Donec eros purus, molestie eu pretium eget, faucibus nec libero. Nullam vehicula auctor augue nec pharetra. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut eget tellus sed velit convallis blandit in quis ipsum. Fusce laoreet mollis facilisis. Phasellus ligula mi, molestie vel porta ac, placerat at nibh.\n\nEtiam id nisl in dolor volutpat tincidunt. Vivamus molestie lorem a eros imperdiet vulputate. Nam quis leo eget diam aliquam facilisis ac non neque. Fusce lacus leo, molestie eu varius a, ultrices quis lorem. Nunc gravida imperdiet vehicula. In hac habitasse platea dictumst. Nunc in tellus ut ante tincidunt sodales vel vel enim. Suspendisse tortor elit, ultrices ac imperdiet vel, rhoncus nec dolor. Vivamus feugiat, lacus egestas dictum ultricies, quam eros rhoncus sapien, et lobortis libero diam et lacus. Mauris quis leo diam, sed posuere mauris. Vestibulum sit amet magna est, suscipit eleifend lacus. Aenean sagittis molestie ipsum, ut interdum justo imperdiet a.";
	[layoutView setString:sampleText];
	
	[layoutContainerView addSubview:layoutView];
	[scrollView setDocumentView:layoutContainerView];
	
	[self.view addSubview:scrollView];
	
	buttonBar = [[JTButtonBar alloc] initWithFrame:CGRectMake(scrollViewFrame.origin.x,CGRectGetHeight([self.view bounds])-BUTTONBAR_HEIGHT,scrollViewFrame.size.width,BUTTONBAR_HEIGHT)];
	[buttonBar setBlurColor:layoutContainerBackgroundColor];
	[buttonBar setAutoresizingMask:CPViewMinYMargin|CPViewWidthSizable];
	[self.view addSubview:buttonBar];
	
	sourceMediaViewController = [[JTSourceMediaViewController alloc] initWithViewFrame:CPMakeRect(CGRectGetMaxX([self.view bounds])-SOURCE_MEDIA_WIDTH,0,SOURCE_MEDIA_WIDTH,CGRectGetHeight([self.view bounds])) autosaveName:@"JTSourceMedia"];
	[[sourceMediaViewController filterTextField] setHidden:YES];
	var sourceMediaView = sourceMediaViewController.view;
	[sourceMediaView setAutoresizingMask:CPViewHeightSizable|CPViewMinXMargin];
	[self.view addSubview:sourceMediaView];
	[sourceMediaViewController resetData];
	
	var publishButton = [FPButton buttonWithCell:[JTToolbarPublishButtonCell buttonCell]];
	[publishButton setFrame:CPMakeRect(CGRectGetMaxX([toolbar bounds])-114,6,107,28)];
	[publishButton setAutoresizingMask:CPViewMinXMargin];
	[toolbar addSubview:publishButton];
}

- (void)formattingChanged:(id)sender
{
	CPLog(@"formatting changed");
	
	/*[[layoutView mapElement] lockFocus];
	var image = CGContextGetImage(ctx,[[layoutView mapElement] bounds]);
	[[layoutView mapElement] unlockFocus];*/
}

- (void)alignmentChanged:(id)sender
{
	CPLog(@"alignment changed");
}

@end