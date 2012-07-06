//
//  MWZViewController.h
//  SimpleDataUpdater
//
//  Created by Jason Wertz on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWZSimpleDataUpdater.h"

@interface MWZViewController : UIViewController <MWZSimpleDataUpdaterDelegate>

@property (weak, nonatomic) IBOutlet UILabel *dlStatus;
@property (weak, nonatomic) IBOutlet UIProgressView *dlProgressSlider;
@property (weak, nonatomic) IBOutlet UIImageView *dlImage;
@property (weak, nonatomic) IBOutlet UISwitch *dlTimeToggle;
@property (weak, nonatomic) IBOutlet UILabel *dlTimeLabel;

- (IBAction)download:(id)sender;
- (IBAction)switchToggled:(id)sender;

@end
