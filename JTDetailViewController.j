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

@import "JTMediaChooserViewController.j"
@import "JTDocumentChooserViewController.j"
@import "JTPageViewController.j"
@import "JTStoreViewController.j"

//var TOOLBAR_HEIGHT = 39;
var SOURCE_MEDIA_WIDTH = 250;
var FADE_OUT_DURATION = 0.2;

@implementation JTDetailViewController : FPViewController
{
	id masterViewController @accessors;
	id contentViewController @accessors;
	id delegate @accessors;
	
	id modalContentViewController @accessors;
	id fadeOutForModalViewAnimation @accessors;
	id fadeOutModalViewAnimation @accessors;
}

- (void)loadView
{
	var detailView = self.view;
	
	var mediaChooser = [[JTMediaChooserViewController alloc] initWithViewFrame:[self.view bounds] autosaveName:@"JTMainMedia"];
	[self setContentViewController:mediaChooser];
}

- (void)presentModalContentViewController:(id)aModalContentViewController
{
	modalContentViewController = aModalContentViewController;
	modalContentViewController.detailViewController = self;
	
	[modalContentViewController.view setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
	
	if (contentViewController != nil) {
		[self.view addSubview:modalContentViewController.view positioned:CPWindowBelow relativeTo:contentViewController.view];
		
		fadeOutForModalViewAnimation = [[FPAnimation alloc] initWithDuration:FADE_OUT_DURATION animationCurve:FPAnimationEaseIn];
		[fadeOutForModalViewAnimation setDelegate:self];
		[fadeOutForModalViewAnimation startAnimation];
	} else 
		[self.view addSubview:modalContentViewController.view];
}

- (void)dismissModalContentViewController
{
	if (modalContentViewController != nil) {
		
		if (contentViewController != nil) {
			[contentViewController.view setFrame:[modalContentViewController.view frame]];
			[contentViewController.view setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
			[self.view addSubview:contentViewController.view positioned:CPWindowBelow relativeTo:modalContentViewController.view];
			if ([contentViewController respondsToSelector:@selector(detailViewController:dismissedModalContentViewController:)])
				[contentViewController detailViewController:self dismissedModalContentViewController:modalContentViewController];
		}
		
		fadeOutModalViewAnimation = [[FPAnimation alloc] initWithDuration:0.1 animationCurve:FPAnimationEaseOut];
		[fadeOutModalViewAnimation setDelegate:self];
		[fadeOutModalViewAnimation startAnimation];
	}
}

- (void)setContentViewController:(id)newViewController
{
	[self setContentViewController:newViewController animated:NO];
}

- (void)setContentViewController:(id)newViewController animated:(BOOL)animate
{
	if (animate)
	{
		self.changeAnimation = [[FPAnimation alloc] initWithDuration:ANIMATED_LAYOUT_DURATION animationCurve:FPAnimationEaseInOut];
		[changeAnimation setDelegate:self];
		[changeAnimation startAnimation];
	}
	else
	{
		if (contentViewController)
		{
			[contentViewController.view removeFromSuperview];
			self.contentViewController = nil;
		}

		if (newViewController)
		{
			self.contentViewController = newViewController;
			contentViewController.detailViewController = self;
			var contentView = contentViewController.view;
			[contentView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
			[self.view addSubview:contentView];
		}
	}
}

- (void)animationFired:(FPAnimation)animation
{
	var currentValue = [animation currentValue];
	
	if (animation == fadeOutForModalViewAnimation)
		[contentViewController.view setAlphaValue:1.0 - currentValue];
	else if (animation == fadeOutModalViewAnimation)
		[modalContentViewController.view setAlphaValue:1.0 - currentValue];
}

- (void)animationFinished:(FPAnimation)animation
{
	if (animation == fadeOutForModalViewAnimation) {
		[contentViewController.view removeFromSuperview];
		[contentViewController.view setAlphaValue:1.0];
	} else if (animation == fadeOutModalViewAnimation) {
		[modalContentViewController.view removeFromSuperview];
		[modalContentViewController.view setAlphaValue:1.0];
		modalContentViewController = nil;
	}
}

- (id)details
{
	return [delegate selectedDetails];
}

- (void)reloadData
{
	var selType = nil;
	if (selType = [delegate selectedType])
	{
		if ([selType isEqualToString:@"Document"] && ![contentViewController isKindOfClass:[JTDocumentChooserViewController class]])
		{
			var documentChooser = [[JTDocumentChooserViewController alloc] initWithViewFrame:[self.view bounds]];
			[self setContentViewController:documentChooser];
		} else if ([selType isEqualToString:@"Media"] && ![contentViewController isKindOfClass:[JTMediaChooserViewController class]])
		{
			var mediaChooser = [[JTMediaChooserViewController alloc] initWithViewFrame:[self.view bounds] autosaveName:@"JTMainMedia"];
			[self setContentViewController:mediaChooser];
		} else if ([selType isEqualToString:@"Store"])
		{
			var storeViewController = [[JTStoreViewController alloc] initWithViewFrame:[self.view bounds]];
			[self setContentViewController:storeViewController];
		}
	} else
	{
		var pageViewer = [[JTPageViewController alloc] initWithViewFrame:[self.view bounds]];
		[self setContentViewController:pageViewer];
	}
	
	[contentViewController resetData];
}

@end