//
//  MAHelpViewController.m
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAHelpViewController.h"
#import "MAAppDelegate.h"
#import "MBProgressHUD.h"

@interface MAHelpViewController () {

    MBProgressHUD *_hud;

}

@end

@implementation MAHelpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{

    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.dimBackground = YES;
    _hud.square = NO;
    _hud.labelText = @"Loading...";

    NSURL *url =[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kMapAttackWebHostname, kMAWebHelpPath]];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];

    [self.webView setDelegate:self];
    [self.webView loadRequest:request];

}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_hud hide:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    self.toolbarItems = [MAAppDelegate appDelegate].toolbarItems;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
