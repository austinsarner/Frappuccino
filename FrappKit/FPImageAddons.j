/*
 * FPImageAddons.j
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

function CPImageWithPNGData(data)
{
 	return [CPImage imageWithPNGData:data];
}

function CGContextGetPNGData(aContext,aRect)
{
	var imageData = FPContextGetImageData(aContext,aRect);
	return FPImageEncodeData(imageData);
}

function FPContextGetImageData(context,aRect)
{
	var imageData;
	try
	{
		try
		{
			imageData = context.getImageData(aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.width);//.data;
		}
		catch (e)
		{
			if (CPBrowserIsEngine(CPGeckoBrowserEngine))
			{
				netscape.security.PrivilegeManager.enablePrivilege("UniversalBrowserRead");
				imageData = context.getImageData(aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.width);//.data;
			} else
				CPLog(@"ERROR: Unable to access image data %@",e);
		}
	}
	catch (e)
	{
		//throw new Error("unable to access image data: " + e);
		CPLog(@"ERROR: Unable to access image data %@",e);
	}
	return imageData;
}

function CGContextGetImage(aContext,aRect)
{
	var imageData = CGContextGetPNGData(aContext,aRect);
	return [CPImage imageWithPNGData:imageData];
}

function FPImageEncodeData(oData)
{
	var aHeader = [];

	var iWidth = oData.width;
	var iHeight = oData.height;

	aHeader.push(0x42); // magic 1
	aHeader.push(0x4D); 

	var iFileSize = iWidth*iHeight*3 + 54; // total header size = 54 bytes
	aHeader.push(iFileSize % 256); iFileSize = Math.floor(iFileSize / 256);
	aHeader.push(iFileSize % 256); iFileSize = Math.floor(iFileSize / 256);
	aHeader.push(iFileSize % 256); iFileSize = Math.floor(iFileSize / 256);
	aHeader.push(iFileSize % 256);

	aHeader.push(0); // reserved
	aHeader.push(0);
	aHeader.push(0); // reserved
	aHeader.push(0);

	aHeader.push(54); // dataoffset
	aHeader.push(0);
	aHeader.push(0);
	aHeader.push(0);

	var aInfoHeader = [];
	aInfoHeader.push(40); // info header size
	aInfoHeader.push(0);
	aInfoHeader.push(0);
	aInfoHeader.push(0);

	var iImageWidth = iWidth;
	aInfoHeader.push(iImageWidth % 256); iImageWidth = Math.floor(iImageWidth / 256);
	aInfoHeader.push(iImageWidth % 256); iImageWidth = Math.floor(iImageWidth / 256);
	aInfoHeader.push(iImageWidth % 256); iImageWidth = Math.floor(iImageWidth / 256);
	aInfoHeader.push(iImageWidth % 256);

	var iImageHeight = iHeight;
	aInfoHeader.push(iImageHeight % 256); iImageHeight = Math.floor(iImageHeight / 256);
	aInfoHeader.push(iImageHeight % 256); iImageHeight = Math.floor(iImageHeight / 256);
	aInfoHeader.push(iImageHeight % 256); iImageHeight = Math.floor(iImageHeight / 256);
	aInfoHeader.push(iImageHeight % 256);

	aInfoHeader.push(1); // num of planes
	aInfoHeader.push(0);

	aInfoHeader.push(24); // num of bits per pixel
	aInfoHeader.push(0);

	aInfoHeader.push(0); // compression = none
	aInfoHeader.push(0);
	aInfoHeader.push(0);
	aInfoHeader.push(0);

	var iDataSize = iWidth*iHeight*3; 
	aInfoHeader.push(iDataSize % 256); iDataSize = Math.floor(iDataSize / 256);
	aInfoHeader.push(iDataSize % 256); iDataSize = Math.floor(iDataSize / 256);
	aInfoHeader.push(iDataSize % 256); iDataSize = Math.floor(iDataSize / 256);
	aInfoHeader.push(iDataSize % 256); 

	for (var i=0;i<16;i++) {
		aInfoHeader.push(0);	// these bytes not used
	}

	var iPadding = (4 - ((iWidth * 3) % 4)) % 4;

	var aImgData = oData.data;

	var strPixelData = "";
	var y = iHeight;
	do {
		var iOffsetY = iWidth*(y-1)*4;
		var strPixelRow = "";
		for (var x=0;x<iWidth;x++) {
			var iOffsetX = 4*x;

			strPixelRow += String.fromCharCode(aImgData[iOffsetY+iOffsetX+2]);
			strPixelRow += String.fromCharCode(aImgData[iOffsetY+iOffsetX+1]);
			strPixelRow += String.fromCharCode(aImgData[iOffsetY+iOffsetX]);
		}
		for (var c=0;c<iPadding;c++) {
			strPixelRow += String.fromCharCode(0);
		}
		strPixelData += strPixelRow;
	} while (--y);

	var strEncoded = FPImageEncodeString(aHeader.concat(aInfoHeader)) + FPImageEncodeString(strPixelData);

	return strEncoded;
}

function FPImageEncodeString(data)
{
	var strData = "";
	if (typeof data == "string") {
		strData = data;
	} else {
		var aData = data;
		for (var i=0;i<aData.length;i++) {
			strData += String.fromCharCode(aData[i]);
		}
	}
	return FPBase64Encode(strData);
}

CPCompositeCopy            = "copy";
CPCompositeSourceOver      = "source-over";
CPCompositeSourceIn        = "source-in";
CPCompositeSourceOut       = "source-out";
CPCompositeSourceAtop      = "source-atop";
CPCompositeDestinationOver = "destination-over"
CPCompositeDestinationIn   = "destination-in"
CPCompositeDestinationOut  = "destination-out";
CPCompositeDestinationAtop = "destination-atop";
CPCompositeXOR             = "xor";
CPCompositePlusDarker      = "darker";
CPCompositePlusLighter     = "lighter";

@implementation CPImage (CPImageAddons) {}

+ (id)imageNamed:(CPString)imageName
{
	//CPLog(@"parse error?");
	return [[self alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:imageName]];
}

- (BOOL)canDraw
{
	return ([self loadStatus]==CPImageLoadStatusCompleted);
}

- (void)drawAtPoint:(CPPoint)point fraction:(float)alpha
{
	if ([self canDraw])
	{
		[CPGraphicsContext saveGraphicsState];
		var ctx = [[CPGraphicsContext currentContext] graphicsPort];
		FPContextSetGlobalAlpha(ctx,alpha);
		var jsImage = [self valueForKey:@"_image"];
		ctx.drawImage(jsImage,point.x,point.y);
		[CPGraphicsContext restoreGraphicsState];
	}
}

- (void)drawAtPoint:(CPPoint)point fromRect:(CPRect)fromRect operation:(CPCompositingOperation)operation fraction:(float)alpha
{
	if ([self canDraw])
	{
		[CPGraphicsContext saveGraphicsState];
		var ctx = [[CPGraphicsContext currentContext] graphicsPort];
		FPContextSetGlobalAlpha(ctx,alpha);
		ctx.globalCompositeOperation = operation;
		var jsImage = [self valueForKey:@"_image"];
		ctx.drawImage(jsImage,fromRect.origin.x,fromRect.origin.y,fromRect.size.width,fromRect.size.height,point.x,point.y,fromRect.size.width,fromRect.size.height);
		[CPGraphicsContext restoreGraphicsState];
	}
}

- (void)drawInRect:(CPRect)rect fraction:(float)alpha
{
	if ([self canDraw])
	{
		[CPGraphicsContext saveGraphicsState];
		var ctx = [[CPGraphicsContext currentContext] graphicsPort];
		ctx.globalAlpha = alpha;
		var jsImage = [self valueForKey:@"_image"];
		ctx.drawImage(jsImage,rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
		[CPGraphicsContext restoreGraphicsState];
	}
}

- (void)drawInRect:(CPRect)toRect fromRect:(CPRect)fromRect operation:(CPCompositingOperation)operation fraction:(float)alpha
{
	if ([self canDraw])
	{
		[CPGraphicsContext saveGraphicsState];
		var ctx = [[CPGraphicsContext currentContext] graphicsPort];
		ctx.globalAlpha = alpha;
		ctx.globalCompositeOperation = operation;
		var jsImage = [self valueForKey:@"_image"];
		ctx.drawImage(jsImage,fromRect.origin.x,fromRect.origin.y,fromRect.size.width,fromRect.size.height,toRect.origin.x,toRect.origin.y,toRect.size.width,toRect.size.height);
		[CPGraphicsContext restoreGraphicsState];
	}
}

+ (CPImage)imageWithPNGData:(CPData)data
{
	return [[CPImage alloc] initWithContentsOfFile:[@"data:image/png;base64," stringByAppendingString:data]];
}

@end