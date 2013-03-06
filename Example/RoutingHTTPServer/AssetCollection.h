//
//  AssetCollection.h
//  RoutingHTTPServer
//
//  Created by Alex Gray on 05/03/2013.
//
//

#import <Cocoa/Cocoa.h>


typedef NS_ENUM(NSUI, AssetType){
	JS,				CSS,
	HTML,			PHP,
	BASH,			ObjC,
	TXT,			UNKNOWN = 99
};

NSString * const assetStringValue[];
@interface NSString (AssetType)
- (AssetType)assetFromString;
@end

@interface Asset : BaseModel

@property (strong, nonatomic) NSS *path, *contents;
@property (assign, nonatomic) NSUI placeNumber;
@property (assign, nonatomic) BOOL isInline, isActive;
@property (assign, nonatomic) AssetType assetType;
+ (instancetype) instanceOfType:(AssetType)type withPath:(NSS*)path orContents:(NSS*)contents isInline:(BOOL)isit;
@end

@interface AssetCollection : NSArrayController
@property (nonatomic, strong) NSMutableArray *folders, *assets;
- (void) addFolder: (NSS*)path matchingType:(AssetType)fileType;
@end
