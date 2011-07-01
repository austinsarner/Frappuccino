/*
 * FPMovieView.j
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

@implementation FPMovieView : CPView
{
	FPMovie	movie			@accessors;
	BOOL controllerVisible	@accessors;
	DOMElement videoElement	@accessors;
}

- (id)initWithFrame:(CPRect)frame
{
	if (self = [super initWithFrame:frame])
	{
		videoElement = document.createElement("video");
		
	    videoElement.style.width  = "100%";
	    videoElement.style.height = "100%";
		
		_DOMElement.appendChild(videoElement);
	}
	return self;
}

- (void)setMovie:(FPMovie)aMovie
{
	movie = aMovie;
	videoElement.src = [aMovie URLString];
}

- (void)play:(id)sender
{
	videoElement.play();
}

- (void)pause:(id)sender
{
	
}

- (void)stop:(id)sender
{
	
}

@end

@implementation FPMovie : CPObject
{
	CPString URLString	@accessors;
}

- (id)initWithContentsOfURL:(CPURL)url byReference:(BOOL)ref
{
	if (self = [super init])
		self.URLString = [url absoluteString];
	return self;
}

+ (FPMovie)movieWithURL:(CPURL)url
{
	var movie = [[self alloc] initWithContentsOfURL:url byReference:YES];
	return [movie autorelease];
}

@end