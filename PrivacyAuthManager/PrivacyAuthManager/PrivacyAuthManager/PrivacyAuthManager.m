//
//  PrivacyAuthManager.m
//  PrivacyAuthManager
//
//  Created by 张时疫 on 2020/6/10.
//  Copyright © 2020 张时疫. All rights reserved.
//

#import "PrivacyAuthManager.h"
#import <Photos/Photos.h>
#import <CoreLocation/CoreLocation.h>
#import <EventKit/EventKit.h>
#import "AppDelegate.h"

//#import <CoreTelephony/CoreTelephonyDefines.h>
@import AddressBook;
@import Contacts;
@import CoreTelephony;

@interface PrivacyAuthManager() <CLLocationManagerDelegate>

@property (nonatomic , strong) AuthorizationStatusBlock locationStatusBlock;
@property (nonatomic , strong) CLLocationManager * locationManager;

@end

@implementation PrivacyAuthManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static PrivacyAuthManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [[PrivacyAuthManager alloc] init];
    });
    return instance;
}

- (void)openPermissionSetting {
    NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if([[UIApplication sharedApplication] canOpenURL:url]) {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:@{UIApplicationOpenURLOptionsSourceApplicationKey: @YES} completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

#pragma mark --- 相册 ---
/** 获取相册权限
 * #import <Photos/Photos.h>
 * Privacy - Photo Library Usage Description
 * 被拒绝或关闭授权时，无法再次请求授权，只能提示用户主动开启*/
- (void)checkPhotoAuthor:(AuthorizationStatusBlock)callback {
    __block AuthorizationStatus state = AuthorizationStatusNotDetermined;
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized) {
        // 用户已授权，允许访问
        state = AuthorizationStatusAuthorized;
        callback(state);
    } else if (status == PHAuthorizationStatusRestricted) {
        NSLog(@"拒绝、关闭授权，请开启相册权限\n 设置 -> 隐私 -> 照片");
        state = AuthorizationStatusRestricted;
        callback(state);
    } else if (status == PHAuthorizationStatusDenied) {
        state = AuthorizationStatusDenied;
        callback(state);
    } else {
        //未请求过授权 PHAuthorizationStatusNotDetermined
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusNotDetermined) {
                state = AuthorizationStatusNotDetermined;
                callback(state);
            } else if (status == PHAuthorizationStatusAuthorized) {
                state = AuthorizationStatusAuthorized;
                callback(state);
            } else if (status == PHAuthorizationStatusDenied) {
                state = AuthorizationStatusDenied;
                callback(state);
            } else {
                state = AuthorizationStatusRestricted;
                callback(state);
            }
        }];
    }
}
#pragma mark --- 相机 ---
/**获取相机权限
 * Privacy - Camera Usage Description*/
- (void)checkCameraAuthor:(AuthorizationStatusBlock)callback {
    __block AuthorizationStatus state = AuthorizationStatusNotDetermined;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized) {
        // 用户已授权，允许访问
        state = AuthorizationStatusAuthorized;
        callback(state);
    } else if (status == AVAuthorizationStatusRestricted) {
        NSLog(@"拒绝、关闭授权，请开启相机权限\n 设置 -> 隐私 -> 相机");
        state = AuthorizationStatusRestricted;
        callback(state);
    } else if (status == AVAuthorizationStatusDenied) {
        state = AuthorizationStatusDenied;
        callback(state);
    } else {
        // 未请求过授权
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                state = AuthorizationStatusAuthorized;
                callback(state);
            } else {
                state = AuthorizationStatusDenied;
                callback(state);
            }
        }];
    }
    
}
#pragma mark --- 麦克风 ---
/*检查麦克风权限
 * Privacy - Microphone Usage Description
 * AVAudioSessionRecordPermissionUndetermined = 'undt’,// 未获取权限
 * AVAudioSessionRecordPermissionDenied = 'deny’,//拒绝授权
 * AVAudioSessionRecordPermissionGranted = ‘grant’//同意授权*/
- (void)checkMicrophoneAuthor:(AuthorizationStatusBlock)callback {
    __block AuthorizationStatus state = AuthorizationStatusNotDetermined;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionRecordPermission status = [audioSession recordPermission];
    if (status == AVAudioSessionRecordPermissionDenied) {
        state = AuthorizationStatusDenied;
        callback(state);
        NSLog(@"拒绝、关闭授权，请开启麦克风权限\n 设置 -> 隐私 -> 麦克风");
    } else if (status == AVAudioSessionRecordPermissionGranted) {
        state = AuthorizationStatusAuthorized;
        callback(state);
    } else {
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    state = AuthorizationStatusAuthorized;
                    callback(state);
                } else {
                    NSLog(@"请开启麦克风访问权限:\n设置 -> 隐私 -> 麦克风");
                    state = AuthorizationStatusDenied;
                    callback(state);
                }
            }];
        }
    }
    
}
#pragma mark --- 通讯录 ---
/**
 * 获取通讯录权限 */
- (void)checkAddressBookAuthor:(AuthorizationStatusBlock)callback {
    __block AuthorizationStatus state = AuthorizationStatusNotDetermined;
    /* iOS9.0及以后
     导入头文件 **@import Contacts;**
     检查是否有通讯录权限 */
    if (@available(iOS 9.0, *)) {
        CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        switch (status) {
            case CNAuthorizationStatusAuthorized: {
                state = AuthorizationStatusAuthorized;
                callback(state);
            } break;
            case CNAuthorizationStatusDenied:{
                state = AuthorizationStatusDenied;
                callback(state);
            } break;
            case CNAuthorizationStatusRestricted:{
                state = AuthorizationStatusRestricted;
                callback(state);
            } break;
            case CNAuthorizationStatusNotDetermined:{
                //查询是否获取通讯录权限
                CNContactStore *contactStore = [[CNContactStore alloc] init];
                [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
                    if (granted) {
                        state = AuthorizationStatusAuthorized;
                    } else {
                        state = AuthorizationStatusDenied;
                    }
                    callback(state);
                }];
            } break;
            default:break;
        }
    } else {
        /**Fallback on earlier versions
         * @import AddressBook;*/
        ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
        switch (status) {
            case kABAuthorizationStatusNotDetermined:
                //state = AuthorizationStatusNotDetermined;
                // 获取通讯录权限
                //ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
                ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, NULL), ^(bool granted, CFErrorRef error) {
                    if (granted) {
                        state = AuthorizationStatusAuthorized;
                        //CFRelease(addressBook);
                    } else {
                        state = AuthorizationStatusDenied;
                    }});
                break;
            case kABAuthorizationStatusAuthorized:
                state = AuthorizationStatusAuthorized;
                break;
            case kABAuthorizationStatusDenied:
                state = AuthorizationStatusDenied;
                break;
            case kABAuthorizationStatusRestricted:
                state = AuthorizationStatusRestricted;
                break;
            default:
                break;
        }
        callback(state);
    }
    
}

#pragma mark --- 日历备忘录 ---
/**检查日历和备忘录权限
 * #import <EventKit/EventKit.h>
 * */
- (void)checkEventAuthorWithType:(EKEntityType)eventType  callback:(AuthorizationStatusBlock)callback {
    __block AuthorizationStatus state = AuthorizationStatusNotDetermined;
    EKAuthorizationStatus EKstatus = [EKEventStore  authorizationStatusForEntityType:eventType];
    switch (EKstatus) {
        case EKAuthorizationStatusNotDetermined:{
            state = AuthorizationStatusNotDetermined;
            EKEventStore *store = [[EKEventStore alloc]init];
            [store requestAccessToEntityType:eventType completion:^(BOOL granted, NSError * _Nullable error) {
                if (granted) {
                    state = AuthorizationStatusAuthorized;
                } else {
                    state = AuthorizationStatusDenied;
                }
                callback(state);
            }];
        }
            break;
        case EKAuthorizationStatusAuthorized:
            state = AuthorizationStatusAuthorized;
            callback(state);
            break;
        case EKAuthorizationStatusDenied:
            state = AuthorizationStatusDenied;
            callback(state);
            break;
        case EKAuthorizationStatusRestricted:
            state = AuthorizationStatusRestricted;
            callback(state);
            break;
        default:
            break;
    }
}

#pragma mark --- 推送通知 ---
- (void)checkNotificationAuthor:(AuthorizationStatusBlock)callback {
    __block AuthorizationStatus state = AuthorizationStatusNotDetermined;
    BOOL pushEnabled;
    // 设置里的通知总开关是否打开
    BOOL settingEnabled = [[UIApplication sharedApplication] isRegisteredForRemoteNotifications];
    // 设置里的通知各子项是否都打开
    BOOL subsettingEnabled = [[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone;
    pushEnabled = settingEnabled && subsettingEnabled;
    //当前打开的权限：
    UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    switch (settings.types) {
        case UIUserNotificationTypeNone:
            NSLog(@"None");
            break;
        case UIUserNotificationTypeAlert:
            NSLog(@"Alert Notification");
            break;
        case UIUserNotificationTypeBadge:
            NSLog(@"Badge Notification");
            break;
        case UIUserNotificationTypeSound:
            NSLog(@"sound Notification'");
            break;
            
        default:
            break;
    }
    //请求权限
    UIUserNotificationSettings *setting = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:setting];
    
}
#pragma mark --- 网络 ---
- (void)checkNetworkAuthor:(AuthorizationStatusBlock)callback {
    __block AuthorizationStatus authState = AuthorizationStatusNotDetermined;
    /**
     使用时需要注意的关键点：
     
     CTCellularData  只能检测蜂窝权限，不能检测WiFi权限。
     一个CTCellularData实例新建时，restrictedState是kCTCellularDataRestrictedStateUnknown，
     之后在cellularDataRestrictionDidUpdateNotifier里会有一次回调，此时才能获取到正确的权限状态。
     当用户在设置里更改了app的权限时，cellularDataRestrictionDidUpdateNotifier会收到回调，如果要停止监听，
     必须将cellularDataRestrictionDidUpdateNotifier设置为nil。
     赋值给cellularDataRestrictionDidUpdateNotifier的block并不会自动释放，
     即便你给一个局部变量的CTCellularData实例设置监听，当权限更改时，还是会收到回调，所以记得将block置nil。
     */
    if (@available(iOS 9.0, *)) {
        CTCellularData *cellularData = [[CTCellularData alloc] init];
        //获取联网状态 switch (state)
        cellularData.cellularDataRestrictionDidUpdateNotifier = ^(CTCellularDataRestrictedState state) {
            switch (state) {
                case kCTCellularDataRestricted: {
                    authState = AuthorizationStatusRestricted;
                } break;
                case kCTCellularDataNotRestricted: {
                    authState = AuthorizationStatusAuthorized;
                } break;
                    //未知，第一次请求
                case kCTCellularDataRestrictedStateUnknown: {
                    authState = AuthorizationStatusNotDetermined;
                } break;
                default: break;
            }
            callback(authState);
        };
    } else {
        // Fallback on earlier versions
    }
}
#pragma mark --- 定位 ---
/**定位权限检测
 * 在 info.plist 中增加以下此段，以说明请求权限的原因
 * 1.Privacy - Location Always and When In Use Usage Description
 * 2.Privacy - Location When In Use Usage Description
 * 3.Privacy - Location Always Usage Description
 * 定位权限申请*/
- (void)checkLocationAuthorAuthorWithType:(AuthorizationStatus)status callback:(AuthorizationStatusBlock)callback {
//    BOOL errorParam = status == AuthorizationStatusWhenInUse ? true : false;
//    NSAssert(errorParam, @"你这样不行。。。。");
    self.locationStatusBlock = callback;
    __block AuthorizationStatus state = AuthorizationStatusNotDetermined;
    if (![CLLocationManager locationServicesEnabled]) {
        state = AuthorizationStatusUnable;
        self.locationStatusBlock(state);
        return;
    }
    CLAuthorizationStatus curStatus = [CLLocationManager authorizationStatus];
    switch (curStatus) {
        case kCLAuthorizationStatusNotDetermined:{
            //未请求授权
            state = AuthorizationStatusNotDetermined;
            //只能请求一次，以后再请求无效，需要主动弹出弹框提示用户手动打开
            if (status == AuthorizationStatusWhenInUse) {
                [self.locationManager requestWhenInUseAuthorization];
            } else if (status == AuthorizationStatusAuthorized) {
                [self.locationManager requestAlwaysAuthorization];
            } else {
                
                NSLog(@"好好传值不要闹！！");
            }
        }
            break;
        case kCLAuthorizationStatusRestricted:{
            //无相关权限，如：家长控制
            state = AuthorizationStatusRestricted;
            self.locationStatusBlock(state);
        }
            break;
        case kCLAuthorizationStatusDenied:{
            //已拒绝访问
            state = AuthorizationStatusDenied;
            self.locationStatusBlock(state);
        }
            break;
        case kCLAuthorizationStatusAuthorizedAlways:{
            //已获取授权，任何时候都可以使用(前台、后台)
            state = AuthorizationStatusAuthorized;
            self.locationStatusBlock(state);
        }
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:{
            //仅授权了在应用程序使用时使用
            state = AuthorizationStatusWhenInUse;
            self.locationStatusBlock(state);
        }
            break;
        default:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    __block AuthorizationStatus state = AuthorizationStatusNotDetermined;
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:{
            //未请求授权
            state = AuthorizationStatusNotDetermined;
        }
            break;
        case kCLAuthorizationStatusRestricted:{
            //无相关权限，如：家长控制
            state = AuthorizationStatusRestricted;
        }
            break;
        case kCLAuthorizationStatusDenied:{
            //已拒绝访问
            state = AuthorizationStatusDenied;
        }
            break;
        case kCLAuthorizationStatusAuthorizedAlways:{
            //已获取授权，任何时候都可以使用(前台、后台)
            state = AuthorizationStatusAuthorized;
        }
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:{
            //仅授权了在应用程序使用时使用
            state = AuthorizationStatusWhenInUse;
        }
            break;
        default:
            break;
    }
    self.locationStatusBlock(state);
}

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

@end
