//
//  AssetCollection.m
//  RoutingHTTPServer
//
//  Created by Alex Gray on 05/03/2013.
//
//

#import "AssetCollection.h"

//NSString* assetType(AssetType enumVal)
//{
//	static NSArray * assetTypes = nil;
//	return assetTypes ?: [NSArray.alloc initWithObjects:AssetTypeArray][enumVal];
//}



// To convert enum to string:	NSString *str = FormatType_toString[theEnumValue];
NSString * const assetStringValue[] = {  @"js",@"css",@"html",@"php",@"sh",@"m",@"txt",@"n/a" };

@implementation NSString (AssetType)
- (AssetType)assetFromString
{
	static NSD *types = nil;		if (!types) types =	@{	@"js" : @(JS), 		@"html"	: @(HTML), 	@"css"	: @(CSS),	@"php" : @(PHP), 	@"sh" : @(BASH),		@"m"  	: @(ObjC),	@"txt"	: @(TXT),	@"n/a" :@(UNKNOWN) };
    return (AssetType)[types[self] intValue];
}
@end


@implementation Asset

+ (instancetype) instanceOfType:(AssetType)type withPath:(NSS*)path orContents:(NSS*)contents isInline:(BOOL)isit;
{
	Asset *n 	= Asset.instance;
	n.assetType	= type != NSNotFound ? type : UNKNOWN ;
	n.path 		= path;
	n.isInline 	= path == nil || isit ?: NO;
	n.contents 	= contents;
	return n;
}
@end

@implementation AssetCollection
- (void) awakeFromNib { _folders = NSMA.new; _assets = NSMA.new; _content = _assets; }
- (void) addFolder: (NSS*)path matchingType:(AssetType)fileType
{
	[_folders addObject:path];
	[_assets addObjectsFromArray:[NSFileManager pathsForItemsInFolder:path withExtension: assetStringValue[fileType]]];
	NSLog(@"folders: %@   assets:%@", _folders, _assets);
}

@end
