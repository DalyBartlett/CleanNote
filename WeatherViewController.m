//
//  WeatherViewController.m
//  CandidateProject
//
//  Created by Louis Zhu on 2017/11/14.
//  Copyright © 2017年 PerrchicK. All rights reserved.
//

#import "WeatherViewController.h"
#import "SmileWeatherDownLoader.h"

@interface WeatherViewController ()<NSXMLParserDelegate>
{
    UIButton *_btn;
}
//解析XML字符串
@property (nonatomic, strong) NSXMLParser *par;
@property (nonatomic, copy) NSString *currentElement;

@property (nonatomic,strong) SmileWeatherDownLoader *loader;
@property (nonatomic,strong) UIView * BackView;
@property (nonatomic,strong) UIImageView *BackgroundImage;
@end

@implementation WeatherViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.BackgroundImage = [[UIImageView alloc]initWithFrame:self.view.bounds];
    self.BackgroundImage.backgroundColor = [UIColor whiteColor];
    [self.BackgroundImage setContentScaleFactor:[[UIScreen mainScreen] scale]];
    self.BackgroundImage.contentMode =  UIViewContentModeScaleAspectFill;
    self.BackgroundImage.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.BackgroundImage.clipsToBounds  = YES;
    [self.view addSubview:self.BackgroundImage];
//    self.BackgroundImage.image = [UIImage imageNamed:@"bg"];
//    [self searchFlickrPhotos];
    self.BackView = [[UIView alloc]initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width, self.view.bounds.size.height/4*2.5)];
    self.BackView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.BackView];
    self.BackView.userInteractionEnabled = NO;
    SmileWeatherDemoVC *demoVC = [SmileWeatherDemoVC DemoVCToView:self.BackView];
    [[SmileWeatherDownLoader sharedDownloader]getWeatherDataFromLocation:self.loaction completion:^(SmileWeatherData * _Nullable data, NSError * _Nullable error) {
        if(data.currentData.currentTemperature.celsius == 0.0)
        {
            [self _TemperturealertWithTitle:nil message:@"Weather condition network is loading abnormally, please Back and reload weather forecast"];
        }
        [demoVC setData:data];
         
        
    }];
    _btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btn setFrame:CGRectMake(0, self.view.bounds.size.height-40, 70, 40)];
    [_btn setTitle:@"Back" forState:UIControlStateNormal];
    _btn.titleLabel.font = [UIFont systemFontOfSize:23];
    [_btn addTarget:self action:@selector(BackAddView) forControlEvents:UIControlEventTouchUpInside];
    [_btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.view addSubview:_btn];
    // Do any additional setup after loading the view.
}

-(void)_TemperturealertWithTitle:(NSString *)title message:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
}

-(void)BackAddView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
