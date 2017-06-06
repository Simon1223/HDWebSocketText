# LFImagePickerController

* 项目UI与资源方面部分使用TZImagePickerController项目，感谢分享。
* 兼容非系统相册的调用方式
* 支持Gif(压缩)、视频（压缩）、图片（压缩）、图片编辑
* 支持iPhone、iPad 横屏
* 详细使用见LFImagePickerController.h 的初始化方法

## Installation 安装

* CocoaPods：pod 'LFImagePickerController'
* 手动导入：将LFImagePickerController\class文件夹拽入项目中，导入头文件：#import "LFImagePickerController.h"

## 调用代码

* LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
* //根据需求设置
* imagePicker.allowTakePicture = NO;  //不显示拍照按钮
* imagePicker.doneBtnTitleStr = @"发送"; //最终确定按钮名称
* [self presentViewController:imagePicker animated:YES completion:nil];

* 设置代理方法，按钮实现
* imagePicker.delegate;

## 图片展示

![image](https://github.com/lincf0912/LFImagePickerController/blob/master/ScreenShots/screenshot.gif)
