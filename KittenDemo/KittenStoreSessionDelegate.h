//
//  KittenStoreSessionDelegate.h
//  KittenDemo
//
//  Created by Mario Diana on 11/21/24.
//

#import <Foundation/Foundation.h>
#import "KittenUpdating.h"

@interface KittenStoreSessionDelegate : NSObject <NSURLSessionDataDelegate>

@property (nonatomic, strong) NSMutableData* data;
@property (nonatomic, weak) id<KittenUpdating> updater;

- (void)resetWithUpdater:(id<KittenUpdating>)updater;

@end
