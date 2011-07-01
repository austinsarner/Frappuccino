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

@implementation JTImageAdjustmentView : CPView
{
	
}

- (id)initWithFrame:(CPRect)aRect
{
	if (self = [super initWithFrame:aRect])
	{
		//var sliderFrame = CPMakeRect(40.0,40.0,CGRectGetWidth(aRect)-50.0,28.0);
		//var slider = [[FPSlider alloc] initWithFrame:sliderFrame];
		//[self addSubview:slider]
		
		var exposureLabel = [CPTextField labelWithTitle:@"Exposure:"];
		[exposureLabel setFrame:CGRectMake(20.0,30.0,60.0,28.0)];
		[exposureLabel setTextColor:[CPColor whiteColor]];
		[exposureLabel setFont:[CPFont boldSystemFontOfSize:11.0]];
		[self addSubview:exposureLabel];
		
		var exposureSlider = [[FPSlider alloc] initWithFrame:CGRectMake(82.0,26.0,205.0,28.0)];
		[exposureSlider setMinValue:-1.0];
		[exposureSlider setMaxValue:1.0];
		[exposureSlider setFloatValue:0.0];
		[exposureSlider setTarget:self];
		[exposureSlider setAction:@selector(sliderAdjusted:)];
		[exposureSlider setAutoresizingMask:CPViewMinXMargin];
		[self addSubview:exposureSlider];
		
		var contrastLabel = [CPTextField labelWithTitle:@"Contrast:"];
		[contrastLabel setFrame:CGRectMake(24.0,60.0,60.0,28.0)];
		[contrastLabel setTextColor:[CPColor whiteColor]];
		[contrastLabel setFont:[CPFont boldSystemFontOfSize:11.0]];
		[self addSubview:contrastLabel];
		
		var contrastSlider = [[FPSlider alloc] initWithFrame:CGRectMake(82.0,56.0,205.0,28.0)];
		[contrastSlider setMinValue:-1.0];
		[contrastSlider setMaxValue:1.0];
		[contrastSlider setFloatValue:0.0];
		[contrastSlider setTarget:self];
		[contrastSlider setAction:@selector(sliderAdjusted:)];
		[contrastSlider setAutoresizingMask:CPViewMinXMargin];
		[self addSubview:contrastSlider];
		
		var saturationLabel = [CPTextField labelWithTitle:@"Saturation:"];
		[saturationLabel setFrame:CGRectMake(16.0,90.0,64.0,28.0)];
		[saturationLabel setTextColor:[CPColor whiteColor]];
		[saturationLabel setFont:[CPFont boldSystemFontOfSize:11.0]];
		[self addSubview:saturationLabel];
		
		var saturationSlider = [[FPSlider alloc] initWithFrame:CGRectMake(82.0,86.0,205.0,28.0)];
		[saturationSlider setMinValue:-1.0];
		[saturationSlider setMaxValue:1.0];
		[saturationSlider setFloatValue:0.0];
		[saturationSlider setTarget:self];
		[saturationSlider setAction:@selector(sliderAdjusted:)];
		[saturationSlider setAutoresizingMask:CPViewMinXMargin];
		[self addSubview:saturationSlider];
		
	}
	return self;
}

- (void)sliderAdjusted:(id)slider
{
	
}

@end