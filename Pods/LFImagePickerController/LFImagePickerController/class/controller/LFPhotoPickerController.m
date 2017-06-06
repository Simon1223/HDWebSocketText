//
//  LFPhotoPickerController.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoPickerController.h"
#import "LFImagePickerController.h"
#import "LFPhotoPreviewController.h"
#import "LFPhotoEdittingController.h"
#import "LFVideoPlayerController.h"
#import "LFImagePickerHeader.h"
#import "UIView+LFFrame.h"
#import "UIView+LFAnimate.h"
#import "UIAlertView+LF_Block.h"
#import "UIImage+LFCommon.h"
#import "UIImage+LF_Format.h"

#import "LFAlbum.h"
#import "LFAsset.h"
#import "LFAssetCell.h"
#import "LFAssetManager+Authorization.h"
#import "LFAssetManager+SaveAlbum.h"
#import "LFPhotoEditManager.h"
#import "LFPhotoEdit.h"

#import <MobileCoreServices/UTCoreTypes.h>

#define kBottomToolBarHeight 50.f

@interface LFCollectionView : UICollectionView

@end

@implementation LFCollectionView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    if ( [view isKindOfClass:[UIControl class]]) {
        return YES;
    }
    return [super touchesShouldCancelInContentView:view];
}

@end

@interface LFPhotoPickerController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    NSMutableArray *_models;
    
    UIButton *_editButton;
    UIButton *_previewButton;
    UIButton *_doneButton;
    
    UIButton *_originalPhotoButton;
    UILabel *_originalPhotoLabel;
    
    BOOL _shouldScrollToBottom;
    BOOL _showTakePhotoBtn;
}
@property (nonatomic, strong) LFCollectionView *collectionView;

@end

@implementation LFPhotoPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    if (!imagePickerVc.isPreview) { /** 非预览模式 */
        
        _shouldScrollToBottom = YES;
        self.view.backgroundColor = [UIColor whiteColor];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:imagePickerVc.cancelBtnTitleStr style:UIBarButtonItemStylePlain target:imagePickerVc action:@selector(cancelButtonClick)];
#pragma clang diagnostic pop
        /** 优先赋值 */
        self.navigationItem.title = _model.name;
        [imagePickerVc showProgressHUD];
        
        dispatch_globalQueue_async_safe(^{
            
            long long start = [[NSDate date] timeIntervalSince1970] * 1000;
            void (^initDataHandle)() = ^{
                if (self.model.models.count) { /** 使用缓存数据 */
                    _models = [NSMutableArray arrayWithArray:_model.models];
                    dispatch_main_async_safe(^{
                        [self initSubviews];
                    });
                } else {
                    /** 倒序情况下。iOS9的result已支持倒序,这里的排序应该为顺序 */
                    BOOL ascending = imagePickerVc.sortAscendingByCreateDate;
                    if (!imagePickerVc.sortAscendingByCreateDate && iOS8Later) {
                        ascending = !imagePickerVc.sortAscendingByCreateDate;
                    }
                    [[LFAssetManager manager] getAssetsFromFetchResult:_model.result allowPickingVideo:imagePickerVc.allowPickingVideo allowPickingImage:imagePickerVc.allowPickingImage fetchLimit:0 ascending:ascending completion:^(NSArray<LFAsset *> *models) {
                        /** 缓存数据 */
                        _model.models = models;
                        _models = [NSMutableArray arrayWithArray:models];
                        dispatch_main_async_safe(^{
                            long long end = [[NSDate date] timeIntervalSince1970] * 1000;
                            NSLog(@"%lu张图片加载耗时：%lld毫秒", (unsigned long)models.count, end - start);
                            [self initSubviews];
                        });
                    }];
                }
            };
            
            if (_model == nil) { /** 没有指定相册，默认显示相片胶卷 */
                [[LFAssetManager manager] getCameraRollAlbum:imagePickerVc.allowPickingVideo allowPickingImage:imagePickerVc.allowPickingImage fetchLimit:0 ascending:imagePickerVc.sortAscendingByCreateDate completion:^(LFAlbum *model) {
                    self.model = model;
                    long long end = [[NSDate date] timeIntervalSince1970] * 1000;
                    NSLog(@"加载相册耗时：%lld毫秒", end - start);
                    initDataHandle();
                }];
            } else { /** 已存在相册数据 */
                initDataHandle();
            }
        });
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    CGRect collectionViewRect = [self viewFrameWithoutNavigation];
    collectionViewRect.size.height -= kBottomToolBarHeight;
    _collectionView.frame = collectionViewRect;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Determine the size of the thumbnails to request from the PHCachingImageManager
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)dealloc
{

}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)initSubviews {
    /** 可能没有model的情况，补充赋值 */
    self.navigationItem.title = _model.name;
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [imagePickerVc hideProgressHUD];
    _showTakePhotoBtn = (([[LFAssetManager manager] isCameraRollAlbum:_model.name]) && imagePickerVc.allowTakePicture);
    
    
    if (_models.count == 0) {
        [self configNonePhotoView];
    } else {
        [self checkSelectedModels];
        [self configCollectionView];
        [self configBottomToolBar];
        [self scrollCollectionViewToBottom];
    }
    
}

- (void)configNonePhotoView {
    
    UIView *nonePhotoView = [[UIView alloc] initWithFrame:[self viewFrameWithoutNavigation]];
    nonePhotoView.backgroundColor = [UIColor clearColor];
    
    NSString *text = @"没有图片或视频";
    UIFont *font = [UIFont systemFontOfSize:18];
    CGSize textSize = [text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size;
    
    UILabel *label = [[UILabel alloc] initWithFrame:(CGRect){{(CGRectGetWidth(nonePhotoView.frame)-textSize.width)/2, (CGRectGetHeight(nonePhotoView.frame)-textSize.height)/2}, textSize}];
    label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    label.font = font;
    label.text = text;
    label.textColor = [UIColor lightGrayColor];
    
    [nonePhotoView addSubview:label];
    nonePhotoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:nonePhotoView];
}

- (void)configCollectionView {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat margin = isiPad ? 15 : 8;
    CGFloat screenWidth = MIN(self.view.width, self.view.height);
    CGFloat itemWH = (screenWidth - (imagePickerVc.columnNumber + 1) * margin) / imagePickerVc.columnNumber;
    layout.itemSize = CGSizeMake(itemWH, itemWH);
    layout.minimumInteritemSpacing = margin;
    layout.minimumLineSpacing = margin;
    
    CGRect collectionViewRect = [self viewFrameWithoutNavigation];
    collectionViewRect.size.height -= kBottomToolBarHeight;
    
    _collectionView = [[LFCollectionView alloc] initWithFrame:collectionViewRect collectionViewLayout:layout];
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.alwaysBounceHorizontal = NO;
    _collectionView.contentInset = UIEdgeInsetsMake(margin, margin, margin, margin);
    
    if (_showTakePhotoBtn && imagePickerVc.allowTakePicture ) {
        _collectionView.contentSize = CGSizeMake(self.view.width, ((_model.count + imagePickerVc.columnNumber) / imagePickerVc.columnNumber) * self.view.width);
    } else {
        _collectionView.contentSize = CGSizeMake(self.view.width, ((_model.count + imagePickerVc.columnNumber - 1) / imagePickerVc.columnNumber) * self.view.width);
    }
    [self.view addSubview:_collectionView];
    [_collectionView registerClass:[LFAssetCell class] forCellWithReuseIdentifier:@"LFAssetCell"];
    [_collectionView registerClass:[LFAssetCameraCell class] forCellWithReuseIdentifier:@"LFAssetCameraCell"];
}

- (void)configBottomToolBar {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    CGFloat yOffset = 0, height = kBottomToolBarHeight;;
    if (self.navigationController.navigationBar.isTranslucent) {
        yOffset = self.view.height - height;
    } else {
        CGFloat navigationHeight = 44;
        if (iOS7Later) navigationHeight += 20;
        yOffset = self.view.height - height - navigationHeight;
    }
    
    UIColor *toolbarBGColor = imagePickerVc.toolbarBgColor;
    UIColor *toolbarTitleColorNormal = imagePickerVc.toolbarTitleColorNormal;
    UIColor *toolbarTitleColorDisabled = imagePickerVc.toolbarTitleColorDisabled;
    UIFont *toolbarTitleFont = imagePickerVc.toolbarTitleFont;
    
    UIView *bottomToolBar = [[UIView alloc] initWithFrame:CGRectMake(0, yOffset, self.view.width, height)];
    bottomToolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    bottomToolBar.backgroundColor = toolbarBGColor;
    
    CGFloat buttonX = 0;
    
//    if (imagePickerVc.allowEditting) {
//        CGFloat editWidth = [imagePickerVc.editBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:toolbarTitleFont} context:nil].size.width + 2;
//        _editButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        _editButton.frame = CGRectMake(10, 3, editWidth, 44);
//        _editButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
//        [_editButton addTarget:self action:@selector(editButtonClick) forControlEvents:UIControlEventTouchUpInside];
//        _editButton.titleLabel.font = toolbarTitleFont;
//        [_editButton setTitle:imagePickerVc.editBtnTitleStr forState:UIControlStateNormal];
//        [_editButton setTitle:imagePickerVc.editBtnTitleStr forState:UIControlStateDisabled];
//        [_editButton setTitleColor:toolbarTitleColorNormal forState:UIControlStateNormal];
//        [_editButton setTitleColor:toolbarTitleColorDisabled forState:UIControlStateDisabled];
//        _editButton.enabled = imagePickerVc.selectedModels.count==1;
//        
//        buttonX = CGRectGetMaxX(_editButton.frame);
//    }
    
    
    if (imagePickerVc.allowPreview) {
        CGFloat previewWidth = [imagePickerVc.previewBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:toolbarTitleFont} context:nil].size.width + 2;
        _previewButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _previewButton.frame = CGRectMake(buttonX+10, 3, previewWidth, 44);
        _previewButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_previewButton addTarget:self action:@selector(previewButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _previewButton.titleLabel.font = toolbarTitleFont;
        [_previewButton setTitle:imagePickerVc.previewBtnTitleStr forState:UIControlStateNormal];
        [_previewButton setTitle:imagePickerVc.previewBtnTitleStr forState:UIControlStateDisabled];
        [_previewButton setTitleColor:toolbarTitleColorNormal forState:UIControlStateNormal];
        [_previewButton setTitleColor:toolbarTitleColorDisabled forState:UIControlStateDisabled];
        _previewButton.enabled = imagePickerVc.selectedModels.count;
        
        buttonX = CGRectGetMaxX(_previewButton.frame);
    }
    
    
    if (imagePickerVc.allowPickingOriginalPhoto && imagePickerVc.isPreview==NO) {
        CGFloat fullImageWidth = [imagePickerVc.fullImageBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:toolbarTitleFont} context:nil].size.width;
        _originalPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _originalPhotoButton.frame = CGRectMake(buttonX, 0, fullImageWidth + 56, 50);
        _originalPhotoButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _originalPhotoButton.imageEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0);
        [_originalPhotoButton addTarget:self action:@selector(originalPhotoButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _originalPhotoButton.titleLabel.font = toolbarTitleFont;
        [_originalPhotoButton setTitle:imagePickerVc.fullImageBtnTitleStr forState:UIControlStateNormal];
        [_originalPhotoButton setTitle:imagePickerVc.fullImageBtnTitleStr forState:UIControlStateSelected];
        [_originalPhotoButton setTitle:imagePickerVc.fullImageBtnTitleStr forState:UIControlStateDisabled];
        [_originalPhotoButton setTitleColor:toolbarTitleColorNormal forState:UIControlStateNormal];
        [_originalPhotoButton setTitleColor:toolbarTitleColorNormal forState:UIControlStateSelected];
        [_originalPhotoButton setTitleColor:toolbarTitleColorDisabled forState:UIControlStateDisabled];
        [_originalPhotoButton setImage:bundleImageNamed(imagePickerVc.photoOriginDefImageName) forState:UIControlStateNormal];
        [_originalPhotoButton setImage:bundleImageNamed(imagePickerVc.photoOriginSelImageName) forState:UIControlStateSelected];
        [_originalPhotoButton setImage:bundleImageNamed(imagePickerVc.photoOriginDefImageName) forState:UIControlStateDisabled];
        _originalPhotoButton.selected = imagePickerVc.isSelectOriginalPhoto;
//        _originalPhotoButton.enabled = imagePickerVc.selectedModels.count > 0;
        
        _originalPhotoLabel = [[UILabel alloc] init];
        _originalPhotoLabel.frame = CGRectMake(fullImageWidth + 46, 0, 80, 50);
        _originalPhotoLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _originalPhotoLabel.textAlignment = NSTextAlignmentLeft;
        _originalPhotoLabel.font = toolbarTitleFont;
        _originalPhotoLabel.textColor = toolbarTitleColorNormal;
        
        [_originalPhotoButton addSubview:_originalPhotoLabel];
        if (imagePickerVc.isSelectOriginalPhoto) [self getSelectedPhotoBytes];
    }
    
    CGSize doneSize = [[imagePickerVc.doneBtnTitleStr stringByAppendingString:@"(10)" ] boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:toolbarTitleFont} context:nil].size;
    doneSize.height = MIN(MAX(doneSize.height, height), 30);
    doneSize.width += 4;
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.frame = CGRectMake(self.view.width - doneSize.width - 12, (height-doneSize.height)/2, doneSize.width, doneSize.height);
    _doneButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    _doneButton.titleLabel.font = toolbarTitleFont;
    [_doneButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_doneButton setTitle:imagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
    [_doneButton setTitle:imagePickerVc.doneBtnTitleStr forState:UIControlStateDisabled];
    [_doneButton setTitleColor:toolbarTitleColorNormal forState:UIControlStateNormal];
    [_doneButton setTitleColor:toolbarTitleColorDisabled forState:UIControlStateDisabled];
    _doneButton.layer.cornerRadius = CGRectGetHeight(_doneButton.frame)*0.2;
    _doneButton.layer.masksToBounds = YES;
    _doneButton.enabled = imagePickerVc.selectedModels.count;
    _doneButton.backgroundColor = _doneButton.enabled ? imagePickerVc.oKButtonTitleColorNormal : imagePickerVc.oKButtonTitleColorDisabled;
    
    UIView *divide = [[UIView alloc] init];
    divide.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.1f];
    divide.frame = CGRectMake(0, 0, self.view.width, 1);
    divide.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    [bottomToolBar addSubview:_editButton];
    [bottomToolBar addSubview:_previewButton];
    [bottomToolBar addSubview:_originalPhotoButton];
    [bottomToolBar addSubview:_doneButton];
    [bottomToolBar addSubview:divide];
    [self.view addSubview:bottomToolBar];
}

#pragma mark - Click Event
- (void)editButtonClick {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    NSArray *models = [imagePickerVc.selectedModels copy];
    LFPhotoPreviewController *photoPreviewVc = [[LFPhotoPreviewController alloc] initWithModels:_models index:[_models indexOfObject:models.firstObject] excludeVideo:YES];
    LFPhotoEdittingController *photoEdittingVC = [[LFPhotoEdittingController alloc] init];
    
    /** 抽取第一个对象 */
    LFAsset *model = models.firstObject;
    /** 获取缓存编辑对象 */
    LFPhotoEdit *photoEdit = [[LFPhotoEditManager manager] photoEditForAsset:model];
    if (photoEdit) {
        photoEdittingVC.photoEdit = photoEdit;
    } else if (model.previewImage) { /** 读取自定义图片 */
        photoEdittingVC.editImage = model.previewImage;
    } else {
        /** 获取对应的图片 */
        [[LFAssetManager manager] getPhotoWithAsset:model.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            photoEdittingVC.editImage = photo;
        }];
    }
    [self pushPhotoPrevireViewController:photoPreviewVc photoEdittingViewController:photoEdittingVC];
}

- (void)previewButtonClick {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    NSArray *models = [imagePickerVc.selectedModels copy];
    LFPhotoPreviewController *photoPreviewVc = [[LFPhotoPreviewController alloc] initWithModels:models index:0 excludeVideo:YES];
    photoPreviewVc.alwaysShowPreviewBar = YES;
    [self pushPhotoPrevireViewController:photoPreviewVc];
}

- (void)originalPhotoButtonClick {
    _originalPhotoButton.selected = !_originalPhotoButton.isSelected;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    imagePickerVc.isSelectOriginalPhoto = _originalPhotoButton.isSelected;;
    if (imagePickerVc.isSelectOriginalPhoto) [self getSelectedPhotoBytes];
}

- (void)doneButtonClick {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    // 1.6.8 判断是否满足最小必选张数的限制
    if (imagePickerVc.minImagesCount && imagePickerVc.selectedModels.count < imagePickerVc.minImagesCount) {
        NSString *title = [NSString stringWithFormat:@"请至少选择%zd张照片", imagePickerVc.minImagesCount];
        [imagePickerVc showAlertWithTitle:title];
        return;
    }
    
    [imagePickerVc showProgressHUD];
    NSMutableArray *thumbnailImages = [NSMutableArray array];
    NSMutableArray *originalImages = [NSMutableArray array];
    NSMutableArray *assets = [NSMutableArray array];
    NSMutableArray *infoArr = [NSMutableArray array];
    
    
    for (NSInteger i = 0; i < imagePickerVc.selectedModels.count; i++) { [assets addObject:@1];[infoArr addObject:@1]; [thumbnailImages addObject:@1];[originalImages addObject:@1];}
    
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_globalQueue_async_safe(^{
        
        if (imagePickerVc.selectedModels.count) {
            void (^photosComplete)(UIImage *, UIImage *, NSDictionary *, NSInteger, id) = ^(UIImage *thumbnail, UIImage *source, NSDictionary *info, NSInteger index, id asset) {
                if (thumbnail) [thumbnailImages replaceObjectAtIndex:index withObject:thumbnail];
                if (source) [originalImages replaceObjectAtIndex:index withObject:source];
                if (info) [infoArr replaceObjectAtIndex:index withObject:info];
                if (asset) [assets replaceObjectAtIndex:index withObject:asset];
                
                if ([assets containsObject:@1]) return;
                
                dispatch_main_async_safe(^{
                    if (weakSelf == nil) return ;
                    [imagePickerVc hideProgressHUD];
                    if (imagePickerVc.autoDismiss) {
                        [imagePickerVc dismissViewControllerAnimated:YES completion:^{
                            [weakSelf callDelegateMethodWithAssets:assets thumbnailImages:thumbnailImages originalImages:originalImages infoArr:infoArr];
                        }];
                    } else {
                        [weakSelf callDelegateMethodWithAssets:assets thumbnailImages:thumbnailImages originalImages:originalImages infoArr:infoArr];
                    }
                });
            };
            
            
            for (NSInteger i = 0; i < imagePickerVc.selectedModels.count; i++) {
                LFAsset *model = imagePickerVc.selectedModels[i];
                LFPhotoEdit *photoEdit = [[LFPhotoEditManager manager] photoEditForAsset:model];
                if (photoEdit) {
                    [[LFPhotoEditManager manager] getPhotoWithAsset:model.asset
                                                         isOriginal:imagePickerVc.isSelectOriginalPhoto
                                                       compressSize:imagePickerVc.imageCompressSize
                                              thumbnailCompressSize:imagePickerVc.thumbnailCompressSize
                                                         completion:^(UIImage *thumbnail, UIImage *source, NSDictionary *info) {
                                                             
                                                             if (imagePickerVc.autoSavePhotoAlbum) {
                                                                 /** 编辑图片保存到相册 */
                                                                 [[LFAssetManager manager] saveImageToCustomPhotosAlbumWithTitle:nil image:source complete:nil];
                                                             }
                                                             photosComplete(thumbnail, source, info, i, model.asset);
                    }];
                } else {
                    
                    if (imagePickerVc.allowPickingLivePhoto && model.subType == LFAssetSubMediaTypeLivePhoto && model.closeLivePhoto == NO) {
                        [[LFAssetManager manager] getLivePhotoWithAsset:model.asset
                                                             isOriginal:imagePickerVc.isSelectOriginalPhoto
                                                             completion:^(UIImage *thumbnail, UIImage *source, NSDictionary *info) {
                                                                 
                                                                 photosComplete(thumbnail, source, info, i, model.asset);
                        }];
                    } else {
                        [[LFAssetManager manager] getPhotoWithAsset:model.asset
                                                         isOriginal:imagePickerVc.isSelectOriginalPhoto
                                                         pickingGif:imagePickerVc.allowPickingGif
                                                       compressSize:imagePickerVc.imageCompressSize
                                              thumbnailCompressSize:imagePickerVc.thumbnailCompressSize
                                                         completion:^(UIImage *thumbnail, UIImage *source, NSDictionary *info) {
                                                             
                                                             photosComplete(thumbnail, source, info, i, model.asset);
                                                         }];
                    }
                    
                }
            }
        } else {
            dispatch_main_async_safe(^{
                [imagePickerVc hideProgressHUD];
                if (imagePickerVc.autoDismiss) {
                    [imagePickerVc dismissViewControllerAnimated:YES completion:^{
                        [weakSelf callDelegateMethodWithAssets:assets thumbnailImages:thumbnailImages originalImages:originalImages infoArr:infoArr];
                    }];
                } else {
                    [weakSelf callDelegateMethodWithAssets:assets thumbnailImages:thumbnailImages originalImages:originalImages infoArr:infoArr];
                }
            });
        }
    });
    
}

- (void)callDelegateMethodWithAssets:(NSArray *)assets thumbnailImages:(NSArray *)thumbnailImages originalImages:(NSArray *)originalImages infoArr:(NSArray *)infoArr {
    
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    id <LFImagePickerControllerDelegate> pickerDelegate = (id <LFImagePickerControllerDelegate>)imagePickerVc.pickerDelegate;
    
    if ([pickerDelegate respondsToSelector:@selector(lf_imagePickerController:didFinishPickingAssets:)]) {
        [pickerDelegate lf_imagePickerController:imagePickerVc didFinishPickingAssets:assets];
    } else if (imagePickerVc.didFinishPickingPhotosHandle) {
        imagePickerVc.didFinishPickingPhotosHandle(assets);
    }
    
    if ([pickerDelegate respondsToSelector:@selector(lf_imagePickerController:didFinishPickingAssets:infos:)]) {
        [pickerDelegate lf_imagePickerController:imagePickerVc didFinishPickingAssets:assets infos:infoArr];
    } else if (imagePickerVc.didFinishPickingPhotosWithInfosHandle) {
        imagePickerVc.didFinishPickingPhotosWithInfosHandle(assets,infoArr);
    }

    
    if ([pickerDelegate respondsToSelector:@selector(lf_imagePickerController:didFinishPickingThumbnailImages:originalImages:)]) {
        [pickerDelegate lf_imagePickerController:imagePickerVc didFinishPickingThumbnailImages:thumbnailImages originalImages:originalImages];
    } else if (imagePickerVc.didFinishPickingImagesHandle) {
        imagePickerVc.didFinishPickingImagesHandle(thumbnailImages, originalImages);
    }
    
    if ([pickerDelegate respondsToSelector:@selector(lf_imagePickerController:didFinishPickingThumbnailImages:originalImages:infos:)]) {
        [pickerDelegate lf_imagePickerController:imagePickerVc didFinishPickingThumbnailImages:thumbnailImages originalImages:originalImages infos:infoArr];
    } else if (imagePickerVc.didFinishPickingImagesWithInfosHandle) {
        imagePickerVc.didFinishPickingImagesWithInfosHandle(thumbnailImages, originalImages, infoArr);
    }
}

#pragma mark - UICollectionViewDataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_showTakePhotoBtn) {
        LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
        if (imagePickerVc.allowPickingImage && imagePickerVc.allowTakePicture) {
            return _models.count + 1;
        }
    }
    return _models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    // the cell lead to take a picture / 去拍照的cell
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    if (((imagePickerVc.sortAscendingByCreateDate && indexPath.row >= _models.count) || (!imagePickerVc.sortAscendingByCreateDate && indexPath.row == 0)) && _showTakePhotoBtn) {
        LFAssetCameraCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LFAssetCameraCell" forIndexPath:indexPath];
        cell.posterImage = bundleImageNamed(imagePickerVc.takePictureImageName);
        
        return cell;
    }
    // the cell dipaly photo or video / 展示照片或视频的cell
    LFAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LFAssetCell" forIndexPath:indexPath];
    cell.photoDefImageName = imagePickerVc.photoDefImageName;
    cell.photoSelImageName = imagePickerVc.photoSelImageName;
    cell.displayGif = imagePickerVc.allowPickingGif;
    cell.displayLivePhoto = imagePickerVc.allowPickingLivePhoto;
    
    NSInteger index = indexPath.row - 1;
    if (imagePickerVc.sortAscendingByCreateDate || !_showTakePhotoBtn) {
        index = indexPath.row;
    }
    LFAsset *model = _models[index];
    cell.model = model;
    cell.onlySelected = !imagePickerVc.allowPreview;
    /** 最大数量时，非选择部分显示不可选 */
    BOOL noSelectedItem = (imagePickerVc.selectedModels.count == imagePickerVc.maxImagesCount && ![imagePickerVc.selectedModels containsObject:model]);
    /** 选中图片时，视频部分显示不可选 */
    BOOL noSelectedVideo = model.type == LFAssetMediaTypeVideo && imagePickerVc.selectedModels.count;
    
    cell.noSelected = noSelectedItem || noSelectedVideo;
    
    
    __weak typeof(self) weakSelf = self;
    cell.didSelectPhotoBlock = ^(BOOL isSelected, LFAsset *cellModel) {
        LFImagePickerController *imagePickerVc = (LFImagePickerController *)weakSelf.navigationController;
        // 1. cancel select / 取消选择
        if (!isSelected) {
            cellModel.isSelected = NO;
            NSArray *selectedModels = [NSArray arrayWithArray:imagePickerVc.selectedModels];
            for (LFAsset *model_item in selectedModels) {
                if ([[[LFAssetManager manager] getAssetIdentifier:cellModel.asset] isEqualToString:[[LFAssetManager manager] getAssetIdentifier:model_item.asset]]) {
                    [imagePickerVc.selectedModels removeObject:model_item];
                    break;
                }
            }
            [weakSelf refreshBottomToolBarStatus];
            
            /** 没有选择需要刷新视频恢复显示 */
            if (imagePickerVc.selectedModels.count == 0) {
                [weakSelf refreshVideoCell];
            } else if (imagePickerVc.selectedModels.count == imagePickerVc.maxImagesCount-1) {
                /** 取消选择为最大数量-1时，显示其他可选 */
                [weakSelf refreshSelectedCell];
            }
        } else {
            // 2. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
            if (imagePickerVc.selectedModels.count < imagePickerVc.maxImagesCount) {
                cellModel.isSelected = YES;
                [imagePickerVc.selectedModels addObject:cellModel];
                [weakSelf refreshBottomToolBarStatus];
                
                /** 首次有选择需要刷新视频隐藏显示 */
                if (imagePickerVc.selectedModels.count == 1) {
                    [weakSelf refreshVideoCell];
                } else if (imagePickerVc.selectedModels.count == imagePickerVc.maxImagesCount) {
                    /** 选择到最大数量，禁止其他的可选显示 */
                    [weakSelf refreshSelectedCell];
                }
                
            } else {
                NSString *title = [NSString stringWithFormat:@"你最多只能选择%zd张照片", imagePickerVc.maxImagesCount];
                [imagePickerVc showAlertWithTitle:title];
                return NO;
            }
        }
        return YES;
    };
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // take a photo / 去拍照
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    if (((imagePickerVc.sortAscendingByCreateDate && indexPath.row >= _models.count) || (!imagePickerVc.sortAscendingByCreateDate && indexPath.row == 0)) && _showTakePhotoBtn)  {
        [self takePhoto]; return;
    }
    // preview phote or video / 预览照片或视频
    NSInteger index = indexPath.row;
    if (!imagePickerVc.sortAscendingByCreateDate && _showTakePhotoBtn) {
        index = indexPath.row - 1;
    }
    LFAsset *model = _models[index];
    if (model.type == LFAssetMediaTypeVideo) {
        if (imagePickerVc.selectedModels.count > 0) {
            LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
            [imagePickerVc showAlertWithTitle:@"选择照片时不能选择视频"];
        } else {
            LFVideoPlayerController *videoPlayerVc = [[LFVideoPlayerController alloc] init];
            videoPlayerVc.model = model;
            [self.navigationController pushViewController:videoPlayerVc animated:YES];
        }
    } else {
        LFPhotoPreviewController *photoPreviewVc = [[LFPhotoPreviewController alloc] initWithModels:[_models copy] index:index excludeVideo:YES];
        [self pushPhotoPrevireViewController:photoPreviewVc];
    }
}

#pragma mark - 拍照图片后执行代理
#pragma mark UIImagePickerControllerDelegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [imagePickerVc showProgressHUDText:nil isTop:YES];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if (picker.sourceType==UIImagePickerControllerSourceTypeCamera && [mediaType isEqualToString:@"public.image"]){
        UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
        [[LFAssetManager manager] saveImageToCustomPhotosAlbumWithTitle:nil image:chosenImage complete:^(id asset, NSError *error) {
            if (asset && !error) {
                [[LFAssetManager manager] getPhotoWithAsset:asset isOriginal:YES completion:^(UIImage *thumbnail, UIImage *source, NSDictionary *info) {
                    [imagePickerVc hideProgressHUD];
                    [picker.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
                        [self callDelegateMethodWithAssets:@[asset] thumbnailImages:@[thumbnail] originalImages:@[source] infoArr:@[info]];
                    }];
                }];
            }else if (error) {
                [imagePickerVc hideProgressHUD];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"拍照错误" message:error.localizedDescription cancelButtonTitle:@"确定" otherButtonTitles:nil block:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    [picker dismissViewControllerAnimated:YES completion:nil];
                }];
                [alertView show];
            }
        }];
    } else {
        [imagePickerVc hideProgressHUD];
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private Method

- (void)takePhoto {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if ((authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied) && iOS7Later) {
        // 无权限 做一个友好的提示
        NSString *appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleDisplayName"];
        if (!appName) appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleName"];
        NSString *message = [NSString stringWithFormat:@"请在iPhone的\"设置-隐私-相机\"中允许%@访问相机",appName];
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"无法使用相机" message:message cancelButtonTitle:@"取消" otherButtonTitles:@"设置" block:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1) { // 去设置界面，开启相机访问权限
                if (iOS8Later) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                } else {
                    NSURL *privacyUrl = [NSURL URLWithString:@"prefs:root=Privacy&path=CAMERA"];
                    if ([[UIApplication sharedApplication] canOpenURL:privacyUrl]) {
                        [[UIApplication sharedApplication] openURL:privacyUrl];
                    } else {
                        NSString *message = @"无法跳转到隐私设置页面，请手动前往设置页面，谢谢";
                        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"抱歉" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
                        [alert show];
                    }
                }
            }
        }];
        
        
        [alert show];
    } else { // 调用相机
        if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
            LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
            if ([imagePickerVc.pickerDelegate respondsToSelector:@selector(lf_imagePickerControllerTakePhoto:)]) {
                [imagePickerVc.pickerDelegate lf_imagePickerControllerTakePhoto:imagePickerVc];
            } else if (imagePickerVc.imagePickerControllerTakePhoto) {
                imagePickerVc.imagePickerControllerTakePhoto();
            } else {
                /** 调用内置相机模块 */
                UIImagePickerControllerSourceType srcType = UIImagePickerControllerSourceTypeCamera;
                UIImagePickerController *mediaPickerController = [[UIImagePickerController alloc] init];
                mediaPickerController.sourceType = srcType;
                mediaPickerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                mediaPickerController.delegate = self;
                mediaPickerController.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
                
                /** warning：Snapshotting a view that has not been rendered results in an empty snapshot. Ensure your view has been rendered at least once before snapshotting or snapshot after screen updates. */
                [self presentViewController:mediaPickerController animated:YES completion:NULL];
            }
        } else {
            NSLog(@"模拟器中无法打开照相机,请在真机中使用");
        }
    }
}

- (void)refreshVideoCell
{
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    NSMutableArray <NSIndexPath *>*indexPaths = [NSMutableArray array];
    [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(LFAssetCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([cell isKindOfClass:[LFAssetCell class]] && cell.model.type == LFAssetMediaTypeVideo) {
            NSInteger index = [_models indexOfObject:cell.model];
            if (_showTakePhotoBtn && !imagePickerVc.sortAscendingByCreateDate) {
                index += 1;
            }
            [indexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        }
    }];
    if (indexPaths.count) {
        [self.collectionView reloadItemsAtIndexPaths:indexPaths];
    }
}

- (void)refreshSelectedCell
{
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    NSMutableArray <NSIndexPath *>*indexPaths = [NSMutableArray array];
    [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(LFAssetCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([cell isKindOfClass:[LFAssetCell class]] && ![imagePickerVc.selectedModels containsObject:cell.model]) {
            NSInteger index = [_models indexOfObject:cell.model];
            if (_showTakePhotoBtn && !imagePickerVc.sortAscendingByCreateDate) {
                index += 1;
            }
            [indexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        }
    }];
    if (indexPaths.count) {
        [self.collectionView reloadItemsAtIndexPaths:indexPaths];
    }
}

- (void)refreshBottomToolBarStatus {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    _editButton.enabled = imagePickerVc.selectedModels.count == 1;
    _previewButton.enabled = imagePickerVc.selectedModels.count > 0;
//    _originalPhotoButton.enabled = imagePickerVc.selectedModels.count > 0;
    _doneButton.enabled = imagePickerVc.selectedModels.count;
    _doneButton.backgroundColor = _doneButton.enabled ? imagePickerVc.oKButtonTitleColorNormal : imagePickerVc.oKButtonTitleColorDisabled;
    
    [_doneButton setTitle:[NSString stringWithFormat:@"%@(%zd)",imagePickerVc.doneBtnTitleStr ,imagePickerVc.selectedModels.count] forState:UIControlStateNormal];
    
//    _originalPhotoButton.selected = (imagePickerVc.isSelectOriginalPhoto && imagePickerVc.selectedModels.count > 0);
    _originalPhotoLabel.hidden = (_originalPhotoButton.selected && imagePickerVc.selectedModels.count == 0);
    if (imagePickerVc.isSelectOriginalPhoto) [self getSelectedPhotoBytes];
}

- (void)pushPhotoPrevireViewController:(LFPhotoPreviewController *)photoPreviewVc {
    
    [self pushPhotoPrevireViewController:photoPreviewVc photoEdittingViewController:nil];
}

- (void)pushPhotoPrevireViewController:(LFPhotoPreviewController *)photoPreviewVc photoEdittingViewController:(LFPhotoEdittingController *)photoEdittingVC {
    
    /** 关联代理 */
    photoEdittingVC.delegate = (id)photoPreviewVc;
    
    __weak typeof(self) weakSelf = self;
    [photoPreviewVc setBackButtonClickBlock:^{
        [weakSelf.collectionView reloadData];
        [weakSelf refreshBottomToolBarStatus];
    }];
    [photoPreviewVc setDoneButtonClickBlock:^{
        [weakSelf doneButtonClick];
    }];
    
    if (photoEdittingVC) {
        NSMutableArray *viewControllers = [self.navigationController.viewControllers mutableCopy];
        [viewControllers addObject:photoPreviewVc];
        [viewControllers addObject:photoEdittingVC];
        [self.navigationController setViewControllers:viewControllers animated:YES];
    } else {
        [self.navigationController pushViewController:photoPreviewVc animated:YES];
    }
}


- (void)getSelectedPhotoBytes {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [[LFAssetManager manager] getPhotosBytesWithArray:imagePickerVc.selectedModels completion:^(NSString *totalBytes) {
        _originalPhotoLabel.text = [NSString stringWithFormat:@"(%@)",totalBytes];
    }];
}

- (void)scrollCollectionViewToBottom {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    if (_shouldScrollToBottom && _models.count > 0 && imagePickerVc.sortAscendingByCreateDate) {
        NSInteger item = _models.count - 1;
        if (_showTakePhotoBtn) {
            LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
            if (imagePickerVc.allowPickingImage && imagePickerVc.allowTakePicture) {
                item += 1;
            }
        }
        [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        _shouldScrollToBottom = NO;
    }
}

- (void)checkSelectedModels {
    NSMutableArray *selectedAssets = [NSMutableArray array];
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    for (LFAsset *model in imagePickerVc.selectedModels) {
        if (model.asset) {
            [selectedAssets addObject:model.asset];
        }
    }
    [imagePickerVc.selectedModels removeAllObjects];
    if (selectedAssets.count) {        
        for (LFAsset *model in _models) {
            model.isSelected = NO;
            NSInteger index = [[LFAssetManager manager] isAssetsArray:selectedAssets containAsset:model.asset];
            if (index != NSNotFound && imagePickerVc.maxImagesCount > imagePickerVc.selectedModels.count) {
                model.isSelected = YES;
                [imagePickerVc.selectedModels addObject:model];
            }
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
