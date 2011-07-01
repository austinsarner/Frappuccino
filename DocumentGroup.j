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

@implementation DocumentGroup : MDManagedObject
{
}

- (CPString)name
{
	return [self recordValueForKey:@"name"];
}

- (CPImage)icon
{
	return [CPImage imageNamed:@"sidebaricons/page.png"];
}

- (CPMutableArray)documentItems
{
	var documentItems = [[DocumentLibrary sharedDocumentLibrary] documentItems];
	var documentArray = [CPMutableArray array];
	for (var i=0;i<[documentItems count];i++)
	{
		var documentItem = [documentItems objectAtIndex:i];
		var groupIDs = [documentItems recordValueForKey:@"groups"];
		if ([groupIDs containsObject:[self recordValueForKey:@"id"]])
			[documentArray addObject:documentItem];
	}
	return documentArray;
}

- (void)addDocument:(id)document
{
	// Do what Media Group does!
	
	//[document addToGroup:self];
}

@end