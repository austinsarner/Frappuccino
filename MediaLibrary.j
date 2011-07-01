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

@import "FrappKit/FPLocalDatabase.j"
@import "MDManagedObject.j"
@import "MediaItem.j"
@import "MediaGroup.j"
@import "FrappKit/FPUUID.j"

var sharedMediaLibrary;
var MEDIA_ITEMS_REQ = @"MEDIAITEM";
var MEDIA_GROUPS_REQ = @"MEDIAGROUP";

@implementation MediaLibrary : CPObject
{
	CPMutableArray mediaItems @accessors;
	CPMutableArray mediaGroups @accessors;
	//JTLocalDatabase	database @accessors;
	//BOOL supportsDatabase;
}

- (id)init
{
	if (self = [super init])
	{
		mediaItems = nil;
		mediaGroups = nil;
	}
	return self;
}

+ (MediaLibrary)sharedMediaLibrary
{
	if (!sharedMediaLibrary)
		sharedMediaLibrary = [[self alloc] init];
	return sharedMediaLibrary;
}

- (MediaItem)mediaItemWithID:(CPString)uid
{
	for (var i=0;i<[mediaItems count];i++)
	{
		var mediaItem = [mediaItems objectAtIndex:i];
		if ([[mediaItem uid] isEqual:uid])
			return mediaItem;
	}
	return nil;
}

- (CPMutableArray)mediaItems
{
	if (mediaItems != nil)
		return mediaItems;
	return [CPMutableArray array];
}

- (CPMutableArray)mediaGroups
{
	if (mediaGroups != nil)
		return mediaGroups;
	return [CPMutableArray array];
}

- (id)init
{
	if (self = [super init])
	{
		[self loadMedia];
	}
	return self;
}

- (void)loadMedia
{       
    var request = [CPURLRequest requestWithURL:[CPURL URLWithString:"http://www.flickr.com/services/rest/?method=flickr.photos.search&tags=cappuccino&media=photos&machine_tag_mode=any&per_page=200&extras=o_dims&format=json&content_type=1&api_key=bb18afb7693f4c25ed019fe2266889a2"]];
    [CPJSONPConnection sendRequest:request callback:"jsoncallback" delegate:self];

    mediaItems = [CPMutableArray array];
    
    //[[CPNotificationCenter defaultCenter] postNotificationName:@"JTMediaLibraryDidLoadNotification" object:self];
    //[[CPNotificationCenter defaultCenter] postNotificationName:@"JTMediaLibraryDidLoadNotification" object:self];
	//[[MDManagedObjectRequest requestWithDelegate:self uid:MEDIA_GROUPS_REQ] fetchObjectsAtPath:@"mediagroup"];
	//[[MDManagedObjectRequest requestWithDelegate:self uid:MEDIA_ITEMS_REQ] fetchObjectsAtPath:@"media"];
}

- (void)connection:(CPJSONPConnection)aConnection didReceiveData:(CPString)data
{
    var mediaGroup = [[MediaGroup alloc] initWithEntity:@"MediaGroup"];
    
    [mediaGroup setRecordValue:@"Haiti" forKey:@"name"];
    [mediaGroup setRecordValue:@"1" forKey:@"id"];
    [mediaGroup setRecordValue:Math.uuid() forKey:@"uuid"];
	
	for (var j = 0; j < [data.photos.photo count]; j++) {
		var photo = [data.photos.photo objectAtIndex:j];
		if (photo.o_width === undefined) {
			continue;
		}
			
		var mediaItem = [[Photo alloc] initWithEntity:@"Photo"];
		
	    [mediaItem setRecordValue:"http://farm"+photo.farm+".static.flickr.com/"+photo.server+"/"+photo.id+"_"+photo.secret+".jpg" forKey:@"media_url"];
	    [mediaItem setRecordValue:"http://farm"+photo.farm+".static.flickr.com/"+photo.server+"/"+photo.id+"_"+photo.secret+"_m.jpg" forKey:@"media_thumb_url"];
	    [mediaItem setRecordValue:[CPString stringWithFormat:@"%d", j] forKey:@"id"];
	    [mediaItem setRecordValue:Math.uuid() forKey:@"uuid"];
		[mediaItem setRecordValue:photo.title forKey:@"title"];	
		[mediaItem setRecordValue:photo.o_width + "x" + photo.o_height forKey:@"media_size"];
		
	    [mediaGroup addMediaItem:mediaItem];
	    [mediaItems addObject:mediaItem];
	}
    
    mediaGroups = [CPMutableArray array];
    [mediaGroups addObject:mediaGroup];
}

- (void)connection:(CPJSONPConnection)aConnection didFailWithError:(CPString)error
{
    alert(error); //a network error occurred
}

- (void)managedObjectRequestFinished:(MDManagedObjectRequest)request
{
	var dictionary = [request responseDictionary];
	
	if ([request.uid isEqualToString:MEDIA_ITEMS_REQ])
	{
		self.mediaItems = [CPMutableArray array];
		var objects = [request responseObjects];
		
		for (var i=0;i<[objects count];i++)
		{
			var object = [objects objectAtIndex:i];
			[mediaItems addObject:object];
		}
	}
	else if ([request.uid isEqualToString:MEDIA_GROUPS_REQ])
	{
		self.mediaGroups = [CPMutableArray array];
		var objects = [request responseObjects];
		
		for (var i=0;i<[objects count];i++)
		{
			var object = [objects objectAtIndex:i];
			[mediaGroups addObject:object];
		}
	}
	
	if ((mediaGroups != nil)&&(mediaItems != nil))
		[[CPNotificationCenter defaultCenter] postNotificationName:@"JTMediaLibraryDidLoadNotification" object:self];
}

- (void)managedObjectRequestFailed:(MDManagedObjectRequest)request
{
	if ([request.uid isEqualToString:MEDIA_ITEMS_REQ])
	{
		CPLog(@"MEDIA REQUEST FAILED");
	}
}

@end