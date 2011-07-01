/*
 * FPLocalStorage.j
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

var sharedLocalStorage;

@implementation FPLocalStorage : CPObject {}

+ (BOOL)loalStorageIsAvailable
{
    return !!window.localStorage;
}

+ (FPLocalStorage)sharedLocalStorage
{
	if (!sharedLocalStorage)
		sharedLocalStorage = [[self alloc] init];
	return sharedLocalStorage;
}

// Working with items

- (void)setValue:(CPString)aValue forKey:(CPString)aKey
{
	try {
	    localStorage.setItem(aKey, aValue);
	} catch (e) {
	    if (e == QUOTA_EXCEEDED_ERR)
	        CPLog('ERROR: Local storage quota exceeded');
	}
}

- (CPString)valueForKey:(CPString)aKey
{
    return localStorage.getItem(aKey);
}

- (void)removeValueForKey:(CPString)aKey
{
    localStorage.removeItem(aKey);
}

- (void)removeAllValues
{
	localStorage.clear();
}

@end