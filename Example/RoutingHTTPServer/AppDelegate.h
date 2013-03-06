
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "AssetCollection.h"


#define REQ RouteRequest
#define RES RouteResponse

@class RoutingHTTPServer;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (strong) IBOutlet NSWindow *window;
@property (strong, nonatomic) RoutingHTTPServer *http;
@property (assign) IBOutlet WebView *webView;
@property (assign) IBOutlet NSTextField *urlField;
@property (assign) IBOutlet	NSTableView *shortcuts;
@property (strong) NSMutableArray *queries;
@property (strong) IBOutlet NSArrayController *queriesController;
@property (strong) NSString *baseURL;
@property (strong) IBOutlet AssetCollection *assets;

@property (weak) IBOutlet NSPathControl *jsPathBar;
@property (weak) IBOutlet NSPathControl *cssPathBar;
@property (weak) IBOutlet NSPathControl *htmlPathBar;

- (void)setupRoutes;

@end

@interface AppDelegate ()
- (void)handleSelectorRequest:(RouteRequest *)request withResponse:(RouteResponse *)response;
@end

@interface Shortcut : NSObject
@property (strong, nonatomic) NSS* uri, *syntax;
- (id) initWithURI:(NSS*)uri syntax:(NSS*)syntax;
@end
