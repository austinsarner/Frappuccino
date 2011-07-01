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

var TableHighlightImageFilePath = "Resources/table_highlight.png",
	TableNormalImageFilePath = "Resources/voll/table_row.png";

@implementation Document : MDManagedObject
{
	CPImage _cachedImage;
	var finishedCachingDelegate;
	var thumbnailLoaded;
	var loadingThumbnail;
	CPString markup;
}

- (id)initWithEntity:(CPString)entity
{
	if (self = [super initWithEntity:entity]) {

		loadingThumbnail = NO;
		thumbnailLoaded = NO;
		return self;
	}

	return nil;
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

- (void)cacheThumbnailWithDelegate:(var)newFinishedCachingDelegate
{
	loadingThumbnail = YES;
	finishedCachingDelegate = newFinishedCachingDelegate;

	_cachedImage = [[CPImage alloc] initWithContentsOfFile:[self recordValueForKey:@"thumbnail_url"]];
	[_cachedImage setDelegate:self];
}

- (void)imageDidLoad:(var)image
{
	thumbnailLoaded = YES;
	loadingThumbnail = NO;
	[finishedCachingDelegate finishedLoadingThumbnailImage:self];
}

- (CPString)thumbnailPath
{
	return [self recordValueForKey:@"thumbnail_url"];
}

- (CPString)name
{
	//CPLog([[self recordDictionary] description]);
	return [self recordValueForKey:@"name"];
}

- (CPURL)documentURL
{
	return [CPURL URLWithString:[self recordValueForKey:@"document_url"]];
}

- (CPString)markup
{
	if (!markup)
	{
		markup = [CPString stringWithContentsOfURL:[self documentURL]];
	}
	return markup;
}

/*- (CPImage)image
{
	return [self recordValueForKey:@"thumbnail_url"];
}*/

- (BOOL)isPhotoCollection
{
	return ([[self recordValueForKey:@"type"] isEqual:@"photos"]);
}

@end

@implementation Article : Document
{
}

@end

@implementation Gallery : Document
{
}

- (void)cacheThumbnailWithDelegate:(var)newFinishedCachingDelegate
{
	loadingThumbnail = YES;
	finishedCachingDelegate = newFinishedCachingDelegate;

	_cachedImage = [[CPImage alloc] initWithContentsOfFile:@"gallery_thumbnail.png"];
	[_cachedImage setDelegate:self];
}

@end