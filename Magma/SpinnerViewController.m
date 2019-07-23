//
//  SpinnerViewController.m
//  Magma
//
//  Created by PixelOmer on 23.07.2019.
//  Copyright © 2019 PixelOmer. All rights reserved.
//

#import "SpinnerViewController.h"

@implementation SpinnerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    UIView *indicatorContainer = [UIView new];
    indicatorContainer.translatesAutoresizingMaskIntoConstraints = NO;
    indicatorContainer.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
	indicatorContainer.layer.masksToBounds = YES;
    indicatorContainer.layer.cornerRadius = 10.0;
    [indicatorContainer addSubview:activityIndicator];
    [activityIndicator.topAnchor constraintEqualToAnchor:indicatorContainer.topAnchor constant:15.0].active = YES;
    [activityIndicator.leftAnchor constraintEqualToAnchor:indicatorContainer.leftAnchor constant:15.0].active = YES;
    [activityIndicator.rightAnchor constraintEqualToAnchor:indicatorContainer.rightAnchor constant:-15.0].active = YES;
    [activityIndicator.bottomAnchor constraintEqualToAnchor:indicatorContainer.bottomAnchor constant:-15.0].active = YES;
    [activityIndicator startAnimating];
    [self.view addSubview:indicatorContainer];
    [indicatorContainer.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [indicatorContainer.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor].active = YES;
}

@end
