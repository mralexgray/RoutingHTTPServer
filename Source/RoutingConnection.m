#import "RoutingConnection.h"
#import "RoutingHTTPServer.h"
#import "HTTPMessage.h"
#import "HTTPResponseProxy.h"

@implementation RoutingConnection {
	__unsafe_unretained RoutingHTTPServer * http;
									 NSDictionary * headers;
										 WebSocket * _ws;
}

- (id)initWithAsyncSocket:(GCDAsyncSocket*)newSocket configuration:(HTTPConfig*)aConfig {

	if (!(self = [super initWithAsyncSocket:newSocket configuration:aConfig])) return nil;
	NSAssert([config.server ISKINDA:RoutingHTTPServer.class], @"A RoutingConnection is being used with a server that is not a RoutingHTTPServer");
	http = (RoutingHTTPServer*)config.server;
	return self;
}

- (BOOL)supportsMethod:(NSString*)method atPath:(NSString*)path { return [http supportsMethod:method] ?: [super supportsMethod:method atPath:path]; }
// The default implementation is strict about the use of Content-Length. Either a given method + path combination must *always* include data or *never* include data. The routing connection is lenient, a POST that sometimes does not include data or a GET that sometimes does is fine. It is up to the route implementations to decide how to handle these situations.
- (BOOL)shouldHandleRequestForMethod:(NSString *)method atPath:(NSString *)path { 	return YES; }

- (void)processBodyData:(NSData *)postDataChunk {  [request appendData:postDataChunk]; } // ? nil : { /* TODO: Log */ };  }

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {   	RouteResponse *response;

	NSURL *url 				= [request URL];	NSString *query = nil;	NSDictionary *params = @{}; headers	= nil;

	if (url) {      path = url.path; // Strip the query string from the path
						query = url.query;
		if (query) params = [self parseParams:query];
	}
	if ((response = [http routeMethod:method withPath:path parameters:params request:request connection:self]) != nil) {
			headers = response.headers;
			 	return response.proxiedResponse;
	}
	NSObject<HTTPResponse> *staticResponse;   NSString *mimeType; 		// Set a MIME type for static files if possible

	headers = (staticResponse 	= [super httpResponseForMethod:method URI:path])
			 && [staticResponse 				respondsToSelector:@selector(filePath)]
			 && (mimeType 			= [http  mimeTypeForPath:[staticResponse performSelector:@selector(filePath)]])
			  ? @{@"Content-Type":mimeType}	: headers;
	return staticResponse;
}
- (void)responseHasAvailableData:(NSObject<HTTPResponse> *)sender {
	((HTTPResponseProxy*)httpResponse).response == sender ? [super responseHasAvailableData:httpResponse] : nil;
}
- (void)responseDidAbort:(NSObject<HTTPResponse> *)sender {
	((HTTPResponseProxy*)httpResponse).response == sender  ? [super responseDidAbort:httpResponse] : nil;
}
- (void)setHeadersForResponse:(HTTPMessage *)response isError:(BOOL)isError {
	[http.defaultHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
		[response setValue:value forHeaderField:field];
	}];
	headers && !isError 	?	[headers enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
										[response setValue:value forHeaderField:field];
									}] : nil;
	// Set the connection header if not already specified
	NSString *connection  = [response valueForHeaderField:@"Connection"]; if (connection) return;
	[response setValue:[self shouldDie] ? @"close" : @"keep-alive" forHeaderField:@"Connection" ];
}

- (NSData*)preprocessResponse:(HTTPMessage*)resp 		{ return [self setHeadersForResponse:resp isError: NO], [super preprocessResponse:		resp]; }
- (NSData*)preprocessErrorResponse:(HTTPMessage*)resp { return [self setHeadersForResponse:resp isError:YES], [super preprocessErrorResponse:resp]; }

- (BOOL)shouldDie { __block BOOL shouldDie = [super shouldDie];
	if (!shouldDie && headers) {  	// Allow custom headers to determine if the connection should be closed
		[headers enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
			if ([field caseInsensitiveCompare:@"connection"] == NSOrderedSame) {
				if ([value caseInsensitiveCompare:@"close"] == NSOrderedSame) 	shouldDie = YES;
				*stop = YES;
			}
		}];
	}
	return shouldDie;
}



- (WebSocket *)webSocketForURI:(NSString *)path
{
	NSLog(@"%@[%p]: webSocketForURI: %@", THIS_FILE, self, path);

	if([path isEqualToString:@"/service"])
	{
		NSLog(@"MyHTTPConnection: Creating MyWebSocket...");
		
		return [WebSocket.alloc initWithRequest:request socket:asyncSocket];
	}
	
	return [super webSocketForURI:path];
}



//- (WebSocket *)webSocketForURI:(NSString *)path {  AZLOGCMD; //	HTTPLogTrace2(@"%@[%p]: webSocketForURI: %@", THIS_FILE, self, path);
//
///** 	Override me to provide custom WebSocket responses. Just override the base WebSocket implem and add your custom functiuionality..
//		Then return an instance of your custom WebSocket here. 		
//		For example:
//			return  [path isEqualToString:@"/myAwesomeWebSocketStream"] ? [MyWebSocket.alloc initWithRequest:request socket:asyncSocket]
//																							: [super webSocketForURI:path];			*/
//
//	
//	return 		[path isEqualToString:@"/service"] 		//	HTTPLogInfo(@"MyHTTPConnection: Creating MyWebSocket...");
//				?	[WebSocket.alloc initWithRequest:request socket:asyncSocket]
//				:	[super webSocketForURI:path];
//}
//
@end
