//
//  MWZSimpleDataUpdater.h
//  SimpleDataUpdater
//
//  Created by Jason Wertz on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// Delegate
@class MWZSimpleDataUpdater;

@protocol MWZSimpleDataUpdaterDelegate <NSObject>
@optional
-(void)updaterWillDownloadData:(MWZSimpleDataUpdater *)updater;
-(void)updaterWillNotDownloadData:(MWZSimpleDataUpdater *)updater;
-(void)updater:(MWZSimpleDataUpdater *)updater didFinishDownloadingData:(NSData *)data;
-(void)updater:(MWZSimpleDataUpdater *)updater didUpdateDownloadProgress:(float)progress;

@end

// Error status
enum {
    MWZUpdateErrorResponseCodeUnknown,
    MWZUpdateErrorTransmissionDisrupted,
    MWZUpdateErrorDataNotVerified,
    MWZUpdateErrorNoNewDataAvailable,
    MWZUpdateErrorUpdateIntervalHasNotElapsed,
    MWZUpdateErrorNone
};

typedef NSInteger MWZUpdateErrorStatus;

@interface MWZSimpleDataUpdater : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>

// Public Properties
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, weak) id<MWZSimpleDataUpdaterDelegate> delegate;
@property MWZUpdateErrorStatus errorStatus;
@property (readonly) BOOL timeDependentUpdates; // Must be set with interval
@property BOOL sendDeviceInformation;

// Initilizers
-(id)initWithURL:(NSURL *)url andDelegate:(id<MWZSimpleDataUpdaterDelegate>)delegate;

// Send key(s)/value(s) to server url for update processing
//-(void)updateWithKeysandValues:(NSDictionary *)values;
-(void)updateWithKey:(NSString *)key andValue:(NSString *)value;

// Verify data download by hash and make sure we redirect to correct url
// Set download host to nil to use the same host as the download URL
-(void)verifyDownload:(BOOL)flag withDownloadHost:(NSString *)host;

// Enable time dependent updates w/interval (this uses NSDefaults for now)
-(void)setTimeDependentUpdates:(BOOL)flag withTimeInterval:(NSTimeInterval)interval;
-(BOOL)shouldUpdate;
-(void)saveUpdateTime;

// Returns nil if time dependent updates are not enabled or no previous update has been run
-(NSDate *)timeOfLastUpdate;


@end
