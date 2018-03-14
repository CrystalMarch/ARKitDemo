//
//  ViewController.m
//  ARKitDemo
//
//  Created by 朱慧平 on 2018/3/14.
//  Copyright © 2018年 CountryPickerView. All rights reserved.
//

#import "ViewController.h"
#import "ModelDisplayViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIButton *displayDemoButton = [[UIButton alloc] init];
    [displayDemoButton setTitle:@"display" forState:UIControlStateNormal];
    [displayDemoButton setBackgroundColor:[UIColor redColor]];
    displayDemoButton.frame = CGRectMake(100, 100, 100, 100);
    displayDemoButton.center = self.view.center;
    [displayDemoButton addTarget:self action:@selector(displayButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:displayDemoButton];
}
- (void)displayButtonClick:(UIButton *)sender{
    ModelDisplayViewController *vc = [[ModelDisplayViewController alloc] init];
    vc.modelType = ModelTypeWolf;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
