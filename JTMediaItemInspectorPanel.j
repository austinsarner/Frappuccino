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

@import "MDAttachedPanel.j"

@implementation JTMediaItemInspectorPanel : MDAttachedPanel
{
	FPTextField nameTextField;
	FPTextField captionTextField;
	
	var representedMediaItem;
}

- (void)setRepresentedMediaItem:(var)newRepresentedMediaItem
{
	representedMediaItem = newRepresentedMediaItem;
	
	if (representedMediaItem == nil) {
		[nameTextField setStringValue:@""];
		[captionTextField setStringValue:@""];
	} else {
		[nameTextField setStringValue:[representedMediaItem title]];
		[captionTextField setStringValue:@"Caption info would go here if it was hooked up..."];
	}
}

- (id)initWithContentRect:(CPRect)contentRect
{
	if (self = [super initWithContentRect:contentRect])
	{
		representedMediaItem = nil;
		
		// Name field
		nameTextField = [FPTextField textFieldWithStringValue:@"" placeholder:@"No Selection" width:130.0];
		[nameTextField setAutoresizingMask:CPViewMaxYMargin];
		
		var nameTextFieldFrame = [nameTextField frame];
		[nameTextField setDelegate:self];
		nameTextFieldFrame.origin.y = 14.0;
		nameTextFieldFrame.origin.x = [[self contentView] frame].size.width / 2.0 - nameTextFieldFrame.size.width / 2.0;
		
		[nameTextField setFrame:nameTextFieldFrame];
		[[self attachedView] addSubview:nameTextField];
		
		// Caption field
		captionTextField = [FPTextField textFieldWithStringValue:@"" placeholder:@"No Selection" width:130.0];
		[captionTextField setAutoresizingMask:CPViewMaxYMargin];
		
		var captionTextFieldFrame = [captionTextField frame];
		//[captionTextField setLineBreakMode:CPLineBreakByWordWrapping];
		captionTextFieldFrame.origin.y = 44.0;
		captionTextFieldFrame.size.height = 70.0;
		captionTextFieldFrame.origin.x = [[self contentView] frame].size.width / 2.0 - captionTextFieldFrame.size.width / 2.0;
		
		[captionTextField setFrame:captionTextFieldFrame];
		[[self attachedView] addSubview:captionTextField];
	}
	
	return self;
}

- (void)controlTextDidChange:(CPNotification)aNotification
{
	if (representedMediaItem != nil) {
		if ([aNotification object] == nameTextField)
			[representedMediaItem setTitle:[nameTextField stringValue]];
	}
}

@end