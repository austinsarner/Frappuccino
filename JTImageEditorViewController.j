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

@import "JTToolbarCells.j"
@import "MDAttachedPanel.j"
@import "JTImageAdjustmentView.j"
@import "JTImageEditorView.j"

var TOOLBAR_HEIGHT = 39;
var BUTTONBAR_HEIGHT = 36;

@implementation JTImageEditorViewController : FPViewController
{
	JTButtonBar			buttonBar @accessors;
	JTToolbar			toolbar;
	JTImageEditorView	imageView;
	CPImage				image @accessors;
	
	FPButton			cropButton;
	MDAttachedPanel		cropPanel;
	
	FPButton			effectsButton;
	MDAttachedPanel		effectsPanel;
	
	FPButton			adjustButton;
	MDAttachedPanel		adjustPanel;
	
	var					mediaItem @accessors;
}

- (void)loadView
{
	[self.view setBackgroundColor:[CPColor blackColor]];
	
	var imageViewFrame = CPRectCreateCopy([self.view bounds]);
	imageViewFrame.origin.y += TOOLBAR_HEIGHT;
	imageViewFrame.size.height -= TOOLBAR_HEIGHT;
	imageViewFrame.size.height -= BUTTONBAR_HEIGHT;

	imageView = [[JTImageEditorView alloc] initWithFrame:imageViewFrame];
	[imageView setAutoresizingMask:CPViewHeightSizable|CPViewWidthSizable];
	
	[self.view addSubview:imageView];
	
	toolbar = [[JTToolbar alloc] initWithFrame:CPMakeRect(0,0,CGRectGetWidth([self.view bounds])-1,TOOLBAR_HEIGHT)];
	[toolbar setAutoresizingMask:CPViewWidthSizable|CPViewMaxYMargin];
	[toolbar setDrawsLeftInset:YES];
	
	var dismissButton = [FPButton buttonWithCell:[JTToolbarButtonCell buttonCell]];
	[dismissButton setFrame:CPMakeRect(7.0,6.0,35.0,28.0)];
	[dismissButton setTitle:@"x"];
	//[[dismissButton cell] setImageOffset:CPMakePoint(0,1)];
	[dismissButton setTarget:self];
	[dismissButton setAction:@selector(dismissImageEditorViewController)];
	
	[toolbar addSubview:dismissButton];
	
	var separator = [[JTToolbarSeparatorView alloc] initWithFrame:CPMakeRect(51.0,6.0,1.0,28.0)];
	[toolbar addSubview:separator];
	
	effectsButton = [FPButton buttonWithCell:[JTToolbarButtonCell buttonCell]];
	[effectsButton setFrame:CPMakeRect(60.0,6.0,35.0,28.0)];
	[effectsButton setImage:[CPImage imageNamed:@"fx.png"]];
	[[effectsButton cell] setImageOffset:CPMakePoint(0,0)];
	[effectsButton setTarget:self];
	[effectsButton setAction:@selector(showEffectsPopover)];
	[toolbar addSubview:effectsButton];
	
	adjustButton = [FPButton buttonWithCell:[JTToolbarButtonCell buttonCell]];
	[adjustButton setFrame:CPMakeRect(100.0,6.0,35.0,28.0)];
	[adjustButton setImage:[CPImage imageNamed:@"adjustimage.png"]];
	[[adjustButton cell] setImageOffset:CPMakePoint(0,0)];
	//[[adjustButton cell] setImageOffset:CPMakePoint(0,0)];
	[adjustButton setTarget:self];
	[adjustButton setAction:@selector(showAdjustPopover)];
	[toolbar addSubview:adjustButton];
	
	separator = [[JTToolbarSeparatorView alloc] initWithFrame:CPMakeRect(144.0,6.0,1.0,28.0)];
	[toolbar addSubview:separator];
	
	cropButton = [FPButton buttonWithCell:[JTToolbarButtonCell buttonCell]];
	[cropButton setFrame:CPMakeRect(153.0,6.0,35.0,28.0)];
	[cropButton setImage:[CPImage imageNamed:@"crop.png"]];
	[[cropButton cell] setImageOffset:CPMakePoint(0,0)];
	[cropButton setTarget:self];
	[cropButton setAction:@selector(showCropPopover)];
	[toolbar addSubview:cropButton];
	
	[self.view addSubview:toolbar];

	buttonBar = [[JTButtonBar alloc] initWithFrame:CGRectMake(imageViewFrame.origin.x,CGRectGetHeight([self.view bounds])-BUTTONBAR_HEIGHT,imageViewFrame.size.width,BUTTONBAR_HEIGHT)];
	[buttonBar setAutoresizingMask:CPViewMinYMargin|CPViewWidthSizable];
	[self.view addSubview:buttonBar];
	
	var publishButton = [FPButton buttonWithCell:[JTToolbarPublishButtonCell buttonCell]];
	[publishButton setFrame:CPMakeRect(CGRectGetMaxX([toolbar bounds])-114,6,107,28)];
	[publishButton setAutoresizingMask:CPViewMinXMargin];
	[toolbar addSubview:publishButton];
	
	effectsPanel = [[ASAttachedPanel alloc] initWithContentRect:CGRectMake(0.0,0.0,300.0,338.0)];
	var effectsChooserView = [[JTEffectChooserView alloc] initWithFrame:CGRectMake(0.0,0.0,300.0,338.0)];
	[[effectsPanel attachedView] addSubview:effectsChooserView];
	[effectsPanel setMainView:effectsChooserView];
	
	adjustPanel = [[ASAttachedPanel alloc] initWithContentRect:CGRectMake(0.0,0.0,300.0,160.0)];
	var imageAdjustmentView = [[JTImageAdjustmentView alloc] initWithFrame:CGRectMake(0.0,0.0,300.0,160.0)];
	[[adjustPanel attachedView] addSubview:imageAdjustmentView];
	[adjustPanel setMainView:imageAdjustmentView];
	
	cropPanel = [[ASAttachedPanel alloc] initWithContentRect:CGRectMake(0.0,0.0,200.0,50.0)];
	var imageCropView = [[JTImageCropView alloc] initWithFrame:CGRectMake(0.0,0.0,200.0,50.0)];
	[[cropPanel attachedView] addSubview:imageCropView];
	[cropPanel setMainView:imageCropView];
	[imageCropView setImageEditorViewController:self];
}

- (void)setImage:(CPImage)aImage
{
	image = aImage;
	[imageView setImage:image];
}

- (void)dismissImageEditorViewController
{
	[self closeAllPopovers];
	[self.detailViewController dismissModalContentViewController];
}

- (void)showEffectsPopover
{
	[self closeAllPopovers];
	[self togglePopover:effectsPanel];
}

- (void)showAdjustPopover
{
	[self closeAllPopovers];
	[self togglePopover:adjustPanel];
}

- (void)showCropPopover
{
	[self closeAllPopovers];
	[self togglePopover:cropPanel];
}

- (void)togglePopover:(id)panel
{
	var isVisible = [panel isVisible];
	var button = nil;
	
	if (panel == effectsPanel)
	{
		button = effectsButton;
		[[panel mainView] setMediaItem:mediaItem];
		[button setImage:[CPImage imageNamed:isVisible?@"fx.png":@"fx_pressed.png"]];
	}
	else if (panel == adjustPanel)
	{
		button = adjustButton;
		[button setImage:[CPImage imageNamed:isVisible?@"adjustimage.png":@"adjustimage_pressed.png"]];
	}
	else if (panel == cropPanel)
	{
		button = cropButton;
		[button setImage:[CPImage imageNamed:isVisible?@"crop.png":@"crop_pressed.png"]];
		[imageView setCropping:(!isVisible)];
	}
	
	if (isVisible)
		[panel fadeOut:nil];
	else
	{
		var origin = [button frame].origin;
		origin.x += Math.floor([button frame].size.width / 2.0);
		origin.y += [button frame].size.height;

		[panel lockToPoint:[toolbar convertPoint:origin toView:nil]];
		[panel fadeIn:nil];
		[[panel mainView] setNeedsDisplay:YES];
	}
}

- (void)closeAllPopovers
{
	var popovers = [effectsPanel,adjustPanel,cropPanel];
	for (var i=0;i<[popovers count];i++)
	{
		var popover = [popovers objectAtIndex:i];
		if ([popover isVisible])
			[self togglePopover:popover];
	}
}

- (void)crop
{
	[imageView crop];
	[cropButton setImage:[CPImage imageNamed:@"crop.png"]];
	[cropPanel fadeOut:nil];	
}

@end

@implementation ASAttachedPanel : MDAttachedPanel
{
	var mainView @accessors;
}

@end

@implementation JTImageCropView : CPView
{
	FPButton		cropButton;
	var				imageEditorViewController @accessors;
}

- (void)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		
		cropButton = [FPButton buttonWithCell:[JTToolbarButtonCell buttonCell]];
		[cropButton setTitle:@"Crop"];
		[cropButton setTarget:imageEditorViewController];
		[cropButton setAction:@selector(crop)];
		var cropButtonFrame = [cropButton frame];
		cropButtonFrame.size.width = 60.0;
		cropButtonFrame.origin.x += frame.size.width - cropButtonFrame.size.width - 10.0;
		cropButtonFrame.origin.y = frame.size.height / 2.0 - cropButtonFrame.size.height / 2.0 + 2.0;
		[cropButton setFrame:cropButtonFrame];
		[self addSubview:cropButton];
	}
	
	return self;
}

- (void)setImageEditorViewController:(var)aImageEditorViewController
{
	imageEditorViewController = aImageEditorViewController;
	[cropButton setTarget:imageEditorViewController];
}

@end

@implementation JTEffectChooserView : CPView
{
	var mediaItem @accessors;
	
	var sepiaImage;
	var grayscaleImage;
	var antiqueImage;
	var	sketchImage;
	var boostImage;
	var fadeImage;
	var vignetteImage;
	var matteImage;
	
	var imageRects;
	
	var clickedEffect;
	var selectedEffect;
	FPImageCell imageCell;
}

- (id)initWithFrame:(CGRect)aFrame
{
	if (self = [super initWithFrame:aFrame]) {
		
		selectedEffect = -1;
		clickedEffect = -1;
		var width = 82.0;
		var height = 82.0;
		var sideOffset = 15.0;
		var offset = 11.0;
		var yOffset = 19.0;
		
		imageRects = [];

		[imageRects addObject:CGRectMake(sideOffset,yOffset,width,height)];
		[imageRects addObject:CGRectMake(sideOffset + width + offset,yOffset,width,height)];
		[imageRects addObject:CGRectMake(sideOffset + width + offset + width + offset,yOffset,width,height)];

		yOffset += height + 22.0;

		[imageRects addObject:CGRectMake(sideOffset,yOffset,width,height)];
		[imageRects addObject:CGRectMake(sideOffset + width + offset,yOffset,width,height)];
		[imageRects addObject:CGRectMake(sideOffset + width + offset + width + offset,yOffset,width,height)];

		yOffset += height + 22.0;

		[imageRects addObject:CGRectMake(sideOffset,yOffset,width,height)];
		[imageRects addObject:CGRectMake(sideOffset + width + offset,yOffset,width,height)];
		[imageRects addObject:CGRectMake(sideOffset + width + offset + width + offset,yOffset,width,height)];
	}
	
	return self;
}

- (void)mouseDown:(CPEvent)event
{
	var location = [self convertPoint:[event locationInWindow] fromView:nil];

	clickedEffect = -1;
	
	for (var i = 0; i < [imageRects count]; i++) {
		if (CGRectContainsPoint([imageRects objectAtIndex:i],location)) {
			clickedEffect = i;			
			break;
		}
	}
	
	[self setNeedsDisplay:YES];
}

- (void)mouseUp:(CPEvent)event
{
	selectedEffect = clickedEffect;
	clickedEffect = -1;
	
	[self setNeedsDisplay:YES];
}

- (void)setMediaItem:(var)aMediaItem
{
	mediaItem = aMediaItem;
	
	imageCell = [[FPImageCell alloc] init];

	sepiaImage = [mediaItem thumbnailImageWithEffect:CCImageEffectSepia];
	[sepiaImage setDelegate:self];
	
	grayscaleImage = [mediaItem thumbnailImageWithEffect:CCImageEffectGrayscale];
	[grayscaleImage setDelegate:self];
	
	antiqueImage = [mediaItem thumbnailImageWithEffect:CCImageEffectAntique];
	[antiqueImage setDelegate:self];
	
	sketchImage = [mediaItem thumbnailImageWithEffect:CCImageEffectSketch];
	[sketchImage setDelegate:self];
	
	boostImage = [mediaItem thumbnailImageWithEffect:CCImageEffectBoostColor];
	[boostImage setDelegate:self];
	
	fadeImage = [mediaItem thumbnailImageWithEffect:CCImageEffectFadeColor];
	[fadeImage setDelegate:self];

	matteImage = [mediaItem thumbnailImageWithEffect:CCImageEffectMatte];
	[matteImage setDelegate:self];
		
	vignetteImage = [mediaItem thumbnailImageWithEffect:CCImageEffectVignette];
	[vignetteImage setDelegate:self];
		
	[self setNeedsDisplay:YES];
}

- (void)imageDidLoad:(CPImage)aImage
{
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(CGRect)rect
{		
	var width = 82.0;
	var height = 82.0;
	var sideOffset = 15.0;
	var offset = 11.0;
	var yOffset = 19.0;
	
	if (selectedEffect != -1) {
		var rect = CGRectInset(CPRectCreateCopy([imageRects objectAtIndex:selectedEffect]),-5.0,-5.0);
		[[[CPColor blueColor] colorWithAlphaComponent:0.5] set];
		[CPBezierPath fillRect:rect];
	}
	
	[[CPColor whiteColor] set];
	
	var rect = CPRectCreateCopy([imageRects objectAtIndex:0]);
	[imageCell setImage:grayscaleImage];
	[imageCell drawWithFrame:rect inView:self];

	rect.origin.y += height + 4.0;
	[@"B & W" drawInRect:rect withFont:[CPFont boldSystemFontOfSize:12] alignment:CPCenterTextAlignment];
	
	rect = CPRectCreateCopy([imageRects objectAtIndex:1]);
	[imageCell setImage:sepiaImage];
	[imageCell drawWithFrame:rect inView:self];

	rect.origin.y += height + 4.0;
	[@"Sepia" drawInRect:rect withFont:[CPFont boldSystemFontOfSize:12] alignment:CPCenterTextAlignment];
	
	rect = CPRectCreateCopy([imageRects objectAtIndex:2]);
	[imageCell setImage:antiqueImage];
	[imageCell drawWithFrame:rect inView:self];	

	rect.origin.y += height + 4.0;
	[@"Antique" drawInRect:rect withFont:[CPFont boldSystemFontOfSize:12] alignment:CPCenterTextAlignment];
	
	yOffset += height + 22.0;
	
	rect = CPRectCreateCopy([imageRects objectAtIndex:3]);
	[imageCell setImage:boostImage];
	[imageCell drawWithFrame:rect inView:self];

	rect.origin.y += height + 4.0;
	[@"Boost Color" drawInRect:rect withFont:[CPFont boldSystemFontOfSize:12] alignment:CPCenterTextAlignment];
	
	rect = CPRectCreateCopy([imageRects objectAtIndex:4]);
	[imageCell setImage:[mediaItem thumbnailImage]];
	[imageCell drawWithFrame:rect inView:self];

	rect.origin.y += height + 4.0;
	[@"Original" drawInRect:rect withFont:[CPFont boldSystemFontOfSize:12] alignment:CPCenterTextAlignment];
		
	rect = CPRectCreateCopy([imageRects objectAtIndex:5]);
	[imageCell setImage:fadeImage];
	[imageCell drawWithFrame:rect inView:self];

	rect.origin.y += height + 4.0;
	[@"Fade Color" drawInRect:rect withFont:[CPFont boldSystemFontOfSize:12] alignment:CPCenterTextAlignment];
		
	yOffset += height + 22.0;
	
	rect = CPRectCreateCopy([imageRects objectAtIndex:6]);
	[imageCell setImage:sketchImage];
	[imageCell drawWithFrame:rect inView:self];

	rect.origin.y += height + 4.0;
	[@"Sketch" drawInRect:rect withFont:[CPFont boldSystemFontOfSize:12] alignment:CPCenterTextAlignment];
	
	rect = CPRectCreateCopy([imageRects objectAtIndex:7]);
	[imageCell setImage:matteImage];
	[imageCell drawWithFrame:rect inView:self];	

	rect.origin.y += height + 4.0;
	[@"Matte" drawInRect:rect withFont:[CPFont boldSystemFontOfSize:12] alignment:CPCenterTextAlignment];
	
	rect = CPRectCreateCopy([imageRects objectAtIndex:8]);
	[imageCell setImage:vignetteImage];
	[imageCell drawWithFrame:rect inView:self];

	rect.origin.y += height + 4.0;
	[@"Vignette" drawInRect:rect withFont:[CPFont boldSystemFontOfSize:12] alignment:CPCenterTextAlignment];

	if (clickedEffect != -1) {
		var rect = CPRectCreateCopy([imageRects objectAtIndex:clickedEffect]);
		[[CPColor colorWithCalibratedWhite:0.0 alpha:0.5] set];
		[CPBezierPath fillRect:rect];
	}
}

@end