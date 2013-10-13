
@class        HTTPMessage ;
@interface   RouteRequest : NSObject

@property (RONLY)     NSS * method;
@property (RONLY)   NSURL * URL;
@property (RONLY)  NSData * body;
@property (RONLY)     NSD * headers,
								  * params;

-      (id) initWithHTTPMessage:(HTTPMessage*)msg parameters:(NSD*)params;

-    (NSS*) header:	(NSS*)field;
-      (id) param:	(NSS*)name;

@end
