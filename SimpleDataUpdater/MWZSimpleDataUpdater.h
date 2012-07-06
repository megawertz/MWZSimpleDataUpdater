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
    MWZUpdateErrorNoNewDataAvailable,
    MWZUpdateErrorUpdateIntervalHasNotElapsed,
    MWZUpdateErrorNone
};

typedef NSInteger MWZUpdateErrorStatus;

@interface MWZSimpleDataUpdater : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>

// Public Properties
@property (nonatomic, retain) NSURL *url;
@property MWZUpdateErrorStatus errorStatus;

// Initilizers
-(id)initWithURL:(NSURL *)url andDelegate:(id<MWZSimpleDataUpdaterDelegate>)delegate;

// Send key(s)/value(s) to server url for update processing
//-(void)updateWithKeysandValues:(NSDictionary *)values;
-(void)updateWithKey:(NSString *)key andValue:(NSString *)value;

// Enable time dependent updates (this uses NSDefaults for now)
-(void)enableTimeDependentUpdates:(BOOL)flag withTimeInterval:(NSTimeInterval)interval;
-(BOOL)isTimeDependentUpdatesEnabled;

// Returns nil if time dependent updates are not enabled or no previous update has been run
-(NSDate *)timeOfLastUpdate;

@end
