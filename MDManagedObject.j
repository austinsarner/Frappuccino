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

@import "MDManagedObjectRequest.j"

@implementation MDManagedObject : CPObject
{
	CPString _objectID @accessors(property=objectID);
	//MDManagedObjectContext _controller @accessors(property=controller);
	BOOL _isUpdated @accessors(getter=isUpdated, setter=setUpdated:);
	BOOL _isDeleted @accessors(getter=isDeleted, setter=setDeleted:);
	CPString _entity @accessors(property=entity);
	CPDictionary	recordDictionary @accessors;
}

+ (id)objectWithEntity:(CPString)entity
{
	var myClass = CPClassFromString(entity);
	return [[[myClass alloc] initWithEntity:entity] autorelease];
}

+ (id)objectWithDictionary:(CPDictionary)recordDictionary
{
	var managedObject = [self objectWithEntity:[recordDictionary valueForKey:@"entity_name"]];
	[managedObject setRecordDictionary:recordDictionary];
	return managedObject;
}

- (id)initWithEntity:(CPString)entity
{
	if (self = [super init])
	{
		_entity = entity;
		_objectID = "";
		//_controller = aController;
		_isDeleted = NO;
		_isUpdated = NO;
		recordDictionary = [[CPMutableDictionary alloc] init];
		//[self _resetObjectDataForProperties];
		//[_controller insertObject:self];
	}
	
	return self;
}

- (void)setRecordDictionary:(CPDictionary)dictionary
{
	self.recordDictionary = dictionary;
}

- (void)recordValueForKey:(CPString)key
{
	return [self.recordDictionary valueForKey:key];
}

- (void)setRecordValue:(CPString)value forKey:(CPString)key
{
	[self.recordDictionary setValue:value forKey:key];
}

- (void)managedObjectRequestFinished:(MDManagedObjectRequest)request
{
	
}

- (void)delete
{
	//[[MDManagedObjectRequest requestWithDelegate:self uid:@"delrecord"] deleteObject:self];
}

- (void)awakeFromInsert
{
	
}

- (void)awakeFromFetch
{
	
}
@end