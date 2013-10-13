#import <Foundation/Foundation.h>
#import "HTTPResponse.h"
#define HTTPCONN 	HTTPConnection
#define HTTPRES 	HTTPResponse
#import "JREnum.h"

JREnumDeclare(ResponseType, ResponseTypeData, ResponseTypeString, ResponseTypeFile, ResponseTypeFileAsync, ResponseTypeDynamic, ResponseTypeSocket);


@class HTTPConnection, HTTPResponseProxy;

@interface RouteResponse : NSObject

@property (weak,readonly) 	 HTTPCONN  * connection;
@property (readonly)         		NSD  * headers;
@property (nonatomic) 	 NSO<HTTPRES> * response;
@property (readonly) 	 NSO<HTTPRES> * proxiedResponse;
@property (nonatomic) 				NSI    statusCode;

- (id)initWithConnection:(HTTPConnection *)theConnection;

- (void) setHeader:			   (NSS*)fld 	 value:(NSS*)val;
- (void) respondWithString:	(NSS*)str;
- (void) respondWithString:   (NSS*)str encoding:(NSStringEncoding)enc;
- (void) respondWithData:	(NSData*)dta;
- (void) respondWithFile:	   (NSS*)pth;
- (void) respondWithFile: 	   (NSS*)pth   async:(BOOL)async;

@end
