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
-(void)updaterFailed:(MWZSimpleDataUpdater *)updater;
-(void)updater:(MWZSimpleDataUpdater *)updater didFinishDownloadingData:(NSData *)data;
@end

// Error status

enum {
    MWZUpdateErrorResponseCodeUnknown,
    MWZUpdateErrorTransmissionDisrupted,
    MWZUpdateErrorNone
};

typedef NSInteger MWZUpdateErrorStatus;

@interface MWZSimpleDataUpdater : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDelegate>

// Properties
@property (nonatomic, retain) NSURL *url;
@property MWZUpdateErrorStatus errorStatus;

// Initilizers
-(id)initWithURL:(NSURL *)url andDelegate:(id<MWZSimpleDataUpdaterDelegate>)delegate;

// Send key(s)/value(s) to server url for update processing
//-(void)updateWithKeysandValues:(NSDictionary *)values;
-(void)updateWithKey:(NSString *)key andValue:(NSString *)value;

// Enable time dependent updates (this uses NSDefaults for now)
-(void)enableTimeDependentUpdates:(BOOL)flag withTimeInterval:(NSTimeInterval)interval;

@end
