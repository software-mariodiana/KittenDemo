//
//  KittenStore.m
//  KittenDemo
//
//  Created by Mario Diana on 7/31/24.
//

#import "KittenHTTPStore.h"

// The key in the Info.plist file. The value needs to be in a file in the SRCROOT
// directory, called "api.key". The contents of that file are loaded with a build
// phase script.
NSString* const MDXCatAPIToken = @"MDXCatAPIToken";

NSString* const KittenStoreFetchErrorNotification = @"KittenStoreFetchErrorNotification";
NSString* const MDXSessionInvalidatedWithErrorNotification = @"MDXSessionInvalidatedWithErrorNotification";

NSString* const CatAPISearchURI = @"https://api.thecatapi.com/v1/images/search";

// Example: [{"id":"9uk","url":"https://cdn2.thecatapi.com/images/9uk.jpg","width":1024,"height":683}]
NSString* const CatAPISearchResponseJSONKey = @"url";

#pragma mark - URLSessionDelegate handling Cat API

@interface KittenStoreSessionDelegate : NSObject <NSURLSessionDataDelegate>
@property (nonatomic, strong) NSMutableData* data;
@property (nonatomic, weak) id<KittenUpdating> updater;
@end

@implementation KittenStoreSessionDelegate

static NSString* const KittenImageDataFetchTaskDescription = @"KittenImageDataFetchTaskDescription";

- (void)resetWithUpdater:(id<KittenUpdating>)updater
{
    self.updater = updater;
    self.data = [NSMutableData data];
}


- (void)updateKittenWithImage:(UIImage *)image
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self updater] updateKitten:image];
    });
}


- (void)postError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:KittenStoreFetchErrorNotification
                                                            object:self
                                                          userInfo:@{ @"error": [error localizedDescription] }];
    });
}


- (void)postSessionInvalidatedWithError
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:MDXSessionInvalidatedWithErrorNotification
                                                            object:self
                                                          userInfo:nil];
    });
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    NSLog(@"Received data: %lu bytes", (unsigned long)[data length]);
    [[self data] appendData:data];
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        NSLog(@"Task completed with error: %@", [error localizedDescription]);
        [self postError:error];
        return;
    }
    
    if (![[task taskDescription] isEqualToString:KittenImageDataFetchTaskDescription]) {
        NSLog(@"## JSON task completed successfully.");
        
        NSError* error = nil;
        id json = [NSJSONSerialization JSONObjectWithData:[self data]
                                                        options:NSJSONReadingMutableContainers
                                                          error:&error];
        
        if (error) {
            [self postError:error];
            return;
        }
        
        // Clear buffer of JSON data to prepare for image data.
        self.data = [NSMutableData data];
        
        NSString* uri = [[json objectAtIndex:0] objectForKey:CatAPISearchResponseJSONKey];
        NSURL* url = [NSURL URLWithString:uri];
        
        NSURLSessionDataTask* task = [session dataTaskWithURL:url];
        [task setTaskDescription:KittenImageDataFetchTaskDescription];
        
        [task resume];
    }
    else {
        NSLog(@"## Image task completed successfully.");
        UIImage* image = [UIImage imageWithData:[self data]];
        
        if (image == nil) {
            [self postError:[NSError errorWithDomain:NSCocoaErrorDomain
                                                code:NSCoderInvalidValueError
                                            userInfo:@{ NSLocalizedDescriptionKey: @"Invalid image data." }]];
            
            return;
        }
        
        [self updateKittenWithImage:image];
    }
}


- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error 
{
    if (error) {
        NSLog(@"Session invalidated with error: %@", [error localizedDescription]);
        [self postError:error];
        [self postSessionInvalidatedWithError];
    } else {
        NSLog(@"Session invalidated successfully.");
    }
}

@end

#pragma mark - Dependency injection for session creation

// This can be mimicked for testing purposes to supply a dummy session.

NSURLSession* KittenStoreSessionFactory(NSString *apiKey)
{
    KittenStoreSessionDelegate* delegate = [[KittenStoreSessionDelegate alloc] init];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    [configuration setHTTPAdditionalHeaders:@{@"x-api-key": apiKey}];
    
    NSOperationQueue* queue = [[NSOperationQueue alloc] init];
    queue.qualityOfService = NSQualityOfServiceUtility;
    queue.maxConcurrentOperationCount = 1;
    
    return [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                         delegate:delegate
                                    delegateQueue:queue];
}


typedef NSURLSession* (*SessionFactoryType)(NSString *apiKey);

#pragma mark - KittenHTTPStore implementation

@interface KittenHTTPStore ()
@property (nonatomic, assign) SessionFactoryType sessionFactory;
@property (nonatomic, strong) NSURLSession* session;
@end

@implementation KittenHTTPStore

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (instancetype)initWithSessionFactory:(SessionFactoryType)sessionFactory
{
    self = [super init];
    
    if (self) {
        _sessionFactory = sessionFactory;
        NSString* apiKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:MDXCatAPIToken];
        _session = [self createURLSessionUsingAPIKey:apiKey];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleSessionInvalidatedWithError:)
                                                     name:MDXSessionInvalidatedWithErrorNotification
                                                   object:nil];
    }
    
    return self;
}


- (void)handleSessionInvalidatedWithError:(NSNotification *)note
{
    NSString* apiKey = [[[NSBundle mainBundle] infoDictionary] objectForKey:MDXCatAPIToken];
    self.session = [self createURLSessionUsingAPIKey:apiKey];
}


- (NSURLSession *)createURLSessionUsingAPIKey:(NSString *)apiKey
{
    SessionFactoryType factory = [self sessionFactory];
    return factory(apiKey);
}


- (void)fetchImageWithUpdater:(id<KittenUpdating>)updater
{
    id delegate = [[self session] delegate];
    [delegate resetWithUpdater:updater];
    NSURL* url = [NSURL URLWithString:CatAPISearchURI];
    NSURLSessionDataTask* task = [[self session] dataTaskWithURL:url];
    [task resume];
}

@end

#pragma mark - Public factory function for store

/**
 * Implementation of factory function from protocol.
 *
 * For testing, use a custom factory method, and pass it a SessionFactoryType function
 * that supplies a mock for the URLSession object.
 */
id<KittenStoring> CreateKittenStore(void)
{
    return [[KittenHTTPStore alloc] initWithSessionFactory:&KittenStoreSessionFactory];
}
