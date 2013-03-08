
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "DDNumber.h"
#import "HTTPLogging.h"

#import "MultipartFormDataParser.h"
#import "MultipartMessageHeaderField.h"
#import "HTTPDynamicFileResponse.h"
#import "HTTPFileResponse.h"
///MULTIPART ABOVE



#import "RoutingConnection.h"
#import "RoutingHTTPServer.h"
#import "HTTPMessage.h"
#import "HTTPResponseProxy.h"

@implementation RoutingConnection {
	__weak RoutingHTTPServer *http;
	NSDictionary *headers;
}

- (id)initWithAsyncSocket:(GCDAsyncSocket *)newSocket configuration:(HTTPConfig *)aConfig {
	if (self = [super initWithAsyncSocket:newSocket configuration:aConfig]) {
		NSAssert([config.server isKindOfClass:[RoutingHTTPServer class]],
				 @"A RoutingConnection is being used with a server that is not a RoutingHTTPServer");

		http = (RoutingHTTPServer *)config.server;
	}
	return self;
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path {

	if ([http supportsMethod:method])
		return YES;

	return [super supportsMethod:method atPath:path];
}

- (BOOL)shouldHandleRequestForMethod:(NSString *)method atPath:(NSString *)path {
	// The default implementation is strict about the use of Content-Length. Either
	// a given method + path combination must *always* include data or *never*
	// include data. The routing connection is lenient, a POST that sometimes does
	// not include data or a GET that sometimes does is fine. It is up to the route
	// implementations to decide how to handle these situations.
	return YES;
}

/*
- (void)processBodyData:(NSData *)postDataChunk {
	BOOL result = [request appendData:postDataChunk];
	if (!result) {
		// TODO: Log
	}
}
*/
- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
	NSURL *url = [request url];
	NSString *query = nil;
	NSDictionary *params = [NSDictionary dictionary];
	headers = nil;

	if (url) {
		path = [url path]; // Strip the query string from the path
		query = [url query];
		if (query) {
			params = [self parseParams:query];
		}
	}

	RouteResponse *response = [http routeMethod:method withPath:path parameters:params request:request connection:self];
	if (response != nil) {
		headers = response.headers;
		return response.proxiedResponse;
	}

	// Set a MIME type for static files if possible
	NSObject<HTTPResponse> *staticResponse = [super httpResponseForMethod:method URI:path];
	if (staticResponse && [staticResponse respondsToSelector:@selector(filePath)]) {
		NSString *mimeType = [http mimeTypeForPath:[staticResponse performSelector:@selector(filePath)]];
		if (mimeType) {
			headers = [NSDictionary dictionaryWithObject:mimeType forKey:@"Content-Type"];
		}
	}
	return staticResponse;
}

- (void)responseHasAvailableData:(NSObject<HTTPResponse> *)sender {
	HTTPResponseProxy *proxy = (HTTPResponseProxy *)httpResponse;
	if (proxy.response == sender) {
		[super responseHasAvailableData:httpResponse];
	}
}

- (void)responseDidAbort:(NSObject<HTTPResponse> *)sender {
	HTTPResponseProxy *proxy = (HTTPResponseProxy *)httpResponse;
	if (proxy.response == sender) {
		[super responseDidAbort:httpResponse];
	}
}

- (void)setHeadersForResponse:(HTTPMessage *)response isError:(BOOL)isError {
	[http.defaultHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
		[response setHeaderField:field value:value];
	}];

	if (headers && !isError) {
		[headers enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
			[response setHeaderField:field value:value];
		}];
	}

	// Set the connection header if not already specified
	NSString *connection = [response headerField:@"Connection"];
	if (!connection) {
		connection = [self shouldDie] ? @"close" : @"keep-alive";
		[response setHeaderField:@"Connection" value:connection];
	}
}

- (NSData *)preprocessResponse:(HTTPMessage *)response {
	[self setHeadersForResponse:response isError:NO];
	return [super preprocessResponse:response];
}

- (NSData *)preprocessErrorResponse:(HTTPMessage *)response {
	[self setHeadersForResponse:response isError:YES];
	return [super preprocessErrorResponse:response];
}

- (BOOL)shouldDie {
	__block BOOL shouldDie = [super shouldDie];

	// Allow custom headers to determine if the connection should be closed
	if (!shouldDie && headers) {
		[headers enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL *stop) {
			if ([field caseInsensitiveCompare:@"connection"] == NSOrderedSame) {
				if ([value caseInsensitiveCompare:@"close"] == NSOrderedSame) {
					shouldDie = YES;
				}
				*stop = YES;
			}
		}];
	}

	return shouldDie;
}


/**
    //扩展HTTPServer支持的请求类型，默认支持GET，HEAD，不支持POST
- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)relativePath
{
	if ([@"POST" isEqualToString:method])
	{
		return YES;
	}
	return [super supportsMethod:method atPath:relativePath];
}

    //处量返回的response数据
- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    return [super httpResponseForMethod:method URI:path];
}

   
    //处理POST请求提交的数据流(下面方法是改自 Andrew Davidson的类)
- (void)processDataChunk:(NSData *)postDataChunk
{
    NSLog(@"processDataChunk function called");
        //multipartData初始化不放在init函数中, 当前类似乎不经init函数初始化
    if (multipartData == nil) {
        multipartData = [[NSMutableArray alloc] init];
    }
    
        //处理multipart/form-data的POST请求中Body数据集中的表单值域并创建文件
	if (!postHeaderOK)
	{
            //0x0A0D: 换行符
		UInt16 separatorBytes = 0x0A0D;
		NSData* separatorData = [NSData dataWithBytes:&separatorBytes length:2];
		
		int l = [separatorData length];
		for (int i = 0; i < [postDataChunk length] - l; i++)
		{
                //每次取两个字节 比对下看看是否是换行
			NSRange searchRange = {i, l};
                //如果是换行符则进行如下处理
			if ([[postDataChunk subdataWithRange:searchRange] isEqualToData:separatorData])
			{
                    //获取dataStartIndex标识的上一个换行位置到当前换行符之间的数据的Range
				NSRange newDataRange = {dataStartIndex, i - dataStartIndex};                
                    //dataStartIndex标识的上一个换行位置到移到当前换行符位置 
				dataStartIndex = i + l;
				i += l - 1;
                    //获取dataStartIndex标识的上一个换行位置到当前换行符之间的数据
				NSData *newData = [postDataChunk subdataWithRange:newDataRange];
                    //如果newData不为空或还没有处理完multipart/form-data中表单变量值域则继续处理剩下的表单值域数据
				if ([newData length] || ![self isBeginOfOctetStream])
				{
                    if ([newData length]) {
                        [multipartData addObject:newData];
                    }
				}
				else
				{
                        //将标识处理完multipart/form-data中表单变量值域的postHeaderOK变量设置为TRUE;
					postHeaderOK = TRUE;
                        //这里暂时写成硬编码 弊端:每次增加表单变量都要改这里的数值
                        //获取Content-Disposition: form-data; name="xxx"; filename="xxx"
					NSString* postInfo = [[NSString alloc] initWithBytes:[[multipartData objectAtIndex:4] bytes] 
                                                                  length:[[multipartData objectAtIndex:4] length] 
                                                                encoding:NSUTF8StringEncoding];
                    NSLog(@"postInfo is:%@", postInfo);
					NSArray* postInfoComponents = [postInfo componentsSeparatedByString:@"; filename="];
					postInfoComponents = [[postInfoComponents lastObject] componentsSeparatedByString:@"\""];
                    NSLog(@"postInfoComponents0 :%@",postInfoComponents);
                    if ([postInfoComponents count]<2) 
                    {
                        return;
                    }
                    
					postInfoComponents = [[postInfoComponents objectAtIndex:1] componentsSeparatedByString:@"\\"];
                    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
					NSString* filename = [documentPath stringByAppendingPathComponent:[postInfoComponents lastObject]];
                    NSLog(@"filename :%@",filename);
					NSRange fileDataRange = {dataStartIndex, [postDataChunk length] - dataStartIndex};
					[[NSFileManager defaultManager] createFileAtPath:filename contents:[postDataChunk subdataWithRange:fileDataRange] attributes:nil];
					NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:filename];// retain];
					if (file)
					{
						[file seekToEndOfFile];
						[multipartData addObject:file];
					}
					
//					[postInfo release];
					break;
				}
			}
		}
	}
	else //表单值域已经处理过了 这之后的数据全是文件数据流
	{
		[(NSFileHandle*)[multipartData lastObject] writeData:postDataChunk];
	}
    
    float uploadProgress = (double)requestContentLengthReceived / requestContentLength;
		//实际应用时 当前类的实例是相当于单例一样被引用(因为只被实例化一次)
	if (uploadProgress >= 1.0) {
		postHeaderOK = NO;
//		[multipartData release];
		multipartData = nil;
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:UPLOAD_FILE_PROGRESS object:[NSNumber numberWithFloat:uploadProgress] userInfo:nil];
}


//检查是否已经处理完了multipart/form-data表单中的表单变量
- (BOOL) isBeginOfOctetStream
{
    NSString *octetStreamFlag = @"Content-Type: application/octet-stream";
    NSString *findData = [[NSString alloc] initWithData:(NSData *)[multipartData lastObject] encoding:NSUTF8StringEncoding];
    
    for (NSData *d in multipartData) {
        NSString *temp = [NSString.alloc initWithData:d encoding:NSUTF8StringEncoding];// autorelease] ;
        NSLog(@"multipartData items: %@", temp);
    }
        //如果已经处理完了multipart/form-data表单中的表单变量
    if ( findData != nil && [findData length] > 0 ) 
    {
        NSLog(@"findData is :%@\n octetStreamFlag is :%@", findData, octetStreamFlag);
        if ([octetStreamFlag isEqualToString:findData]) {
            NSLog(@"multipart/form-data 变量值域数据处理完毕");
//            [findData release];
            return YES;
        }
//        [findData release];
        return NO;
    }
    return NO;
}



*/
// Log levels : off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_VERBOSE; // | HTTP_LOG_FLAG_TRACE;


/**
 * All we have to do is override appropriate methods in HTTPConnection.
 **/

//@implementation MyHTTPConnection

//- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
//{
//	HTTPLogTrace();
//	
//	// Add support for POST
//
//	if ([method isEqualToString:@"POST"])
//	{
//		if ([path isEqualToString:@"/upload.html"])
//		{
//			return YES;
//		}
//	}
//	
//	return [super supportsMethod:method atPath:path];
//}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
	HTTPLogTrace();
	
	// Inform HTTP server that we expect a body to accompany a POST request
	
	if([method isEqualToString:@"POST"] && [path isEqualToString:@"/upload.html"]) {
        // here we need to make sure, boundary is set in header
        NSString* contentType = [request headerField:@"Content-Type"];
		NSLog(@"%@, %@, %@", request.body, request.allHeaderFields, request);//req.connection  );

        int paramsSeparator = [contentType rangeOfString:@";"].location;
        if( NSNotFound == paramsSeparator ) {
            return NO;
        }
        if( paramsSeparator >= contentType.length - 1 ) {
            return NO;
        }
        NSString* type = [contentType substringToIndex:paramsSeparator];
        if( ![type isEqualToString:@"multipart/form-data"] ) {
            // we expect multipart/form-data content type
            return NO;
        }

		// enumerate all params in content-type, and find boundary there
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
/*
- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
	HTTPLogTrace();
	
	if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/upload.html"])
	{

		// this method will generate response with links to uploaded file
		NSMutableString* filesStr = [[NSMutableString alloc] init];

		for( NSString* filePath in uploadedFiles ) {
			//generate links
			[filesStr appendFormat:@"<a href=\"%@\"> %@ </a><br/>",filePath, [filePath lastPathComponent]];
		}
		NSString* templatePath = [[config documentRoot] stringByAppendingPathComponent:@"upload.html"];
		NSDictionary* replacementDict = [NSDictionary dictionaryWithObject:filesStr forKey:@"MyFiles"];
		// use dynamic file response to apply our links to response template
		return [[HTTPDynamicFileResponse alloc] initWithFilePath:templatePath forConnection:self separator:@"%" replacementDictionary:replacementDict];
	}
	if( [method isEqualToString:@"GET"] && [path hasPrefix:@"/upload/"] ) {
		// let download the uploaded files
		return [[HTTPFileResponse alloc] initWithFilePath: [[config documentRoot] stringByAppendingString:path] forConnection:self];
	}
	
	return [super httpResponseForMethod:method URI:path];
}
*/
- (void)prepareForBodyWithSize:(UInt64)contentLength
{
	HTTPLogTrace();
	
	// set up mime parser
    NSString* boundary = [request headerField:@"boundary"];
    parser = [[MultipartFormDataParser alloc] initWithBoundary:boundary formEncoding:NSUTF8StringEncoding];
    parser.delegate = self;

	uploadedFiles = [[NSMutableArray alloc] init];
}


- (void)processBodyData:(NSData *)postDataChunk
{
	HTTPLogTrace();
    // append data to the parser. It will invoke callbacks to let us handle
    // parsed data.
    [parser appendData:postDataChunk];
}


//-----------------------------------------------------------------
#pragma mark multipart form data parser delegate


- (void) processStartOfPartWithHeader:(MultipartMessageHeader*) header {
	// in this sample, we are not interested in parts, other then file parts.
	// check content disposition to find out filename

    MultipartMessageHeaderField* disposition = [header.fields objectForKey:@"Content-Disposition"];
	NSString* filename = [[disposition.params objectForKey:@"filename"] lastPathComponent];

    if ( (nil == filename) || [filename isEqualToString: @""] ) {
        // it's either not a file part, or
		// an empty form sent. we won't handle it.
		return;
	}    
	NSString* uploadDirPath = [NSTemporaryDirectory() withPath:NSS.UUIDString];
	//[[config documentRoot] stringByAppendingPathComponent:@"upload"];


	BOOL isDir = YES;
	if (![[NSFileManager defaultManager]fileExistsAtPath:uploadDirPath isDirectory:&isDir ]) {
		[[NSFileManager defaultManager]createDirectoryAtPath:uploadDirPath withIntermediateDirectories:YES attributes:nil error:nil];
	}
	
    NSString* filePath = [uploadDirPath stringByAppendingPathComponent: filename];
    if( [[NSFileManager defaultManager] fileExistsAtPath:filePath] ) {
        storeFile = nil;
    }
    else {
		HTTPLogVerbose(@"Saving file to %@", filePath);
		[[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];	
		storeFile = [NSFileHandle fileHandleForWritingAtPath:filePath];
		[uploadedFiles addObject: [NSString stringWithFormat:@"/upload/%@", filename]];
    }
}


- (void) processContent:(NSData*) data WithHeader:(MultipartMessageHeader*) header 
{
	// here we just write the output from parser to the file.
	if( storeFile ) {
		[storeFile writeData:data];
	}
}

- (void) processEndOfPartWithHeader:(MultipartMessageHeader*) header
{
	// as the file part is over, we close the file.
	[storeFile closeFile];
	storeFile = nil;
}

@end
