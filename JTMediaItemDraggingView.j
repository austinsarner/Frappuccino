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

@implementation JTMediaItemDraggingView : CPView
{
	CPMutableArray draggedMediaItemCells @accessors;
}

- (void)drawRect:(CGRect)dirtyRect
{
	var currentOffset = 0.0;
	
	for (var i = 0; i < [draggedMediaItemCells count]; i++) {
		
		var currentMediaItemCell = [draggedMediaItemCells objectAtIndex:i];
		var currentMediaItemCellFrame = CPRectCreateCopy([currentMediaItemCell frame]);
		currentMediaItemCellFrame.origin = CGPointMake(currentOffset,currentOffset);
		
		[currentMediaItemCell setShouldIgnoreSelection:YES];
		[currentMediaItemCell drawWithFrame:currentMediaItemCellFrame useCachedImageIfAvailable:NO alpha:0.6];
		
		currentOffset += 5.0;
	}
}

- (void)setDraggedMediaItemCells:(CPArray)newDraggedMediaItemCells
{
	draggedMediaItemCells = newDraggedMediaItemCells;
	
	var currentOffset = 0.0;
	var adjustedFrame = CPRectCreateCopy([self frame]);
	
	for (var i = 0; i < [draggedMediaItemCells count]; i++) {
		
		adjustedFrame.size.width += currentOffset;
		adjustedFrame.size.height += currentOffset;

		currentOffset += 5.0;
	}
	
	[self setFrame:adjustedFrame];
	[self setNeedsDisplay:YES];
}