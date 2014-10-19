//
//  EVCLabelTableViewCell.m
//  MyDailyBeat
//
//  Created by Virinchi Balabhadrapatruni on 10/18/14.
//  Copyright (c) 2014 eVerveCorp. All rights reserved.
//

#import "EVCLabelTableViewCell.h"

@implementation EVCLabelTableViewCell

@synthesize messageLbl;
- (id) initWithMessage:(NSString *)lblText {
    self = [self init];
    if (self) {
        self.message = lblText;
    }
    
    return self;
}

- (void)awakeFromNib {
    self.messageLbl.text = self.message;
}

@end
