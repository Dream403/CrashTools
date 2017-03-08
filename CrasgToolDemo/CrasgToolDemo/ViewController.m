//
//  ViewController.m
//  CrasgToolDemo
//
//  Created by Snow_lu on 2017/3/8.
//  Copyright © 2017年 小虾米. All rights reserved.
//

#import "ViewController.h"
#import "CatchCrash.h"
@interface ViewController ()

@end

@implementation ViewController
- (IBAction)carshAction:(id)sender {
    //测试内退消息
    [self performSelector:@selector(test:)];
//
    [[NSMutableDictionary dictionaryWithCapacity:0] setValue:nil forKey:@"key"];

    
}
- (IBAction)clearB:(id)sender {
    
    NSLog(@"clear %d",[CatchCrash clearCrashLog]);
    
    NSArray  *temp =[CatchCrash getCrashLog];
    NSLog(@"%@",   temp );
    
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}





- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
