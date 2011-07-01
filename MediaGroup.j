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
@import "MediaLibrary.j"

@implementation MediaGroup : MDManagedObject
{
	CPMutableArray mediaItemIDs;
}

- (id)initWithEntity:(CPString)entity
{
	if (self = [super initWithEntity:entity])
	{
		mediaItemIDs = nil;
	}
	return self;
}

- (CPString)name
{
	return [self recordValueForKey:@"name"];
}

- (CPImage)icon
{
	return [CPImage imageNamed:@"sidebaricons/page.png"];
}

- (CPMutableArray)mediaItems
{   
	if (mediaItemIDs == nil)
	{
		mediaItemIDs = [[CPMutableArray alloc] init];
		[mediaItemIDs addObjectsFromArray:[self recordValueForKey:@"media_items"]];
	}
	
	var mediaItems = [[MediaLibrary sharedMediaLibrary] mediaItems];
	var mediaArray = [CPMutableArray array];
	for (var i=0;i<[mediaItems count];i++)
	{
		var mediaItem = [mediaItems objectAtIndex:i];
		var mediaID = [mediaItem recordValueForKey:@"id"];
		
		if ([mediaItemIDs containsObject:mediaID])
			[mediaArray addObject:mediaItem];
	}
	return mediaArray;
}

- (void)addMediaItem:(id)mediaItem
{
	if (mediaItemIDs == nil)
	    mediaItemIDs = [[CPMutableArray alloc] init];

	var mediaItemID = [mediaItem recordValueForKey:@"id"];
	
	if (![mediaItemIDs containsObject:mediaItemID])
	{
		var groupID = [self recordValueForKey:@"id"];
		[mediaItemIDs addObject:mediaItemID];
		
        // var request = [MDManagedObjectRequest requestWithDelegate:self uid:@"add_media_item_to_group"];
        // var command = [CPString stringWithFormat:@"add_item/%@/%@",groupID,mediaItemID];
        // [request performCommand:command atPath:@"mediagroup"];
	}
}

- (void)removeMediaItem:(id)mediaItem
{
	var mediaItemID = [mediaItem recordValueForKey:@"id"];
	
	if ([mediaItemIDs containsObject:mediaItemID])
	{
		var groupID = [self recordValueForKey:@"id"];
		[mediaItemIDs removeObject:mediaItemID];
		
        // var request = [MDManagedObjectRequest requestWithDelegate:self uid:@"remove_media_item_from_group"];
        // var command = [CPString stringWithFormat:@"remove_item/%@/%@",groupID,mediaItemID];
        // [request performCommand:command atPath:@"mediagroup"];
	}
	
}

@end