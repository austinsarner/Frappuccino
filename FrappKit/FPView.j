/*
 * FPView.j
 * Frappuccino
 *
 * Created by Austin Sarner and Mark Davis.
 * Copyright 2010 Austin Sarner and Mark Davis.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@implementation FPView : CPView
{
	BOOL _setupMouseMoved;
	BOOL shouldTrackMouseMoved @accessors;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		shouldTrackMouseMoved = NO;
		_setupMouseMoved = NO;
	}
	return self;
}

- (void)displayRectIgnoringOpacity:(CGRect)aRect inContext:(CPGraphicsContext)aGraphicsContext
{
	[self lockFocus];
	
	CGContextClearRect([[CPGraphicsContext currentContext] graphicsPort], aRect);
	
	if ([self backgroundColor] && [[self backgroundColor] alphaComponent]>0.0)
	{
		[[self backgroundColor] setFill];
		CGContextFillRect([[CPGraphicsContext currentContext] graphicsPort],aRect);
	}
	
	[self drawRect:aRect];
	[self unlockFocus];
}

- (void)lockFocus
{
	[super lockFocus];
	if (shouldTrackMouseMoved==YES && _setupMouseMoved==NO && _DOMContentsElement)
	{
		_setupMouseMoved = YES;
		_DOMContentsElement.onmousemove = function (event) { [self _mouseMovedEventReceived:event]; };
	}
}

- (void)_mouseMovedEventReceived:(DOMEvent)aDOMEvent
{
	var type = aDOMEvent.type,
        location = CPMakePoint(aDOMEvent.clientX, aDOMEvent.clientY),
        timestamp = aDOMEvent.timeStamp ? aDOMEvent.timeStamp : new Date(),
        sourceElement = (aDOMEvent.target || aDOMEvent.srcElement),
        windowNumber = 0,
        modifierFlags = (aDOMEvent.shiftKey ? CPShiftKeyMask : 0) | 
                        (aDOMEvent.ctrlKey ? CPControlKeyMask : 0) | 
                        (aDOMEvent.altKey ? CPAlternateKeyMask : 0) | 
                        (aDOMEvent.metaKey ? CPCommandKeyMask : 0);
	
	var mouseEvent = [CPEvent mouseEventWithType:type location:location modifierFlags:modifierFlags timestamp:timestamp windowNumber:windowNumber context:nil eventNumber:-1 clickCount:0 pressure:0.0];
	[self mouseMoved:mouseEvent];
}

- (void)mouseMoved:(CPEvent)mouseEvent
{
	//var localPoint = [self convertPoint:[mouseEvent locationInWindow] fromView:nil];
	//CPLog(@"mouse moved: {%f,%f}",localPoint.x,localPoint.y);
}

@end