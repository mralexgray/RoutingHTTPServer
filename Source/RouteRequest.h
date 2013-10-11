#import <Foundation/Foundation.h>
@class HTTPMessage;

@interface RouteRequest : NSObject

@property (nonatomic, readonly) NSDictionary *headers;
@property (nonatomic, readonly) NSDictionary *params;

- (id)initWithHTTPMessage:(HTTPMessage *)msg parameters:(NSDictionary *)params;
- (NSString *)header:(NSString *)field;
- (id)param:(NSString *)name;
- (NSString *)method;
- (NSURL *)URL;
- (NSData *)body;

@end
