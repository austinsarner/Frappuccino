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

@import <Foundation/CPObject.j>
@import "JTLoginController.j"
@import "JTMasterViewController.j"
@import "MediaLibrary.j"
@import "JTColor.j"
@import "JTButtons.j"
@import "JTMediaBrowserView.j"
@import "JTMediaItemCell.j"

var LOGIN_COOKIE = "JOURNALIST_KEY";

@implementation AppController : CPObject
{
	CPString				accountName @accessors;
	CPWindow				mainWindow @accessors;
	CPString				apiKey @accessors;
	CPView					contentView @accessors;
	JTLoginController		loginController;
	CPString				backendDomain @accessors;
	BOOL					requireLogin @accessors;
	
	JTMasterViewController	masterViewController @accessors;
	//FPViewController	detailViewController @accessors;
	//FPViewController	contentViewController;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
	var location = [CPString stringWithString:window.location];
	var runningLocally = [location hasPrefix:@"file:///"];
	
	if (runningLocally) CPLogRegister(CPLogPopup);
	[CPApp setDelegate:self];
	
	var useLocalServer = YES;
	
	requireLogin = NO;
	backendDomain = useLocalServer?@"mark-davis-macbook-pro.local:8080":@"173.203.111.78:8080";
	accountName = @"journalist";
	mainWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];
	[mainWindow setTitle:@"Medium"];
	contentView = [mainWindow contentView];
	[contentView setBackgroundColor:[CPColor colorWithHexString:@"4b4b4b"]];
	
	masterViewController = [[JTMasterViewController alloc] initWithViewFrame:[contentView bounds]];
	
    [mainWindow orderFront:self];
	
	[self checkLogin];
}

- (void)checkLogin
{
	var loggedIn = NO;
	
	var loginCookie = [[CPCookie alloc] initWithName:LOGIN_COOKIE];
	
	if ([loginCookie value] && ![[loginCookie value] isEqualToString:@""])
		loggedIn = YES;
	
	if (requireLogin && !loggedIn)
	{
		var bounds = [contentView bounds];
		
		if (!loginController)
			loginController = [[JTLoginController alloc] initWithDelegate:self];
		[loginController.loginWindow makeKeyAndOrderFront:nil];
	}
	else
	{
		self.apiKey = requireLogin?[loginCookie value]:@"testkey213";
		[self loadAdmin];
	}
}

- (void)loadAdmin
{
	[MediaLibrary sharedMediaLibrary];
	[DocumentLibrary sharedDocumentLibrary];
	
	var masterView = masterViewController.view;
	[contentView addSubview:masterView];
	[masterView setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];
	[mainWindow makeFirstResponder:masterViewController.view];
}

// Login Delegate

- (void)loginDidComplete:(id)sender
{
	var loginCookie = [[CPCookie alloc] initWithName:LOGIN_COOKIE];
	var apiKey = loginController.apiKey;
	
	self.apiKey = apiKey;
	[loginCookie setValue:apiKey expires:[CPDate dateWithTimeIntervalSinceNow:3600] domain:backendDomain];
	[self closeLoginPanel];
}

- (void)logout:(id)sender
{
	var loginCookie = [[CPCookie alloc] initWithName:LOGIN_COOKIE];
	[loginCookie setValue:@"" expires:[CPDate dateWithTimeIntervalSinceNow:3600] domain:backendDomain];
	window.location = window.location;
}

- (void)closeLoginPanel
{
	[loginController.loginWindow orderOut:nil];
	[self loadAdmin];
}

@end