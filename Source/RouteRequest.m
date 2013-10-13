#import "RouteRequest.h"
#import "HTTPMessage.h"

@implementation RouteRequest { HTTPMessage *message; }	@synthesize params;

- (id)initWithHTTPMessage:(HTTPMessage*)msg parameters:(NSD*)prmtrs { return self = super.init ? params = prmtrs, message = msg, self : nil; }

-    (NSS*) description 				{ return [NSString stringWithData:message.messageData encoding:NSASCIIStringEncoding];	}
-    (NSD*) headers 						{ return message.allHeaderFields; 					}
-    (NSS*) header:	(NSS*)field 	{ return [message valueForHeaderField:field];	}
-      (id) param:	(NSS*)name	 	{ return params[name];									}
-    (NSS*) method 						{ return message.method;								}
-  (NSURL*) URL 							{ return message.URL;									}
- (NSData*) body 							{ return message.body;									}

@end
