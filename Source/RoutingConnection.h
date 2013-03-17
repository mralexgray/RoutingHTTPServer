#import <Foundation/Foundation.h>
#import "HTTPConnection.h"

//#import "AppDelegate.h"

#define UPLOAD_FILE_PROGRESS @"uploadfileprogress"


@class RoutingHTTPServer;

@class MultipartFormDataParser;

@interface RoutingConnection : HTTPConnection
{
    MultipartFormDataParser*        parser;
		NSFileHandle*					storeFile;
		NSMutableArray*					uploadedFiles;

//	int             dataStartIndex;
//	NSMutableArray  *multipartData;
//	BOOL            postHeaderOK;
}
//- (BOOL) isBeginOfOctetStream;


@end
