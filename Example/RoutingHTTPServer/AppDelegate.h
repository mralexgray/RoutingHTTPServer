
#import <WebKit/WebKit.h>
#import "HTTPConnection.h"

#define REQ RouteRequest
#define RES RouteResponse

#define UPLOAD_FILE_PROGRESS @"uploadfileprogress"
//#define HTTPLogVerbose(arg,...) NSLog(arg,...)

@class RoutingHTTPServer;
@interface AppDelegate : NSObject <NSApplicationDelegate, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (NATOM, STRNG) RoutingHTTPServer *http;
@property (WK)  IBOutlet    WebView *webView;
@property (WK) 	IBOutlet 	    NSW *window;
@property (WK) 	IBOutlet     NSTXTF *urlField;
@property (ASS) 	IBOutlet     NSTextView *stdOutView;
@property (WK) 	IBOutlet	   NSTV *shortcuts;
@property (WK) 	IBOutlet       NSAC *queriesController;
@property (NATOM, STRNG) 	NSMA 			*queries;
@property (NATOM, STRNG) 	NSS 			*baseURL;


@property (WK) IBOutlet	NSArrayController *assetController;
@property (WK) IBOutlet	NSTableView *assetTable;
@property (NATOM, STRNG) AssetCollection *assets;

@property (WK) IBOutlet NSPathControl *jsPathBar;
@property (WK) IBOutlet NSPathControl *cssPathBar;
@property (WK) IBOutlet NSPathControl *htmlPathBar;

- (void)setupRoutes;
- (IBAction) selectAssets: (id) sender;

@end

@interface AppDelegate ()
- (void)handleSelectorRequest:(RouteRequest *)request withResponse:(RouteResponse *)response;
@end

@interface Shortcut : NSObject
@property (STRNG, NATOM) NSS* uri, *syntax;
- (id) initWithURI:(NSS*)uri syntax:(NSS*)syntax;
@end
