//
//  KittenStoring.h
//  KittenDemo
//
//  Created by Mario Diana on 8/4/24.
//

#import <Foundation/Foundation.h>
#import "Kitten.h"

extern NSString* const KittenStoreFetchErrorNotification;

@protocol KittenStoring <NSObject>
- (void)fetchImageForKitten:(id<Kitten>)kitten;
@end

/**
 * Factory function to create implementation.
 */
extern id<KittenStoring> CreateKittenStore(void);
