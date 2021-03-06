//
//  EVCAppDelegate.m
//  MyDailyBeat
//
//  Created by Virinchi Balabhadrapatruni on 8/17/14.
//  Copyright (c) 2014 eVerveCorp. All rights reserved.
//

#import "EVCAppDelegate.h"
#import "BankDatabase.h"

@implementation EVCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    EVCLoginViewController *login = [[EVCLoginViewController alloc] initWithNibName:@"EVCLoginViewController_iPhone" bundle:nil];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:login];
    
    [self.window makeKeyAndVisible];
    NSArray *bundz = [[NSBundle bundleForClass:[self class]] URLsForResourcesWithExtension:@"framework" subdirectory:nil];
    for (NSURL *bundleURL in bundz) {
        NSBundle *child = [NSBundle bundleWithURL:bundleURL];
        [child load];
    }
    
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    [[UINavigationBar appearance] setBarTintColor:UIColorFromHex(0x0097A4)];
    [[UITabBar appearance] setBarTintColor:UIColorFromHex(0x0097A4)];
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Helvetica" size:15.0f], NSFontAttributeName, UIColorFromHex(0xE6E6E6), NSForegroundColorAttributeName, nil] forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Helvetica" size:15.0f], NSFontAttributeName, UIColorFromHex(0xFFFFFF), NSForegroundColorAttributeName, nil] forState:UIControlStateSelected];
    [[UITableView appearance] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    
    
    return YES;
}

- (BOOL)hasEverBeenLaunched
{
    // A boolean which determines if app has eer been launched
    BOOL hasBeenLaunched;
    
    // Testig if application has launched before and if it has to show the home-login screen to login
    // to social networks (facebook, Twitter)
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"HasAlreadyLaunched"]) {
        // Setting variable to YES because app has been launched before
        hasBeenLaunched = YES;
        NSLog(@"App has been already launched");
    } else {
        // Setting variable to NO because app hasn't been launched before
        hasBeenLaunched = NO;
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasAlreadyLaunched"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"This is the first run ever...");
    }
    
    return hasBeenLaunched;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"JobTypeFilter"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"JobSearchRadiusFilter"];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"JobTypeFilter"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"JobSearchRadiusFilter"];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
