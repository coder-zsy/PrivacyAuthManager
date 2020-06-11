//
//  PrivacyAuthManager.h
//  PrivacyAuthManager
//
//  Created by 张时疫 on 2020/6/10.
//  Copyright © 2020 张时疫. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 未使用的功能不建议申请相关权限，可以删除相关代码 */

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger , AuthorizationStatus) {
    AuthorizationStatusNotDetermined, // 未请求授权
    AuthorizationStatusRestricted, // 无相关权限，如：家长控制
    AuthorizationStatusUnable, // 服务不可用
    AuthorizationStatusDenied, // 已拒绝访问
    AuthorizationStatusWhenInUse, // 拥有 app 使用时的权限
    AuthorizationStatusAuthorized, // 拥有所有权限(使用、后台)
};

typedef void(^AuthorizationStatusBlock)(AuthorizationStatus status);

@interface PrivacyAuthManager : NSObject

/**这里使用单例模式主要是因为：
 * 获取定位权限时，定位对象会在请求定位权限时被释放，导致请求定位权限的弹框一闪而逝
*/
+ (instancetype)sharedManager;

/**
 * 打开设置界面 */
- (void)openPermissionSetting ;

/** 获取相册权限
 * 在 info.plist 中增加以下此段，以说明请求权限的原因
 * Privacy - Photo Library Usage Description
 * 被拒绝或关闭授权时，无法再次请求授权，只能提示用户主动开启*/
- (void)checkPhotoAuthor:(AuthorizationStatusBlock)callback ;

/** 获取相机权限
 * 在 info.plist 中增加以下此段，以说明请求权限的原因
 * Privacy - Camera Usage Description NSCameraUsageDescription
 @param callback XYAuthorizationStatus
 */
- (void)checkCameraAuthor:(AuthorizationStatusBlock)callback ;

/*检查麦克风权限
 * Privacy - Microphone Usage Description   NSMicrophoneUsageDescription
 */
- (void)checkMicrophoneAuthor:(AuthorizationStatusBlock)callback ;

/**
 * 获取通讯录权限
 * Privacy - Contacts Usage Description   NSContactsUsageDescription */
- (void)checkAddressBookAuthor:(AuthorizationStatusBlock)callback;

#pragma mark --- 通知、连网权限待验证
- (void)checkNotificationAuthor:(AuthorizationStatusBlock)callback;
- (void)checkNetworkAuthor:(AuthorizationStatusBlock)callback;

/**定位权限检测
 * 在 info.plist 中增加以下此段，以说明请求权限的原因
 * 1.Privacy - Location Always and When In Use Usage Description
 * 2.Privacy - Location When In Use Usage Description  NSLocationWhenInUseUsageDescription
 * 3.Privacy - Location Always Usage Description
 * 定位权限申请*/
- (void)checkLocationAuthorAuthorWithType:(AuthorizationStatus)status callback:(AuthorizationStatusBlock)callback ;


@end

NS_ASSUME_NONNULL_END
