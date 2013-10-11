
#import <Foundation/Foundation.h>
#import "HTTPConnection.h"


@class RoutingHTTPServer;
@interface RoutingConnection : HTTPConnection

@property (readonly) WebSocket *ws;
@end
