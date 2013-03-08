#import "AppDelegate.h"
#import <KSHTMLWriter/KSHTMLWriter.h>
#import "RoutingHTTPServer.h"
#import "HTTPConnection.h"
#import "HTTPAsyncFileResponse.h"
#import "HTTPFileResponse.h"
#import "HTTPConnection.h"
#import "HTTPDataResponse.h"


#define $SHORT(A,B) [Shortcut.alloc initWithURI:A syntax:B]
#define	vLOG(A)	[((AppDelegate*)[NSApp sharedApplication].delegate).textOutField appendToStdOutView:A] // $(@"%s: %@", __PRETTY_FUNCTION__, [NSString stringWithFormat: args])]
//#define	NSLog(...)	[((AppDelegate*)[NSApp sharedApplication].delegate).textOutField appendToStdOutView:A] // $(@"%s: %@", __PRETTY_FUNCTION__, [NSString stringWithFormat: args])]
//#define NSLog(args...) _AZSimpleLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,args);
@implementation AppDelegate

//	essential for list view to work.
- (AssetCollection*) assets	{ return _assets = AssetCollection.sharedInstance; 	}

- (void)setupRoutes
{
	//	[_http get:@"*" withBlock:^(REQ *req, RES *res) { NSLog(@"Req:%@... Params: %@", req, req.params);   NSLog(@"Res:%@... Params: %@", res, res.headers);   }];
//    NSMutableString *xml = [NSMutableString string];
//    KSXMLWriter *writer = [[KSXMLWriter alloc] initWithOutputWriter:xml];
//
//    [writer startElement:@"foo" attributes:nil];
//    [writer writeCharacters:@"bar"];
//    [writer endElement];
//
//	KSHTMLWriter *_writer = [[KSHTMLWriteralloc initWithOutputWriter:output encoding:NSUTF8StringEncoding];
//	[_writer writeString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"];
//
//	[_writer pushAttribute:@"xmlns" value:@"http://www.sitemaps.org/schemas/sitemap/0.9"];
//	[_writer startElement:@"sitemapindex"];

	//	NSUI lastItemInMatrix = [_queriesController.arrangedObjects indexOfObjectPassingTest:^BOOL(Shortcut *shortcut, NSUI idx, BOOL *stop) {	return [shortcut.uri isEqualToString:@"/custom"];	}];

	[@[	@[ @"/hello",			       @"/hello" ],	@[ @"/hello/:name",			@"/hello/somename"],
		@[ @"{^/page/(\\d+)$}", 	@"/page/9999"],	@[ @"/info",						 @"/info" ],
		@[ @"/customHTML",			   @"/custom"]]

	eachWithIndex:^(id obj, NSI idx) {	[_queriesController insertObject:$SHORT(obj[0], obj[1]) atArrangedObjectIndex:idx];

		[_http get:obj[0] withBlock:^(REQ *req, RES *res) {	[res respondWithString

		: idx == 1 ?    @"This text is showing because the URL ends with '/hello'"
		: idx == 2 ? $( @"Hello %@!", req.params[@"name"])
		: idx == 3 ? $( @"/page/%@",  req.params[@"captures"][0])
		: idx == 4 ? $( @"This could be written as '	%@  ' \n\n Which would output req: %@  \n and response: %@.", @"[_http get:@\"/info\" withBlock:^(REQ *req, RES *res) { AZLOG(req);	AZLOG(res);	}]; \n 			[res respondWithString:theResponse]; }]; \n}];'", req, res)
		: idx == 5 ? ^{ return @"custom placeholder"; }() : @""

	];	}]; }];

	[@[	@[ @"/bootstrap",	 	 @"/bootstrap"],	@[ @"{^/ugh.png", 				   @"/ugh.png"],
		@[ @"/colorlist",	 	@"/colorlist" ],	@[ @"/selector",				  @"/selector"],
		@[ @"/widgets",		  	   @"/widgets"],	@[ @"/xml",			          		   @"/xml"],
		@[ @"/recognize",    	 @"/recognize"],
		@[ @"/wav:",		       	   @"/wav"],	@[ @"http://mrgray.com/sip/sipml5/",   @"/sip"],
		@[ @"{^/vageen.png",    @"/vageen.png"]]
													each:^(id obj) { [_queriesController addObject: $SHORT(obj[1], obj[0])]; }];



//	[[_queriesController.arrangedObjects subarrayToIndex:lastItemInMatrix + 1] eachWithIndex:^(Shortcut *obj, NSInteger idx) {


	[_http get:@"/sip" withBlock:^(RouteRequest *request, RouteResponse *response) {
		[response setStatusCode:302]; // or 301
		[response setHeader:@"Location" value:@"http://mrgray.com/sip/sipml5/"];//[self.baseURL stringByAppendingString:@"/new"]];
	}];

//	[_http get:@"/info" withBlock:^(REQ *req, RES *res) { AZLOG(req);	AZLOG(res);	}];

	[_http get:@"/bootstrap" withBlock:^(REQ *req, RES *res) {
		 [Bootstrap initWithUserStyle:nil script:nil andInnerHTML:nil  calling:^(id sender) {
// 	initWithUserStyles:@"" script:@"" andInnerHTML:@"<P>HELLO</P>" calling:^(id sender) {
			[res respondWithString:[(NSS*)sender copy]];
		 }];
	}];

	[_http get:@"/indexUP.html" withBlock:^(REQ *req, RES *res) {
		NSLog(@"%@", req.params);
			[res respondWithFile:$(@"%@%@",[NSBundle.mainBundle resourcePath],@"/indexUP.html")];
	}];
	
	[_http get:@"/recognize" withBlock:^(REQ *req, RES *res) {
		GoogleTTS *u = GoogleTTS.instance;
		[u getText:NSS.dicksonBible withCompletion:^(NSString *text, NSString *wavpath) {
			[res respondWithFile:wavpath];
		}];
	}];
	//	SELECTORS AS STRINGS
	[@[	@[ @"/colorlist", 	@"colorlist:withResponse:"],
	 	@[ @"/selector",	@"handleSelectorRequest:withResponse:"]] each:^(id obj) {
		 [_http handleMethod:@"GET" withPath:obj[0] target:self selector:$SEL(obj[1])];
	 }];

	[_http get:@"{^/ugh.png" withBlock:^(RouteRequest *req, RouteResponse *res) {
		NSIMG* rando = [NSIMG.systemImages.randomElement scaledToMax:AZMinDim(_webView.bounds.size)];
		[res respondWithData: PNGRepresentation(rando)];
		//[rando.bitmap representationUsingType:NSJPEGFileType  properties:nil]];
	}];

	[_http get:@"{^/vageen.png" withBlock:^(REQ *req, RES *res) {
//		[self contactSheetWith: [NSIMG.frameworkImages withMaxItems:10]  rect:AZScreenFrame() cols:3
//					  callback:^(NSIMG *i) {
		 [res respondWithData:[[NSImage contactSheetWith:[NSIMG.frameworkImages withMaxRandomItems:10]
										         inFrame:_webView.bounds columns:4]
						 .bitmap representationUsingType: NSJPEGFileType properties:nil]];
//		 NSData *result = [i.bitmap	representationUsingType:NSJPEGFileType properties:nil];
						  //		NSData *d = [rando.representations[0] bitmapRepresentation];// bitmapRepresentation;//][0] representationUsingType:NSPNGFileType properties:nil];// TIFFRepresentation];
//						  [res respondWithData:result]; }];
	}];
	[_http get:@"/record/*.*" withBlock:^(RouteRequest *req, RouteResponse *res) {
		NSLog(@"req params:  %@", req.params);
//        [res setStatusCode:302]; // or 301
//        [res setHeader:@"Location" value:[self.baseURL stringByAppendingString:@"/record/"]];
		[res respondWithFile:[[[NSBundle.mainBundle resourcePath] withPath:@"FlashWavRecorder"]withPath:req.params[@"wildcards"][0]]];
	}];
	[_http post:@"/uploadwav" withBlock:^(REQ *req, RES *res) {	// Create a new widget, [request body] contains the POST body data. For this example we're just going to echo it back.
		NSLog(@"Post to /uploadwav %@", req.params);
	}];
}
	//	ADB target:self selector:@selector()];

	//		NSData *d = [rando.representations[0] bitmapRepresentation];// bitmapRepresentation;//][0] representationUsingType:NSPNGFileType properties:nil];// TIFFRepresentation];


//		NSS *thePath = req.params[@"filepath"] ?: @"/Users/localadmin/Desktop/blanche.withspeech.flac";
//		GoogleTTS *u = [GoogleTTS instanceWithWordsToSpeak:NSS.dicksonisms.randomElement];
//		[NSThread performBlockInBackground:^{
//			u.words = NSS.dicksonisms.randomElement;
//			[res respondWithFile:u.nonFlacFile];
//
//				[[NSThread mainThread] performBlock:^{
//										[res respondWithFile:wavpath async:YES];
//				}];
//			}];
//		}];

		//[GoogleTTS instanceWithWordsToSpeak:NSS.dicksonisms.randomElement completion:^(NSString *t, NSS*file) {
//			NSLog(@"wavpath:%@.... u/nonflac: %@",wavpath,  u.nonFlacFile);
//			NSData *bytes	= [NSData dataWithContentsOfURL:$URL(u.nonFlacFile)];//wav g.nonFlacFile]];
//			NSLog(@"sending:'%ld' bytes", [bytes length]);
//			[res respondWithFile:u.nonFlacFile];

/**
	[_http post:@"/xml" withBlock:^(RouteRequest *request, RouteResponse *response) {
		NSData *bodyData = [request body];
		NSString *xml = [[NSString alloc] initWithBytes:[bodyData bytes] length:[bodyData length] encoding:NSUTF8StringEncoding];

		// Green?
		NSRange tagRange = [xml rangeOfString:@"<greenLevel>"];
		if (tagRange.location != NSNotFound) {
			NSUInteger start = tagRange.location + tagRange.length;
			NSUInteger end = [xml rangeOfString:@"<" options:0 range:NSMakeRange(start, [xml length] - start)].location;
			if (end != NSNotFound) {
				NSString *greenLevel = [xml substringWithRange:NSMakeRange(start, end - start)];
				[response respondWithString:greenLevel];
			}
		}
	}];


	[_http post:@"/widgets" withBlock:^(REQ *req, RES *res) {	// Create a new widget, [request body] contains the POST body data. For this example we're just going to echo it back.
		NSLog(@"POST: %@", req.body);
		[res respondWithData:req.body];	}];
*/
	// Routes can also be handled through selectors


/**
	[_http get:@"/wav" withBlock:^(RouteRequest *req, RouteResponse *res) {

		GoogleTTS *g = [GoogleTTS instanceWithWordsToSpeak:NSS.dicksonisms.randomElement completion:^(NSString *s) {

			NSURL *urlPath = [NSURL fileURLWithPath:g.nonFlacFile];
//			NSString *wavbundlepath = [urlPath absoluteString];
//			NSLog(@"wavbundlepath: %@",wavbundlepath);
			NSLog(@"Text from google: %s.... playing WAV.");
			NSData *bytes=[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:g.nonFlacFile]];
			[res respondWithData:bytes];
		}];
//		NSLog(@"bytes: %@",bytes);
	}];

	NSString *recordPostLength = [NSString stringWithFormat:@"%d", [bytes length]];

//	NSMutableString *urlstr = [NSMutableString stringWithFormat:@"%@", @"http://www.myserver.com/api/UploadFile?Name="];
//	[urlstr appendString:@"Temp"];
//	[urlstr appendFormat:@"&MemberID=%d", 0];
//	[urlstr appendFormat:@"&Type=%@",@"Recording"];
//	[urlstr appendFormat:@"&client=%@",@"ios"];
//	NSLog(@"urlstr.......%@",urlstr);

	NSMutableURLRequest *recordRequest = [[NSMutableURLRequest alloc] init] ;
	[recordRequest setURL:[NSURL URLWithString:urlstr]];

	NSInputStream *dataStream = [NSInputStream inputStreamWithData:bytes];
	[recordRequest setHTTPBodyStream:dataStream];

	[recordRequest setHTTPMethod:@"POST"];

	NSURLResponse *recordResponse;
	NSError *recordError;
	NSData *recordResponseData = [NSURLConnection sendSynchronousRequest:recordRequest returningResponse:&recordResponse error:&recordError];

	NSString *recordResp = [[NSString alloc]initWithData:recordResponseData encoding:NSUTF8StringEncoding];
	NSLog(@"recordResp:%@", recordResp);
	recordResponceJson = [recordResp JSONValue];
	NSLog(@"recordResponceJson = %@",recordResponceJson);
	recId = [recordResponceJson valueForKey:@"ID"];
	NSLog(@"recId....%@", recId);
*/
//		[res respondWithFile:@"/Users/localadmin/Desktop/2206 167.jpg"];  //  OK

//		NSS * tmp = [[NSTemporaryDirectory() withPath:NSS.UUIDString] withExt:@"png"]; // OK
//		[NSIMG.frameworkImages.randomElement saveAs:tmp];
//		[res respondWithFile:tmp async:YES];


////			[response respondWithFile:  (NSS *)path async:(BOOL)async;
//
//			NSS*	path = @"/tmp/atoztempfile.CE4DED94-E457-4A0A-B214-B1866616DDBA.png";// [i asTempFile];
//			NSLog(@"image: %@  path: %@", i, path);
//
////			[i openInPreview];
//			[res respondWithFile:path];// (NSS *)path async:(BOOL)async;
//
////			[i lockFocus];
//			NSBIR *bitmapRep = [NSBIR.alloc initWithFocusedViewRect:AZRectFromSize(i.size)];
//			[i unlockFocus];
//
//			NSData *rep = [bitmapRep representationUsingType:NSPNGFileType properties:Nil];

//			NSBIR *bitmapRep = [NSBIR.alloc initWithFocusedViewRect:AZRectBy( i.size.width, i.size.height)];
//			[i unlockFocus];
//			NSData *rep = [bitmapRep representationUsingType:NSPNGFileType properties:Nil];
//			NSLog(@"idata: %@", rep);
//			[res respondWithData:rep];//PNGRepresentation(i)];//rep]; //[self PNGRepresentationOfImage:image]];
//		}];

//	}];
//	NSLog(@"Queries: %@..  Arranged: %@", _queries, _queriesController.arrangedObjects);
//	[_shortcuts reloadData];


- (void)tableViewSelectionDidChange:(NSNotification *)notification;
{
	AZLOG(notification.object);
	if (notification.object == _shortcuts)
		[self loadURL:$(@"%@%@",_baseURL, ((Shortcut*)_queriesController.arrangedObjects[_shortcuts.selectedRow]).uri)];
	else {
		NSS *pre = $(@"<pre>%@</pre>", [((Asset*)_assetController.arrangedObjects[_assetTable.selectedRow]).markup encodeHTMLCharacterEntities]);

		[_webView.mainFrame loadHTMLString:[pre wrapInHTML]  baseURL:$URL(_baseURL)];
	}
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
	_http.port = 8080;
	_baseURL = $(@"http://localhost:%i", _http.port);
	[self setupRoutes];
	NSError *error;	if (![_http start:&error]) 	NSLog(@"Error starting HTTP server: %@", error)	else [self loadURL:nil];
	return _http;
}


- (void)awakeFromNib {

	_queries 				= NSMA.new;
	_urlField.delegate 		= self;
	self.http.documentRoot 	= LogAndReturn([NSB bundleForClass:KSHTMLWriter.class].resourcePath);//@"/";//[[Bootstrap class]reso];// withPath:@"twitter_bootstrap_admin"];
//	_http.connectionClass	= [WTZHTTPConnection class];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUploadProgressNotification:) name:UPLOAD_FILE_PROGRESS object:nil];
	
	[_assetTable registerForDraggedTypes:@[AssetDataType]];

}

- (void)textDidEndEditing: (NSNotification*)note { 	[self loadURL:_urlField.stringValue]; }

- (void)loadURL:(NSS*)string	{	[_webView.mainFrame loadRequest: [NSURLREQ requestWithURL:$URL(string ?: $(@"http://localhost:%i", _http.port))]];	}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame	{	_urlField.stringValue = sender.mainFrameURL;	}


// drag operation stuff
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    // Copy the row numbers to the pasteboard.
    NSData *zNSIndexSetData = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:AssetDataType] owner:self];
    [pboard setData:zNSIndexSetData forType:AssetDataType];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
    // Add code here to validate the drop
    //NSLog(@"validate Drop");
    return NSDragOperationEvery;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:AssetDataType];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    NSInteger dragRow = [rowIndexes firstIndex];

    // Move the specified row to its new location...
	// if we remove a row then everything moves down by one
	// so do an insert prior to the delete
	// --- depends which way we're moving the data!!!
	if (dragRow < row) {
		[_assets insertObject:[_assets.assets objectAtIndex:dragRow] inAssetsAtIndex:row];
		[_assets removeObjectFromAssetsAtIndex:dragRow];
//		[_assetTable noteNumberOfRowsChanged];
//		[self.nsTableViewObj reloadData];

		return YES;

	} // end if

//	MyData * zData = [nsAryOfDataValues objectAtIndex:dragRow];
//	[nsAryOfDataValues removeObjectAtIndex:dragRow];
//	[nsAryOfDataValues insertObject:zData atIndex:row];
//	[self.nsTableViewObj noteNumberOfRowsChanged];
//	[self.nsTableViewObj reloadData];

	return YES;
}


- (IBAction) selectAssets: (id) sender
{

	NSLog(@"opening");
	NSOpenPanel* openPanel = NSOpenPanel.openPanel;
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection: YES];
	NSA *tarr 		= @[@"js", @"css", @"txt", @"html", @"php", @"shtml"];
	[openPanel setAllowedFileTypes:tarr];
    [openPanel beginSheetModalForWindow: _window completionHandler: ^(NSI result) {
		if (result == NSFileHandlingPanelOKButton) {
//		NSURL *url = [[panel URLs] objectAtIndex: 0];
//			   url = [openPanel URL];
//		[ @[ @[_cssPathBar, @"style"], @[_htmlPathBar, @"div"], @[_jsPathBar, @"javascript"]] each:^(NSA *obj) {
			[openPanel.URLs each:^(NSURL* obj) {
				NSS* path = obj.path;
				AssetType type = [path.pathExtension assetFromString];
				NSLog(@"adding type: %@ from path: %@", assetStringValue[type], path);
				[self.assets insertObject:[Asset instanceOfType:type withPath:path orContents:nil isInline:NO] inAssetsAtIndex:_assets.countOfAssets];
//				[self.assets addFolder:path matchingType:type];
			}];
		}
	}];
} // openEarthinizerDoc


//
//- (void) handlePosts
//{
//	[_http post:@"/xml" withBlock:^(RouteRequest *request, RouteResponse *response) {
//		NSData *bodyData = [request body];
//		NSString *xml = [[NSString alloc] initWithBytes:[bodyData bytes] length:[bodyData length] encoding:NSUTF8StringEncoding];
//
//		// Green?
//		NSRange tagRange = [xml rangeOfString:@"<greenLevel>"];
//		if (tagRange.location != NSNotFound) {
//			NSUInteger start = tagRange.location + tagRange.length;
//			NSUInteger end = [xml rangeOfString:@"<" options:0 range:NSMakeRange(start, [xml length] - start)].location;
//			if (end != NSNotFound) {
//				NSString *greenLevel = [xml substringWithRange:NSMakeRange(start, end - start)];
//				[response respondWithString:greenLevel];
//			}
//		}
//	}];
////	[_http post:@"/widgets" withBlock:^(REQ *req, RES *res) {	// Create a new widget, [request body] contains the POST body data. For this example we're just going to echo it back.
//		NSLog(@"POST: %@", req.body);
//		[res respondWithData:req.body];	}];
		
//		NSLog(@"POST: %@", req.body);
//		[res respondWithData:req.body];	}];
//		HTTPConnection* *con = [res connection];
//		[con respondWithFile:tmp async:YES];
//		NSLog(@"%@, %@, %@", req.body, req.headers, req);//req.connection  );
//		[res.connection processBodyDa]
//		NSData *d = [req body];
		
//		[d writeToFile:tmp atomically:YES];

//		[res.connection  BodyData:req.body];


		 // OK
//newu //] wit atomically:]

//	if([method isEqualToString:@"POST"] && [path isEqualToString:@"/upload.html"]) {
        // here we need to make sure, boundary is set in header
//        NSString* contentType = req.headers[@"Content-Type"];
//        int paramsSeparator = [contentType rangeOfString:@";"].location;
//        if( NSNotFound == paramsSeparator ) {
////            return NO;
//        }
//        if( paramsSeparator >= contentType.length - 1 ) {
////            return NO;
//        }
//        NSString* type = [contentType substringToIndex:paramsSeparator];
//        if( ![type isEqualToString:@"application/json"] ) { //![type isEqualToString:@"multipart/form-data"] ) {
//            // we expect multipart/form-data content type
////			return NO;
//        }
//		return YES;
//	}];
//}
//
/**		// enumerate all params in content-type, and find boundary there
        NSArray* params = [[contentType substringFromIndex:paramsSeparator + 1] componentsSeparatedByString:@";"];
        for( NSString* param in params ) {
            paramsSeparator = [param rangeOfString:@"="].location;
            if( (NSNotFound == paramsSeparator) || paramsSeparator >= param.length - 1 ) {
                continue;
            }
            NSString* paramName = [param substringWithRange:NSMakeRange(1, paramsSeparator-1)];
            NSString* paramValue = [param substringFromIndex:paramsSeparator+1];
            
            if( [paramName isEqualToString: @"boundary"] ) {
                // let's separate the boundary from content-type, to make it more handy to handle
                [request setHeaderField:@"boundary" value:paramValue];
            }
        }
        // check if boundary specified
        if( nil == [request headerField:@"boundary"] )  {
            return NO;
        }
        return YES;
    }
	return [super expectsRequestBodyFromMethod:method atPath:path];
}
*/
//- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
//{
//	HTTPLogTrace();
//
//	if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/upload.html"])
//	{

//		// this method will generate response with links to uploaded file
//		NSMutableString* filesStr = [[NSMutableString alloc] init];
//
//		for( NSString* filePath in uploadedFiles ) {
//			//generate links
//			[filesStr appendFormat:@"<a href=\"%@\"> %@ </a><br/>",filePath, [filePath lastPathComponent]];
//		}
//		NSString* templatePath = [[config documentRoot] stringByAppendingPathComponent:@"upload.html"];
//		NSDictionary* replacementDict = [NSDictionary dictionaryWithObject:filesStr forKey:@"MyFiles"];
		// use dynamic file response to apply our links to response template
//		return [[HTTPDynamicFileResponse alloc] initWithFilePath:templatePath forConnection:self separator:@"%" replacementDictionary:replacementDict];
//	}
//	if( [method isEqualToString:@"GET"] && [path hasPrefix:@"/upload/"] ) {
//		// let download the uploaded files
//		return [[HTTPFileResponse alloc] initWithFilePath: [[config documentRoot] stringByAppendingString:path] forConnection:self];
//	}
//
//	return [super httpResponseForMethod:method URI:path];
//}

//- (void)prepareForBodyWithSize:(UInt64)contentLength
//{
//	HTTPLogTrace();
//
//	// set up mime parser
//    NSString* boundary = [request headerField:@"boundary"];
//    parser = [[MultipartFormDataParser alloc] initWithBoundary:boundary formEncoding:NSUTF8StringEncoding];
//    parser.delegate = self;
//
//	uploadedFiles = [[NSMutableArray alloc] init];
//}
//
//- (void)processBodyData:(NSData *)postDataChunk
//{
//	HTTPLogTrace();
//    // append data to the parser. It will invoke callbacks to let us handle
//    // parsed data.
//    [parser appendData:postDataChunk];
//}
#pragma mark multipart form data parser delegate
//- (void) processStartOfPartWithHeader:(MultipartMessageHeader*) header {
//	// in this sample, we are not interested in parts, other then file parts.
//	// check content disposition to find out filename
//
//    MultipartMessageHeaderField* disposition = [header.fields objectForKey:@"Content-Disposition"];
//	NSString* filename = [[disposition.params objectForKey:@"filename"] lastPathComponent];
//
//    if ( (nil == filename) || [filename isEqualToString: @""] ) {
//        // it's either not a file part, or
//		// an empty form sent. we won't handle it.
//		return;
//	}    
//	NSString* uploadDirPath = [[config documentRoot] stringByAppendingPathComponent:@"upload"];
//
//	BOOL isDir = YES;
//	if (![[NSFileManager defaultManager]fileExistsAtPath:uploadDirPath isDirectory:&isDir ]) {
//		[[NSFileManager defaultManager]createDirectoryAtPath:uploadDirPath withIntermediateDirectories:YES attributes:nil error:nil];
//	}
//
//    NSString* filePath = [uploadDirPath stringByAppendingPathComponent: filename];
//    if( [[NSFileManager defaultManager] fileExistsAtPath:filePath] ) {
//        storeFile = nil;
//    }
//    else {
//		NSLog(@"Saving file to %@", filePath);
//
//		HTTPLogVerbose(@"Saving file to %@", filePath);
//		[[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];	
//		storeFile = [NSFileHandle fileHandleForWritingAtPath:filePath];
//		[uploadedFiles addObject: [NSString stringWithFormat:@"/upload/%@", filename]];
//    }
//}

//- (void) processContent:(NSData*) data WithHeader:(MultipartMessageHeader*) header 
//{
//	// here we just write the output from parser to the file.
//	if( storeFile ) {
//		[storeFile writeData:data];
//	}
//}
//
//- (void) processEndOfPartWithHeader:(MultipartMessageHeader*) header
//{
//	// as the file part is over, we close the file.
//	[storeFile closeFile];
//	storeFile = nil;
//}
//
//
//    //注意这里并不能直接改变progressView.progress的值 因为NSNotification也是运行在非主线程中的!
//- (void)handleUploadProgressNotification:(NSNotification *) notification
//{
//    NSNumber *uploadProgress = (NSNumber *)[notification object];
////    [self performSelectorOnMainThread:@selector(changeProgressViewValue:) withObject:uploadProgress waitUntilDone:NO];
//}

@end


@implementation Shortcut
- (id) initWithURI:(NSS*)uri syntax:(NSS*)syntax	{	if (self != super.init ) return nil; _syntax = syntax; _uri = uri; return self; }
@end
