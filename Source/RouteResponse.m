#import "RouteResponse.h"
#import "HTTPConnection.h"
#import "HTTPDataResponse.h"
#import "HTTPFileResponse.h"
#import "HTTPAsyncFileResponse.h"
#import "HTTPResponseProxy.h"

#ifndef HTTPResDel
#define HTTPResDel NSObject<HTTPResponse>
#endif

JREnumDefine(ResponseType);

@implementation RouteResponse 									{	HTTPResponseProxy *proxy; }

- (id)initWithConnection:(HTTPCONN*)theConnection	 		{	if (self != super.init) return nil;
	_connection 	= theConnection; _headers= NSMD.new;	proxy = HTTPResponseProxy.new; return self;
}
- (HTTPResDel*)        response									{	return proxy.response; 																				}
- (void)		        setResponse:(HTTPResDel*)resp			{ 			 proxy.response = resp;		   															}
- (HTTPResDel*) proxiedResponse 									{ return  proxy.response || !proxy.customStatus || _headers.count ? proxy : nil; 	}
- (NSInteger) statusCode	 										{ return  proxy.status; 																				}
- (void)   setStatusCode:(NSInteger)status					{         proxy.status = status; 																	}
- (void) setHeader:(NSString*)fld value:(NSString*)val 	{ _headers[fld] = val; 																					}

- (void) setResponse:(id)data type:(ResponseType)type {

	self.response 	= type == ResponseTypeString && [data ISKINDA:NSString.class]
																	? [HTTPDataResponse.alloc initWithData:[data dataUsingEncoding:NSUTF8StringEncoding]]
						: type == ResponseTypeFile 		? [HTTPAsyncFileResponse.alloc initWithFilePath:data forConnection:_connection]
						: type == ResponseTypeFileAsync 	? [HTTPFileResponse.alloc initWithFilePath:data forConnection:_connection]			: nil;
}
- (void)respondWithString:(NSString*)str 											{ [self setResponse:str type:ResponseTypeString]; 				}
- (void)respondWithString:(NSString*)str encoding:(NSStringEncoding)enc { [self setResponse:str type:ResponseTypeString]; 				}
- (void)respondWithData:	 (NSData*)dta 											{ [self setResponse:dta type:ResponseTypeData];					}
- (void)respondWithFile:  (NSString*)pth 											{ [self setResponse:pth type:ResponseTypeFileAsync]; 			}
- (void)respondWithFile:  (NSString*)pth async:(BOOL)a 						{ [self setResponse:pth type:a ? ResponseTypeFileAsync
																																		 : ResponseTypeFile];         }


//	[self respondWithString:string encoding:NSUTF8StringEncoding]; }
//	if (async) {		self.response = [[HTTPAsyncFileResponse alloc] initWithFilePath:path forConnection:connection];
//	} else {			self.response = [[HTTPFileResponse alloc] initWithFilePath:path forConnection:connection];
//	}
//}

@end
