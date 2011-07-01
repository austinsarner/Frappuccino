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

@implementation MDManagedObjectController : CPObject
{
	CPURL _backendURL @accessors(property=url);
	id	_delegate		@accessors(property=delegate);
	CPString _jsonData	@accessors(property=jsonData);
	CPString _apiKey	@accessors(property=apiKey);
	int	method			@accessors(property=method);
}

- (id)initWithURL:(CPURL)aURL delegate:(id)aDelegate
{
	if (self = [super init])
	{
		self.delegate = aDelegate;
		self.url = aURL;
		self.apiKey = @"testkey213";
	}
	return self;
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

- (void)fetchObjectsWithEntity:(CPString)entity
{
	CPLog(@"fetch %@s",entity);
	self.method = 1;
	self.jsonData = @"";
	var requestUrl = [CPString stringWithFormat:@"%@/%@/search/?api_key=%@",[self.url absoluteString],entity,self.apiKey];
	var request = [CPURLRequest requestWithURL:requestUrl];
	var connection = [CPURLConnection connectionWithRequest:request delegate:self];
}

- (void)fetchObjectWithID:(CPString)objectID forEntity:(CPString)entity
{
	self.method = 2;
	self.jsonData = @"";
	var requestUrl = [CPString stringWithFormat:@"%@/%@/view/%@/?api_key=%@",[self.url absoluteString],entity,objectID,self.apiKey];
	var request = [CPURLRequest requestWithURL:requestUrl];
	var connection = [CPURLConnection connectionWithRequest:request delegate:self];
}

- (void)connection:(CPURLConnection)aConnection didReceiveData:(CPString)data
{
	self.jsonData = [self.jsonData stringByAppendingString:data];
}

- (void)connection:(CPURLConnection)aConnection didFailWithError:(CPString)error
{
	alert(error);
}

- (void)connectionDidFinishLoading:(CPURLConnection)aConnection
{
	CPLog(self.jsonData);
	var jsonObject = [self.jsonData objectFromJSON];
	if ([jsonObject["code"] isEqualToString:@"0"])
		alert(@"Download Failed");
	else
	{
		[self.delegate managedObjectControllerLoadedObjects:jsonObject["response"]];
	}
}

@end