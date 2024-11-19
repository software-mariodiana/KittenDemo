//
//  KittenJSONParsing.h
//  KittenDemo
//
//  Created by Mario Diana on 11/19/24.
//

#import <Foundation/Foundation.h>

@protocol KittenURI <NSObject>
@property (nonatomic, strong, readonly) NSURL* url;
@property (nonatomic, strong, readonly) NSError* error;
@end

@protocol KittenJSONParsing <NSObject>
- (id<KittenURI>)parseJSONData:(NSData *)data;
@end

/**
 * Factory function to create implementation.
 */
extern id<KittenJSONParsing> CreateKittenParser(void);
