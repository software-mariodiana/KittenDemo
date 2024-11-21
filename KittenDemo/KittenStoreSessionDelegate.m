//
//  KittenStoreSessionDelegate.m
//  KittenDemo
//
//  Created by Mario Diana on 11/21/24.
//

#import "KittenStoreSessionDelegate.h"
#import "KittenJSONParsing.h"

NSString* const KittenStoreFetchErrorNotification = @"KittenStoreFetchErrorNotification";
NSString* const MDXSessionInvalidatedWithErrorNotification = @"MDXSessionInvalidatedWithErrorNotification";


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


- (NSURL *)extractImageURLFromData:(NSData *)data
{
    id parser = CreateKittenParser();
    id kitten = [parser parseJSONData:data];
    
    if ([kitten error]) {
        [self postError:[kitten error]];
        return nil;
    }
    
    return [kitten url];
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
        NSURL* url = [self extractImageURLFromData:[self data]];
        
        // Clear buffer of JSON data to prepare for image data.
        self.data = [NSMutableData data];
        
        if (url) {
            NSURLSessionDataTask* task = [session dataTaskWithURL:url];
            [task setTaskDescription:KittenImageDataFetchTaskDescription];
            
            [task resume];
        }
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
