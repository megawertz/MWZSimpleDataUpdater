//
//  MWZSimpleDataUpdater.m
//  SimpleDataUpdater
//
//  Created by Jason Wertz on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MWZSimpleDataUpdater.h"
#import <CommonCrypto/CommonDigest.h>
#import <sys/utsname.h>

#define DEFAULT_UPDATE_TIMESPAN     60 * 60 * 24 * 1 // 1 day
#define LAST_UPDATE_SETTINGS_KEY    @"MWZLastUpdateCheck"         
#define FAILURE_STATUS_CODE         204 // No content
#define SUCCESS_STATUS_CODE         200 // OK
#define HASH_QUERY_VALUE            @"hash"

// Private
@interface MWZSimpleDataUpdater ()

// Private Properties
@property NSTimeInterval timeDependentUpdatesInterval;
@property long totalDownloaded;
@property long expectedDownloadSize;
@property (nonatomic, strong) NSMutableData *downloadData;
@property BOOL verifyDownload;
@property (nonatomic, strong) NSString *fileHash;
@property (nonatomic, strong) NSString *fileDownloadHost;
@property (nonatomic, strong) NSString *actualFileDownloadHost;

// Private Methods
-(NSString *)md5FromData:(NSData *)data;
// Generate all data to be sent to server
// TODO: Let the user pass-in the values to be logged
-(NSString *)generateDeviceInformationQueryString;
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
@synthesize fileHash = _fileHash;
@synthesize fileDownloadHost = _fileDownloadHost;
@synthesize verifyDownload = _verifyDownload;
@synthesize sendDeviceInformation = _sendDeviceInformation;

#pragma mark - Private Helper Methods

-(NSString *)md5FromData:(NSData *)data {
    
    unsigned char result[16];
    CC_MD5( data.bytes, data.length, result );
    
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
    
}

-(NSString *)generateDeviceInformationQueryString {
    
    
    // Get Device ID
    struct utsname systemInfo;
    uname(&systemInfo);    
    NSString *deviceVersion = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
   
    // Get OS Version
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];

    // Get Vendor Identifier (iOS 6 and above only)
    NSString *vendorID = nil;
    if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)])
        [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    // Get current app version
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    
    // currentDBVersion is required by updateWithKey:andValue: and not defined here.
    // This string is appended to the normal update URL below.
    NSString *deviceInfoQuery = [NSString stringWithFormat:@"&deviceVersion=%@&osVersion=%@&appVersion=%@&vendorId=%@",deviceVersion,osVersion,appVersion,vendorID];
    return deviceInfoQuery;
}


#pragma mark - Public Methods

// Initilizers
-(id)init {
    return [self initWithURL:nil andDelegate:nil];
}

-(id)initWithURL:(NSURL *)url andDelegate:(id<MWZSimpleDataUpdaterDelegate>)delegate {
    if((self = [super init])) {
        _timeDependentUpdates = NO;
        _verifyDownload = NO;
        _errorStatus = MWZUpdateErrorNone;
        _timeDependentUpdatesInterval = DEFAULT_UPDATE_TIMESPAN;
        _url = url;
        _delegate = delegate;
    }
    
    return self;
}

-(void)verifyDownload:(BOOL)flag withDownloadHost:(NSString *)host {
  
    self.verifyDownload = flag;
    
    // If host is nil use the existing host
    self.fileDownloadHost = (host == nil) ? [self.url host] : host;

}

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

// Send key(s)/value(s) to server url for update processing
-(void)updateWithKey:(NSString *)key andValue:(NSString *)value {
    
    if([self shouldUpdate])
    {
        NSMutableString *urlWithParameters = [NSMutableString stringWithFormat:@"%@?%@=%@",[self url], key, value];
        
        if(self.sendDeviceInformation)
            [urlWithParameters appendString:[self generateDeviceInformationQueryString]];
        
        NSURL *fullURL = [NSURL URLWithString:[urlWithParameters stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fullURL];

        __unused NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
        
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
-(void)setTimeDependentUpdates:(BOOL)flag withTimeInterval:(NSTimeInterval)interval {

    _timeDependentUpdates = flag;

    if(interval < 0)
        interval = DEFAULT_UPDATE_TIMESPAN;
    
    [self setTimeDependentUpdatesInterval:interval];
    
}

-(NSDate *)timeOfLastUpdate {
    
    NSDate *lastUpdate = nil;
    
    if([self timeDependentUpdates]) {
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
   
    // Data is done downloading.
    // Should we verify it?
    if([self verifyDownload]) {
    
        // If so, check it against the hash and URL 
        BOOL dataVerified = NO;

        if([self.fileHash isEqualToString:[self md5FromData:[self downloadData]]] && [self.actualFileDownloadHost isEqualToString:self.fileDownloadHost]){
            dataVerified = YES;
        }
        
        if(dataVerified) {
            if ([_delegate respondsToSelector:@selector(updater:didFinishDownloadingData:)]) {
                [_delegate updater:self didFinishDownloadingData:[self downloadData]];
            }
        }
        else {
            [self setErrorStatus:MWZUpdateErrorDataNotVerified];
            if ([_delegate respondsToSelector:@selector(updaterWillNotDownloadData:)]) {
                [_delegate updaterWillNotDownloadData:self];
            }
            
        }
    }
    else {
        if ([_delegate respondsToSelector:@selector(updater:didFinishDownloadingData:)]) {
            [_delegate updater:self didFinishDownloadingData:[self downloadData]];
        }
    }
}

-(NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    
    // Add code here to respond to a redirect if necessary
    
    // We only need this if it is necessary to verify the download
    // This delegate can get called multiple times but the last redirect should be our final download destination so the last state of these values should be valid.

    if([self verifyDownload]) {
        // Get the headers
        NSHTTPURLResponse *r = (NSHTTPURLResponse *)response;
        NSDictionary *redirectHeaders = [r allHeaderFields];
        // Get the URL we are actually going to for verification against where we think we are going
        NSString *urlString = [redirectHeaders objectForKey:@"Location"];
        NSURL *fullURL = [NSURL URLWithString:urlString];
        [self setActualFileDownloadHost:[fullURL host]];
        
        // Get the file hash from the query string
        // This is set by the server-side script sending the redirect request
        // This assumes the hash is the only value sent back
        // TODO: Set this to grab all query items into an NSDictionary and just grab the one referenced by the constant
        NSArray *queryComponents = [[fullURL query] componentsSeparatedByString:@"="];
        NSString *hashKey = [queryComponents objectAtIndex:0];
        if([hashKey isEqualToString:HASH_QUERY_VALUE])
            [self setFileHash:[queryComponents objectAtIndex:1]];
    
    }
    
    return request;
}





@end
