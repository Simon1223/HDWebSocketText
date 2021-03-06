//
//  LFPhotoEditManager.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/23.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoEditManager.h"
#import "LFImagePickerHeader.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "LFPhotoEdit.h"
#import "LFAsset.h"
#import "UIImage+LF_ImageCompress.h"
#import "UIImage+LFCommon.h"

@interface LFPhotoEditManager ()

@property (nonatomic, strong) NSMutableDictionary *photoEditDict;
@end

@implementation LFPhotoEditManager

static LFPhotoEditManager *manager;
+ (instancetype)manager {
    if (manager == nil) {
        manager = [[self alloc] init];
        manager.photoEditDict = [@{} mutableCopy];
    }
    return manager;
}

+ (void)free
{
    [manager.photoEditDict removeAllObjects];
    manager = nil;
}

- (void)setPhotoEdit:(LFPhotoEdit *)obj forAsset:(LFAsset *)asset
{
    __weak typeof(self) weakSelf = self;
    if (asset.asset) {
        if (asset.name.length) {
            if (obj) {
                [weakSelf.photoEditDict setObject:obj forKey:asset.name];
            } else {
                [weakSelf.photoEditDict removeObjectForKey:asset.name];
            }
        } else {
            [self requestForAsset:asset.asset complete:^(NSString *name) {
                if (name.length) {
                    if (obj) {
                        [weakSelf.photoEditDict setObject:obj forKey:name];
                    } else {
                        [weakSelf.photoEditDict removeObjectForKey:name];
                    }
                }
            }];
        }
    } else if (asset.previewImage) {
        NSString *name = [NSString stringWithFormat:@"%zd", [asset.previewImage hash]];
        if (obj) {
            [weakSelf.photoEditDict setObject:obj forKey:name];
        } else {
            [weakSelf.photoEditDict removeObjectForKey:name];
        }
    }
}

- (LFPhotoEdit *)photoEditForAsset:(LFAsset *)asset
{
    __weak typeof(self) weakSelf = self;
    __block LFPhotoEdit *photoEdit = nil;
    if (asset.asset) {
        if (asset.name.length) {
            photoEdit = [weakSelf.photoEditDict objectForKey:asset.name];
        } else {
            [self requestForAsset:asset.asset complete:^(NSString *name) {
                if (name.length) {
                    photoEdit = [weakSelf.photoEditDict objectForKey:name];
                }
            }];
        }
    } else if (asset.previewImage) {
        NSString *name = [NSString stringWithFormat:@"%zd", [asset.previewImage hash]];
        photoEdit = [weakSelf.photoEditDict objectForKey:name];
    }
    return photoEdit;
}

- (void)requestForAsset:(id)asset complete:(void (^)(NSString *name))complete
{
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = (PHAsset *)asset;
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        option.synchronous = YES; /** 同步 */
        [[PHImageManager defaultManager] requestImageDataForAsset:phAsset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            
            NSURL *fileUrl = [info objectForKey:@"PHImageFileURLKey"];
            if (complete) complete(fileUrl.lastPathComponent);
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
        NSString *fileName = assetRep.filename;
        if (complete) complete(fileName);
    }
}

/**
 通过asset解析缩略图、标清图/原图、图片数据字典
 
 @param asset PHAsset／ALAsset
 @param isOriginal 是否原图
 @param completion 返回block 顺序：缩略图、标清图、图片数据字典
 */
- (void)getPhotoWithAsset:(id)asset
               isOriginal:(BOOL)isOriginal
               completion:(void (^)(UIImage *thumbnail, UIImage *source, NSDictionary *info))completion
{
    [self getPhotoWithAsset:asset isOriginal:isOriginal compressSize:kCompressSize thumbnailCompressSize:kThumbnailCompressSize completion:completion];
}

/**
 通过asset解析缩略图、标清图/原图、图片数据字典
 
 @param asset PHAsset／ALAsset
 @param isOriginal 是否原图
 @param compressSize 非原图的压缩大小
 @param thumbnailCompressSize 缩略图压缩大小
 @param completion 返回block 顺序：缩略图、标清图、图片数据字典
 */
- (void)getPhotoWithAsset:(id)asset
               isOriginal:(BOOL)isOriginal
             compressSize:(CGFloat)compressSize
    thumbnailCompressSize:(CGFloat)thumbnailCompressSize
               completion:(void (^)(UIImage *thumbnail, UIImage *source, NSDictionary *info))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *thumbnail = nil;
        UIImage *source = nil;
        NSMutableDictionary *imageInfo = [NSMutableDictionary dictionary];
        
        __weak typeof(self) weakSelf = self;
        __block LFPhotoEdit *photoEdit = nil;
        [self requestForAsset:asset complete:^(NSString *name) {
            if (name.length) {
                photoEdit = [weakSelf.photoEditDict objectForKey:name];
                /** 图片文件名 */
                [imageInfo setObject:name forKey:kImageInfoFileName];
            }
        }];
        
        /** 标清图/原图 */
        source = photoEdit.editPreviewImage;
        /** 图片数据 */
        NSData *imageData = nil;
        if (!isOriginal) { /** 标清图 */
            imageData = [source fastestCompressImageDataWithSize:(compressSize <=0 ? kCompressSize : compressSize)];
            source = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
        } else {
            imageData = UIImageJPEGRepresentation(source, 0.75);
        }
        [imageInfo setObject:imageData forKey:kImageInfoFileOriginalData];
        /** 图片大小 */
        [imageInfo setObject:@(imageData.length) forKey:kImageInfoFileByte];
        /** 图片宽高 */
        CGSize imageSize = source.size;
        NSValue *value = [NSValue valueWithBytes:&imageSize objCType:@encode(CGSize)];
        [imageInfo setObject:value forKey:kImageInfoFileSize];
        
        /** 缩略图 */
        CGFloat aspectRatio = imageSize.width / (CGFloat)imageSize.height;
        CGFloat th_pixelWidth = 80 * 2.0; // scale
        CGFloat th_pixelHeight = th_pixelWidth / aspectRatio;
        thumbnail = [source scaleToSize:CGSizeMake(th_pixelWidth, th_pixelHeight)];
        NSData *thumbnailData = [thumbnail fastestCompressImageDataWithSize:(thumbnailCompressSize <=0 ? kThumbnailCompressSize : thumbnailCompressSize)];
        [imageInfo setObject:thumbnailData forKey:kImageInfoFileThumbnailData];
        thumbnail = [UIImage imageWithData:thumbnailData scale:[UIScreen mainScreen].scale];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(thumbnail, source, imageInfo);
        });
    });
}
@end
