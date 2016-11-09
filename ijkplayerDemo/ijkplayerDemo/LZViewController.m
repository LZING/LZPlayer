//
//  LZViewController.m
//  ijkplayerDemo
//
//  Created by mac on 16/11/9.
//  Copyright © 2016年 youshixiu. All rights reserved.
//

#import "LZViewController.h"
#import "LZPlayViewController.h"

@implementation LZViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *button = [[UIButton alloc] init];
    [button setTitle:@"回放" forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [button addTarget:self action:@selector(recordButtonDidClick) forControlEvents:UIControlEventTouchUpInside];
    button.center = self.view.center;
//    button.frame.size = CGSizeMake(100, 100);
    button.frame = CGRectMake(100, 100, 100, 100);
    button.backgroundColor = [UIColor redColor];
    [self.view addSubview:button];
}

- (void)recordButtonDidClick {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"player" bundle:nil];
    LZPlayViewController *playerVC = [sb instantiateInitialViewController];
    [self presentViewController:playerVC animated:YES completion:nil];
}

@end
