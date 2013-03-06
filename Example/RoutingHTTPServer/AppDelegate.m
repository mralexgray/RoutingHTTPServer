#import "AppDelegate.h"


#define $SHORT(A,B) [Shortcut.alloc initWithURI:A syntax:B]

@implementation AppDelegate
- (void)setupRoutes
{
	[@[ @[ @"/hello",					@"/hello" ],
	    @[ @"/hello/:name",		@"/hello/somename"],
	    @[ @"{^/page/(\\d+)}", 	 	 @"/page/9999"],
		@[ @"{^/ugh.png", 			   @"/ugh.png"],
		@[ @"/colorlist",	        @"/colorlist" ],
		@[ @"/selector",			 @"/selector" ],
		@[ @"/widgets",				  @"/widgets" ]] each:^(id obj) {

		[_queriesController addObject:$SHORT(obj[1], obj[0])];
	}];

	[[_queriesController.arrangedObjects subarrayFromIndex:0 toIndex:2] eachWithIndex:^(Shortcut *obj, NSInteger idx) {
		[_http get:obj.uri withBlock:^(REQ *req, RES *res) {

			NSS *theResponse = idx == 0	? 	@"Hello!"
							 : idx == 1 ? 	$(@"Hello %@!", req.params[@"name"])
										: 	$(@"You requested page %@", req.params[@"captures"][0]);
			[res respondWithString:theResponse];
		}];
	}];

	[_http post:@"/widgets" withBlock:^(REQ *req, RES *res) {	// Create a new widget, [request body] contains the POST body data. For this example we're just going to echo it back.
		NSLog(@"POST: %@", req.body);
		[res respondWithData:req.body];	}];

	// Routes can also be handled through selectors
	[@[	@[@"/colorlist", 	@"colorlist:withResponse:"],
		@[ @"/selector",	@"handleSelectorRequest:withResponse:"]] each:^(id obj) {
			[_http handleMethod:@"GET" withPath:obj[0] target:self selector:$SEL(obj[1])];
	}];

//	ADB target:self selector:@selector()];

	[_http get:@"{^/ugh.png" withBlock:^(RouteRequest *req, RouteResponse *res) {
		NSImage *image = [[[NSImage systemImages]randomElement] scaleToFillSize:NSMakeSize(344,344)];
		NSData *d = [image TIFFRepresentation];

		[res respondWithData:d]; //[self PNGRepresentationOfImage:image]];
	}];

	[_http get:@"{^/vageen.png" withBlock:^(REQ *req, RES *res) {
		[self contactSheetWith: [NSIMG.frameworkImages withMaxItems:10]  rect:AZScreenFrame() cols:3 callback:^(NSIMG *i) {
//			[response respondWithFile:  (NSS *)path async:(BOOL)async;

			NSS*	path = @"/tmp/atoztempfile.CE4DED94-E457-4A0A-B214-B1866616DDBA.png";// [i asTempFile];
			NSLog(@"image: %@  path: %@", i, path);

//			[i openInPreview];
			[res respondWithFile:path];// (NSS *)path async:(BOOL)async;

//			[i lockFocus];
//			NSBIR *bitmapRep = [NSBIR.alloc initWithFocusedViewRect:AZRectFromSize(i.size)];
//			[i unlockFocus];
//
//			NSData *rep = [bitmapRep representationUsingType:NSPNGFileType properties:Nil];

//			NSBIR *bitmapRep = [NSBIR.alloc initWithFocusedViewRect:AZRectBy( i.size.width, i.size.height)];
//			[i unlockFocus];
//			NSData *rep = [bitmapRep representationUsingType:NSPNGFileType properties:Nil];
//			NSLog(@"idata: %@", rep);
//			[res respondWithData:rep];//PNGRepresentation(i)];//rep]; //[self PNGRepresentationOfImage:image]];
		}];

	}];
	NSLog(@"Queries: %@..  Arranged: %@", _queries, _queriesController.arrangedObjects);
//	[_shortcuts reloadData];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification;
{
	[self loadURL:$(@"%@%@",_baseURL, ((Shortcut*)_queriesController.arrangedObjects[_shortcuts.selectedRow]).uri)];
}

- (void)contactSheetWith:(NSA*)images rect:(NSR)rect cols:(NSUI)cols callback:(void (^)(NSImage *))callback  {

	[NSThread performBlockInBackground:^{
		NSIMG* image =	[NSImage contactSheetWith:images inFrame:rect columns:cols];
		[[NSThread mainThread] performBlock:^{	callback(image); }];
    }];
}

- (void)handleSelectorRequest:(REQ *)request withResponse:(RES *)response {
	[response respondWithString:@"Handled through selector"];
}

- (void)colorlist:(REQ *)request withResponse:(RES *)response {

	__block NSMS *htmlText = @"<html><head><title>TEST</title>"\
								"<style> div { float:left; margin: 20px; padding: 20px; width:100px; height:100px; } </style>"\
							    "</head><body><ul>".mutableCopy;
				
	[NSColor.randomPalette /*colorNames */ each:^(NSC* color) {

		NSS *values = $(@"bright: %f, hue: %f,  sat: %f",	color.brightnessComponent,
															color.hueComponent,
															color.saturationComponent);
		[htmlText appendFormat: @"<li>"\
									"<div>%@ %@ </div>"\
									"<div style='background-color:#%@; color: %@; %@> %@<div>"\
								 "</li>", 	color.nameOfColor,
								 			color.isBoring ? @"IS VERY BORING": @"IS EXCITING!",
											color.toHex,
											color.contrastingForegroundColor.toHex,
											color.isBoring ? @"'": @" outline:10px solid red;'",
											values];
	}];
	[htmlText appendFormat: @"</ul></body></html>"];
	NSLog(@"sending: %@", htmlText);
	[response respondWithString:htmlText.copy];
}


-(RoutingHTTPServer*) http
{
	if (_http) return _http; else _http = RoutingHTTPServer.new;
	NSD* bundleInfo = NSBundle.mainBundle.infoDictionary; // Set a default Server header in the form of YourApp/1.0
	NSS *appVersion = bundleInfo[@"CFBundleShortVersionString"] ?: bundleInfo[@"CFBundleVersion"];
	_http.defaultHeaders = @{ @"Server": $(@"%@/%@", bundleInfo[@"CFBundleName"],appVersion) };
	_http.type	= @"_http._tcp.";
	[self setupRoutes];
	_http.port = 8080;
	_baseURL = $(@"http://localhost:%i", _http.port);
	NSError *error;	if (![_http start:&error]) 	NSLog(@"Error starting HTTP server: %@", error)	else [self loadURL:nil];
	return _http;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	_queries = NSMA.new;
	_urlField.delegate = self;
	self.http.documentRoot = [NSB.mainBundle.resourcePath withPath:@"twitter_bootstrap_admin"];	//	[@"~/Sites" stringByExpandingTildeInPath]];

	[@[ @[_cssPathBar, @"css"], @[_htmlPathBar, @"html"], @[_jsPathBar, @"js"]] each:^(id obj) {
		NSS* path = [[obj[0] URL]path];
		AssetType type = [(NSString*)obj[1] assetFromString];
		NSLog(@"adding type: %@ from path: %@", assetStringValue[type], path);
		[_assets addFolder:path matchingType:type];
	}];

}

- (void)textDidEndEditing: (NSNotification*)note { 	[self loadURL:_urlField.stringValue]; }

- (void)loadURL:(NSS*)string	{	[_webView.mainFrame loadRequest: [NSURLREQ requestWithURL:$URL(string ?: $(@"http://localhost:%i", _http.port))]];	}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame	{	_urlField.stringValue = sender.mainFrameURL;	}

@end


@implementation Shortcut
- (id) initWithURI:(NSS*)uri syntax:(NSS*)syntax	{	if (self != super.init ) return nil; _syntax = syntax; _uri = uri; return self; }
@end
