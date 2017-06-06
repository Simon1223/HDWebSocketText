//
//  LFAssetCell.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAssetCell.h"
#import "LFImagePickerHeader.h"
#import "LFAsset.h"
#import "LFAssetManager.h"
#import "UIView+LFFrame.h"
#import "UIView+LFAnimate.h"
#import "LFPhotoEditManager.h"
#import "LFPhotoEdit.h"

#pragma mark - /// 宫格图片视图

#define kAdditionalSize (isiPad ? 15 : 0)
#define kVideoBoomHeight (17.f + kAdditionalSize)

@interface LFAssetCell ()
@property (weak, nonatomic) UIImageView *imageView;       // The photo / 照片
@property (weak, nonatomic) UIImageView *selectImageView;
@property (weak, nonatomic) UIImageView *editMaskImageView;
@property (weak, nonatomic) UIView *bottomView;
@property (weak, nonatomic) UIButton *selectPhotoButton;

@property (nonatomic, weak) UIImageView *videoImgView;
@property (weak, nonatomic) UILabel *timeLength;

@property (weak, nonatomic) UIView *maskHitView;
@end

@implementation LFAssetCell

- (void)setModel:(LFAsset *)model {
    _model = model;

    /** 优先显示编辑图片 */
    LFPhotoEdit *photoEdit = [[LFPhotoEditManager manager] photoEditForAsset:model];
    if (photoEdit.editPreviewImage) {
        self.imageView.image = photoEdit.editPreviewImage;
    } else if (model.previewImage) { /** 显示自定义图片 */
        self.imageView.image = model.previewImage;
    }  else {
        [[LFAssetManager manager] getPhotoWithAsset:model.asset photoWidth:self.width completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if ([model.asset isEqual:self.model.asset]) {
                self.imageView.image = photo;
            }
            
        } progressHandler:nil networkAccessAllowed:NO];
    }
    
    self.selectPhotoButton.selected = model.isSelected;
    self.selectImageView.image = self.selectPhotoButton.isSelected ? bundleImageNamed(self.photoSelImageName) : bundleImageNamed(self.photoDefImageName);
    
    /** 显示编辑标记 */
    self.editMaskImageView.hidden = (photoEdit.editPreviewImage == nil);
    
    [self setTypeToSubView];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.imageView.image = nil;
}

- (void)setTypeToSubView {
    
    if (self.model.type == LFAssetMediaTypePhoto) {
        _selectImageView.hidden = NO;
        _selectPhotoButton.hidden = NO;
        _bottomView.hidden = YES;
        
        if (self.displayGif && self.model.subType == LFAssetSubMediaTypeGIF) {
            _bottomView.hidden = NO;
            self.timeLength.text = @"GIF";
            self.videoImgView.hidden = YES;
            _timeLength.x = 5;
        } else if (self.displayLivePhoto && self.model.subType == LFAssetSubMediaTypeLivePhoto) {
            _bottomView.hidden = NO;
            self.timeLength.text = @"Live";
            self.videoImgView.hidden = YES;
            _timeLength.x = 5;
        }
    } else if (self.model.type == LFAssetMediaTypeVideo) {
        _selectImageView.hidden = YES;
        _selectPhotoButton.hidden = YES;
        _bottomView.hidden = NO;
        self.timeLength.text = _model.timeLength;
        self.videoImgView.hidden = NO;
        _timeLength.x = self.videoImgView.y;
    }
}

- (void)setOnlySelected:(BOOL)onlySelected
{
    _onlySelected = onlySelected;
    if (onlySelected) {
        _selectPhotoButton.frame = self.bounds;
    } else {
        _selectPhotoButton.frame = CGRectMake(self.width - 30 - kAdditionalSize, 0, 30 + kAdditionalSize, 30 + kAdditionalSize);
    }
}

- (void)setNoSelected:(BOOL)noSelected
{
    _noSelected = noSelected;
    self.maskHitView.hidden = !noSelected;
}

- (void)selectPhotoButtonClick:(UIButton *)sender {
    if (self.didSelectPhotoBlock) {
        BOOL isSelected = self.didSelectPhotoBlock(!sender.selected, self.model);
        if (isSelected) {
            sender.selected = !sender.isSelected;
            self.selectImageView.image = sender.isSelected ? bundleImageNamed(self.photoSelImageName) : bundleImageNamed(self.photoDefImageName);
            if (sender.isSelected) {
                [UIView showOscillatoryAnimationWithLayer:_selectImageView.layer type:OscillatoryAnimationToBigger];
            }
        }
    }
}

#pragma mark - Lazy load

- (UIButton *)selectPhotoButton {
    if (_selectPhotoButton == nil) {
        UIButton *selectPhotoButton = [[UIButton alloc] init];
        selectPhotoButton.frame = CGRectMake(self.width - 30 - kAdditionalSize, 0, 30 + kAdditionalSize, 30 + kAdditionalSize);
        [selectPhotoButton addTarget:self action:@selector(selectPhotoButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:selectPhotoButton];
        _selectPhotoButton = selectPhotoButton;
    }
    return _selectPhotoButton;
}

- (UIImageView *)imageView {
    if (_imageView == nil) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.frame = CGRectMake(0, 0, self.width, self.height);
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [self.contentView addSubview:imageView];
        _imageView = imageView;
        
        [self.contentView bringSubviewToFront:_selectImageView];
        [self.contentView bringSubviewToFront:_bottomView];
        [self.contentView bringSubviewToFront:_editMaskImageView];
    }
    return _imageView;
}

- (UIImageView *)selectImageView {
    if (_selectImageView == nil) {
        UIImageView *selectImageView = [[UIImageView alloc] init];
        selectImageView.frame = CGRectMake(self.width - 28 - kAdditionalSize, 2, 26 + kAdditionalSize, 26 + kAdditionalSize);
        [self.contentView addSubview:selectImageView];
        _selectImageView = selectImageView;
    }
    return _selectImageView;
}

- (UIImageView *)editMaskImageView
{
    if (_editMaskImageView == nil) {
        UIImageView *editMaskImageView = [[UIImageView alloc] init];
        editMaskImageView.frame = CGRectMake(5, self.height - 27 - kAdditionalSize, 22 + kAdditionalSize, 22 + kAdditionalSize);
        [editMaskImageView setImage:bundleImageNamed(@"contacts_add_myablum.png")];
        editMaskImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:editMaskImageView];
        _editMaskImageView = editMaskImageView;
    }
    return _editMaskImageView;
}

- (UIView *)bottomView {
    if (_bottomView == nil) {
        UIView *bottomView = [[UIView alloc] init];
        bottomView.frame = CGRectMake(0, self.height - kVideoBoomHeight, self.width, kVideoBoomHeight);
        static NSInteger rgb = 0;
        bottomView.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.8];
        [self.contentView addSubview:bottomView];
        _bottomView = bottomView;
    }
    return _bottomView;
}

- (UIImageView *)videoImgView {
    if (_videoImgView == nil) {
        UIImageView *videoImgView = [[UIImageView alloc] init];
        videoImgView.frame = CGRectMake(8, 0, kVideoBoomHeight, kVideoBoomHeight);
        [videoImgView setImage:bundleImageNamed(@"VideoSendIcon.png")];
        [self.bottomView addSubview:videoImgView];
        _videoImgView = videoImgView;
    }
    return _videoImgView;
}

- (UILabel *)timeLength {
    if (_timeLength == nil) {
        UILabel *timeLength = [[UILabel alloc] init];
        timeLength.font = [UIFont boldSystemFontOfSize:isiPad ? 17 : 11];
        timeLength.frame = CGRectMake(self.videoImgView.x, 0, self.width - self.videoImgView.x - 5, kVideoBoomHeight);
        timeLength.textColor = [UIColor whiteColor];
        timeLength.textAlignment = NSTextAlignmentRight;
        [self.bottomView addSubview:timeLength];
        _timeLength = timeLength;
    }
    return _timeLength;
}

- (UIView *)maskHitView
{
    if (_maskHitView == nil) {
        UIView *view = [[UIButton alloc] init];
        view.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.5f];
        view.frame = self.bounds;
        view.hidden = YES;
        [self.contentView addSubview:view];
        _maskHitView = view;
    }
    [self.contentView bringSubviewToFront:_maskHitView];
    return _maskHitView;
}

@end

#pragma mark - /// 拍照视图

@interface LFAssetCameraCell ()
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation LFAssetCameraCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        _imageView = [[UIImageView alloc] init];
        _imageView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.500];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_imageView];
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)setPosterImage:(UIImage *)posterImage
{
    _posterImage = posterImage;
    [self.imageView setImage:posterImage];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _imageView.frame = self.bounds;
}

@end
