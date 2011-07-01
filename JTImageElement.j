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

@import "JTElement.j"

@implementation JTImageElement : JTElement
{
	CPImage	image @accessors;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		self.usesInspector = YES;
		self.proportionalScale = YES;
	}
	return self;
}

- (void)setImage:(CPImage)anImage
{
	image = anImage;
	[image setDelegate:self];
	if ([image loadStatus]==CPImageLoadStatusCompleted)
		[self setNeedsDisplay:YES];
}

- (void)imageDidLoad:(CPImage)loadedImage
{
	[self setImage:loadedImage];
}

- (void)drawRect:(CPRect)aRect
{
	var imageRect = CGRectInset([self bounds],padding,padding);
	var imageSize = [image size];
	
	if (imageSize.width > imageSize.height)
	{
		var newImageHeight = imageSize.height * (imageRect.size.width / imageSize.width);
		imageRect.origin.y = CGRectGetMidY(imageRect) - newImageHeight/2;
		imageRect.size.height = newImageHeight;
	}
	else if (imageSize.height > imageSize.width)
	{
		var newImageWidth = imageSize.width * (imageRect.size.height / imageSize.height);
		imageRect.origin.x = CGRectGetMidX(imageRect) - newImageWidth/2;
		imageRect.size.width = newImageWidth;
	}
	
	if (image && [image loadStatus]==CPImageLoadStatusCompleted)
		[image drawInRect:imageRect fraction:1.0];
	
	[super drawRect:aRect];
}

- (void)mouseEntered:(CPEvent)event
{
	CPLog(@"mouse entered");
}

- (void)mouseExited:(CPEvent)event
{
	CPLog(@"mouse exited");
}

- (void)mouseMoved:(CPEvent)event
{
	CPLog(@"mouse moved");
}

@end