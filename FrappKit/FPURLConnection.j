/*
 * FPURLConnection.j
 * Frappuccino
 *
 * Created by Austin Sarner and Mark Davis.
 * Copyright 2010 Austin Sarner and Mark Davis.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@implementation FPURLConnection : CPObject
{
	CPURLRequest request	@accessors;
	id delegate				@accessors;
	BOOL isCanceled			@accessors;
	/* @ignore */
	JSObject _XMLHTTPRequest;
	BOOL completed;
}

- (id)initWithRequest:(CPURLRequest)aRequest delegate:(id)aDelegate startImmediately:(BOOL)shouldStartImmediately
{
	if (self = [super init])
	{
		self.request = aRequest;
		self.delegate = aDelegate;
		isCancelled = NO;
		
		if (shouldStartImmediately) [self start];
	}
	return self;
}

- (id)initWithRequest:(CPURLRequest)aRequest delegate:(id)aDelegate
{
	return [self initWithRequest:aRequest delegate:aDelegate startImmediately:YES];
}

+ (id)connectionWithRequest:(CPURLRequest)aRequest delegate:(id)aDelegate
{
	return [[[self alloc] initWithRequest:aRequest delegate:aDelegate] autorelease];
}

- (void)start
{
	completed = NO;
	_XMLHTTPRequest = new XMLHttpRequest();
	_XMLHTTPRequest.addEventListener("load",function (anEvent){[self _xmlHTTPRequestLoaded]},false);
	_XMLHTTPRequest.addEventListener("error",function (anEvent){[self _xmlHTTPRequestFailed]},false);
	_XMLHTTPRequest.addEventListener("load",function (anEvent) {[self _xmlHTTPRequestAborted]},false);
	_XMLHTTPRequest.open("GET", [[self.request URL] absoluteString], true);
	_XMLHTTPRequest.send(null);
}

/* @ignore */

- (void)_xmlHTTPRequestLoaded
{
	completed = YES;
	[self.delegate connection:self didReceiveData:_XMLHTTPRequest.responseText];
	[self.delegate connectionDidFinishLoading:self];
}

- (void)_xmlHTTPRequestFailed
{
	[self.delegate connection:self didFailWithError:@"unknown"];
}

- (void)_xmlHTTPRequestAborted
{
	if (!completed)
		[self.delegate connectionDidFinishLoading:self];
}

@end