#import "RoutingHTTPServer.h"
#import "RoutingConnection.h"
#import "Route.h"

@implementation RoutingHTTPServer {	NSMutableDictionary *routes, *defaultHeaders,*mimeTypes;  dispatch_queue_t routeQueue; }

@synthesize defaultHeaders;

- (NSURL*) URL {  return  $URL($(@"http://%@:%ld/",self.domain, self.port)); }

- (id)init {	if (self != super.init) return nil;

	connectionClass 	= [RoutingConnection self];
	routes 				= NSMutableDictionary.new;
	defaultHeaders 	= NSMutableDictionary.new; 	[self setupMIMETypes];
	return self;
}

#if !OS_OBJECT_USE_OBJC_RETAIN_RELEASE
- (void)dealloc { if (routeQueue) dispatch_release(routeQueue); }
#endif

- (void)setDefaultHeaders:(NSDictionary*)headers 							{ defaultHeaders = headers ? headers.mutableCopy : @{}.mutableCopy; 	}
- (void)setDefaultHeader:(NSString*)field value:(NSString*)value 	{ defaultHeaders [field] = value; 												}
- (dispatch_queue_t)routeQueue 													{ return routeQueue;																	}

- (void)setRouteQueue:(dispatch_queue_t)queue {
#if !OS_OBJECT_USE_OBJC_RETAIN_RELEASE
	if (queue) 			dispatch_retain(queue);
	if (routeQueue)	dispatch_release(routeQueue);
#endif
	routeQueue = queue;
}
- (NSDictionary*)mimeTypes {	return mimeTypes;	}
- (void)setMIMETypes:(NSDictionary*)types { mimeTypes = types ? [types mutableCopy] : @{}.mutableCopy; }
- (void)setMIMEType:(NSString*)theType forExtension:(NSString*)ext { mimeTypes[ext] = theType; }

- (NSString*)mimeTypeForPath:(NSString*)path { return 	!path.pathExtension || path.pathExtension.length < 1 ? nil
																		:	mimeTypes[path.pathExtension.lowercaseString];
}

- (void)    ws:(NSString*)path withBlock:(RequestHandler)block { [self handleMethod:@"GET" withPath:path block:block];		}
// void (^RequestHandler)(RouteRequest *request, RouteResponse *response);
- (void)   get:(NSString*)path withBlock:(RequestHandler)block { [self handleMethod:@"GET" withPath:path block:block];		}
- (void)  post:(NSString*)path withBlock:(RequestHandler)block { [self handleMethod:@"POST" withPath:path block:block];		}
- (void)   put:(NSString*)path withBlock:(RequestHandler)block { [self handleMethod:@"PUT" withPath:path block:block];    	}
- (void)delete:(NSString*)path withBlock:(RequestHandler)block { [self handleMethod:@"DELETE" withPath:path block:block];	}

- (void)handleMethod:(NSString*)method withPath:(NSString*)path block:(RequestHandler)block {
	Route *route = [self routeWithPath:path];	route.handler = block;	[self addRoute:route forMethod:method];
}
- (void)handleMethod:(NSString*)method withPath:(NSString*)path target:(id)target selector:(SEL)selector {
	Route *route = [self routeWithPath:path];	route.target = target;	route.selector = selector; [self addRoute:route forMethod:method];
}
- (void)addRoute:(Route*)route forMethod:(NSString*)method { method = method.uppercaseString;

	__block NSMutableArray *methodRoutes = routes[method] ?: ^{ routes[method] = (methodRoutes = @[].mutableCopy); return methodRoutes; }();
	[methodRoutes addObject:route];
	![method isEqualToString:@"GET"] ?: [self addRoute:route forMethod:@"HEAD"]; 	// Define a HEAD route for all GET routes
}

- (Route*)routeWithPath:(NSString*)path { Route *route = Route.new;	NSMutableArray *keys = NSMutableArray.new;

																						 // This is a custom regular expression, just remove the {}
	if (path.length > 2 && [path characterAtIndex:0] == '{') path = [path substringWithRange:NSMakeRange(1, [path length] - 2)];
	else {

		// Escape regex characters
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[.+()]" options:0 error:nil];
		path = [regex stringByReplacingMatchesInString:path options:0 range:NSMakeRange(0, path.length) withTemplate:@"\\\\$0"];

		// Parse any :parameters and * in the path
		regex = [NSRegularExpression regularExpressionWithPattern:@"(:(\\w+)|\\*)" options:0 error:nil];
		NSMutableString *regexPath = [NSMutableString stringWithString:path];
		__block NSInteger diff = 0;
		[regex enumerateMatchesInString:path options:0 range:NSMakeRange(0, path.length)
			usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
				NSRange replacementRange = NSMakeRange(diff + result.range.location, result.range.length);
				NSString *replacementString;

				NSString *capturedString = [path substringWithRange:result.range];
				if ([capturedString isEqualToString:@"*"]) {	[keys addObject:@"wildcards"]; replacementString = @"(.*?)";
				} else {
					[keys addObject:[path substringWithRange:[result rangeAtIndex:2]]]; // was keystring
					replacementString = @"([^/]+)";
				}
				[regexPath replaceCharactersInRange:replacementRange withString:replacementString];
				diff += replacementString.length - result.range.length;
			}];
		path = [NSString stringWithFormat:@"^%@$", regexPath];
	}
	route.regex = [NSRegularExpression regularExpressionWithPattern:path options:NSRegularExpressionCaseInsensitive error:nil];
	if (keys.count) route.keys = keys;
	return route;
}

- (BOOL)supportsMethod:(NSString*)method {
	return ([routes objectForKey:method] != nil);
}

- (void)handleRoute:(Route*)route withRequest:(RouteRequest*)request response:(RouteResponse*)response {
	if (route.handler) {
		route.handler(request, response);
	} else {
		#pragma clang diagnostic push
		#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[route.target performSelector:route.selector withObject:request withObject:response];
		#pragma clang diagnostic pop
	}
}

- (RouteResponse*)routeMethod:(NSString*)method withPath:(NSString*)path parameters:(NSDictionary*)params request:(HTTPMessage*)httpMessage connection:(HTTPConnection*)connection {

	NSMutableArray *methodRoutes; if (!(methodRoutes = routes[method])) return nil;

	for (Route *route in methodRoutes) {  NSTextCheckingResult *result;

		if (!(result = [route.regex firstMatchInString:path options:0 range:NSMakeRange(0, path.length)])) continue;;

		// The first range is all of the text matched by the regex.
		NSUInteger captureCount = [result numberOfRanges];

		if (route.keys) {
			// Add the route's parameters to the parameter dictionary, accounting for the first range containing the matched text.
			if (captureCount == [route.keys count] + 1) {
				NSMutableDictionary *newParams = [params mutableCopy];
				NSUInteger index = 1;
				BOOL firstWildcard = YES;
				for (NSString *key in route.keys) {
					NSString *capture = [path substringWithRange:[result rangeAtIndex:index]];
					if ([key isEqualToString:@"wildcards"]) {
						NSMutableArray *wildcards = [newParams objectForKey:key];
						if (firstWildcard) {
							// Create a new array and replace any existing object with the same key
							wildcards = NSMutableArray.new;
							[newParams setObject:wildcards forKey:key];
							firstWildcard = NO;
						}
						[wildcards addObject:capture];
					} else [newParams setObject:capture forKey:key];
					index++;
				}
				params = newParams;
			}
		} else if (captureCount > 1) {
			// For custom regular expressions place the anonymous captures in the captures parameter
			NSMutableDictionary *newParams 	= [params mutableCopy];
			NSMutableArray *captures 			= NSMutableArray.new;
			for (NSUInteger i = 1; i < captureCount; i++) [captures addObject:[path substringWithRange:[result rangeAtIndex:i]]];
			[newParams setObject:captures forKey:@"captures"];
			params = newParams;
		}
		RouteRequest   *request = [RouteRequest.alloc initWithHTTPMessage:httpMessage parameters:params];
		RouteResponse *response = [RouteResponse.alloc initWithConnection:connection];
		!routeQueue ?  [self handleRoute:route withRequest:request response:response]
							// Process the route on the specified queue
						:	dispatch_sync(routeQueue, ^{	@autoreleasepool { [self handleRoute:route withRequest:request response:response];	} });
		return response;
	}
	return nil;
}

- (void)setupMIMETypes {
	mimeTypes = @{@"js": @"application/x-javascript", @"gif" : @"image/gif", @"jpg": @"image/jpeg", @"jpeg":@"image/jpeg",@"png": @"image/png", @"svg":@"image/svg+xml", @"tif":@"image/tiff", @"tiff":@"image/tiff", @"ico": @"image/x-icon", @"bmp": @"image/x-ms-bmp", @"css": @"text/css",
				@"html":@"text/html", @"htm":@"text/html",@"txt": @"text/plain", @"xml":@"text/xml"}.mutableCopy;
}

@end
