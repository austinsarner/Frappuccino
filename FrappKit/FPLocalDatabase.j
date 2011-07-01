/*
 * FPLocalDatabase.j
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

@implementation FPLocalDatabase : CPObject
{
	JSObject _localDB;
}

- (id)initWithName:(CPString)databaseName version:(CPString)version
{
	if (self = [super init])
	{
		_localDB = FPLocalDatabaseOpen(databaseName, version, databaseName, 1024*1024);
	}
	return self;
}

/*- (void)executeSQL:(CPString)sqlString
{
	FPLocalDatabaseExecuteSQL(_localDB,sqlString);
}*/

- (void)executeRequest:(FPLocalDatabaseRequest)request
{
	request.database = self;
	request.delegate = self;
	[request execute];
}

- (void)createTable:(CPString)tableName withFields:(CPArray)fields
{
	var fieldString = [fields componentsJoinedByString:@", "];
	var sqlString = [CPString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(%@)",tableName,fieldString];
	[self executeRequest:[FPLocalDatabaseRequest requestWithSQL:sqlString]];
}

@end

@implementation FPLocalDatabaseRequest
{
	CPString sqlString @accessors;
	id delegate @accessors;
	id database @accessors;
}

+ (CPString)requestWithSQL:(CPString)string
{
	var request = [[self alloc] init];
	request.sqlString = string;
	return [request autorelease];
}

- (void)execute
{
	CPLog(@"execute SQL");
	database.transaction(function(tx)
	{
		tx.executeSql(sql, []);
	});
}

- (void)requestFinished:(var)result
{
	CPLog(@"request finished: %@",result);
}

@end

function FPLocalDatabaseOpen(name,version,displayName,size)
{
	var db;
	try
	{
	    if (window.openDatabase)
		{
	        db = openDatabase(name, version, displayName, size);
	        if (!db)
	            CPLog("ERROR: Failed to open the database on disk. This is probably because the version was bad or there is not enough space left in this domain's quota");
	    }
		else
	        CPLog("ERROR: Couldn't open the database. Please try with a WebKit nightly with this feature enabled");
	}
	catch(err)
	{
		CPLog(@"ERROR: Database feature isn't available");
	}
	return db;
}