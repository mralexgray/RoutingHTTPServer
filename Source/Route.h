#import <Foundation/Foundation.h>
#import "RoutingHTTPServer.h"

@interface Route : NSObject

@property (nonatomic, strong) NSRegularExpression *regex;
@property (nonatomic, copy) RequestHandler handler;
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, copy) NSArray *keys;

@end
