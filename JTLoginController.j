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

@import "JTSpinner.j"

var LOGIN_PANEL_RESOURCE = @"Resources/login_panel.png",
	LOGIN_HEADER_RESOURCE = @"Resources/login_header.png";

@implementation JTLoginController : CPObject
{
	CPWindow	loginWindow @accessors;
	JPButton	loginButton;
	FPTextField	usernameField;
	JTSpinner	spinner;
	FPTextField	passwordField;
	CPString	apiKey;
	CPString	jsonData;
	//CPWindow	loginWindow;
	id			delegate @accessors;
}

-(id)initWithDelegate:(id)aDelegate
{
	if (self=[super init])
	{
		self.delegate = aDelegate;
		
		loginWindow = [[CPWindow alloc] initWithContentRect:[aDelegate.mainWindow frame] styleMask:CPBorderlessWindowMask];
		[loginWindow setBackgroundColor:[CPColor colorWithCalibratedWhite:0.2 alpha:1.0]];
		[loginWindow setLevel:6];
		[loginWindow setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
		[loginWindow setDelegate:self];
		[loginWindow center];
		
		// Content
		var	contentView = [loginWindow contentView],
			bounds = [contentView bounds];
		
		var loginViewRect = CPMakeRect(0,0,350,200);
		loginViewRect.origin = CPMakePoint(CGRectGetMidX(bounds)-loginViewRect.size.width/2,CGRectGetMidY(bounds)-loginViewRect.size.height/2);
		
		var loginView = [[JTLoginView alloc] initWithFrame:loginViewRect];
		[loginView setAutoresizingMask:CPViewMinYMargin|CPViewMaxYMargin|CPViewMinXMargin|CPViewMaxXMargin];
		
		var welcomeField = [CPTextField labelWithTitle:@"Journalist Login"];
		[welcomeField setFont:[CPFont boldSystemFontOfSize:20]];
		[welcomeField setFrame:CPMakeRect(90,25,160,40)];
		[loginView addSubview:welcomeField];
		
		// Username Field
		usernameField = [FPTextField textFieldWithStringValue:@"" placeholder:@"Username" width:280];
		[usernameField setFrame:CPMakeRect(39,65,278,28)];
		[loginView addSubview:usernameField];
		
		passwordField = [FPSecureTextField textFieldWithStringValue:@"" placeholder:@"Password" width:280];
		[passwordField setFrame:CPMakeRect(39,100,278,28)];
		//[passwordField setDelegate:self];
		[passwordField setTarget:self];
		[passwordField setAction:@selector(login:)];
		[loginView addSubview:passwordField];
		
		[usernameField setNextKeyView:passwordField];
		[passwordField setNextKeyView:usernameField];
		
		// Login Button
		loginButton = [FPButton buttonWithTitle:@"Login"];
		
		var loginButtonFrame = [loginButton frame];
		loginButtonFrame.origin = CPMakePoint(234,150);
		loginButtonFrame.size.width = 80;
		[loginButton setFrame:loginButtonFrame];
		[loginButton setTarget:self];
		[loginButton setAction:@selector(login:)];
		[loginView addSubview:loginButton];
		
		// Progress Indicator
		spinner = [[JTSpinner alloc] initWithFrame:CPMakeRect(210,153,16,16)];
		[loginView addSubview:spinner];
		
		[contentView addSubview:loginView];
	}
	return self;
}

- (void)imageDidLoad:(id)anImage
{
	if ([[anImage filename] isEqual:LOGIN_HEADER_RESOURCE])
		[loginImageView setImage:anImage];
	else
		[loginPanelView setImage:anImage];
}

-(void)windowDidResize:(CPNotification)notification
{
	//[loginWindow center];
}

- (void)login:(id)sender
{
	[loginButton setEnabled:NO];
	[spinner startAnimation:nil];
	self.jsonData = @"";
	
	var domain = [[CPApp delegate] backendDomain];
	var username = [CPString stringWithFormat:@"%@:%@",[usernameField stringValue],self.delegate.accountName];
	var password = [passwordField stringValue];
	//var urlString = @"http://www.mozilla.org/";
	var urlString = [CPString stringWithFormat:@"http://%@/journalist_backend/session/login/?user=%@&pass=%@",domain,username,password];
	var loginURL = [CPURL URLWithString:urlString];
	var request = [CPURLRequest requestWithURL:loginURL];
	var connection = [FPURLConnection connectionWithRequest:request delegate:self];
}

- (void)connection:(FPURLConnection)aConnection didReceiveData:(CPString)data
{
	self.jsonData = [jsonData stringByAppendingString:data];
}

- (void)connection:(FPURLConnection)aConnection didFailWithError:(CPString)error
{
	CPLog(@"connection failed because of unknown error");
}

- (void)connectionDidFinishLoading:(FPURLConnection)aConnection
{
	[loginButton setEnabled:YES];
	[spinner stopAnimation:nil];
	if ([jsonData length]>0)
	{
		var dictionary = [CPDictionary dictionaryWithJSObject:[jsonData objectFromJSON]];
		if ([[dictionary valueForKey:@"code"] isEqualToString:@"0"])
		{
			/*var alert = [[CPAlert alloc] init];
			[alert setAlertStyle:CPWarningAlertStyle];
			[alert setMessageText:@"Login Failed\n\nThe username or password entered was incorrect."];
			[[alert valueForKey:@"alertPanel"] setLevel:7];
			[alert addButtonWithTitle:@"OK"];
			[alert runModal];*/
			CPLog(@"Login Failed");
		}
		else
		{
			//CPLog([dictionary description]);
			self.apiKey = [CPString stringWithString:[dictionary valueForKey:@"api_key"]];
		
			[self.delegate loginDidComplete:nil];
	    }
		[passwordField setStringValue:@""];
	} else
	{
		/*var alert = [[CPAlert alloc] init];
		[alert setAlertStyle:CPWarningAlertStyle];
		[alert setMessageText:@"Login Failed\n\nData could not be retrieved from the server."];
		[[alert valueForKey:@"alertPanel"] setLevel:7];
		[alert addButtonWithTitle:@"OK"];
		[alert runModal];*/
		CPLog(@"Login Failed");
	}
}

@end

@implementation JTLoginView : CPView
{
	
}

- (id)initWithFrame:(CPRect)aFrame
{
	if (self = [super initWithFrame:aFrame])
	{
		//[self setBackgroundColor:[CPColor colorWithCalibratedWhite:0.5 alpha:1.0]];
	}
	return self;
}

- (void)drawRect:(CPRect)aRect
{
	[[CPColor colorWithCalibratedWhite:0.95 alpha:1.0] set];
	
	var backgroundPath = [CPBezierPath bezierPath];
	[backgroundPath appendBezierPathWithRoundedRect:[self bounds] xRadius:8 yRadius:8];
	[backgroundPath fill];
}

@end