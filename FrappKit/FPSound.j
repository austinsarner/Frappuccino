/*
 * FPSound.j
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

var sharedSoundManager;

function FPAudioLoadURL(audio,url)
{
	audio.src = url;
	audio.load();
}
function FPAudioPlay(audio) { audio.play(); }
function FPAudioPaused(audio) { return audio.paused; }
function FPAudioPause(audio) { audio.pause(); }
function FPAudioVolume(audio) { return audio.volume; }
function FPAudioSetVolume(audio,volume) { audio.volume = volume; }

@implementation FPSoundManager : CPObject
{
	DOMElement	audio;
	CPString	currentSoundPath @accessors;
}

-(id)init
{
	if (self = [super init])
	{
		audio = document.createElement("audio");
		document.body.appendChild(audio);
	}
	return self;
}

+ (FPSoundManager)sharedSoundManager
{
	if (!sharedSoundManager)
		sharedSoundManager = [[self alloc] init];
	return sharedSoundManager;
}

- (void)playSound:(FPSound)sound
{
	if (![currentSoundPath isEqualToString:[sound URLString]])
	{
		currentSoundPath = [sound URLString];
		FPAudioLoadURL(audio,currentSoundPath);
	}
	FPAudioPlay(audio);
}

- (int)duration
{
	return audio.duration;
}

- (int)currentTime
{
	return audio.currentTime;
}

- (float)progress
{
	return ([self currentTime]/[self duration]);
}

- (BOOL)isPlaying
{
	return !FPAudioPaused(audio);
}

- (void)pauseSound:(FPSound)sound
{
	if ([[sound URLString] isEqualToString:currentSoundPath])
		[self pause];
}

- (void)stop
{
	[self pause];
	audio.load();
}

- (void)pause
{
	FPAudioPause(audio);
}

- (void)setVolume:(int)volume
{
	FPAudioSetVolume(audio,volume);
}

- (int)volume
{
	return FPAudioVolume(audio);
}

@end

@implementation FPSound : CPObject
{
	CPString URLString @accessors;
	
}

- (id)initWithContentsOfURL:(CPURL)url byReference:(BOOL)ref
{
	if (self = [super init])
		self.URLString = [url absoluteString];
	return self;
}

+ (FPSound)soundWithURL:(CPURL)url
{
	var sound = [[self alloc] initWithContentsOfURL:url byReference:YES];
	return [sound autorelease];
}

- (BOOL)isPlaying
{
	if ([[FPSoundManager sharedSoundManager] isPlaying])
		return [[[FPSoundManager sharedSoundManager] currentSoundPath] isEqualToString:URLString];
	return NO;
}

- (void)play
{
	[[FPSoundManager sharedSoundManager] playSound:self];
}

- (void)stop
{
	[[FPSoundManager sharedSoundManager] stop];
}

- (void)pause
{
	[[FPSoundManager sharedSoundManager] pauseSound:self];
}

@end