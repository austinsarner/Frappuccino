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

@import "MDManagedObject.j"
@import "MediaGroup.j"
@import "CCImageTypes.j"

@implementation MediaItem : MDManagedObject
{
	CPImage _cachedImage;
	
	var finishedCachingDelegate;
	var thumbnailLoaded;
	var loadingThumbnail;
	var sizeDetermined;
}

- (id)initWithEntity:(CPString)entity
{
	if (self = [super initWithEntity:entity])
	{
		loadingThumbnail = NO;
		thumbnailLoaded = NO;
	}
	return self;
}

- (BOOL)loadingThumbnail
{
	return loadingThumbnail;
}

- (BOOL)thumbnailLoaded
{
	return thumbnailLoaded;
}

- (CPImage)thumbnailImage
{
	return _cachedImage;
}

- (CPString)thumbnailURL
{
	return [CPURL URLWithString:[self recordValueForKey:@"media_thumb_url"]];
    
	// var host = [CPString stringWithFormat:@"http://%@",[[CPApp delegate] backendDomain]];
	// var urlString = [CPString stringWithFormat:@"%@/media/image/%@%@",host,[self uid],[self recordValueForKey:@"thumbnail_suffix"]];
	// return [CPURL URLWithString:urlString];
}

- (void)cacheThumbnailWithDelegate:(var)newFinishedCachingDelegate
{
	loadingThumbnail = YES;
	finishedCachingDelegate = newFinishedCachingDelegate;
	
	_cachedImage = [[CPImage alloc] initWithContentsOfFile:[[self thumbnailURL] absoluteString]];
	[_cachedImage setDelegate:self];
}

- (void)loadThumbnail:(id)sender
{
	[self cacheThumbnailWithDelegate:_tempCacheDelegate];
}

- (void)imageDidLoad:(var)image
{
	thumbnailLoaded = YES;
	loadingThumbnail = NO
	[finishedCachingDelegate finishedLoadingThumbnailImage:self];
}

- (CPString)name
{
	return [self recordValueForKey:@"name"];
}

- (CPString)uid
{
	return [self recordValueForKey:@"uuid"];
}

- (CPURL)mediaURL
{
    // var host = [CPString stringWithFormat:@"http://%@",[[CPApp delegate] backendDomain]];
    // var urlString = [CPString stringWithFormat:@"%@/media/image/%@%@",host,[self uid],[self recordValueForKey:@"media_suffix"]];
    // return [CPURL URLWithString:urlString];
	return [CPURL URLWithString:[self recordValueForKey:@"media_url"]];
}

- (CPSize)mediaSize
{
	var sizeString = [self recordValueForKey:@"media_size"];
	var sizeComponents = [sizeString componentsSeparatedByString:@"x"];
	
	if ([sizeComponents count] != 2)
		return CPMakeSize(0.0,0.0);
	
	return CPMakeSize([[sizeComponents objectAtIndex:0] floatValue],[[sizeComponents objectAtIndex:1] floatValue])
}

- (void)managedObjectRequestFinished:(id)request
{
}

- (void)recordValueForKey:(CPString)key
{
	return [self.recordDictionary valueForKey:key];
}

@end

@implementation Photo : MediaItem
{
	CPMutableDictionary thumbnailEffectImages;
}

- (id)initWithEntity:(CPString)entity
{
	if (self = [super initWithEntity:entity])
	{
		thumbnailEffectImages = [[CPMutableDictionary alloc] init];
	}
	
	return self;
}

- (CPImage)thumbnailImageWithEffect:(CCImageEffect)effect
{
	var effectID = [CPString stringWithFormat:@"%d",effect];
	var thumbnailImage = [thumbnailEffectImages valueForKey:effectID];
	if (thumbnailImage == nil)
	{
		var domain = [[CPApp delegate] backendDomain];
		var thumbnailURL = [CPString stringWithFormat:@"http://%@/media/imagefx/%@/%@.jpg",domain,[self uid],effectID];

		thumbnailImage = [[CPImage alloc] initWithContentsOfFile:thumbnailURL];
		[thumbnailEffectImages setValue:thumbnailImage forKey:effectID];
	}
	return thumbnailImage;
}

@end

@implementation Audio : MediaItem
{
	
}

@end

@implementation Video : MediaItem
{
	
}

@end