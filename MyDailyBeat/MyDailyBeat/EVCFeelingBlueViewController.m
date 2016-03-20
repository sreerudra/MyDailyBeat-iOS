//
//  EVCFeelingBlueViewController.m
//  MyDailyBeat
//
//  Created by Virinchi Balabhadrapatruni on 1/9/15.
//  Copyright (c) 2015 eVerveCorp. All rights reserved.
//

#import "EVCFeelingBlueViewController.h"

@interface EVCFeelingBlueViewController ()

@end

@implementation EVCFeelingBlueViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImage* image3 = [EVCCommonMethods imageWithImage:[UIImage imageNamed:@"hamburger-icon-white"] scaledToSize:CGSizeMake(30, 30)];
    CGRect frameimg = CGRectMake(0, 0, image3.size.width, image3.size.height);
    UIButton *someButton = [[UIButton alloc] initWithFrame:frameimg];
    [someButton setBackgroundImage:image3 forState:UIControlStateNormal];
    [someButton addTarget:self action:@selector(showMenu)
         forControlEvents:UIControlEventTouchUpInside];
    [someButton setShowsTouchWhenHighlighted:YES];
    
    UIBarButtonItem *menuButton =[[UIBarButtonItem alloc] initWithCustomView:someButton];

    self.navigationItem.rightBarButtonItem = menuButton;
    
    UIImage* image4 = [EVCCommonMethods imageWithImage:[UIImage imageNamed:@"profile-icon-white"] scaledToSize:CGSizeMake(30, 30)];
    CGRect frameimg2 = CGRectMake(0, 0, image4.size.width, image4.size.height);
    UIButton *someButton2 = [[UIButton alloc] initWithFrame:frameimg2];
    [someButton2 setBackgroundImage:image4 forState:UIControlStateNormal];
    [someButton2 addTarget:self action:@selector(showProfile)
          forControlEvents:UIControlEventTouchUpInside];
    [someButton2 setShowsTouchWhenHighlighted:YES];
    
    UIBarButtonItem *profileButton =[[UIBarButtonItem alloc] initWithCustomView:someButton2];
    self.navigationItem.leftBarButtonItem = profileButton;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *TAG = @"TAG";
    
    UITableViewCell *cell = cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TAG];
    
    switch (indexPath.row) {
        case 0: {
            cell.textLabel.text = @"Call Suicide Hotline";
            UIImage *image = [UIImage imageNamed:@"suicide.png"];
            image = [EVCCommonMethods imageWithImage:image scaledToSize:CGSizeMake(60, 60)];
            cell.imageView.image = image;
        }
            break;
        case 1: {
            cell.textLabel.text = @"Call Veterans Hotline";
            UIImage *image = [UIImage imageNamed:@"veterans.png"];
            image = [EVCCommonMethods imageWithImage:image scaledToSize:CGSizeMake(60, 60)];
            cell.imageView.image = image;
        }
            break;
        case 2: {
            cell.textLabel.text = @"Call Anonymously";
            UIImage *image = [UIImage imageNamed:@"anonymous.png"];
            image = [EVCCommonMethods imageWithImage:image scaledToSize:CGSizeMake(60, 60)];
            cell.imageView.image = image;
        }
            break;
            
        default:
            break;
    }
    
    return cell;
    
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0:
            [self makeCall: @"1-800-273-8255"];
            break;
        case 1:
            [self makeCall: @"1-800-273-8255" withAccessCode:@"1"];
            break;
        case 2: {
            EVCFeelingBlueTableViewController *table = [[EVCFeelingBlueTableViewController alloc] initWithNibName:@"EVCFeelingBlueTableViewController" bundle:nil];
            [self.navigationController pushViewController:table animated:YES];
            break;
        }
            
        default:
            break;
    }
}

- (IBAction)callSuicideAction:(id)sender {
    [self makeCall: @"1-800-273-8255"];
}
- (IBAction)callVeteransAction:(id)sender {
    [self makeCall: @"1-800-273-8255" withAccessCode:@"1"];
}

- (IBAction)callTestAction:(id)sender {
    [self makeCall: @"1-978-761-3113"];
}

- (void) makeCall:(NSString *) num {
    NSString *dialstring = [[NSString alloc] initWithFormat:@"telprompt://%@", num];
    NSURL *url = [NSURL URLWithString:dialstring];
    [[UIApplication sharedApplication] openURL:url];
}
- (void) makeCall:(NSString *) num withAccessCode: (NSString *) code{
    NSString *dialstring = [[NSString alloc] initWithFormat:@"telprompt://%@,,%@", num, code];
    NSURL *url = [NSURL URLWithString:dialstring];
    [[UIApplication sharedApplication] openURL:url];
}

- (void) showMenu {
    [self.sideMenuViewController presentRightMenuViewController];
}

- (void) showProfile {
    [self.sideMenuViewController presentLeftMenuViewController];
}

@end
