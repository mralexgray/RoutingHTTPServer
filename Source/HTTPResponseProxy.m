
#import "HTTPResponseProxy.h"

@implementation HTTPResponseProxy @synthesize status = _stts, response = _resp;

- (NSInteger) status 									{ return _stts ?: [_resp respondsToSelector:@selector(status)] ? _resp.status : 200; 	}
- (NSInteger) customStatus	 							{ return _stts; 																								}
-      (void) setStatus:		  (NSInteger)code	{ 			_stts = code;		 																				}

// Implement the required HTTPResponse methods
-    (UInt64) contentLength 							{ return _resp ?  _resp.contentLength : 0; 				}
-    (UInt64) offset 									{ return _resp ?  _resp.offset 		  : 0;				}
-      (void) setOffset:		 (UInt64)off		{ if    (_resp)   _resp.offset 		  = off;				}
-   (NSData*) readDataOfLength:(NSUInteger)len 	{ return _resp ? [_resp readDataOfLength:len] : nil; 	}
-      (BOOL) isDone 									{ return _resp ?  _resp.isDone 		  : YES; 			}

// Forward all other invocations to the actual response object
- (BOOL) respondsToSelector:(SEL)sel 				{ return [_resp respondsToSelector:sel] ?: [super respondsToSelector:sel];				}
- (void) forwardInvocation:(NSInvocation*)inv 	{			[_resp respondsToSelector:inv.selector] ? [inv invokeWithTarget: _resp]
																																 : [super forwardInvocation:inv]; 	}

@end

