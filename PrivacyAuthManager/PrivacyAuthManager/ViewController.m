//
//  ViewController.m
//  PrivacyAuthManager
//
//  Created by 张时疫 on 2020/6/10.
//  Copyright © 2020 张时疫. All rights reserved.
//

#import "ViewController.h"
#import "PrivacyAuthManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
    
    UIButton * checkPerssionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [checkPerssionButton setTitle:@"权限检查" forState:UIControlStateNormal];
    [checkPerssionButton setBackgroundColor:[UIColor blueColor]];
    [checkPerssionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [checkPerssionButton addTarget:self action:@selector(checkPerssion:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:checkPerssionButton];
    checkPerssionButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint * centerYConstraint = [NSLayoutConstraint constraintWithItem:checkPerssionButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    NSLayoutConstraint * leftConstraint = [NSLayoutConstraint constraintWithItem:checkPerssionButton attribute:NSLayoutAttributeLeftMargin relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:50];
    NSLayoutConstraint * rightConstraint = [NSLayoutConstraint constraintWithItem:checkPerssionButton attribute:NSLayoutAttributeRightMargin relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:-50];
    NSLayoutConstraint * heightConstraint = [NSLayoutConstraint constraintWithItem:checkPerssionButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0 constant:50];
    [self.view addConstraints:@[leftConstraint, rightConstraint, heightConstraint, centerYConstraint]];
}

- (void)checkPerssion: (UIButton *)button {
//    checkLocationAuthorAuthorWithType
//    [[PrivacyAuthManager sharedManager] checkNetworkAuthor:^(AuthorizationStatus status) {
//        NSLog(@"请求权限结果：：：：：%ld", (long)status);
//    }];
    [[PrivacyAuthManager sharedManager] checkLocationAuthorAuthorWithType:AuthorizationStatusAuthorized callback:^(AuthorizationStatus status) {
        NSLog(@"请求权限结果：：：：：%ld", (long)status);
    }];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
}

@end
