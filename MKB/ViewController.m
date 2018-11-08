//
//  ViewController.m
//  Test
//
//  Created by Dan Lee on 2018/11/8.
//  Copyright © 2018 Dan Lee. All rights reserved.
//

#import "ViewController.h"
#import "MKB.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *valueTipLabel;
@property (weak, nonatomic) IBOutlet UIButton *settingButton;
@property (weak, nonatomic) IBOutlet UIButton *gettingButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)setAction:(id)sender {
    MKB *mkb = [MKB defaultMKB];
    [mkb setObject:@"Hello_value" forKey:@"Hello_key"];
}

- (IBAction)getAction:(id)sender {
    MKB *mkb = [MKB defaultMKB];
    NSString *v = [mkb objectForKey:@"Hello_key"];
    self.valueTipLabel.text = v;
}

- (IBAction)makeACrash:(id)sender {
    @[][666];
}


@end
