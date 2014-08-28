//
//  EVCMakeFriendsPrefsViewController.m
//  MyDailyBeat
//
//  Created by Virinchi Balabhadrapatruni on 8/24/14.
//  Copyright (c) 2014 eVerveCorp. All rights reserved.
//

#import "EVCMakeFriendsPrefsViewController.h"

@interface EVCMakeFriendsPrefsViewController ()

@end

@implementation EVCMakeFriendsPrefsViewController

@synthesize tableView, api, formController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.formController = [[FXFormController alloc] init];
    self.formController.tableView = self.tableView;
    self.formController.delegate = self;
    self.formController.form = [[MakeFriendsPrefs alloc] init];
    api = [API getInstance];
    
        
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //reload the table
    [self retrievePrefs];
}

- (void) retrievePrefs {
    dispatch_queue_t queue = dispatch_queue_create("dispatch_queue_t_dialog", NULL);
    dispatch_async(queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view makeToastActivity];
        });
        
        self.formController.form = [api retrieveMakeFriendsPrefs];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view hideToastActivity];
            if (self.formController.form == nil)
                self.formController.form = [[MakeFriendsPrefs alloc] init];
            [self.tableView reloadData];
            
        });
    });

}

- (void)submit:(UITableViewCell<FXFormFieldCell> *)cell {
    MakeFriendsPrefs *prefs = cell.field.form;
    dispatch_queue_t queue = dispatch_queue_create("dispatch_queue_t_dialog", NULL);
    dispatch_async(queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view makeToastActivity];
        });

        BOOL success = [api uploadMakeFriendsPrefs:prefs];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view hideToastActivity];
            if (success)
                [self.navigationController popViewControllerAnimated:YES];
            else
                NSLog(@"Failed");
            
        });
    });
}



@end