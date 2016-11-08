//
//  ViewController.m
//  ZHAudioPlayerDemo
//
//  Created by kaka on 16/11/8.
//  Copyright © 2016年 kaka. All rights reserved.
//

#import "ViewController.h"
#import "ZHAudioPlayer.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //网络音频
    [[ZHAudioPlayer sharedInstance] manageAudioWithUrlPath:@"网络音频地址" playOrPause:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
