//
//  DVOAppDelegate.m
//  Demo
//
//  Created by Mo Bitar on 4/20/14.
//  Copyright (c) 2014 Diveo. All rights reserved.
//

#import "DVOAppDelegate.h"
#import "DVOBouncer.h"

@implementation DVOAppDelegate
{
    DVOBouncer *bouncer;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    UIView *greenView = [[UIView alloc] initWithFrame:self.window.bounds];
    [greenView setBackgroundColor:[UIColor greenColor]];
    
    UIView *blueView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(greenView.frame), CGRectGetWidth(greenView.frame), CGRectGetHeight(greenView.frame))];
    [blueView setBackgroundColor:[UIColor blueColor]];
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.window.bounds];
    [scrollView setContentSize:CGSizeMake(CGRectGetWidth(greenView.frame), CGRectGetHeight(greenView.frame) * 2)];
    
    [scrollView addSubview:greenView];
    [scrollView addSubview:blueView];

    [self.window addSubview:scrollView];
    
    bouncer = [DVOBouncer bounceScrollView:scrollView inDirection:DVOBounceDirectionBottom];
    
    return YES;
}
@end
