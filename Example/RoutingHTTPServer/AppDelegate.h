
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "AssetCollection.h"


#define REQ RouteRequest
#define RES RouteResponse

@class RoutingHTTPServer;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (STRNG) RoutingHTTPServer *http;
@property (WK)  IBOutlet    WebView *webView;
@property (WK) 	IBOutlet 	    NSW *window;
@property (WK) 	IBOutlet     NSTXTF *urlField;
@property (WK) 	IBOutlet	   NSTV *shortcuts;
@property (WK) 	IBOutlet       NSAC *queriesController;
@property (STRNG) 	NSMA 			*queries;
@property (STRNG) 	NSS 			*baseURL;


@property (WK) IBOutlet	NSArrayController *assetController;
@property (WK) IBOutlet	NSTableView *assetTable;
@property (NATOM) AssetCollection *assets;

@property (WK) IBOutlet NSPathControl *jsPathBar;
@property (WK) IBOutlet NSPathControl *cssPathBar;
@property (WK) IBOutlet NSPathControl *htmlPathBar;

- (void)setupRoutes;

@end

@interface AppDelegate ()
- (void)handleSelectorRequest:(RouteRequest *)request withResponse:(RouteResponse *)response;
@end

@interface Shortcut : NSObject
@property (STRNG, nonatomic) NSS* uri, *syntax;
- (id) initWithURI:(NSS*)uri syntax:(NSS*)syntax;
@end
