//
//  MWZSimpleDataUpdater.m
//  SimpleDataUpdater
//
//  Created by Jason Wertz on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MWZSimpleDataUpdater.h"

#define DEFAULT_UPDATE_TIMESPAN     0
#define LAST_UPDATE_SETTINGS_KEY    @"MWZLastUpdateCheck"         
#define FAILURE_STATUS_CODE         204 // No content
#define SUCCESS_STATUS_CODE         200 // OK

// Private
@interface MWZSimpleDataUpdater () {
}

// Private Properties
@property BOOL timeDependentUpdates;
@property NSTimeInterval timeDependentUpdatesInterval;
@property long totalDownloaded;
@property long expectedDownloadSize;
@property (nonatomic, weak) id<MWZSimpleDataUpdaterDelegate> delegate;
@property (nonatomic, strong) NSMutableData *downloadData;

// Private Methods
-(BOOL)shouldUpdate;
-(void)saveUpdateTime;

@end

@implementation MWZSimpleDataUpdater

@synthesize totalDownloaded = _totalDownloaded;
@synthesize expectedDownloadSize = _expectedDownloadSize;
@synthesize errorStatus = _errorStatus;
@synthesize timeDependentUpdatesInterval = _timeDependentUpdatesInterval;
@synthesize url = _url;
@synthesize timeDependentUpdates = _timeDependentUpdates;
@synthesize delegate = _delegate;
@synthesize downloadData = _downloadData;

#pragma mark - Private Helper Methods

-(BOOL)shouldUpdate {
    
    // Do we really do need to check with the server?
    if([self timeDependentUpdates]) {
        NSDate *lastUpdate = [self timeOfLastUpdate];
        
        // Do we actually have a time for the last update from NSUserDefaults
        // If not, set the current time and proceed with a check
        if(lastUpdate == nil) {
            return YES;
        }
        
        // See if the update needs to be processed
        // Last update is always prior to now so this should always be negative
        NSTimeInterval interval = fabs([lastUpdate timeIntervalSinceNow]);
        
        if(interval > [self timeDependentUpdatesInterval]) {
            return YES;
        }
        else {
            return NO;
        }
        
    }
    // If we aren't using time dependent updates just check
    else {
        return YES;
    }
}

-(void)saveUpdateTime {
    NSDate *now = [NSDate date];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:now forKey:LAST_UPDATE_SETTINGS_KEY];

}

#pragma mark - Public Methods

// Initilizers

-(id)init {
    if((self = [super init])) {
        _timeDependentUpdates = NO;
        _errorStatus = MWZUpdateErrorNone;
    }
    
    return self;
}

-(id)initWithURL:(NSURL *)url andDelegate:(id<MWZSimpleDataUpdaterDelegate>)delegate { 
    if((self = [self init])) {
        _url = url;
        _delegate = delegate;
    }
    
    return self; 
}

// Send key(s)/value(s) to server url for update processing
-(void)updateWithKey:(NSString *)key andValue:(NSString *)value {
    
    if([self shouldUpdate])
    {
        NSString *urlWithParameters = [NSString stringWithFormat:@"%@?%@=%@",[self url], key, value];
        
        NSURL *fullURL = [NSURL URLWithString:[urlWithParameters stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:fullURL];
        
        NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
        
        [self saveUpdateTime];
    }
    else {
        [self setErrorStatus:MWZUpdateErrorUpdateIntervalHasNotElapsed];
        if ([_delegate respondsToSelector:@selector(updaterWillNotDownloadData:)]) {
            [_delegate updaterWillNotDownloadData:self];
        }
    }
}

// Enable time dependent updates (this uses NSDefaults)
-(void)enableTimeDependentUpdates:(BOOL)flag withTimeInterval:(NSTimeInterval)interval { 
    [self setTimeDependentUpdates:flag];

    if(interval < 0)
        interval = DEFAULT_UPDATE_TIMESPAN;
    
    [self setTimeDependentUpdatesInterval:interval];
    
}

-(BOOL)isTimeDependentUpdatesEnabled {
    return _timeDependentUpdates;
}

-(NSDate *)timeOfLastUpdate {
    
    NSDate *lastUpdate = nil;
    
    if([self isTimeDependentUpdatesEnabled]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        lastUpdate = (NSDate *)[defaults objectForKey:LAST_UPDATE_SETTINGS_KEY];
    }
    
    return lastUpdate;
}

#pragma mark - NSURLConnection Delegates 

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
 
    [self setErrorStatus:MWZUpdateErrorNone];

    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

    NSInteger statusCode = [httpResponse statusCode];
    
    if(statusCode == SUCCESS_STATUS_CODE) {
        if ([_delegate respondsToSelector:@selector(updaterWillDownloadData:)]) {
            [_delegate updaterWillDownloadData:self];
        }
        NSMutableData *tmp = [NSMutableData data];
        [self setDownloadData:tmp];
        [self setExpectedDownloadSize:[response expectedContentLength]];
        [self setTotalDownloaded:0];
    }
    else if(statusCode == FAILURE_STATUS_CODE) {
        [self setErrorStatus:MWZUpdateErrorNoNewDataAvailable];
        if ([_delegate respondsToSelector:@selector(updaterWillNotDownloadData:)]) {
            [_delegate updaterWillNotDownloadData:self];
        }
        [connection cancel];
    }
    else {
        [self setErrorStatus:MWZUpdateErrorResponseCodeUnknown];
        if ([_delegate respondsToSelector:@selector(updaterWillNotDownloadData:)]) {
            [_delegate updaterWillNotDownloadData:self];
        }
        [connection cancel];
    }
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self setErrorStatus:MWZUpdateErrorTransmissionDisrupted];
    if ([_delegate respondsToSelector:@selector(updaterWillNotDownloadData:)]) {
        [_delegate updaterWillNotDownloadData:self];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    self.totalDownloaded += [data length];
    [[self downloadData] appendData:data];
   
    if ([_delegate respondsToSelector:@selector(updater:didUpdateDownloadProgress:)]) {
        
        float progress = 0.0;
        // If no content length is sent in headers, expectedDownloadSize should == -1
        if([self expectedDownloadSize] >= 0)
        {
            progress = ((double)_totalDownloaded/_expectedDownloadSize);
        }        
        
        [_delegate updater:self didUpdateDownloadProgress:progress];
    }
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if ([_delegate respondsToSelector:@selector(updater:didFinishDownloadingData:)]) {
        [_delegate updater:self didFinishDownloadingData:[self downloadData]];
    }

}

-(NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    
    // Add code here to respond to a redirect if necessary
    // If a redirect is required just allow it by returning the request argument
    return request;
}





@end
