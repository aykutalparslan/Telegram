#import "TGGenericPeerMediaGalleryImageItem.h"

#import <LegacyComponents/LegacyComponents.h>

#import <LegacyComponents/TGRemoteImageView.h>
#import <LegacyComponents/TGImageMediaAttachment.h>

#import "TGAppDelegate.h"

@interface TGGenericPeerMediaGalleryImageItem ()
{
    TGImageInfo *_legacyImageInfo;
    TGImageMediaAttachment *_media;
}

@end

@implementation TGGenericPeerMediaGalleryImageItem

- (instancetype)initWithImageId:(int64_t)imageId accessHash:(int64_t)accessHash orLocalId:(int64_t)localId peerId:(int64_t)peerId messageId:(int32_t)messageId legacyImageInfo:(TGImageInfo *)legacyImageInfo embeddedStickerDocuments:(NSArray *)embeddedStickerDocuments hasStickers:(bool)hasStickers originInfo:(TGMediaOriginInfo *)originInfo
{
    CGSize imageSize = CGSizeZero;
    NSString *legacyCacheUrl = [legacyImageInfo closestImageUrlWithSize:CGSizeMake(1000.0f, 1000.0f) resultingSize:&imageSize];
    NSString *legacyThumbnailCacheUrl = [legacyImageInfo closestImageUrlWithSize:CGSizeZero resultingSize:NULL];
    
    NSString *legacyFilePath = nil;
    if ([legacyCacheUrl hasPrefix:@"file://"])
        legacyFilePath = [legacyCacheUrl substringFromIndex:@"file://".length];
    else
        legacyFilePath = [[TGRemoteImageView sharedCache] pathForCachedData:legacyCacheUrl];
    
    NSMutableString *imageUri = [[NSMutableString alloc] init];
    [imageUri appendString:@"media-gallery-image://?"];
    if (imageId != 0)
        [imageUri appendFormat:@"&id=%" PRId64 "", imageId];
    else if (localId != 0)
        [imageUri appendFormat:@"&local-id=%" PRId64 "", localId];
    [imageUri appendFormat:@"&legacy-file-path=%@", legacyFilePath];
    
    NSString *escapedLegacyThumbnailCacheUrl = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)legacyThumbnailCacheUrl, (__bridge CFStringRef)@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-", (__bridge CFStringRef)@"&?= ", kCFStringEncodingUTF8);
    [imageUri appendFormat:@"&legacy-thumbnail-cache-url=%@", escapedLegacyThumbnailCacheUrl];
    
    [imageUri appendFormat:@"&width=%d", (int)imageSize.width];
    [imageUri appendFormat:@"&height=%d", (int)imageSize.height];
    [imageUri appendFormat:@"&renderWidth=%d", (int)imageSize.width];
    [imageUri appendFormat:@"&renderHeight=%d", (int)imageSize.height];
    
    [imageUri appendFormat:@"&messageId=%" PRId32 "", (int32_t)messageId];
    [imageUri appendFormat:@"&conversationId=%" PRId64 "", (int64_t)peerId];
    
    if (originInfo != nil)
        [imageUri appendFormat:@"&origin_info=%@", [originInfo stringRepresentation]];
    
    NSString *escapedCacheUrl = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)legacyCacheUrl, (__bridge CFStringRef)@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-", (__bridge CFStringRef)@"&?= :/+", kCFStringEncodingUTF8);
    [imageUri appendFormat:@"&legacy-cache-url=%@", escapedCacheUrl];
    
    self = [super initWithUri:imageUri imageSize:imageSize];
    if (self != nil)
    {
        self.imageId = imageId;
        self.accessHash = accessHash;
        _legacyImageInfo = legacyImageInfo;
        _messageId = messageId;
        _peerId = peerId;
        self.embeddedStickerDocuments = embeddedStickerDocuments;
        self.hasStickers = hasStickers;
        self.originInfo = originInfo;
    }
    return self;
}

- (instancetype)initWithMedia:(TGImageMediaAttachment *)media localId:(int64_t)localId peerId:(int64_t)peerId messageId:(int32_t)messageId
{
    self = [self initWithImageId:media.imageId accessHash:media.accessHash orLocalId:localId peerId:peerId messageId:messageId legacyImageInfo:media.imageInfo embeddedStickerDocuments:media.embeddedStickerDocuments hasStickers:media.hasStickers originInfo:media.originInfo];
    if (self != nil)
    {
        _media = media;
    }
    return self;
}

- (NSArray *)textCheckingResults
{
    if (_textCheckingResults != nil)
        return _textCheckingResults;
    
    _textCheckingResults = [TGMessage textCheckingResultsForText:_caption highlightMentionsAndTags:true highlightCommands:false entities:_entities];
    return _textCheckingResults;
}

- (id)media
{
    return _media;
}

- (BOOL)isEqual:(id)object
{
    if (![super isEqual:object])
        return false;
    
    if ([object isKindOfClass:[TGGenericPeerMediaGalleryImageItem class]])
    {
        return TGObjectCompare(_authorPeer, ((TGGenericPeerMediaGalleryImageItem *)object).authorPeer) && ABS(_date - ((TGGenericPeerMediaGalleryImageItem *)object).date) < DBL_EPSILON && _messageId == ((TGGenericPeerMediaGalleryImageItem *)object).messageId;
    }
    
    return false;
}

- (NSString *)filePathForRemoteImageId:(int64_t)remoteImageId
{
    static NSString *filesDirectory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        filesDirectory = [[TGAppDelegate documentsPath] stringByAppendingPathComponent:@"files"];
    });
    
    NSString *photoDirectoryName = [[NSString alloc] initWithFormat:@"image-remote-%" PRIx64 "", remoteImageId];
    NSString *photoDirectory = [filesDirectory stringByAppendingPathComponent:photoDirectoryName];
    
    NSString *imagePath = [photoDirectory stringByAppendingPathComponent:@"image.jpg"];
    return imagePath;
}

- (NSString *)filePath
{
    NSString *localPath = [self filePathForRemoteImageId:self.imageId];
    if ([[NSFileManager defaultManager] fileExistsAtPath:localPath])
        return localPath;
    
    NSString *legacyCacheUrl = [_legacyImageInfo closestImageUrlWithSize:CGSizeMake(1000.0f, 1000.0f) resultingSize:NULL];
    
    NSString *legacyFilePath = nil;
    if ([legacyCacheUrl hasPrefix:@"file://"])
        legacyFilePath = [legacyCacheUrl substringFromIndex:@"file://".length];
    else
        legacyFilePath = [[TGRemoteImageView sharedCache] pathForCachedData:legacyCacheUrl];
    
    return legacyFilePath;
}

@end
