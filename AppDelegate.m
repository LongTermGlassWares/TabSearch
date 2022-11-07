//
//  AppDelegate.m
//  TabSearch
//
//  Copyright 2022 Long Term Glass Wares, LLC. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:self.tabController];
    self.tabController.selectedIndex = 0;
    [self.window makeKeyAndVisible];

    return TRUE;
}


@end
