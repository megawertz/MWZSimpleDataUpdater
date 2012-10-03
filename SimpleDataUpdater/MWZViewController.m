//
//  MWZViewController.m
//  SimpleDataUpdater
//
//  Created by Jason Wertz on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MWZViewController.h"

#define DOWNLOAD_SCRIPT_URL @"https://yourappname.appspot.com/downloader"
#define DOWNLOAD_TIME_INTERVAL 30
#define QUERY_KEY @"v"
#define QUERY_VALUE @"0"

@interface MWZViewController ()
@end

@implementation MWZViewController

@synthesize dlStatus;
@synthesize dlProgressSlider;
@synthesize dlImage;
@synthesize dlTimeToggle;
@synthesize dlTimeLabel;
@synthesize dlVerifyToggle;

#pragma mark - MWZSimpleDataUpdaterDelegateMethods

-(void)updaterWillDownloadData:(MWZSimpleDataUpdater *)updater {
    
    if([dlVerifyToggle isOn])
        [self.dlStatus setText:@"Verified"];
    else
        [self.dlStatus setText:@"Available"];
}

-(void)updaterWillNotDownloadData:(MWZSimpleDataUpdater *)updater {
    
    if([updater errorStatus] == MWZUpdateErrorNoNewDataAvailable)
        [self.dlStatus setText:@"Nothing New"];

    if([updater errorStatus] == MWZUpdateErrorUpdateIntervalHasNotElapsed)
        [self.dlStatus setText:@"Too Soon"];

    if([updater errorStatus] == MWZUpdateErrorDataNotVerified)
        [self.dlStatus setText:@"Data Not Verified."];
    
    if([updater errorStatus] == MWZUpdateErrorResponseCodeUnknown ||
       [updater errorStatus] == MWZUpdateErrorTransmissionDisrupted)
        [self.dlStatus setText:@"Error"];

}

-(void)updater:(MWZSimpleDataUpdater *)updater didFinishDownloadingData:(NSData *)data {
    UIImage *image = [UIImage imageWithData:data];
    [self.dlImage setImage:image];
    
}

-(void)updater:(MWZSimpleDataUpdater *)updater didUpdateDownloadProgress:(float)progress {
    [self.dlProgressSlider setProgress:progress];
}



#pragma mark - Standard ViewController Stuff

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
}

- (void)viewDidUnload
{
    [self setDlStatus:nil];
    [self setDlProgressSlider:nil];
    [self setDlImage:nil];
    [self setDlTimeToggle:nil];
    [self setDlTimeLabel:nil];
    [self setDlVerifyToggle:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)download:(id)sender {

    // Lazy load this, no need for this to persist
    NSURL *url = [NSURL URLWithString:DOWNLOAD_SCRIPT_URL];
    
    MWZSimpleDataUpdater *updater = [[MWZSimpleDataUpdater alloc] initWithURL:url andDelegate:self];

    [updater setSendDeviceInformation:YES];
    
    [updater verifyDownload:[dlVerifyToggle isOn] withDownloadHost:nil];
    
    [updater setTimeDependentUpdates:[dlTimeToggle isOn] withTimeInterval:DOWNLOAD_TIME_INTERVAL];
    
    [updater updateWithKey:QUERY_KEY andValue:QUERY_VALUE];
  
}

- (IBAction)switchToggled:(id)sender {
    
    NSString *tmp = @"-";
    if([dlTimeToggle isOn])
    {
         tmp = [NSString stringWithFormat:@"%d Seconds",DOWNLOAD_TIME_INTERVAL];
    }
  
    [self.dlTimeLabel setText:tmp];
    
}

@end
