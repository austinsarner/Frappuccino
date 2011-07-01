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

/*

@protocol MDManagedObjectRequestDelegate
- (void)managedObjectRequestFailed:(MDManagedObjectRequest)request;
- (void)managedObjectRequestFinished:(MDManagedObjectRequest)request;
@end

*/

@implementation MDManagedObjectRequest : CPObject
{
	CPURL _backendURL @accessors(property=url);
	id	_delegate		@accessors(property=delegate);
	CPString _jsonData	@accessors(property=jsonData);
	CPString _apiKey	@accessors(property=apiKey);
	int	method			@accessors(property=method);
	//CPString _fetchedEntity @accessors(property=fetchedEntity);
	CPString _uid @accessors(property=uid);
}

- (id)initWithDelegate:(id)aDelegate
{
	if (self = [super init])
	{
		self.delegate = aDelegate;
		var urlString = [CPString stringWithFormat:@"http://%@",[[CPApp delegate] backendDomain]];
		self.url = [CPURL URLWithString:urlString];
		self.apiKey = @"testkey213";
	}
	return self;
}

+ (id)requestWithDelegate:(id)aDelegate uid:(CPString)uniqueID
{
	var request = [[self alloc] initWithDelegate:aDelegate];
	request.uid = uniqueID;
	return [request autorelease];
}

- (void)insertObject:(MDManagedObject)anObject
{
	
}

- (void)deleteObject:(MDManagedObject)anObject
{
	
}

/*- (CPURL)apiURLForEntity:(CPString)entity
{
	var urlString = [[self.url absoluteString] stringByAppendingFormat:@"/%@",entity];
	return [CPURL URLWithString:urlString];
}*/

- (void)fetchObjectsAtPath:(CPString)path
{
	self.method = 1;
	self.jsonData = @"";
	var requestURL = [CPString stringWithFormat:@"%@/%@/?api_key=%@",[self.url absoluteString],[path lowercaseString],self.apiKey];
	CPLog(requestURL);
	var request = [CPURLRequest requestWithURL:[CPURL URLWithString:requestURL]];
	var connection = [FPURLConnection connectionWithRequest:request delegate:self];
}

- (void)performCommand:(CPString)command atPath:(CPString)path
{
	//add_to_group
	self.method = 2;
	self.jsonData = @"";
	var requestURL = [CPString stringWithFormat:@"%@/%@/%@/?api_key=%@",[self.url absoluteString],[path lowercaseString],command,self.apiKey];
	CPLog(requestURL);
	var request = [CPURLRequest requestWithURL:[CPURL URLWithString:requestURL]];
	var connection = [FPURLConnection connectionWithRequest:request delegate:self];
}

/*- (void)fetchObjectWithID:(CPString)objectID forEntity:(CPString)entity
{
	self.method = 2;
	self.jsonData = @"";
	var requestURL = [CPString stringWithFormat:@"%@/%@/view/%@/?api_key=%@",[self.url absoluteString],[entity lowercaseString],objectID,self.apiKey];
	var request = [CPURLRequest requestWithURL:[CPURL URLWithString:requestURL]];
	var connection = [FPURLConnection connectionWithRequest:request delegate:self];
}*/

- (void)connection:(FPURLConnection)aConnection didReceiveData:(CPString)data
{
	self.jsonData = [self.jsonData stringByAppendingString:data];
}

- (void)connection:(FPURLConnection)aConnection didFailWithError:(CPString)error
{
	alert(error);
}

- (void)connectionDidFinishLoading:(FPURLConnection)aConnection
{
	if ([[[self responseDictionary] valueForKey:@"code"] isEqualToString:@"0"])
		[self.delegate managedObjectRequestFailed:self];
	else
		[self.delegate managedObjectRequestFinished:self];
}

- (CPDictionary)responseDictionary
{
	return [CPDictionary dictionaryWithJSObject:[self.jsonData objectFromJSON] recursively:YES];
}

- (CPArray)responseObjects
{
	var managedObjects = [CPMutableArray array];
	var records = [[self responseDictionary] valueForKey:@"response"];
	if (records != nil)
	{
		var i;
		for (i=0;i<[records count];i++)
		{
			var recordInfo = [records objectAtIndex:i];
			[managedObjects addObject:[MDManagedObject objectWithDictionary:recordInfo]];
		}
	}
	return managedObjects;
}

@end