
#import "RoutingHTTPServer.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"


@interface RoutingHTTPServerTests : XCTestCase {	RoutingHTTPServer *http; }	- (void) setupRoutes;

- (void) verifyRouteWithMethod:			(NSString*)meth path:(NSString*)pth;
- (void) verifyRouteNotFoundWithMethod:(NSString*)meth path:(NSString*)pth;
- (void) handleSelectorRequest:(RouteRequest*)req withResponse:(RouteResponse *)res;
- (void) verifyMethod:(NSString*)meth path:(NSString *)pth 		 contentType:(NSString*)contentType
										 inputString:(NSString *)input responseString:(NSString*)expectedResStr;
@end

@implementation RoutingHTTPServerTests

- (void)setUp 		{	[super setUp];		http = RoutingHTTPServer.alloc.init; [self setupRoutes];	AZLOGOUT; }

- (void)tearDown 	{	[super tearDown]; 																			AZLOGOUT; }

- (void)testRoutes { AZLOGIN;

	HTTPMessage *mess = HTTPMessage.alloc.initEmptyRequest;
	RouteResponse *response = [http routeMethod:@"GET"   withPath:@"/null" 			  parameters:@{}
											      request:mess  connection:nil];
	XX(mess); XX(response);
	XCTAssertNil(response, @"Received response for path that does not exist");

	[self verifyRouteWithMethod:@"GET" path:@"/hello"];
	[self verifyRouteWithMethod:@"GET" path:@"/hello/you"];
	[self verifyRouteWithMethod:@"GET" path:@"/page/3"];
	[self verifyRouteWithMethod:@"GET" path:@"/files/test.txt"];
	[self verifyRouteWithMethod:@"GET" path:@"/selector"];
	[self verifyRouteWithMethod:@"POST" path:@"/form"];
	[self verifyRouteWithMethod:@"POST" path:@"/users/bob"];
	[self verifyRouteWithMethod:@"POST" path:@"/users/bob/dosomething"];

	[self verifyRouteNotFoundWithMethod:@"POST" path:@"/hello"];
	[self verifyRouteNotFoundWithMethod:@"POST" path:@"/selector"];
	[self verifyRouteNotFoundWithMethod:@"GET" path:@"/page/a3"];
	[self verifyRouteNotFoundWithMethod:@"GET" path:@"/page/3a"];
	[self verifyRouteNotFoundWithMethod:@"GET" path:@"/form"];
}

- (void)testPost {	AZLOGIN; 	NSError *error = nil;

	if (![http start:&error]) 	XCTFail(@"HTTP server failed to start");
										XCTAssertNil(error, @"Uh oh, error during Post! %@", error);

	NSString *xmlString = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<greenLevel>supergreen</greenLevel>";
	[self verifyMethod:@"POST" path:@"/xml" contentType:@"text/xml" inputString:xmlString responseString:@"supergreen"];

	AZLOGOUT;
}

- (void)setupRoutes { AZLOGIN;

	[http get:@"/hello" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:@"/hello"];
	}];

	[http get:@"/hello/:name" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:[NSString stringWithFormat:@"/hello/%@", [request param:@"name"]]];
	}];

	[http post:@"/form" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:@"/form"];
	}];

	[http post:@"/users/:name" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:[NSString stringWithFormat:@"/users/%@", [request param:@"name"]]];
	}];

	[http post:@"/users/:name/:action" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:[NSString stringWithFormat:@"/users/%@/%@",
									 [request param:@"name"],
									 [request param:@"action"]]];
	}];

	[http get:@"{^/page/(\\d+)$}" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response respondWithString:[NSString stringWithFormat:@"/page/%@",
									 [[request param:@"captures"] objectAtIndex:0]]];
	}];

	[http get:@"/files/*.*" withBlock:^(RouteRequest *request, RouteResponse *response) {
		NSArray *wildcards = [request param:@"wildcards"];
		[response respondWithString:[NSString stringWithFormat:@"/files/%@.%@",
									 [wildcards objectAtIndex:0],
									 [wildcards objectAtIndex:1]]];
	}];

	[http handleMethod:@"GET" withPath:@"/selector" target:self selector:@selector(handleSelectorRequest:withResponse:)];

	[http post:@"/xml" withBlock:^(RouteRequest *request, RouteResponse *response) {
		NSData *bodyData = [request body];
		NSString *xml = [[NSString alloc] initWithBytes:[bodyData bytes] length:[bodyData length] encoding:NSUTF8StringEncoding];

		// Green?
		NSRange tagRange = [xml rangeOfString:@"<greenLevel>"];
		if (tagRange.location != NSNotFound) {
			NSUInteger start = tagRange.location + tagRange.length;
			NSUInteger end = [xml rangeOfString:@"<" options:0 range:NSMakeRange(start, [xml length] - start)].location;
			if (end != NSNotFound) {
				NSString *greenLevel = [xml substringWithRange:NSMakeRange(start, end - start)];
				[response respondWithString:greenLevel];
			}
		}
	}];
	AZLOGOUT;
}

- (void)handleSelectorRequest:(RouteRequest *)request withResponse:(RouteResponse *)response { AZLOGIN;
	[response respondWithString:@"/selector"];
	AZLOGOUT;
}

- (void)verifyRouteWithMethod:(NSString *)method path:(NSString *)path { AZLOGIN;

	RouteResponse *response = [http routeMethod:method withPath:path parameters:@{} request:HTTPMessage.alloc.initEmptyRequest connection:nil];
	XCTAssertNotNil(response.proxiedResponse, @"Proxied response is nil for %@ %@", method, path);
	NSUInteger length 		= [response.proxiedResponse contentLength];
	NSData *data 				= [response.proxiedResponse readDataOfLength:length];
	NSS *responseString 		= [NSS stringWithData:data encoding:NSUTF8StringEncoding];
	XCTAssertEqualObjects(responseString, path, @"Unexpected response for %@ %@", method, path);
	AZLOGOUT;
}

- (void)verifyRouteNotFoundWithMethod:(NSString *)method path:(NSString *)path {

	AZLOGIN;
	RouteResponse *response = [http routeMethod:method withPath:path parameters:@{} request:HTTPMessage.alloc.initEmptyRequest connection:nil];
	XCTAssertNil(response, @"Response should have been nil for %@ %@", method, path);
	AZLOGOUT;
}

- (void)verifyMethod:(NSString*)meth path:(NSString*)pth contentType:(NSString*)cntntType inputString:(NSString*)inStr responseString:(NSString*)expctResStr {

	AZLOGIN; __block NSError *error = nil;
	__block NSURLResponse *response; __block NSHTTPURLResponse *httpResponse; __block NSData *responseData,*data; __block NSString *responseString;
	ASIHTTPRequest *requester 	= [ASIHTTPRequest.alloc initWithURL:$URL([[@"http://127.0.0.1:" withString:@(http.listeningPort).stringValue] withPath:pth])];
	requester.requestMethod    = meth.uppercaseString;
	requester.requestHeaders   = @{@"Content-Type":cntntType,@"Content-Length":@(data.length).stringValue}.mutableCopy;
	if ((data = [inStr dataUsingEncoding:NSUTF8StringEncoding])) requester.postBody = data.mutableCopy;
	requester.completionBlock 	= ^(ASIHTTPRequest *request) {

		data 		= request.responseData;
		error  	= [request error];
//	NSError *error = nil;
//	responseData 	= LogAndReturn([NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error]);

//		NSS *responsePage      	= request.responseString.copy;

//		if (requestError) { block($DEFINE(@"undefined", @"no response from urban")); return; }
//		AZHTMLParser *p 	= [AZHTMLParser.alloc initWithString:responsePage error:&requestError];
//		HTMLNode *title 	= [p.head findChildWithAttribute:@"property" matchingName:@"og:title" allowPartial:YES];
//		NSS *content	 	= [title getAttributeNamed:@"content"];
//		HTMLNode *descN   = [p.head findChildWithAttribute:@"property" matchingName:@"og:description" allowPartial:YES];
//		NSS *desc  			= [descN getAttributeNamed:@"content"];
	};

//	NSURLResponse *response; NSHTTPURLResponse *httpResponse; NSMutableURLRequest *request; NSData *responseData,*data; NSString *responseString;
//	data 		= [inStr dataUsingEncoding:NSUTF8StringEncoding];
//	request 	= [NSMutableURLRequest.alloc initWithURL:$URL([[@"http://127.0.0.1:" withString:@(http.listeningPort).stringValue] withPath:pth])];
//	[request setHTTPMethod:meth];
//	[request addValue:cntntType 						forHTTPHeaderField:@"Content-Type"];
//	[request addValue:@(data.length).stringValue forHTTPHeaderField:@"Content-Length"];
//	[request setHTTPBody:data];
//

//	responseData 	= LogAndReturn([NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error]);
	[requester startAsynchronous];

	XCTAssertNotNil(requester, 		@"No response received for %@ %@", 		 meth, pth);
	XCTAssertNotNil(responseData, @"No response data received for %@ %@", meth, pth);
	XCTAssertTrue([requester ISKINDA:ASIHTTPRequest.class], @"Response is not an NSHTTPURLResponse"); // NSHTTPURLResponse.class

//	XCTAssertEqual((httpResponse = (NSHTTPURLResponse*)response).statusCode, 200L, @"Unexpected status code for %@ %@", meth, pth);

//	responseString = [NSString stringWithBytes:responseData.bytes length:(unsigned int)responseData.length encoding:NSUTF8StringEncoding];
//	XX(expctResStr); XX(responseString);
//	XCTAssertEqualObjects(responseString, expctResStr, @"Unexpected response for %@ %@", meth, pth);
	AZLOGOUT;
}

@end
