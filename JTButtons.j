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

@import "JTMediaItemCell.j"

@implementation JTButton : CPView
{
	var highlighted @accessors;

	id target @accessors;
	SEL action @accessors;
}

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		highlighted = NO;
	}

	return self;
}

- (void)mouseDown:(CPEvent)event
{
	highlighted = YES;
	[self setNeedsDisplay:YES];
}

- (void)mouseUp:(CPEvent)event
{
	if (highlighted && target != nil)
		[target performSelector:action];

	highlighted = NO;
	[self setNeedsDisplay:YES];
}

- (void)mouseDragged:(CPEvent)event
{
	var location = [[self superview] convertPoint:[event locationInWindow] fromView:nil];
	if (CGRectContainsPoint([self frame],location))
		highlighted = YES;
	else
		highlighted = NO;

	[self setNeedsDisplay:YES];
}

@end

@implementation JTInsetButton : JTButton
{
	
}

- (void)drawRect:(CPRect)aRect
{
	var borderRect = CPMakeRect(CGRectGetMaxX([self bounds])-1,1,1,CGRectGetHeight([self bounds])-1);
	[[CPColor insetColor] set];
	var borderPath = [CPBezierPath bezierPathWithRect:borderRect];
	[borderPath fill];
	
	borderRect.origin.x-=2;
	var borderPath = [CPBezierPath bezierPathWithRect:borderRect];
	[borderPath fill];
	
	borderRect.origin.x++;
	[[CPColor borderColor] set];
	var borderPath = [CPBezierPath bezierPathWithRect:borderRect];
	[borderPath fill];
}

@end

@implementation JTActivityButton : JTInsetButton
{
	
}

- (void)drawRect:(CPRect)aRect
{
	if ([self highlighted])
		[[CPColor colorWithCalibratedWhite:1.0 alpha:0.8] set];
	else
		[[CPColor colorWithCalibratedWhite:1.0 alpha:0.5] set];
		
	[CPGraphicsContext saveGraphicsState];
	[[FPShadow shadowWithOffset:CPMakePoint(0,-1) blur:0 color:[CPColor colorWithCalibratedWhite:0.0 alpha:0.8]] set];
	var plusThickness = 4;
	var plusRect = CPMakeRect(13,11,14,14);
	var plusPath = [CPBezierPath bezierPathWithRect:CPMakeRect(plusRect.origin.x,CGRectGetMidY(plusRect)-plusThickness/2,plusRect.size.width,plusThickness)];
	[plusPath appendBezierPath:[CPBezierPath bezierPathWithRect:CPMakeRect(CGRectGetMidX(plusRect)-plusThickness/2,plusRect.origin.y,plusThickness,plusRect.size.height)]];
	[plusPath fill];
	[CPGraphicsContext restoreGraphicsState];
	
	[super drawRect:aRect];
}

@end

@implementation JTAddButton : JTInsetButton
{
}

- (void)drawRect:(CPRect)aRect
{
	if ([self highlighted])
		[[CPColor colorWithCalibratedWhite:1.0 alpha:0.8] set];
	else
		[[CPColor colorWithCalibratedWhite:1.0 alpha:0.5] set];

	[CPGraphicsContext saveGraphicsState];
	[[FPShadow shadowWithOffset:CPMakePoint(0,-1) blur:0 color:[CPColor colorWithCalibratedWhite:0.0 alpha:0.8]] set];
	var plusThickness = 4;
	var plusRect = CPMakeRect(13,11,14,14);
	var plusPath = [CPBezierPath bezierPathWithRect:CPMakeRect(plusRect.origin.x,CGRectGetMidY(plusRect)-plusThickness/2,plusRect.size.width,plusThickness)];
	[plusPath appendBezierPath:[CPBezierPath bezierPathWithRect:CPMakeRect(CGRectGetMidX(plusRect)-plusThickness/2,plusRect.origin.y,plusThickness,plusRect.size.height)]];
	[plusPath fill];
	[CPGraphicsContext restoreGraphicsState];
	
	[super drawRect:aRect];
}

@end

@implementation JTOpenFilesAddButton : JTAddButton
{
	var fileElement;
	var formElement;
	var submitElement;
	var iFrameElement;
	
	var mediaBrowserToUpdate @accessors;
}

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		
		[self setTarget:self];
		[self setAction:@selector(showOpenPanel)];
		
		formElement = document.createElement("form");
		formElement.method = "POST";
		formElement.enctype = "multipart/form-data";
		formElement.target = "upload_target";
		
		var domain = [[CPApp delegate] backendDomain]
		formElement.action = [CPString stringWithFormat:@"http://%@/media/upload/",domain];
		
		iFrameElement = document.createElement("iframe");
		iFrameElement.style.display = "none";
		iFrameElement.name = "upload_target";
		iFrameElement.id = "upload_target";
		iFrameElement.src = "";
		formElement.appendChild(iFrameElement);
		
		fileElement = document.createElement("input");
		fileElement.setAttribute("name", "file");
		fileElement.setAttribute("type", "file");
		fileElement.setAttribute("multiple", "true");
		fileElement.style.position = "absolute";
		fileElement.style.bottom = 0;
		fileElement.style.height = 0;
		fileElement.style.opacity = 0;
		fileElement.onchange = function() {
										formElement.submit();
										iFrameElement.onload = function()
										{
											var responseData = iFrameElement.contentWindow.document.body.innerHTML;
											[self mediaUploaded:responseData];
										};
									};
		formElement.appendChild(fileElement);
		
		submitElement = document.createElement("input");
		submitElement.type = "submit";
		submitElement.style.display = "none";
		formElement.appendChild(submitElement);
		
		//fileElement.style.display = "none";
		_DOMElement.appendChild(formElement);		
	}
	
	return self;
}

- (void)mediaUploaded:(CPString)response
{
	var elementComponents = [response componentsSeparatedByString:@">"];
	var jsonString = [elementComponents objectAtIndex:1];
	jsonString = [[jsonString componentsSeparatedByString:@"<"] objectAtIndex:0];
	
	var mediaDictionary = [CPDictionary dictionaryWithJSObject:[jsonString objectFromJSON] recursively:YES];
	var mediaItem = [MDManagedObject objectWithDictionary:[mediaDictionary valueForKey:@"response"]];
	[[[MediaLibrary sharedMediaLibrary] mediaItems] addObject:mediaItem];
	
	window.setTimeout(function(){
	var mediaCell = [[JTMediaItemCell alloc] initWithRepresentedObject:[[[MediaLibrary sharedMediaLibrary] mediaItems] lastObject]];
	mediaCell.uniqueID = [mediaItem uid];
	[mediaBrowserToUpdate addMediaItemCell:mediaCell];
	},10.0);
}

- (void)showOpenPanel
{
	fileElement.click();
}

@end