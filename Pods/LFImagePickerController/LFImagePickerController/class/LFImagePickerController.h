//
//  LFImagePickerController.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFLayoutPickerController.h"
#import "LFImagePickerPublicHeader.h"


@class LFAsset;
@protocol LFImagePickerControllerDelegate;
@interface LFImagePickerController : LFLayoutPickerController

/// Use this init method / 用这个初始化方法
- (instancetype)initWithMaxImagesCount:(NSInteger)maxImagesCount delegate:(id<LFImagePickerControllerDelegate>)delegate;
- (instancetype)initWithMaxImagesCount:(NSInteger)maxImagesCount columnNumber:(NSInteger)columnNumber delegate:(id<LFImagePickerControllerDelegate>)delegate;
- (instancetype)initWithMaxImagesCount:(NSInteger)maxImagesCount columnNumber:(NSInteger)columnNumber delegate:(id<LFImagePickerControllerDelegate>)delegate pushPhotoPickerVc:(BOOL)pushPhotoPickerVc;
/// This init method just for previewing photos,pickerDelegate = self; / 用这个初始化方法以预览图片,pickerDelegate = self;
- (instancetype)initWithSelectedAssets:(NSArray /**<PHAsset/ALAsset *>*/*)selectedAssets index:(NSInteger)index excludeVideo:(BOOL)excludeVideo;
/// This init method just for previewing photos, complete block call back  (invalid delegate)/ 用这个初始化方法以预览图片 complete => 完成后返回全新数组 （代理无效）
- (instancetype)initWithSelectedPhotos:(NSArray <UIImage *>*)selectedPhotos index:(NSInteger)index complete:(void (^)(NSArray <UIImage *>* photos))complete;

/** 预览模式 */
@property (nonatomic, readonly) BOOL isPreview;

/** 每行的数量 */
@property (nonatomic, readonly) NSInteger columnNumber;

/// Default is 9 / 默认最大可选9张图片
@property (nonatomic, assign) NSInteger maxImagesCount;

/// The minimum count photos user must pick, Default is 0
/// 最小照片必选张数,默认是0
@property (nonatomic, assign) NSInteger minImagesCount;

/// Sort photos ascending by creationDate，Default is YES
/// 对照片排序，按创建时间升序，默认是YES。如果设置为NO,最新的照片会显示在最前面，内部的拍照按钮会排在第一个
@property (nonatomic, assign) BOOL sortAscendingByCreateDate;

/// Default is YES, if set NO, the original photo button will hide. user can't picking original photo.
/// 默认为YES，如果设置为NO,原图按钮将隐藏，用户不能选择发送原图
@property (nonatomic, assign) BOOL allowPickingOriginalPhoto;

/// Default is YES, if set NO, user can't picking video.
/// 默认为YES，如果设置为NO,用户将不能选择视频
@property (nonatomic, assign) BOOL allowPickingVideo;

/// Default is YES, if set NO, user can't picking image.
/// 默认为YES，如果设置为NO,用户将不能选择发送图片
@property(nonatomic, assign) BOOL allowPickingImage;

/// Default is NO, if set YES, user can picking gif.(support compress，CompressSize parameter is ignored)
/// 默认为NO，如果设置为YES,用户可以选择gif图片(支持压缩，忽略压缩参数)
@property (nonatomic, assign) BOOL allowPickingGif;

/// Default is NO, if set YES, user can picking live photo.(support compress，CompressSize parameter is ignored)
/// 默认为NO，如果设置为YES,用户可以选择live photo(支持压缩，忽略压缩参数)
@property (nonatomic, assign) BOOL allowPickingLivePhoto;

/// Default is YES, if set NO, take picture will be hidden.
/// 默认为YES，如果设置为NO,拍照按钮将隐藏
@property(nonatomic, assign) BOOL allowTakePicture;

/// Default is YES, if set NO, user can't preview photo.
/// 默认为YES，如果设置为NO,预览按钮将隐藏,用户将不能去预览照片
@property (nonatomic, assign) BOOL allowPreview;

/// Default is YES, if set NO, user can't editting photo.
/// 默认为YES，如果设置为NO,编辑按钮将隐藏,用户将不能去编辑照片
@property (nonatomic, assign) BOOL allowEditting;

/// Default is YES, if set NO, the picker don't dismiss itself.
/// 默认为YES，如果设置为NO, 选择器将不会自己dismiss
@property(nonatomic, assign) BOOL autoDismiss;

/// Default is NO, if set YES, the picker support interface orientation.
/// 默认为NO，如果设置为YES, 选择器将会适配横屏
@property(nonatomic, assign) BOOL supportAutorotate;

/// Limit video size, Default is 10*1024 in KB
/// 限制视频大小发送，默认10MB（10*1024）单位KB
@property (nonatomic, assign) float maxVideoSize;

/// Compressed image size (allowPickingOriginalPhoto=YES, Invalid), Default is 100 in KB
/// 压缩标清图的大小（没有勾选原图的情况有效），默认为100 单位KB （只能压缩到接近该值的大小）
@property(nonatomic, assign) float imageCompressSize;

/// Compressed thumbnail image size, Default is 10 in KB
/// 压缩缩略图的大小，默认为10 单位KB
@property(nonatomic, assign) float thumbnailCompressSize;

/// Default is YES, if set NO，The edited photo is not saved to the photo album
/// 默认为YES，如果设置为NO，编辑后的图片不会保存到系统相册
@property(nonatomic, assign) BOOL autoSavePhotoAlbum;

/// The photos user have selected
/// 用户选中过的图片数组
@property (nonatomic, readonly) NSMutableArray<LFAsset *> *selectedModels;
@property (nonatomic, setter=setSelectedAssets:) NSArray /**<PHAsset/ALAsset/UIImage *>*/*selectedAssets;
/** 是否选择原图 */
@property (nonatomic, assign) BOOL isSelectOriginalPhoto;

/// Public Method
//- (void)cancelButtonClick;

/** block回调，具体使用见LFImagePickerControllerDelegate代理描述 */
@property (nonatomic, copy) void (^imagePickerControllerTakePhoto)();
@property (nonatomic, copy) void (^imagePickerControllerDidCancelHandle)();
/** 图片 */
@property (nonatomic, copy) void (^didFinishPickingPhotosHandle)(NSArray *assets);
@property (nonatomic, copy) void (^didFinishPickingPhotosWithInfosHandle)(NSArray *assets,NSArray<NSDictionary *> *infos);
@property (nonatomic, copy) void (^didFinishPickingImagesHandle)(NSArray<UIImage *> *thumbnailImages,NSArray<UIImage *> *originalImages);
@property (nonatomic, copy) void (^didFinishPickingImagesWithInfosHandle)(NSArray<UIImage *> *thumbnailImages,NSArray<UIImage *> *originalImages, NSArray<NSDictionary *> *infos);
/** 视频 */
@property (nonatomic, copy) void (^didFinishPickingVideoHandle)(UIImage *coverImage,id asset);
@property (nonatomic, copy) void (^didFinishPickingVideoWithThumbnailAndPathHandle)(UIImage *coverImage, NSString *path);


/** 代理 */
@property (nonatomic, weak) id<LFImagePickerControllerDelegate> pickerDelegate;

@end


@protocol LFImagePickerControllerDelegate <NSObject> /** 每个代理方法都有对应的block回调 */
@optional


/**
 当allowTakePicture=YES，点击拍照会执行
 方案1：如果不实现这个代理方法，执行内置拍照模块，拍照完成后会自动保存到相册，执行图片回调相关代理。
 方案2：实现这个代理方法，则由开发者自己处理拍照模块，完毕后手动dismiss或其他操作。

 @param picker 选择器
 */
- (void)lf_imagePickerControllerTakePhoto:(LFImagePickerController *)picker;

/**
 当选择器点击取消的时候，会执行回调

 @param picker 选择器
 */
- (void)lf_imagePickerControllerDidCancel:(LFImagePickerController *)picker;
//如果系统版本大于iOS8，asset是PHAsset类的对象，否则是ALAsset类的对象

/// ======== 图片回调 ========

/**
 当选择器点击完成的时候，会执行回调

 @param picker 选择器
 @param assets 相片对象
 */
- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingAssets:(NSArray *)assets;

/**
 当选择器点击完成的时候，会执行回调

 @param picker 选择器
 @param assets 相片对象
 @param infos 相片信息
 */
- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingAssets:(NSArray *)assets infos:(NSArray<NSDictionary *> *)infos;

/**
 当选择器点击完成的时候，会执行回调
 👍傻瓜接口：将asset方向调整为向上，生成2张图片（压缩的缩略图10k左右；原图会根据UI是否勾选原图处理，没有勾选则压缩成标清图）
 
 @param picker 选择器
 @param thumbnailImages 缩略图
 @param originalImages 原图
 */
- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingThumbnailImages:(NSArray<UIImage *> *)thumbnailImages originalImages:(NSArray<UIImage *> *)originalImages;
/**
 当选择器点击完成的时候，会执行回调
 👍傻瓜接口：将asset方向调整为向上，生成2张图片（压缩的缩略图10k左右；原图会根据UI是否勾选原图处理，没有勾选则压缩成标清图），附带（原图/标清图）的部分信息，
 
 @param picker 选择器
 @param thumbnailImages 缩略图
 @param originalImages 原图
 @param infos 图片信息
 */
- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingThumbnailImages:(NSArray<UIImage *> *)thumbnailImages originalImages:(NSArray<UIImage *> *)originalImages infos:(NSArray<NSDictionary *> *)infos;

/// ======== 视频回调 ========

/**
 当选择器点击完成的时候，会执行回调

 @param picker 选择器
 @param coverImage 视频第一帧图片
 @param asset 相片对象
 */
- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(id)asset;
/**
 当选择器点击完成的时候，会执行回调
 👍傻瓜接口：将asset提取到缓存空间并压缩视频保存，回调路径可复制到自定义目录；若需要删除缓存，缓存路径由LFAssetManager提供
 
 @param picker 选择器
 @param coverImage 视频第一帧图片
 @param path 视频路径mp4
 */
- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage path:(NSString *)path;

@end
