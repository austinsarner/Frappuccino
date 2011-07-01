/*
 * FPXMLDocument.j
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

FPXMLLoadStatusInitialized    = 0;
FPXMLLoadStatusLoading        = 1;
FPXMLLoadStatusCompleted      = 2;
FPXMLLoadStatusCancelled      = 3;
/*00038 CPImageLoadStatusInvalidData    = 4;
00039 CPImageLoadStatusUnexpectedEOF  = 5;
00040 CPImageLoadStatusReadError      = 6;*/

@implementation CPObject (FPXMLDocumentDelegate)
- (void)xmlDocumentDidLoad:(FPXMLDocument)document {}
@end

@implementation FPXMLDocument : CPObject
{
	int loadStatus @accessors;
	CPURL dataURL;
	id delegate @accessors;
	CPString xmlString;
}

- (id)initWithContentsOfURL:(CPURL)url
{
	if (self = [super init])
	{
		loadStatus = FPXMLLoadStatusInitialized;
		dataURL = url;
		var dataURLRequest = [CPURLRequest requestWithURL:dataURL];
		var dataURLConnection = [FPURLConnection connectionWithRequest:dataURLRequest delegate:self];
	}
	return self;
}

+ (FPXML)documentWithContentsOfURL:(CPURL)url
{
	return [[[self alloc] initWithContentsOfURL:url] autorelease];
}

- (void)connection:(FPURLConnection)connection didReceiveData:(CPString)data
{
	xmlString = data;
}

- (void)connectionDidFinishLoading:(FPURLConnection)connection
{
	var xmlParser = [[FPXMLParser alloc] initWithData:xmlString];
	[xmlParser setDelegate:self];
	[xmlParser parse];
}

- (void)connection:(FPURLConnection)connection didFailWithError:(id)error
{
	
}

// FPXMLParserDelegate

- (void)parserDidStartDocument:(FPXMLParser)parser
{
	CPLog(@"!! STARTED PARSING");
}

- (void)parserDidEndDocument:(FPXMLParser)parser
{
	CPLog(@"!! ENDED PARSING");
}

- (void)parser:(FPXMLParser)parser didStartElement:(CPString)elementName attributes:(CPDictionary)attributeDict
{
	CPLog(@"STARTED ELEMENT: %@",elementName);
}

- (void)parser:(FPXMLParser)parser didEndElement:(CPString)elementName
{
	CPLog(@"ENDED ELEMENT: %@",elementName);
}

- (void)parser:(FPXMLParser)parser foundCharacters:(CPString)string
{
	CPLog(@"FOUND CHARACTERS: %@",string);
}

@end

@implementation CPObject (FPXMLParserDelegate)

- (void)parserDidStartDocument:(FPXMLParser)parser {}
- (void)parserDidEndDocument:(FPXMLParser)parser {}

- (void)parser:(FPXMLParser)parser didStartElement:(CPString)elementName attributes:(CPDictionary)attributeDict {}
- (void)parser:(FPXMLParser)parser didEndElement:(CPString)elementName {}

- (void)parser:(FPXMLParser)parser foundCharacters:(CPString)string {}

@end

@implementation FPXMLParser : CPObject
{
	JSObject _domParser;
	JSObject _xmlDoc;
	id delegate @accessors;
}

- (id)initWithData:(CPString)xmlString
{
	if (self = [super init])
	{
		if (window.DOMParser)
		{
			_domParser = new DOMParser();
			_xmlDoc = _domParser.parseFromString(xmlString,"text/xml");
		}
		else // Internet Explorer
		{
			_xmlDoc = new ActiveXObject("Microsoft.XMLDOM");
			_xmlDoc.async = "false";
			_xmlDoc.loadXML(xmlString); 
		}
	}
	return self;
}

+ (id)parserWithString:(CPString)xmlString
{
	return [[[self alloc] initWithString:xmlString] autorelease];
}

- (void)parse
{
	if (delegate != nil)
	{
		var jtmlElement = _xmlDoc.getElementsByTagName("jtml")[0];
		
		[delegate parserDidStartDocument:self];
		[self _parseElement:jtmlElement];
		[delegate parserDidEndDocument:self];
	}
	else
		CPLog(@"ERROR: FPXMLParser requires a delegate before parsing");
}

- (void)_parseElement:(JSObject)anElement
{
	var anElementName = anElement.tagName;
	[delegate parser:self didStartElement:anElementName attributes:nil];
	[delegate parser:self foundCharacters:anElement.innerText];
	
	var elements = anElement.childNodes;
	for (var e=0;e<elements.length;e++)
	{
		var element = elements[e];
		var elementName = element.tagName;
		if (elementName != nil)
			[self _parseElement:element];
	}
	[delegate parser:self didEndElement:anElementName];
}

@end