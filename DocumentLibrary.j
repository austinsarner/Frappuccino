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
@import "Document.j"
@import "DocumentGroup.j"

var sharedDocumentLibrary;
var DOCUMENT_ITEMS_REQ = @"DOCUMENTITEM";
var DOCUMENT_GROUPS_REQ = @"DOCUMENTGROUP";

@implementation DocumentLibrary : CPObject
{
	CPMutableArray documentItems @accessors;
	CPMutableArray documentGroups @accessors;
}

+ (DocumentLibrary)sharedDocumentLibrary
{
	if (!sharedDocumentLibrary)
		sharedDocumentLibrary = [[self alloc] init];
	return sharedDocumentLibrary;
}

- (Document)documentItemWithID:(CPString)uid
{
	for (var i=0;i<[documentItems count];i++)
	{
		var documentItem = [documentItems objectAtIndex:i];
		if ([[documentItem recordValueForKey:@"id"] isEqual:uid])
			return documentItem;
	}
	return nil;
}

- (CPMutableArray)documentItems
{
	if (documentItems)
		return documentItems;
	return [CPMutableArray array];
}

- (CPMutableArray)documentGroups
{
	if (documentGroups)
		return documentGroups;
	return [CPMutableArray array];
}

- (id)init
{
	if (self = [super init])
		[self loadDocuments];
	return self;
}

- (void)loadDocuments
{
	//[[MDManagedObjectRequest requestWithDelegate:self uid:DOCUMENT_GROUPS_REQ] fetchObjectsAtPath:@"documentgroup"];
	//[[MDManagedObjectRequest requestWithDelegate:self uid:DOCUMENT_ITEMS_REQ] fetchObjectsAtPath:@"document"];
}

- (void)managedObjectRequestFinished:(MDManagedObjectRequest)request
{
	var dictionary = [request responseDictionary];
	
	if ([request.uid isEqualToString:DOCUMENT_ITEMS_REQ])
	{
		self.documentItems = [CPMutableArray array];
		var objects = [request responseObjects];
		
		for (var i=0;i<[objects count];i++)
		{
			var object = [objects objectAtIndex:i];
			[documentItems addObject:object];
		}
	}
	else if ([request.uid isEqualToString:DOCUMENT_GROUPS_REQ])
	{
		self.documentGroups = [CPMutableArray array];
		var objects = [request responseObjects];
		
		for (var i=0;i<[objects count];i++)
		{
			var object = [objects objectAtIndex:i];
			[documentGroups addObject:object];
		}
	}
	
	if ((documentItems != nil)&&(documentGroups != nil))
		[[CPNotificationCenter defaultCenter] postNotificationName:@"JTDocumentLibraryDidLoadNotification" object:self];
}

- (void)managedObjectRequestFailed:(MDManagedObjectRequest)request
{
	if ([request.uid isEqualToString:DOCUMENT_ITEMS_REQ])
	{
		CPLog(@"Document REQUEST FAILED");
	}
}

@end