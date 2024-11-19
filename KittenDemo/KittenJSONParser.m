//
//  KittenJSONParser.m
//  KittenDemo
//
//  Created by Mario Diana on 11/19/24.
//

#import "KittenJSONParser.h"

// Example: [{"id":"9uk","url":"https://cdn2.thecatapi.com/images/9uk.jpg","width":1024,"height":683}]
NSString* const CatAPISearchResponseJSONKey = @"url";


@interface Kitten : NSObject <KittenURI>
@property (nonatomic, strong) NSURL* url;
@property (nonatomic, strong) NSError* error;
@end

@implementation Kitten
@end


@implementation KittenJSONParser

- (NSError *)createErrorWithDescription:(NSString *)message
{
    return [NSError errorWithDomain:NSCocoaErrorDomain
                               code:NSURLErrorCannotParseResponse
                           userInfo:@{ NSLocalizedDescriptionKey:message }];
}


- (id)validateJSON:(NSData *)data error:(NSError **)error
{
    id json = [NSJSONSerialization JSONObjectWithData:data
                                                    options:NSJSONReadingMutableContainers
                                                      error:error];
    
    if (*error) {
        return nil;
    }
    
    if (![json respondsToSelector:@selector(objectAtIndex:)]) {
        *error = [self createErrorWithDescription:@"Unexpected JSON format."];
        return nil;
    }
    
    if (![json respondsToSelector:@selector(count)] || [json count] == 0) {
        *error = [self createErrorWithDescription:@"Unexpected JSON format."];
        return nil;
    }
    
    id firstItem = [json objectAtIndex:0];
    
    if (![firstItem respondsToSelector:@selector(objectForKey:)]) {
        *error = [self createErrorWithDescription:@"Unexpected JSON format."];
        return nil;
    }
    
    if (![firstItem objectForKey:CatAPISearchResponseJSONKey]) {
        *error = [self createErrorWithDescription:@"Unexpected JSON format."];
        return nil;
    }
    
    return json;
}


- (id<KittenURI>)parseJSONData:(NSData *)data
{
    NSError* error = nil;
    id json = [self validateJSON:data error:&error];
    
    Kitten* kitten = [[Kitten alloc] init];
    
    if (error) {
        kitten.error = error;
    }
    else {
        NSString* location = [[json objectAtIndex:0] objectForKey:CatAPISearchResponseJSONKey];
        kitten.url = [NSURL URLWithString:location];
    }
    
    return kitten;
}

@end


id<KittenJSONParsing> CreateKittenParser(void)
{
    return [[KittenJSONParser alloc] init];
}
