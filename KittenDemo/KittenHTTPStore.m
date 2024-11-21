//
//  KittenStore.m
//  KittenDemo
//
//  Created by Mario Diana on 7/31/24.
//

#import "KittenHTTPStore.h"
#import "KittenStoreSessionDelegate.h"

// The key in the Info.plist file. The value needs to be in a file in the SRCROOT
// directory, called "api.key". The contents of that file are loaded with a build
// phase script.
NSString* const MDXCatAPIToken = @"MDXCatAPIToken";

NSString* const CatAPISearchURI = @"https://api.thecatapi.com/v1/images/search";


#pragma mark - Dependency injection for session creation

// Function can be mimicked for testing purposes to supply a dummy session.

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
